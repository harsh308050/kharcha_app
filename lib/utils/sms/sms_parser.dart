import 'sms_transaction.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum AccountType { unknown, bank, card, upi, wallet }

enum WalletType { unknown, gpay, paytm, phonepe, amazompay, airtel, icici }

enum CardType { unknown, credit, debit }

enum CardScheme { unknown, visa, mastercard, rupay, amex, diners }

enum BalanceKeywordType { available, outstanding }

enum TransactionType { debit, credit }

// ============================================================================
// MODELS
// ============================================================================

class AccountInfo {
  final AccountType type;
  final String? number;
  final String? name;
  final String? bankName;
  final String? cardScheme;
  final CardType cardType;

  AccountInfo({
    this.type = AccountType.unknown,
    this.number,
    this.name,
    this.bankName,
    this.cardScheme,
    this.cardType = CardType.unknown,
  });
}

class MerchantInfo {
  final String? merchant;
  final String? referenceNo;

  MerchantInfo({this.merchant, this.referenceNo});
}

class Balance {
  final double amount;
  final BalanceKeywordType type;

  Balance({required this.amount, required this.type});
}

// ============================================================================
// KEYWORDS & CONSTANTS
// ============================================================================

final List<String> availableBalanceKeywords = <String>[
  'balance',
  'available balance',
  'available',
  'acc bal',
  'acct bal',
];

final List<String> outstandingBalanceKeywords = <String>[
  'outstanding balance',
  'outstanding amount',
  'outstanding',
  'amt due',
  'due amount',
];

final Map<String, String> bankNameMap = <String, String>{
  'icici': 'ICICI Bank',
  'hdfc': 'HDFC Bank',
  'sbi': 'SBI',
  'axis': 'Axis Bank',
  'kotak': 'Kotak Bank',
  'indusind': 'IndusInd Bank',
  'yes': 'YES Bank',
  'federal': 'Federal Bank',
  'idbi': 'IDBI Bank',
  'boi': 'Bank of India',
  'bob': 'Bank of Baroda',
  'pnb': 'PNB',
  'union': 'Union Bank',
  'canara': 'Canara Bank',
  'southeast': 'South East Bank',
  'iaici': 'ICICI Bank',
  'yesbank': 'YES Bank',
  'hsbc': 'HSBC',
  'sc': 'Standard Chartered',
  'dbs': 'DBS',
  'citi': 'Citibank',
  'ibl': 'ICICI Bank',
  'upi': 'UPI',
  'rupay': 'RuPay',
};

final List<String> upiKeywords = <String>[
  'upi',
  'google pay',
  'googlepay',
  'gpay',
  'phonepe',
  'paytm',
  'whatsapp pay',
  'whatsappay',
];

final List<String> wallets = <String>[
  'google_pay',
  'paytm',
  'phonepe',
  'amazon_pay',
  'airtel_money',
  'icici_pay',
  'phone_pe',
  'google_pay',
];

final Map<String, CardScheme> cardSchemeKeywords = <String, CardScheme>{
  'visa': CardScheme.visa,
  'mastercard': CardScheme.mastercard,
  'master card': CardScheme.mastercard,
  'rupay': CardScheme.rupay,
  'amex': CardScheme.amex,
  'american express': CardScheme.amex,
  'diners': CardScheme.diners,
};

final List<String> creditCardKeywords = <String>[
  'credit card',
  'creditcard',
  'cc',
];

final List<String> debitCardKeywords = <String>[
  'debit card',
  'debitcard',
  'atm card',
];

final List<String> upiHandles = <String>[
  '@okhdfcbank',
  '@okaxis',
  '@okicici',
  '@okyes',
  '@okybl',
  '@upi',
  '@ibl',
];

final List<String> combinedWords = <String>[
  'available balance',
  'outstanding balance',
  'credit card',
  'debit card',
  'gsm',
];

// ============================================================================
// PARSERS
// ============================================================================

