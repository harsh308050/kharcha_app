import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kharcha/utils/background/note_bridge.dart';
import 'package:kharcha/utils/drive/drive_backup_service.dart';
import 'package:kharcha/utils/drive/transaction_repository.dart';
import 'package:kharcha/utils/sms/sms_transaction.dart';

/// Reads pending transactions from SharedPreferences when Flutter app starts.
///
/// This class bridges the gap between native Kotlin code (which stores
/// transactions in SharedPreferences) and Flutter code (which uses Google Drive
/// as the primary storage).
///
/// IMPORTANT: Android native code stores data in "kharcha_background"
/// SharedPreferences, which is NOT the same as Flutter's
/// SharedPreferences.getInstance() (which uses "FlutterSharedPreferences").
/// All reads/writes to Android-side prefs MUST go through NoteBridge
/// (MethodChannel).
///
/// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 14.4, 14.5, 15.4, 15.5
class FlutterStartupReader {
  final DriveBackupService _driveBackupService;
  final TransactionRepository _transactionRepository;

  FlutterStartupReader({
    DriveBackupService? driveBackupService,
    TransactionRepository? transactionRepository,
  }) : _driveBackupService = driveBackupService ?? DriveBackupService(),
       _transactionRepository =
           transactionRepository ?? TransactionRepository.instance;

