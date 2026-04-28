import 'package:kharcha/utils/sms/bank_sender_mapper.dart';

enum SmsTransactionType { credit, debit, unknown }

class SmsTransaction {
  final String rawMessage;
  final String senderId;
  final DateTime? smsDate;
  final SmsTransactionType type;
  final String method;
  final double amount;
  final double balance;
  final String currency;
  final String bank;
  final String account;
  final String counterparty;
  final String reference;
  final String date;
  final String? category;
  final String note;

  const SmsTransaction({
    required this.rawMessage,
    this.senderId = '',
    this.smsDate,
    required this.type,
    required this.method,
    required this.amount,
    required this.balance,
    required this.currency,
    required this.bank,
    required this.account,
    required this.counterparty,
    required this.reference,
    required this.date,
    this.category,
    this.note = 'Imported from SMS',
  });

  SmsTransaction copyWith({
    String? rawMessage,
    String? senderId,
    DateTime? smsDate,
    SmsTransactionType? type,
    String? method,
    double? amount,
    double? balance,
    String? currency,
    String? bank,
    String? account,
    String? counterparty,
    String? reference,
    String? date,
    String? category,
    String? note,
  }) {
    return SmsTransaction(
      rawMessage: rawMessage ?? this.rawMessage,
      senderId: senderId ?? this.senderId,
      smsDate: smsDate ?? this.smsDate,
      type: type ?? this.type,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      bank: bank ?? this.bank,
      account: account ?? this.account,
      counterparty: counterparty ?? this.counterparty,
      reference: reference ?? this.reference,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      // Raw SMS fields
      'rawMessage': rawMessage,
      'senderId': senderId,
      'smsDate': smsDate?.toIso8601String(),
      'type': type.name,
      'method': method,
      'amount': amount,
      'balance': balance,
      'currency': currency,
      'bank': bank,
      'account': account,
      'counterparty': counterparty,
      'reference': reference,
      'date': date,
      // User customization fields
      'category': category ?? 'Other',
      'note': note,
      // Computed display fields for faster restoration
      'transactionDateISO': transactionDate.toIso8601String(),
      'displayMerchant': displaySenderLabel,
      'isDebit': isDebit,
      'formattedAmountStr': formattedAmount,
    };
  }

  bool get isDebit => type == SmsTransactionType.debit;

  bool get isKnownTransaction => type != SmsTransactionType.unknown;

  DateTime get transactionDate {
    final DateTime? messageDate = smsDate;
    if (messageDate != null) {
      return messageDate;
    }

    final DateTime? parsedDate = _tryParseDate(date);
    if (parsedDate != null) {
      return parsedDate;
    }

    return DateTime.now();
  }

  String get displaySenderLabel {
    // 1. Try mapping senderId to a known bank name (e.g., "HDFCBK" → "HDFC Bank")
    final String mappedBankName = BankSenderMapper.bankName(senderId) ?? '';
    if (mappedBankName.isNotEmpty) {
      return mappedBankName;
    }

    // 2. Use the counterparty/merchant name if available (e.g., "Amazon", "Swiggy")
    final String normalizedCounterparty = counterparty.trim();
    if (normalizedCounterparty.isNotEmpty) {
      return normalizedCounterparty;
    }

    // 3. Use the bank name field (already resolved by TransactionParser on Android)
    //    This handles cases where the senderId format (e.g., "BZ-KOTAKB", phone numbers)
    //    doesn't match BankSenderMapper but the parser extracted the bank name correctly.
    final String normalizedBank = bank.trim();
    if (normalizedBank.isNotEmpty) {
      return normalizedBank;
    }

    // 4. Last resort: show the raw senderId
    final String normalizedSender = senderId.trim();
    if (normalizedSender.isNotEmpty) {
      return normalizedSender;
    }

    return 'Unknown Sender';
  }

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';

  String get formattedSignedAmount =>
      '${isDebit ? '-' : '+'}$formattedAmount';

  String get formattedDateTime {
    const List<String> monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final DateTime value = transactionDate;
    final int monthIndex = value.month - 1;
    final String month = monthNames[monthIndex.clamp(0, monthNames.length - 1)];

    final int hour = value.hour;
    final int minute = value.minute;
    final int hour12 = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final String amPm = hour >= 12 ? 'PM' : 'AM';
    final String minutePadded = minute.toString().padLeft(2, '0');

    return '$month ${value.day}, ${value.year} • $hour12:$minutePadded $amPm';
  }

  Map<String, dynamic> toLedgerJson() {
    final String signedAmount =
        '${type == SmsTransactionType.debit ? '-' : '+'}₹${amount.toStringAsFixed(2)}';
    return <String, dynamic>{
      'title': counterparty.isEmpty ? bank : counterparty,
      'subtitle': account.isEmpty ? bank : 'A/C XX$account',
      'amount': signedAmount,
      'category': category ?? 'Other',
      'note': '',
      'dateTimeText': date,
      'rawSms': rawMessage,
      'senderId': senderId,
      'reference': reference,
      'bank': bank,
      'account': account,
      'method': method,
      'balance': balance,
    };
  }

  DateTime? _tryParseDate(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final RegExp alphaMonthPattern = RegExp(
      r'^(\d{2})[-/]([A-Za-z]{3})[-/](\d{2,4})$',
    );
    final Match? alphaMatch = alphaMonthPattern.firstMatch(normalized);
    if (alphaMatch != null) {
      final int? day = int.tryParse(alphaMatch.group(1) ?? '');
      final String monthLabel = (alphaMatch.group(2) ?? '').toLowerCase();
      final int? yearRaw = int.tryParse(alphaMatch.group(3) ?? '');
      final int? month = _monthFromShortName(monthLabel);
      if (day == null || yearRaw == null || month == null) {
        return null;
      }

      final int year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;
      return DateTime(year, month, day);
    }

    final RegExp numericPattern = RegExp(r'^(\d{2})[-/](\d{2})[-/](\d{2,4})$');
    final Match? numericMatch = numericPattern.firstMatch(normalized);
    if (numericMatch != null) {
      final int? day = int.tryParse(numericMatch.group(1) ?? '');
      final int? month = int.tryParse(numericMatch.group(2) ?? '');
      final int? yearRaw = int.tryParse(numericMatch.group(3) ?? '');
      if (day == null || month == null || yearRaw == null) {
        return null;
      }

      final int year = yearRaw < 100 ? 2000 + yearRaw : yearRaw;
      return DateTime(year, month, day);
    }

    return null;
  }

  int? _monthFromShortName(String month) {
    const Map<String, int> monthLookup = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    return monthLookup[month];
  }
}
