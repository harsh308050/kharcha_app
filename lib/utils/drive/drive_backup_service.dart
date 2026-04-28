import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:kharcha/utils/sms/sms_transaction.dart';

class DriveBackupResult {
  final bool success;
  final bool uploaded;
  final String message;

  const DriveBackupResult({
    required this.success,
    required this.uploaded,
    required this.message,
  });

  factory DriveBackupResult.success({
    bool uploaded = false,
    String message = 'Drive backup completed.',
  }) {
    return DriveBackupResult(
      success: true,
      uploaded: uploaded,
      message: message,
    );
  }

  factory DriveBackupResult.failure(String message) {
    return DriveBackupResult(success: false, uploaded: false, message: message);
  }
}

class DriveBackupService {
  static const String _driveFileScope =
      'https://www.googleapis.com/auth/drive.file';
  static const String _driveAppDataScope =
      'https://www.googleapis.com/auth/drive.appdata';
  static const String _folderName = 'kharcha';
  static const String _transactionsFileName = 'transactions.json';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  DriveBackupService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(scopes: <String>[_driveFileScope, _driveAppDataScope]);

  Future<DriveBackupResult> backupTransactionsToDrive(
    List<SmsTransaction> transactions,
  ) async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return DriveBackupResult.failure('No signed-in Firebase user.');
    }

    final String userEmail = (currentUser.email ?? '').trim().toLowerCase();
    if (userEmail.isEmpty) {
      return DriveBackupResult.failure('Signed-in user email is missing.');
    }

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await _firestore
        .collection('users')
        .doc(userEmail)
        .get();
    final Map<String, dynamic>? userData = userSnapshot.data();
    final bool driveGranted =
        (userData?['driveAccessGranted'] as bool?) ?? false;
    if (!driveGranted) {
      return DriveBackupResult.failure('Drive access was not granted.');
    }

    final String expectedDriveEmail =
        ((userData?['driveAccountEmail'] as String?) ?? userEmail)
            .trim()
            .toLowerCase();

    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    if (account == null) {
      account = await _googleSignIn.signIn();
      if (account == null) {
        return DriveBackupResult.failure(
          'Unable to sign in to Google account for Drive backup.',
        );
      }
    }

    String signedDriveEmail = account.email.trim().toLowerCase();
    if (signedDriveEmail != expectedDriveEmail) {
      await _googleSignIn.signOut();
      account = await _googleSignIn.signIn();
      if (account == null) {
        return DriveBackupResult.failure(
          'Google account selection was cancelled for Drive backup.',
        );
      }

      signedDriveEmail = account.email.trim().toLowerCase();
      if (signedDriveEmail != expectedDriveEmail) {
        return DriveBackupResult.failure(
          'Selected Google account does not match Drive-linked account.',
        );
      }
    }

    final bool scopesGranted = await _googleSignIn.requestScopes(<String>[
      _driveFileScope,
      _driveAppDataScope,
    ]);
    if (!scopesGranted) {
      return DriveBackupResult.failure('Google Drive scopes were not granted.');
    }

    final Map<String, String> headers = await account.authHeaders;
    if (!headers.containsKey('Authorization')) {
      return DriveBackupResult.failure(
        'Missing Google auth header for Drive API calls.',
      );
    }

    final _GoogleAuthClient client = _GoogleAuthClient(headers);
    try {
      final drive.DriveApi driveApi = drive.DriveApi(client);
      final String folderId = await _ensureKharchaFolder(driveApi);

      final String? existingFileId = await _findTransactionsFileId(
        driveApi,
        folderId,
      );

      final List<Map<String, dynamic>> existingTransactions =
          existingFileId == null
          ? <Map<String, dynamic>>[]
          : await _readExistingTransactions(client, existingFileId);

      final Map<String, Map<String, dynamic>> mergedById =
          <String, Map<String, dynamic>>{};

      for (final Map<String, dynamic> existing in existingTransactions) {
        final String id = _resolveTransactionId(existing);
        if (id.isEmpty) {
          continue;
        }
        final Map<String, dynamic> normalized = <String, dynamic>{...existing}
          ..['transactionId'] = id;
        mergedById[id] = normalized;
      }

      int newTransactionsAdded = 0;
      for (final SmsTransaction transaction in transactions) {
        final Map<String, dynamic> current = _transactionToDriveJson(
          transaction,
        );
        final String id = current['transactionId'] as String;
        if (!mergedById.containsKey(id)) {
          newTransactionsAdded += 1;
        }
        mergedById[id] = current;
      }

      final List<Map<String, dynamic>> mergedTransactions =
          mergedById.values.toList()..sort(
            (Map<String, dynamic> a, Map<String, dynamic> b) =>
                _transactionEpoch(b).compareTo(_transactionEpoch(a)),
          );

      final bool shouldUpload =
          existingFileId == null || newTransactionsAdded > 0;

      if (shouldUpload) {
        final String jsonPayload = jsonEncode(<String, dynamic>{
          'app': 'kharcha',
          'schemaVersion': 2,
          'exportMode': 'incremental-merge',
          'exportedAt': DateTime.now().toIso8601String(),
          'userEmail': userEmail,
          'totalTransactions': mergedTransactions.length,
          'newTransactionsAdded': newTransactionsAdded,
          'transactions': mergedTransactions,
        });

        final List<int> bytes = utf8.encode(jsonPayload);
        final drive.Media media = drive.Media(
          Stream<List<int>>.fromIterable(<List<int>>[bytes]),
          bytes.length,
        );

        if (existingFileId == null) {
          final drive.File createMetadata = drive.File()
            ..name = _transactionsFileName
            ..mimeType = 'application/json'
            ..parents = <String>[folderId];

          await driveApi.files.create(createMetadata, uploadMedia: media);
        } else {
          final drive.File updateMetadata = drive.File()
            ..name = _transactionsFileName
            ..mimeType = 'application/json';

          await driveApi.files.update(
            updateMetadata,
            existingFileId,
            uploadMedia: media,
          );
        }
      }

      await _firestore.collection('users').doc(userEmail).set(<String, dynamic>{
        'driveLastBackupAt': FieldValue.serverTimestamp(),
        'driveLastBackupCount': mergedTransactions.length,
        'driveLastBackupNewCount': newTransactionsAdded,
        'driveLastBackupWasUploaded': shouldUpload,
        'driveBackupFileName': _transactionsFileName,
        'driveLastBackupStatus': 'success',
        'driveLastBackupError': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return DriveBackupResult.success(
        uploaded: shouldUpload,
        message: shouldUpload
            ? 'Drive backup uploaded successfully.'
            : 'No new transactions to upload.',
      );
    } catch (e, st) {
      debugPrint('Drive backup failed: $e');
      debugPrint(st.toString());

      await _firestore.collection('users').doc(userEmail).set(<String, dynamic>{
        'driveLastBackupAt': FieldValue.serverTimestamp(),
        'driveLastBackupStatus': 'failed',
        'driveLastBackupError': e.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return DriveBackupResult.failure(
        'Drive backup failed: ${e.runtimeType}. Check Google Cloud Drive API and OAuth setup.',
      );
    } finally {
      client.close();
    }
  }

  Future<DriveBackupResult> updateTransactionInDrive({
    required SmsTransaction original,
    required SmsTransaction updated,
  }) async {
    return _mutateTransactionsInDrive((List<Map<String, dynamic>> existing) {
      final Map<String, Map<String, dynamic>> byId =
          <String, Map<String, dynamic>>{};
      for (final Map<String, dynamic> value in existing) {
        final String id = _resolveTransactionId(value);
        if (id.isNotEmpty) {
          byId[id] = <String, dynamic>{...value, 'transactionId': id};
        }
      }

      final String originalId = _buildTransactionIdFromSeed(
        _transactionSeed(
          rawMessage: original.rawMessage,
          senderId: original.senderId,
          smsDate: original.smsDate?.toIso8601String() ?? '',
          amount: original.amount.toStringAsFixed(2),
          type: original.type.name,
          method: original.method,
          bank: original.bank,
          account: original.account,
          counterparty: original.counterparty,
          reference: original.reference,
        ),
      );

      if (!byId.containsKey(originalId)) {
        return (transactions: existing, uploaded: false, changed: false);
      }

      final Map<String, dynamic> updatedJson = _transactionToDriveJson(updated)
        ..['transactionId'] = originalId;
      byId[originalId] = updatedJson;

      final List<Map<String, dynamic>> next = byId.values.toList()
        ..sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              _transactionEpoch(b).compareTo(_transactionEpoch(a)),
        );

      return (transactions: next, uploaded: true, changed: true);
    });
  }

  Future<DriveBackupResult> deleteTransactionFromDrive({
    required SmsTransaction transaction,
  }) async {
    return _mutateTransactionsInDrive((List<Map<String, dynamic>> existing) {
      final String targetId = _buildTransactionIdFromSeed(
        _transactionSeed(
          rawMessage: transaction.rawMessage,
          senderId: transaction.senderId,
          smsDate: transaction.smsDate?.toIso8601String() ?? '',
          amount: transaction.amount.toStringAsFixed(2),
          type: transaction.type.name,
          method: transaction.method,
          bank: transaction.bank,
          account: transaction.account,
          counterparty: transaction.counterparty,
          reference: transaction.reference,
        ),
      );

      final List<Map<String, dynamic>> next = <Map<String, dynamic>>[];
      bool removed = false;
      for (final Map<String, dynamic> value in existing) {
        final String currentId = _resolveTransactionId(value);
        if (!removed && currentId == targetId) {
          removed = true;
          continue;
        }
        next.add(value);
      }

      return (transactions: next, uploaded: removed, changed: removed);
    });
  }

  Future<DriveBackupResult> _mutateTransactionsInDrive(
    ({List<Map<String, dynamic>> transactions, bool uploaded, bool changed})
    Function(List<Map<String, dynamic>> existing)
    mutation,
  ) async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return DriveBackupResult.failure('No signed-in Firebase user.');
    }

    final String userEmail = (currentUser.email ?? '').trim().toLowerCase();
    if (userEmail.isEmpty) {
      return DriveBackupResult.failure('Signed-in user email is missing.');
    }

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await _firestore
        .collection('users')
        .doc(userEmail)
        .get();
    final Map<String, dynamic>? userData = userSnapshot.data();
    final bool driveGranted =
        (userData?['driveAccessGranted'] as bool?) ?? false;
    if (!driveGranted) {
      return DriveBackupResult.failure('Drive access was not granted.');
    }

    final String expectedDriveEmail =
        ((userData?['driveAccountEmail'] as String?) ?? userEmail)
            .trim()
            .toLowerCase();

    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    if (account == null) {
      account = await _googleSignIn.signIn();
      if (account == null) {
        return DriveBackupResult.failure(
          'Unable to sign in to Google account for Drive backup.',
        );
      }
    }

    String signedDriveEmail = account.email.trim().toLowerCase();
    if (signedDriveEmail != expectedDriveEmail) {
      await _googleSignIn.signOut();
      account = await _googleSignIn.signIn();
      if (account == null) {
        return DriveBackupResult.failure(
          'Google account selection was cancelled for Drive backup.',
        );
      }

      signedDriveEmail = account.email.trim().toLowerCase();
      if (signedDriveEmail != expectedDriveEmail) {
        return DriveBackupResult.failure(
          'Selected Google account does not match Drive-linked account.',
        );
      }
    }

    final bool scopesGranted = await _googleSignIn.requestScopes(<String>[
      _driveFileScope,
      _driveAppDataScope,
    ]);
    if (!scopesGranted) {
      return DriveBackupResult.failure('Google Drive scopes were not granted.');
    }

    final Map<String, String> headers = await account.authHeaders;
    if (!headers.containsKey('Authorization')) {
      return DriveBackupResult.failure(
        'Missing Google auth header for Drive API calls.',
      );
    }

    final _GoogleAuthClient client = _GoogleAuthClient(headers);
    try {
      final drive.DriveApi driveApi = drive.DriveApi(client);
      final String folderId = await _ensureKharchaFolder(driveApi);
      final String? existingFileId = await _findTransactionsFileId(
        driveApi,
        folderId,
      );
      if (existingFileId == null) {
        return DriveBackupResult.failure('No Drive backup file found.');
      }

      final List<Map<String, dynamic>> existing =
          await _readExistingTransactions(client, existingFileId);
      final ({
        List<Map<String, dynamic>> transactions,
        bool uploaded,
        bool changed,
      })
      result = mutation(existing);

      if (!result.changed) {
        return DriveBackupResult.success(
          uploaded: false,
          message: 'No matching transaction found to update.',
        );
      }

      final String jsonPayload = jsonEncode(<String, dynamic>{
        'app': 'kharcha',
        'schemaVersion': 2,
        'exportMode': 'incremental-merge',
        'exportedAt': DateTime.now().toIso8601String(),
        'userEmail': userEmail,
        'totalTransactions': result.transactions.length,
        'newTransactionsAdded': 0,
        'transactions': result.transactions,
      });

      final List<int> bytes = utf8.encode(jsonPayload);
      final drive.Media media = drive.Media(
        Stream<List<int>>.fromIterable(<List<int>>[bytes]),
        bytes.length,
      );

      final drive.File updateMetadata = drive.File()
        ..name = _transactionsFileName
        ..mimeType = 'application/json';

      await driveApi.files.update(
        updateMetadata,
        existingFileId,
        uploadMedia: media,
      );

      return DriveBackupResult.success(
        uploaded: result.uploaded,
        message: 'Drive backup updated successfully.',
      );
    } catch (e) {
      return DriveBackupResult.failure(
        'Drive backup failed: ${e.runtimeType}. Check Google Cloud Drive API and OAuth setup.',
      );
    } finally {
      client.close();
    }
  }

  Future<String> _ensureKharchaFolder(drive.DriveApi driveApi) async {
    final drive.FileList list = await driveApi.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and name = '$_folderName' and 'root' in parents and trashed = false",
      $fields: 'files(id,name)',
      spaces: 'drive',
      pageSize: 10,
    );

    final List<drive.File>? files = list.files;
    if (files != null && files.isNotEmpty && files.first.id != null) {
      return files.first.id!;
    }

    final drive.File folderMetadata = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = <String>['root'];

    final drive.File folder = await driveApi.files.create(
      folderMetadata,
      $fields: 'id',
    );

    final String? folderId = folder.id;
    if (folderId == null || folderId.isEmpty) {
      throw StateError('Failed to create Drive folder for backup.');
    }

    return folderId;
  }

  Future<String?> _findTransactionsFileId(
    drive.DriveApi driveApi,
    String folderId,
  ) async {
    final drive.FileList list = await driveApi.files.list(
      q: "name = '$_transactionsFileName' and '$folderId' in parents and trashed = false",
      $fields: 'files(id,name)',
      spaces: 'drive',
      pageSize: 10,
    );

    final List<drive.File>? files = list.files;
    if (files == null || files.isEmpty) {
      return null;
    }

    return files.first.id;
  }

  Future<List<Map<String, dynamic>>> _readExistingTransactions(
    _GoogleAuthClient client,
    String fileId,
  ) async {
    final Uri uri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
    );
    final http.Response response = await client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return <Map<String, dynamic>>[];
    }

    if (response.body.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return <Map<String, dynamic>>[];
    }

    final List<dynamic> rawList =
        (decoded['transactions'] as List<dynamic>?) ?? <dynamic>[];

    return rawList
        .whereType<Map>()
        .map((Map value) => Map<String, dynamic>.from(value))
        .toList();
  }

  Map<String, dynamic> _transactionToDriveJson(SmsTransaction transaction) {
    final String id = _buildTransactionIdFromSeed(
      _transactionSeed(
        rawMessage: transaction.rawMessage,
        senderId: transaction.senderId,
        smsDate: transaction.smsDate?.toIso8601String() ?? '',
        amount: transaction.amount.toStringAsFixed(2),
        type: transaction.type.name,
        method: transaction.method,
        bank: transaction.bank,
        account: transaction.account,
        counterparty: transaction.counterparty,
        reference: transaction.reference,
      ),
    );

    final Map<String, dynamic> payload = <String, dynamic>{
      ...transaction.toJson(),
      'transactionId': id,
    };

    // Only set default note if note is completely empty or null
    // Do NOT overwrite if user has added a custom note
    final String note = (payload['note'] as String?)?.trim() ?? '';
    final bool hasRawMessage = transaction.rawMessage.trim().isNotEmpty;

    // Only set default note if the note field is truly empty
    if (hasRawMessage && note.isEmpty) {
      final String normalizedMethod = transaction.method.trim();
      payload['note'] = normalizedMethod.isEmpty
          ? 'Imported from SMS'
          : 'Imported via $normalizedMethod SMS';
    }

    return payload;
  }

  String _resolveTransactionId(Map<String, dynamic> value) {
    final String existingId = (value['transactionId'] as String?)?.trim() ?? '';
    if (existingId.isNotEmpty) {
      return existingId;
    }

    return _buildTransactionIdFromSeed(
      _transactionSeed(
        rawMessage: (value['rawMessage'] as String?) ?? '',
        senderId: (value['senderId'] as String?) ?? '',
        smsDate: (value['smsDate'] as String?) ?? '',
        amount: value['amount']?.toString() ?? '',
        type: (value['type'] as String?) ?? '',
        method: (value['method'] as String?) ?? '',
        bank: (value['bank'] as String?) ?? '',
        account: (value['account'] as String?) ?? '',
        counterparty: (value['counterparty'] as String?) ?? '',
        reference: (value['reference'] as String?) ?? '',
      ),
    );
  }

  String _transactionSeed({
    required String rawMessage,
    required String senderId,
    required String smsDate,
    required String amount,
    required String type,
    required String method,
    required String bank,
    required String account,
    required String counterparty,
    required String reference,
  }) {
    return <String>[
      rawMessage.trim(),
      senderId.trim().toLowerCase(),
      smsDate.trim(),
      amount.trim(),
      type.trim().toLowerCase(),
      method.trim().toLowerCase(),
      bank.trim().toLowerCase(),
      account.trim().toLowerCase(),
      counterparty.trim().toLowerCase(),
      reference.trim().toLowerCase(),
    ].join('|');
  }

  String _buildTransactionIdFromSeed(String seed) {
    const int fnvOffset = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    int hash = fnvOffset;

    for (final int byte in utf8.encode(seed)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }

  int _transactionEpoch(Map<String, dynamic> value) {
    final String smsDate = (value['smsDate'] as String?)?.trim() ?? '';
    if (smsDate.isEmpty) {
      return 0;
    }

    final DateTime? parsed = DateTime.tryParse(smsDate);
    return parsed?.millisecondsSinceEpoch ?? 0;
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _authHeaders;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._authHeaders);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_authHeaders);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