class AccountParser {
  static AccountInfo getAccountInfo(String message) {
    final String lower = message.toLowerCase();

    // Detect type
    final AccountType type = _detectAccountType(lower);

    // Get account number
    final String? number = _extractAccountNumber(message, type);

    // Get account holder name
    final String? name = _extractAccountHolderName(message);

    // Get bank name
    final String? bankName = _extractBankName(lower);

    // Get card scheme if card
    final String? cardScheme = type == AccountType.card
        ? _extractCardScheme(lower)
        : null;

    // Get card type if card
    final CardType cardType = type == AccountType.card
        ? _detectCardType(lower)
        : CardType.unknown;

    return AccountInfo(
      type: type,
      number: number,
      name: name,
      bankName: bankName,
      cardScheme: cardScheme,
      cardType: cardType,
    );
  }

  static AccountType _detectAccountType(String lower) {
    if (_hasCardKeywords(lower)) {
      return AccountType.card;
    }
    if (_hasUpiKeywords(lower)) {
      return AccountType.upi;
    }
    if (_hasWalletKeywords(lower)) {
      return AccountType.wallet;
    }
    if (_hasAccountKeywords(lower)) {
      return AccountType.bank;
    }
    return AccountType.unknown;
  }

  static bool _hasCardKeywords(String lower) {
    final List<String> keywords = <String>[
      ...creditCardKeywords,
      ...debitCardKeywords,
      ...cardSchemeKeywords.keys,
    ];
    for (final String keyword in keywords) {
      if (lower.contains(keyword)) return true;
    }
    return false;
  }

  static bool _hasUpiKeywords(String lower) {
    for (final String keyword in upiKeywords) {
      if (lower.contains(keyword)) return true;
    }
    for (final String handle in upiHandles) {
      if (lower.contains(handle)) return true;
    }
    return false;
  }

  static bool _hasWalletKeywords(String lower) {
    for (final String wallet in wallets) {
      if (wallet.isEmpty) continue;
      final String checkName = wallet.replaceAll('_', ' ');
      if (lower.contains(checkName)) return true;
    }
    return false;
  }

  static bool _hasAccountKeywords(String lower) {
    return RegExp(r'\b(?:a/c|ac|acct|account)\b', caseSensitive: false)
        .hasMatch(lower);
  }

  static String? _extractAccountNumber(String message, AccountType type) {
    // For cards: Extract last 4 digits
    if (type == AccountType.card) {
      final RegExp masked = RegExp(
        r'(?:x|\*){1,4}(\d{4})',
        caseSensitive: false,
      );
      final Match? match = masked.firstMatch(message);
      if (match != null) return match.group(1);

      final RegExp plain = RegExp(
        r'\b(\d{4})\b',
      );
      final Match? plainMatch = plain.firstMatch(message);
      if (plainMatch != null) return plainMatch.group(1);
    }

    // For bank accounts: Extract account number
    if (type == AccountType.bank) {
      final RegExp accPattern = RegExp(
        r'(?:a/c|ac|acct|account)\s*(?:no\.?)?\s*([0-9]{4,})',
        caseSensitive: false,
      );
      final Match? match = accPattern.firstMatch(message);
      if (match != null) return match.group(1);
    }

    // For UPI: Extract UPI ID
    if (type == AccountType.upi) {
      final RegExp upiPattern = RegExp(
        r'([a-zA-Z0-9._-]+@[a-zA-Z]+)',
        caseSensitive: false,
      );
      final Match? match = upiPattern.firstMatch(message);
      if (match != null) return match.group(1);
    }

    return null;
  }

  static String? _extractAccountHolderName(String message) {
    final RegExp pattern = RegExp(
      r'(?:hi|hello|dear|mr|mrs|ms)\.?\s+([a-z]+)',
      caseSensitive: false,
    );
    final Match? match = pattern.firstMatch(message);
    if (match != null && (match.group(1)?.length ?? 0) > 1) {
      return match.group(1);
    }
    return null;
  }