  /// Process all pending transactions from SharedPreferences.
  ///
  /// This method:
  /// 1. Applies any pending note updates to existing/pending transactions
  /// 2. Reads all pending transactions via MethodChannel (from Android's prefs)
  /// 3. Deserializes JSON to SmsTransaction objects
  /// 4. Assigns default category "Other" if uncategorized
  /// 5. Checks for duplicates against existing Drive data
  /// 6. Saves new transactions to Google Drive
  /// 7. Removes processed transactions from Android's SharedPreferences
  /// 8. Updates TransactionRepository to refresh UI
  ///
  /// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7
  Future<void> processPendingTransactions() async {
    debugPrint(
      'FlutterStartupReader: ========== STARTING PROCESSING ==========',
    );

    try {
      // Step 1: Apply any note updates to pending transactions FIRST
      // This modifies the pending transaction JSON in Android's SharedPreferences
      // BEFORE we read them, so the notes are already embedded in the transaction data.
      debugPrint(
        'FlutterStartupReader: Step 1 - Applying note updates to pending/existing transactions',
      );
      await _applyNoteUpdates();

      // Step 2: Read pending transactions via MethodChannel (from Android's kharcha_background prefs)
      debugPrint(
        'FlutterStartupReader: Step 2 - Reading pending transactions via MethodChannel',
      );
      final Map<String, String> pendingTransactions =
          await NoteBridge.getPendingTransactions();

      if (pendingTransactions.isEmpty) {
        debugPrint('FlutterStartupReader: No pending transactions found');
        return;
      }

      debugPrint(
        'FlutterStartupReader: Found ${pendingTransactions.length} pending transactions',
      );

      // Log each transaction
      for (final entry in pendingTransactions.entries) {
        debugPrint(
          'FlutterStartupReader: Transaction ${entry.key}: ${entry.value.substring(0, entry.value.length > 100 ? 100 : entry.value.length)}...',
        );
      }

      // Parse transactions from JSON
      final List<SmsTransaction> parsedTransactions = <SmsTransaction>[];
      final List<String> transactionIdsToRemove = <String>[];

      for (final MapEntry<String, String> entry
          in pendingTransactions.entries) {
        final String transactionId = entry.key;
        final String json = entry.value;

        try {
          final SmsTransaction? transaction = _parseTransaction(json);
          if (transaction != null) {
            parsedTransactions.add(transaction);
            transactionIdsToRemove.add(transactionId);
          } else {
            debugPrint(
              'FlutterStartupReader: Failed to parse transaction $transactionId',
            );
            // Remove invalid transaction from SharedPreferences
            transactionIdsToRemove.add(transactionId);
          }
        } catch (e) {
          debugPrint(
            'FlutterStartupReader: Error parsing transaction $transactionId: $e',
          );
          // Remove invalid transaction from SharedPreferences
          transactionIdsToRemove.add(transactionId);
        }
      }

      if (parsedTransactions.isEmpty) {
        debugPrint('FlutterStartupReader: No valid transactions to process');
        // Clean up invalid transactions
        await _removePendingTransactions(transactionIdsToRemove);
        return;
      }

      // Load existing transactions from repository
      await _transactionRepository.loadTransactions();
      final List<SmsTransaction> existingTransactions =
          _transactionRepository.transactions;

      // Filter out duplicates
      final List<SmsTransaction> newTransactions = parsedTransactions
          .where(
            (SmsTransaction transaction) =>
                !_isDuplicate(transaction, existingTransactions),
          )
          .toList();

      if (newTransactions.isEmpty) {
        debugPrint(
          'FlutterStartupReader: All transactions are duplicates, skipping save',
        );
        // Clean up processed transactions
        await _removePendingTransactions(transactionIdsToRemove);
        return;
      }

      debugPrint(
        'FlutterStartupReader: Processing ${newTransactions.length} new transactions',
      );

      // Save new transactions to Google Drive
      final DriveBackupResult result = await _driveBackupService
          .backupTransactionsToDrive(<SmsTransaction>[
            ...existingTransactions,
            ...newTransactions,
          ]);

      if (result.success) {
        debugPrint(
          'FlutterStartupReader: Successfully saved transactions to Drive',
        );

        // Update repository to refresh UI
        await _updateRepository();

        // Remove processed transactions from SharedPreferences
        await _removePendingTransactions(transactionIdsToRemove);

        debugPrint(
          'FlutterStartupReader: Cleaned up ${transactionIdsToRemove.length} pending transactions',
        );
      } else {
        debugPrint(
          'FlutterStartupReader: Failed to save transactions to Drive: ${result.message}',
        );
        // Leave transactions in SharedPreferences for retry on next startup
      }
    } catch (e, stackTrace) {
      debugPrint('FlutterStartupReader: Error processing transactions: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't throw - allow app to continue even if processing fails
    }
  }

  /// Apply note updates from notification actions.
  ///
  /// When a user adds a note via the notification RemoteInput, Android stores:
  /// 1. The note in the pending transaction JSON (via SharedPreferencesStore.updateTransactionNote)
  /// 2. A separate "pending_note_update_<id>" entry for cases where the transaction
  ///    was already synced to Drive before the note was added.
  ///
  /// This method handles scenario #2: if the transaction is already in Drive,
  /// update it there. If it's still pending, the note is already embedded in
  /// the transaction JSON (done by Android's updateTransactionNote), so we just
  /// clean up the pending_note_update entry.
  Future<void> _applyNoteUpdates() async {
    try {
      print('=== FLUTTER NOTE UPDATE: Starting note update processing ===');
      
      // Read note updates via MethodChannel from Android's kharcha_background prefs
      final Map<String, String> noteUpdates = await NoteBridge.getPendingNoteUpdates();
      
      print('=== FLUTTER NOTE UPDATE: Retrieved ${noteUpdates.length} note updates ===');

      if (noteUpdates.isEmpty) {
        print('=== FLUTTER NOTE UPDATE: No pending note updates found ===');
        return;
      }

      // Also read pending transactions to check if a note's transaction is still pending
      final Map<String, String> pendingTransactions = await NoteBridge.getPendingTransactions();

      print(
        '=== FLUTTER NOTE UPDATE: Found ${noteUpdates.length} note updates, ${pendingTransactions.length} pending transactions ===',
      );

      // Load existing transactions from Drive
      print('=== FLUTTER NOTE UPDATE: Loading transactions from Drive ===');
      await _transactionRepository.loadTransactions();
      final List<SmsTransaction> existingTransactions =
          _transactionRepository.transactions;

      print(
        '=== FLUTTER NOTE UPDATE: Loaded ${existingTransactions.length} existing transactions ===',
      );

      bool hasUpdates = false;

      for (final MapEntry<String, String> entry in noteUpdates.entries) {
        final String transactionId = entry.key;
        final String note = entry.value;

        print(
          '=== FLUTTER NOTE UPDATE: Processing note for $transactionId: "$note" ===',
        );

        // Check if this transaction is still in the pending queue
        if (pendingTransactions.containsKey(transactionId)) {
          // Transaction is still pending — the note has already been written into
          // the pending transaction JSON by Android's updateTransactionNote().
          // We just need to clean up the separate note update entry.
          print(
            '=== FLUTTER NOTE UPDATE: Transaction $transactionId is still pending, note already embedded in JSON ===',
          );
          await NoteBridge.removePendingNoteUpdate(transactionId);
          continue;
        }

        // Transaction is NOT pending — it was already synced to Drive.
        // We need to find it in Drive and update the note there.
        print(
          '=== FLUTTER NOTE UPDATE: Transaction $transactionId already in Drive, searching for match ===',
        );

        // Try to find matching transaction by reference or recent timestamp
        SmsTransaction? matchingTransaction;

        // Strategy 1: Search by raw message content similarity
        // The Android transactionId format is sms_{senderId}_{amount}_{timestamp}
        // Try to extract components to match
        final RegExp idPattern = RegExp(r'^sms_(.+?)_(\d+)_(\d+)_(\d+)$');
        final Match? idMatch = idPattern.firstMatch(transactionId);
        
        if (idMatch != null) {
          final String senderId = idMatch.group(1) ?? '';
          // Amount has underscore replacing dot: "1250_00" -> 1250.00
          final String amountWhole = idMatch.group(2) ?? '0';
          final String amountDecimal = idMatch.group(3) ?? '00';
          final double amount = double.tryParse('$amountWhole.$amountDecimal') ?? 0.0;
          final int timestamp = int.tryParse(idMatch.group(4) ?? '0') ?? 0;
          
          print(
            '=== FLUTTER NOTE UPDATE: Parsed ID - sender: $senderId, amount: $amount, timestamp: $timestamp ===',
          );
          
          // Find transaction matching sender + amount + timestamp proximity
          for (final SmsTransaction t in existingTransactions) {
            final bool senderMatch = t.senderId.toUpperCase().contains(senderId.toUpperCase()) ||
                senderId.toUpperCase().contains(t.senderId.toUpperCase());
            final bool amountMatch = (t.amount - amount).abs() < 0.01;
            
            if (senderMatch && amountMatch) {
              // Check timestamp proximity (within 1 minute)
              if (timestamp > 0 && t.smsDate != null) {
                final int txTimestamp = t.smsDate!.millisecondsSinceEpoch;
                if ((txTimestamp - timestamp).abs() < 60000) {
                  matchingTransaction = t;
                  print(
                    '=== FLUTTER NOTE UPDATE: Matched by sender+amount+timestamp: ${t.reference} ===',
                  );
                  break;
                }
              }
              // If no timestamp match but sender + amount match, use as fallback
              matchingTransaction ??= t;
            }
          }
        }

        // Strategy 2: Fallback - most recent transaction within 30 minutes
        if (matchingTransaction == null) {
          final DateTime now = DateTime.now();
          final List<SmsTransaction> recentTransactions = existingTransactions
              .where((SmsTransaction t) {
                final Duration difference = now.difference(t.transactionDate);
                return difference.inMinutes < 30;
              })
              .toList();

          if (recentTransactions.isNotEmpty) {
            recentTransactions.sort(
              (a, b) => b.transactionDate.compareTo(a.transactionDate),
            );
            matchingTransaction = recentTransactions.first;
            print(
              '=== FLUTTER NOTE UPDATE: Fallback - using most recent transaction: ${matchingTransaction.reference} ===',
            );
          }
        }

        if (matchingTransaction == null) {
          print(
            '=== FLUTTER NOTE UPDATE: No matching transaction found for $transactionId, removing stale update ===',
          );
          await NoteBridge.removePendingNoteUpdate(transactionId);
          continue;
        }

        // Update the transaction with the new note
        final SmsTransaction updated = matchingTransaction.copyWith(note: note);

        print(
          '=== FLUTTER NOTE UPDATE: Updating Drive transaction: ${matchingTransaction.reference} with note: "$note" ===',
        );

        final DriveBackupResult result = await _driveBackupService
            .updateTransactionInDrive(
              original: matchingTransaction,
              updated: updated,
            );

        if (result.success) {
          print(
            '=== FLUTTER NOTE UPDATE: Successfully updated note in Drive ===',
          );
          await NoteBridge.removePendingNoteUpdate(transactionId);
          hasUpdates = true;
        } else {
          print(
            '=== FLUTTER NOTE UPDATE: Failed to update note in Drive: ${result.message} ===',
          );
          // Leave the update request for retry on next app open
        }
      }

      if (hasUpdates) {
        print('=== FLUTTER NOTE UPDATE: Refreshing transaction repository ===');
        await _transactionRepository.loadTransactions(forceRefresh: true);
        print('=== FLUTTER NOTE UPDATE: Repository refreshed successfully ===');
      }

      print('=== FLUTTER NOTE UPDATE: Note update processing complete ===');
    } catch (e, stackTrace) {
      print('=== FLUTTER NOTE UPDATE: Error applying note updates: $e ===');
      print('=== FLUTTER NOTE UPDATE: Stack trace: $stackTrace ===');
    }
  }

  /// Parse a transaction from JSON string.
  ///
  /// Returns null if parsing fails or if required fields are missing.
  ///
  /// Requirements: 7.2
  SmsTransaction? _parseTransaction(String json) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(json) as Map<String, dynamic>;

      // Extract required fields
      final String rawMessage = data['rawMessage'] as String? ?? '';
      final String senderId = data['senderId'] as String? ?? '';
      final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final String typeStr = data['type'] as String? ?? 'unknown';
      final String method = data['method'] as String? ?? '';
      final String bank = data['bank'] as String? ?? '';
      final String account = data['account'] as String? ?? '';
      final String counterparty = data['counterparty'] as String? ?? '';
      final String reference = data['reference'] as String? ?? '';
      final String date = data['date'] as String? ?? '';
      final double balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      final String currency = data['currency'] as String? ?? 'INR';
      
      // Read note from JSON — respect user-set notes, only default if truly absent
      final String? rawNote = data['note'] as String?;
      final String note = (rawNote != null && rawNote.trim().isNotEmpty)
          ? rawNote
          : 'Imported from SMS';

      // Parse category - assign "Other" if not set or empty
      String category = data['category'] as String? ?? 'Other';
      if (category.trim().isEmpty) {
        category = 'Other';
      }

      // Parse transaction type
      final SmsTransactionType type = _parseTransactionType(typeStr);

      // Validate required fields
      if (rawMessage.isEmpty || amount <= 0) {
        debugPrint(
          'FlutterStartupReader: Invalid transaction - missing required fields',
        );
        return null;
      }

      // Parse SMS date if available
      DateTime? smsDate;
      final int? timestamp = data['timestamp'] as int?;
      if (timestamp != null && timestamp > 0) {
        smsDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      debugPrint(
        'FlutterStartupReader: Parsed transaction - note: "$note", category: "$category"',
      );

      return SmsTransaction(
        rawMessage: rawMessage,
        senderId: senderId,
        smsDate: smsDate,
        type: type,
        method: method,
        amount: amount,
        balance: balance,
        currency: currency,
        bank: bank,
        account: account,
        counterparty: counterparty,
        reference: reference,
        date: date,
        category: category,
        note: note,
      );
    } catch (e) {
      debugPrint('FlutterStartupReader: Error parsing transaction JSON: $e');
      return null;
    }
  }

