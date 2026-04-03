import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:kharcha/utils/sms/sms_transaction.dart';

class DriveReadService {
  static const String _driveFileScope =
      'https://www.googleapis.com/auth/drive.file';
  static const String _driveAppDataScope =
      'https://www.googleapis.com/auth/drive.appdata';
  static const String _folderName = 'kharcha';
  static const String _transactionsFileName = 'transactions.json';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  DriveReadService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(scopes: <String>[_driveFileScope, _driveAppDataScope]);

  /// Reads transactions from Google Drive's transactions.json file
  Future<List<SmsTransaction>> readTransactionsFromDrive() async {
    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return <SmsTransaction>[];
    }

    final String userEmail = (currentUser.email ?? '').trim().toLowerCase();
    if (userEmail.isEmpty) {
      return <SmsTransaction>[];
    }

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await _firestore
        .collection('users')
        .doc(userEmail)
        .get();
    final Map<String, dynamic>? userData = userSnapshot.data();
    final bool driveGranted = (userData?['driveAccessGranted'] as bool?) ?? false;

    if (!driveGranted) {
      return <SmsTransaction>[];
    }

    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();

      if (account == null) {
        return <SmsTransaction>[];
      }

      final Map<String, String> headers = await account.authHeaders;
      if (!headers.containsKey('Authorization')) {
        return <SmsTransaction>[];
      }

      final _GoogleAuthClient client = _GoogleAuthClient(headers);
      final drive.DriveApi driveApi = drive.DriveApi(client);

      // Find kharcha folder
      final String? folderId = await _findKharchaFolder(driveApi);
      if (folderId == null) {
        return <SmsTransaction>[];
      }

      // Find transactions.json file
      final String? fileId = await _findTransactionsFileId(driveApi, folderId);
      if (fileId == null) {
        return <SmsTransaction>[];
      }

      // Download and parse transactions.json
      final List<SmsTransaction> transactions =
          await _readAndParseTransactions(client, fileId);
      return transactions;
    } catch (_) {
      return <SmsTransaction>[];
    }
  }

  Future<String?> _findKharchaFolder(drive.DriveApi driveApi) async {
    try {
      final drive.FileList result = await driveApi.files.list(
        q: "name='$_folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (result.files?.isNotEmpty ?? false) {
        return result.files!.first.id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _findTransactionsFileId(
    drive.DriveApi driveApi,
    String folderId,
  ) async {
    try {
      final drive.FileList result = await driveApi.files.list(
        q: "'$folderId' in parents and name='$_transactionsFileName' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (result.files?.isNotEmpty ?? false) {
        return result.files!.first.id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<SmsTransaction>> _readAndParseTransactions(
    _GoogleAuthClient client,
    String fileId,
  ) async {
    try {
      final String url =
          'https://www.googleapis.com/drive/v3/files/$fileId?alt=media';
      final http.Response response = await client.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return <SmsTransaction>[];
      }

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> transactionsList =
          (data['transactions'] as List<dynamic>?) ?? <dynamic>[];

      final List<SmsTransaction> transactions = <SmsTransaction>[];
      for (final dynamic item in transactionsList) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final SmsTransaction? transaction = _parseTransactionJson(item);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      return transactions;
    } catch (_) {
      return <SmsTransaction>[];
    }
  }

  SmsTransaction? _parseTransactionJson(Map<String, dynamic> json) {
    try {
      final String? typeStr = json['type'] as String?;
      final SmsTransactionType type = typeStr == 'credit'
          ? SmsTransactionType.credit
          : typeStr == 'debit'
              ? SmsTransactionType.debit
              : SmsTransactionType.unknown;

      final DateTime? smsDate = json['smsDate'] != null
          ? DateTime.tryParse(json['smsDate'] as String)
          : null;

      return SmsTransaction(
        rawMessage: (json['rawMessage'] as String?) ?? '',
        senderId: (json['senderId'] as String?) ?? '',
        smsDate: smsDate,
        type: type,
        method: (json['method'] as String?) ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        currency: (json['currency'] as String?) ?? 'INR',
        bank: (json['bank'] as String?) ?? '',
        account: (json['account'] as String?) ?? '',
        counterparty: (json['counterparty'] as String?) ?? '',
        reference: (json['reference'] as String?) ?? '',
        date: (json['date'] as String?) ?? '',
        category: (json['category'] as String?) ?? 'Other',
        note: (json['note'] as String?) ?? 'Imported from SMS',
      );
    } catch (_) {
      return null;
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _headers.forEach((String key, String value) {
      request.headers[key] = value;
    });
    return _inner.send(request);
  }

  late final http.Client _inner = http.Client();
}
