import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kharcha/utils/drive/drive_read_service.dart';
import 'package:kharcha/utils/sms/sms_transaction.dart';

/// A singleton repository that caches transactions loaded from Google Drive.
///
/// Both [HomeTabScreen] and [LedgerTabScreen] should read from this repository
/// instead of calling [DriveReadService] directly. This eliminates:
///   - Redundant Drive API calls
///   - Race conditions between concurrent reads/writes
///   - The "shows 0" bug caused by a fresh async load racing with navigation
class TransactionRepository {
  TransactionRepository._();

  static final TransactionRepository instance = TransactionRepository._();

  final DriveReadService _driveReadService = DriveReadService();

  // Cached transactions — never null after first load attempt
  List<SmsTransaction> _transactions = const <SmsTransaction>[];

  // Whether a load is currently in progress
  bool _isLoading = false;

  // Whether we have completed at least one load attempt
  bool _hasLoaded = false;

  // Notifier that listeners (Home, Ledger) subscribe to
  final ValueNotifier<List<SmsTransaction>> transactionsNotifier =
      ValueNotifier<List<SmsTransaction>>(const <SmsTransaction>[]);

  // Loading state notifier
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  List<SmsTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  /// Loads transactions from Drive. If a load is already in progress, the
  /// caller simply waits for it to finish via the notifiers.
  ///
  /// Pass [forceRefresh] = true to bypass the cache and re-fetch from Drive.
  Future<void> loadTransactions({bool forceRefresh = false}) async {
    // If already loading, don't start another concurrent fetch
    if (_isLoading) {
      return;
    }

    // If we already have data and no refresh is requested, skip
    if (_hasLoaded && !forceRefresh) {
      return;
    }

    _isLoading = true;
    isLoadingNotifier.value = true;

    try {
      final List<SmsTransaction> fetched = await _driveReadService
          .readTransactionsFromDrive();

      _transactions = fetched;
      _hasLoaded = true;
      transactionsNotifier.value = List<SmsTransaction>.unmodifiable(fetched);
    } catch (_) {
      // Keep existing cached data on error; just mark as loaded so we don't
      // spin forever
      _hasLoaded = true;
    } finally {
      _isLoading = false;
      isLoadingNotifier.value = false;
    }
  }

  /// Called by the Ledger tab after a successful Drive backup so that the
  /// Home tab immediately reflects the new data without an extra Drive read.
  void updateTransactions(List<SmsTransaction> updated) {
    _transactions = updated;
    _hasLoaded = true;
    transactionsNotifier.value = List<SmsTransaction>.unmodifiable(updated);
  }

  /// Resets the cache (e.g. on sign-out).
  void clear() {
    _transactions = const <SmsTransaction>[];
    _hasLoaded = false;
    transactionsNotifier.value = const <SmsTransaction>[];
  }
}
