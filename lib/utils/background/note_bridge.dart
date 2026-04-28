import 'package:flutter/services.dart';

/// Bridge to communicate with Android for background data
///
/// Android stores transactions and notes in "kharcha_background" SharedPreferences
/// which is not accessible via Flutter's SharedPreferences.getInstance().
/// This class uses MethodChannel to read from Android's SharedPreferences.
class NoteBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.harsh.kharcha/background',
  );

  /// Get all pending note updates from Android SharedPreferences
  ///
  /// Returns a map of transactionId -> note text
  static Future<Map<String, String>> getPendingNoteUpdates() async {
    try {
      final dynamic result = await _channel.invokeMethod(
        'getPendingNoteUpdates',
      );
      if (result is Map) {
        return Map<String, String>.from(result);
      }
      return <String, String>{};
    } catch (e) {
      print('NoteBridge: Error getting pending note updates: $e');
      return <String, String>{};
    }
  }

  /// Remove a processed note update from Android SharedPreferences
  ///
  /// @param transactionId The transaction ID to remove
  static Future<void> removePendingNoteUpdate(String transactionId) async {
    try {
      await _channel.invokeMethod('removePendingNoteUpdate', <String, dynamic>{
        'transactionId': transactionId,
      });
    } catch (e) {
      print('NoteBridge: Error removing pending note update: $e');
    }
  }

  /// Get all pending transactions from Android SharedPreferences
  ///
  /// Returns a map of transactionId -> JSON string
  /// This reads from Android's "kharcha_background" prefs, NOT Flutter's default prefs.
  static Future<Map<String, String>> getPendingTransactions() async {
    try {
      final dynamic result = await _channel.invokeMethod(
        'getPendingTransactions',
      );
      if (result is Map) {
        return Map<String, String>.from(result);
      }
      return <String, String>{};
    } catch (e) {
      print('NoteBridge: Error getting pending transactions: $e');
      return <String, String>{};
    }
  }

  /// Remove a processed pending transaction from Android SharedPreferences
  ///
  /// @param transactionId The transaction ID to remove
  static Future<void> removePendingTransaction(String transactionId) async {
    try {
      await _channel.invokeMethod('removePendingTransaction', <String, dynamic>{
        'transactionId': transactionId,
      });
    } catch (e) {
      print('NoteBridge: Error removing pending transaction: $e');
    }
  }
}