  static String? _extractBankName(String lower) {
    for (final MapEntry<String, String> entry in bankNameMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String? _extractCardScheme(String lower) {
    for (final MapEntry<String, CardScheme> entry
        in cardSchemeKeywords.entries) {
      if (lower.contains(entry.key)) return entry.value.toString();
    }
    return null;
  }

  static CardType _detectCardType(String lower) {
    for (final String keyword in creditCardKeywords) {
      if (lower.contains(keyword)) return CardType.credit;
    }
    for (final String keyword in debitCardKeywords) {
      if (lower.contains(keyword)) return CardType.debit;
    }
    return CardType.unknown;
  }
}

class BalanceParser {
  static String? getBalance(
    String message,
    BalanceKeywordType type,
  ) {
    final String lower = message.toLowerCase();
    final List<String> keywords = type == BalanceKeywordType.available
        ? availableBalanceKeywords
        : outstandingBalanceKeywords;

    for (final String keyword in keywords) {
      final int idx = lower.indexOf(keyword.toLowerCase());
      if (idx != -1) {
        return _extractBalanceValue(
          message,
          idx + keyword.length,
          lower,
        );
      }
    }
    return null;
  }

  static String? _extractBalanceValue(
    String message,
    int startIdx,
    String lower,
  ) {
    if (startIdx >= message.length) return null;

    final String substring = message.substring(startIdx).trim();
    if (substring.isEmpty) return null;

    final RegExp balancePattern = RegExp(
      r"(?:Rs\.?|INR)?\s*([0-9]+(?:[,][0-9]{2})*(?:[.][0-9]{1,2})?)",
      caseSensitive: false,
    );
    final Match? match = balancePattern.firstMatch(substring);
    if (match != null) {
      final String? value = match.group(1);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

class TransactionParser {
  static String getTransactionAmount(String message) {
    final RegExp pattern = RegExp(
      r'(?:Rs\.?|INR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final Match? match = pattern.firstMatch(message);
    return match?.group(1) ?? '';
  }

  static TransactionType? getTransactionType(String message) {
    final String lower = message.toLowerCase();
    if (RegExp(
      r'\b(?:debited|debit|sent|paid|spent|purchase|withdrawn|deducted|charged)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return TransactionType.debit;
    }
    if (RegExp(
      r'\b(?:credited|credit|received|deposit|refund|reversed|repayment)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return TransactionType.credit;
    }
    return null;
  }
}

class MerchantParser {
  static MerchantInfo extractMerchantInfo(String message) {
    final String merchant = _extractMerchant(message);
    final String? referenceNo = _extractReferenceNumber(message);
    return MerchantInfo(merchant: merchant.isEmpty ? null : merchant, referenceNo: referenceNo);
  }

  static String _extractMerchant(String message) {
    final RegExp atPattern = RegExp(r'at\s+([a-z\s]+?)(?:\.|,|;|$|\d)', caseSensitive: false);
    final Match? atMatch = atPattern.firstMatch(message);
    if (atMatch != null) {
      final String? extracted = atMatch.group(1);
      if (extracted != null && extracted.trim().isNotEmpty) {
        return extracted.trim();
      }
    }

    final RegExp toPattern = RegExp(r'(?:sent|paid)\s+to\s+([a-z\s]+?)(?:\.|,|;|$|\d)', caseSensitive: false);
    final Match? toMatch = toPattern.firstMatch(message);
    if (toMatch != null) {
      final String? extracted = toMatch.group(1);
      if (extracted != null && extracted.trim().isNotEmpty) {
        return extracted.trim();
      }
    }

    return '';
  }

  static String? _extractReferenceNumber(String message) {
    final RegExp refPattern = RegExp(
      r'(?:ref|reference|rrn|utr|txn|transaction\s*id|txn\s*id)\s*[:\-#]*\s*([a-z0-9-]{6,})',
      caseSensitive: false,
    );
    final Match? match = refPattern.firstMatch(message);
    return match?.group(1);
  }
}

// ============================================================================
// MESSAGE PROCESSOR UTILITIES
// ============================================================================

class MessageProcessor {
  static bool isNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    return double.tryParse(value.replaceAll(',', '')) != null;
  }

  static String trimLeadingAndTrailingChars(String value, String char) {
    final String pattern = RegExp.escape(char);
    return value.replaceAll(RegExp('^$pattern+|$pattern+\$'), '');
  }

  static String processMessage(String message) {
    return message.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String padCurrencyValue(String value) {
    return 'Rs.$value';
  }

  static List<String> getNextWords(String message, String trigger, {int count = 1}) {
    final List<String> words = message.split(' ');
    final int idx = words.indexWhere((String w) => w.toLowerCase().contains(trigger.toLowerCase()));
    if (idx == -1 || idx + count >= words.length) return <String>[];
    return words.sublist(idx + 1, (idx + 1 + count).clamp(0, words.length));
  }
}

// ============================================================================
// SMS PARSER - MAIN CLASS
// ============================================================================

class SmsParser {
  static final RegExp _amountExp = RegExp(
    r'(?:Rs\.?|INR)\s*([0-9]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final RegExp _maskedAccountExp = RegExp(
    r'(?:X|\*){1,4}(\d{4})',
    caseSensitive: false,
  );
  static final RegExp _accountExp = RegExp(
    r'(?:A/c|Acct|AC)\s*(?:No\.?\s*)?(\d{4})',
    caseSensitive: false,
  );
  static final RegExp _dateExp = RegExp(
    r'(\d{2}[-/][A-Za-z]{3}[-/]\d{2,4}|\d{2}[-/]\d{2}[-/]\d{2,4})',
  );
  static final RegExp _refExp = RegExp(
    r'\b(?:ref|reference|rrn|utr|txn|txnid|transaction\s*id|upi\s*ref)\b\s*[:\-#]*\s*([A-Za-z0-9-]{6,})',
    caseSensitive: false,
  );
  static final RegExp _accountKeywordExp = RegExp(
    r'\b(?:ac|acct|account|a/c)\b',
    caseSensitive: false,
  );

  static final RegExp _requestLikeExp = RegExp(
    r'\b(?:collect\s+request|request\s+to\s+pay|payment\s+request|request\s+for\s+(?:debit|payment|pay)|pending\s+approval|approve\s+(?:the\s+)?(?:collect|debit|payment)|requested\s+money|has\s+requested\s+money|money\s+request|request\s+money|on\s+approval)\b',
    caseSensitive: false,
  );
  static final RegExp _nonTxnExp = RegExp(
    r'\b(?:authori[sz]ation\s+(?:request|for)|authori[sz]e\s+this\s+payment|consent\s+request|upi\s+mandate|e-mandate|mandate|nach|autopay|otp|pin|verification|verify\s+this\s+transaction|balance\s+enquiry|mini\s+statement)\b',
    caseSensitive: false,
  );
  static final RegExp _txnVerbExp = RegExp(
    r'\b(?:debited|credited|sent|paid|received|deducted|charged|spent|withdrawn)\b',
    caseSensitive: false,
  );
  static final RegExp _txnContextExp = RegExp(
    r'\b(?:transaction|txn|transfer|payment|purchase|withdrawal|imps|neft|rtgs|upi|card|atm|pos)\b',
    caseSensitive: false,
  );

  static final String _balanceKeywordPattern = <String>[
    ...availableBalanceKeywords,
    ...outstandingBalanceKeywords,
  ].map(RegExp.escape).join('|');
  static final RegExp _balanceKeywordExp = RegExp(
    '\\b($_balanceKeywordPattern)\\b',
    caseSensitive: false,
  );
  static final String _bankKeywordPattern = bankNameMap.keys
      .map(RegExp.escape)
      .where((String value) => value.isNotEmpty)
      .join('|');
  static final RegExp _bankKeywordExp = RegExp(
    '\\b($_bankKeywordPattern)\\b',
    caseSensitive: false,
  );
  static final String _upiKeywordPattern = upiKeywords
      .map(RegExp.escape)
      .where((String value) => value.isNotEmpty)
      .join('|');
  static final RegExp _upiKeywordExp = RegExp(
    '\\b($_upiKeywordPattern)\\b',
    caseSensitive: false,
  );
  static final String _cardKeywordPattern = <String>[
    ...creditCardKeywords,
    ...debitCardKeywords,
    ...cardSchemeKeywords.keys,
  ].map(RegExp.escape).join('|');
  static final RegExp _cardKeywordExp = RegExp(
    '\\b($_cardKeywordPattern)\\b',
    caseSensitive: false,
  );

  static String _normalize(String message) {
    return message.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool isFinancialSms(String message) {
    return parseMessage(message) != null;
  }

  static SmsTransaction? parseMessage(String message) {
    final String normalized = _normalize(message);
    if (normalized.isEmpty || _isNonTransaction(normalized)) return null;
    if (!_isLikelyTransaction(normalized)) return null;

    final SmsTransaction? parsed = _buildTransaction(normalized, message);
    return parsed;
  }

  static List<SmsTransaction> parseMessages(List<String> messages) {
    final List<SmsTransaction> results = <SmsTransaction>[];
    for (final String message in messages) {
      final SmsTransaction? parsed = parseMessage(message);
      if (parsed != null) {
        results.add(parsed);
      }
    }
    return results;
  }

  static SmsTransaction? _buildTransaction(
    String normalized,
    String rawMessage,
  ) {
    final AccountInfo account = AccountParser.getAccountInfo(normalized);
    final MerchantInfo merchantInfo = MerchantParser.extractMerchantInfo(
      normalized,
    );

    final String amountText = TransactionParser.getTransactionAmount(normalized);
    double amount = _parseAmount(amountText);
    if (amount <= 0) {
      amount = _parseAmountFromRegex(normalized);
    }
    if (amount <= 0) return null;

    TransactionType? type = TransactionParser.getTransactionType(normalized);
    type ??= _inferType(normalized);
    final SmsTransactionType smsType = _mapType(type);
    if (smsType == SmsTransactionType.unknown) return null;

    final String? available = BalanceParser.getBalance(
      normalized,
      BalanceKeywordType.available,
    );
    final String? outstanding = BalanceParser.getBalance(
      normalized,
      BalanceKeywordType.outstanding,
    );
    double balance = _parseAmount(available);
    if (balance <= 0) {
      balance = _parseAmount(outstanding);
    }

    String accountNo = account.number ?? '';
    if (accountNo.isEmpty) {
      accountNo = _parseAccountFallback(normalized);
    }

    String bank = account.bankName ?? '';
    if (bank.isEmpty) {
      bank = _detectBankName(normalized);
    }

    final String counterparty = (merchantInfo.merchant ?? '').isNotEmpty
        ? merchantInfo.merchant ?? ''
        : account.name ?? '';

    final String reference = (merchantInfo.referenceNo ?? '').isNotEmpty
        ? merchantInfo.referenceNo ?? ''
        : _parseReference(normalized);

    final String date = _parseDate(normalized);

    return SmsTransaction(
      rawMessage: rawMessage,
      type: smsType,
      method: _inferMethod(normalized, account),
      amount: amount,
      balance: balance,
      currency: 'INR',
      bank: bank,
      account: accountNo,
      counterparty: counterparty,
      reference: reference,
      date: date,
    );
  }

  static bool _isLikelyTransaction(String normalized) {
    if (_isNonTransaction(normalized)) return false;

    final bool hasAmount = _amountExp.hasMatch(normalized) ||
        TransactionParser.getTransactionAmount(normalized).isNotEmpty;
    if (!hasAmount) return false;

    final bool hasTxnVerb = _txnVerbExp.hasMatch(normalized);
    final bool hasTxnContext = _txnContextExp.hasMatch(normalized);
    final bool hasUpi = _upiKeywordExp.hasMatch(normalized) ||
        _hasUpiHandle(normalized);
    final bool hasAccount = _accountKeywordExp.hasMatch(normalized) ||
        _cardKeywordExp.hasMatch(normalized) ||
        _hasWalletKeyword(normalized);
    final bool hasBank = _bankKeywordExp.hasMatch(normalized);
    final bool hasBalance = _balanceKeywordExp.hasMatch(normalized);
    final bool hasRef = _refExp.hasMatch(normalized);

    if (hasTxnVerb || hasUpi || hasRef) return true;
    if (hasAccount && (hasBank || hasTxnContext || hasBalance)) return true;
    if (hasBank && (hasTxnContext || hasBalance)) return true;
    return hasTxnContext && hasBalance;
  }

  static double _parseAmount(String? value) {
    if (value == null || value.isEmpty) return 0;
    final String normalized = value.replaceAll(',', '');
    return double.tryParse(normalized) ?? 0;
  }

  static double _parseAmountFromRegex(String text) {
    final Match? match = _amountExp.firstMatch(text);
    if (match == null) return 0;
    return _parseAmount(match.group(1));
  }

  static String _parseDate(String text) {
    final Match? match = _dateExp.firstMatch(text);
    return match == null ? '' : (match.group(1) ?? '');
  }

  static String _parseAccountFallback(String text) {
    final Match? masked = _maskedAccountExp.firstMatch(text);
    if (masked != null) {
      return masked.group(1) ?? '';
    }
    final Match? plain = _accountExp.firstMatch(text);
    return plain?.group(1) ?? '';
  }

  static String _parseReference(String text) {
    final Match? match = _refExp.firstMatch(text);
    return match?.group(1) ?? '';
  }

  static SmsTransactionType _mapType(TransactionType? type) {
    if (type == TransactionType.debit) return SmsTransactionType.debit;
    if (type == TransactionType.credit) return SmsTransactionType.credit;
    return SmsTransactionType.unknown;
  }

  static TransactionType? _inferType(String text) {
    final String lower = text.toLowerCase();
    if (RegExp(
      r'\b(?:credited|credit|received|deposit|refund|reversed|repayment)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return TransactionType.credit;
    }
    if (RegExp(
      r'\b(?:debited|debit|sent|paid|spent|purchase|withdrawn|deducted|charged)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return TransactionType.debit;
    }
    return null;
  }

  static String _inferMethod(String text, AccountInfo account) {
    final String lower = text.toLowerCase();
    if (account.type == AccountType.upi) return 'UPI';
    if (account.type == AccountType.wallet) return 'WALLET';
    if (account.type == AccountType.card) return 'CARD';
    if (lower.contains('upi')) return 'UPI';
    if (lower.contains('neft')) return 'NEFT';
    if (lower.contains('imps')) return 'IMPS';
    if (lower.contains('rtgs')) return 'RTGS';
    if (lower.contains('card')) return 'CARD';
    return 'OTHER';
  }

  static String _detectBankName(String text) {
    final String lower = text.toLowerCase();
    for (final MapEntry<String, String> entry in bankNameMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return '';
  }

  static bool _hasUpiHandle(String text) {
    final String lower = text.toLowerCase();
    for (final String handle in upiHandles) {
      if (lower.contains(handle.toLowerCase())) return true;
    }
    return false;
  }

  static bool _hasWalletKeyword(String text) {
    final String lower = text.toLowerCase();
    for (final String wallet in wallets) {
      if (wallet.isEmpty) continue;
      if (lower.contains(wallet.toLowerCase())) return true;
      final String withSpace = wallet.replaceAll('_', ' ');
      if (withSpace.isNotEmpty && lower.contains(withSpace)) return true;
    }
    return false;
  }

  static bool _isNonTransaction(String normalized) {
    if (_requestLikeExp.hasMatch(normalized)) return true;
    return _nonTxnExp.hasMatch(normalized) && !_txnVerbExp.hasMatch(normalized);
  }
}