  /// Parse transaction type from string.
  ///
  /// Requirements: 7.2
  SmsTransactionType _parseTransactionType(String typeStr) {
    final String normalized = typeStr.toLowerCase().trim();
    switch (normalized) {
      case 'debit':
        return SmsTransactionType.debit;
      case 'credit':
        return SmsTransactionType.credit;
      default:
        return SmsTransactionType.unknown;
    }
  }

  /// Check if a transaction is a duplicate.
  ///
  /// A transaction is considered a duplicate if another transaction exists
  /// with the same reference ID, or if the raw message, amount, and date match.
  ///
  /// Requirements: 7.3, 14.4
  bool _isDuplicate(
    SmsTransaction transaction,
    List<SmsTransaction> existingTransactions,
  ) {
    // Check for duplicate by reference ID
    if (transaction.reference.isNotEmpty) {
      final bool hasDuplicateReference = existingTransactions.any(
        (SmsTransaction existing) =>
            existing.reference.isNotEmpty &&
            existing.reference == transaction.reference,
      );
      if (hasDuplicateReference) {
        debugPrint(
          'FlutterStartupReader: Duplicate found by reference: ${transaction.reference}',
        );
        return true;
      }
    }

    // Check for duplicate by raw message, amount, and sender
    final bool hasDuplicateMessage = existingTransactions.any(
      (SmsTransaction existing) =>
          existing.rawMessage == transaction.rawMessage &&
          existing.amount == transaction.amount &&
          existing.senderId == transaction.senderId,
    );

    if (hasDuplicateMessage) {
      debugPrint('FlutterStartupReader: Duplicate found by message content');
      return true;
    }

    return false;
  }

  /// Remove processed transactions from Android's SharedPreferences via MethodChannel.
  ///
  /// Requirements: 7.5, 14.5
  Future<void> _removePendingTransactions(List<String> transactionIds) async {
    try {
      for (final String transactionId in transactionIds) {
        await NoteBridge.removePendingTransaction(transactionId);
      }

      debugPrint(
        'FlutterStartupReader: Removed ${transactionIds.length} transactions from SharedPreferences',
      );
    } catch (e) {
      debugPrint(
        'FlutterStartupReader: Error removing pending transactions: $e',
      );
    }
  }

  /// Update TransactionRepository to refresh UI.
  ///
  /// Requirements: 7.7
  Future<void> _updateRepository() async {
    try {
      // Force refresh from Drive to get latest data
      await _transactionRepository.loadTransactions(forceRefresh: true);
      debugPrint('FlutterStartupReader: Updated TransactionRepository');
    } catch (e) {
      debugPrint('FlutterStartupReader: Error updating repository: $e');
    }
  }
}
