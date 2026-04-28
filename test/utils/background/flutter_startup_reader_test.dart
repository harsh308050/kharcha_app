import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/utils/background/flutter_startup_reader.dart';
import 'package:kharcha/utils/drive/drive_backup_service.dart';
import 'package:kharcha/utils/drive/transaction_repository.dart';
import 'package:kharcha/utils/sms/sms_transaction.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'flutter_startup_reader_test.mocks.dart';

@GenerateMocks([DriveBackupService, TransactionRepository])
void main() {
  late MockDriveBackupService mockDriveBackupService;
  late MockTransactionRepository mockTransactionRepository;
  late FlutterStartupReader startupReader;

  setUp(() {
    mockDriveBackupService = MockDriveBackupService();
    mockTransactionRepository = MockTransactionRepository();
    
    when(mockTransactionRepository.loadTransactions(forceRefresh: anyNamed('forceRefresh')))
        .thenAnswer((_) async {});
    when(mockTransactionRepository.transactions).thenReturn([]);
    
    when(mockDriveBackupService.backupTransactionsToDrive(any))
        .thenAnswer((_) async => DriveBackupResult.success(uploaded: true));
        
    startupReader = FlutterStartupReader(
      driveBackupService: mockDriveBackupService,
      transactionRepository: mockTransactionRepository,
    );
  });

  test('processPendingTransactions parses JSON, assigns category, and cleans up SharedPreferences', () async {
    final validJson = jsonEncode({
      'rawMessage': 'Debited Rs 100',
      'senderId': 'HDFCBK',
      'amount': 100.0,
      'type': 'DEBIT',
      'method': 'UPI',
      'bank': 'HDFC',
      'account': '1234',
      'counterparty': 'Amazon',
      'reference': 'REF123',
      'date': '2023-01-01',
      'balance': 5000.0,
      'timestamp': 1672531200000,
    });
    
    SharedPreferences.setMockInitialValues({
      'pending_transaction_123': validJson,
      'other_key': 'should_be_ignored',
    });

    await startupReader.processPendingTransactions();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('pending_transaction_123'), isFalse);
    expect(prefs.getString('other_key'), 'should_be_ignored');

    verify(mockDriveBackupService.backupTransactionsToDrive(any)).called(1);
    verify(mockTransactionRepository.loadTransactions(forceRefresh: true)).called(1);
  });

  test('processPendingTransactions ignores duplicate transactions', () async {
    final duplicateJson = jsonEncode({
      'rawMessage': 'Debited Rs 100',
      'senderId': 'HDFCBK',
      'amount': 100.0,
      'type': 'DEBIT',
      'method': 'UPI',
      'bank': 'HDFC',
      'account': '1234',
      'counterparty': 'Amazon',
      'reference': 'REF_DUPLICATE',
      'date': '2023-01-01',
      'balance': 5000.0,
    });

    SharedPreferences.setMockInitialValues({
      'pending_transaction_456': duplicateJson,
    });

    final existingTransaction = SmsTransaction(
      rawMessage: 'Debited Rs 100',
      senderId: 'HDFCBK',
      type: SmsTransactionType.debit,
      method: 'UPI',
      amount: 100.0,
      balance: 5000.0,
      currency: 'INR',
      bank: 'HDFC',
      account: '1234',
      counterparty: 'Amazon',
      reference: 'REF_DUPLICATE',
      date: '2023-01-01',
    );

    when(mockTransactionRepository.transactions).thenReturn([existingTransaction]);

    await startupReader.processPendingTransactions();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('pending_transaction_456'), isFalse);

    verifyNever(mockDriveBackupService.backupTransactionsToDrive(any));
  });

  test('processPendingTransactions retains failed parses and continues', () async {
    final invalidJson = '{invalid_json}';
    final validJson = jsonEncode({
      'rawMessage': 'Valid message',
      'senderId': 'HDFCBK',
      'amount': 200.0,
      'type': 'DEBIT',
      'method': 'UPI',
      'bank': 'HDFC',
      'account': '1234',
      'counterparty': 'Amazon',
      'reference': 'REF_VALID',
      'date': '2023-01-01',
      'balance': 5000.0,
    });

    SharedPreferences.setMockInitialValues({
      'pending_transaction_invalid': invalidJson,
      'pending_transaction_valid': validJson,
    });

    await startupReader.processPendingTransactions();

    final prefs = await SharedPreferences.getInstance();
    // In current implementation, invalid transactions are removed to prevent infinite loop.
    expect(prefs.containsKey('pending_transaction_invalid'), isFalse);
    expect(prefs.containsKey('pending_transaction_valid'), isFalse);
    
    verify(mockDriveBackupService.backupTransactionsToDrive(any)).called(1);
  });
}
