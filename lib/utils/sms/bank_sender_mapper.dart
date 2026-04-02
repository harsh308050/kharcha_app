enum BankCategory {
  publicSector,
  privateSector,
  foreign,
  cooperative,
  payments,
  unknown,
}

class BankInfo {
  final String name;
  final BankCategory category;
  final String? logoAsset;

  const BankInfo({
    required this.name,
    required this.category,
    this.logoAsset,
  });

  @override
  String toString() => 'BankInfo(name: $name, category: ${category.name})';
}

class BankSenderMapper {
  BankSenderMapper._();

  static String normalizeSenderId(String senderId) {
    final String raw = senderId.trim().toUpperCase();
    if (raw.isEmpty) {
      return '';
    }

    final List<String> tokens = raw
        .split(RegExp(r'[^A-Z0-9]+'))
        .map((String part) => part.trim())
        .where((String part) => part.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return '';
    }

    String candidate = tokens.first;

    // Prefer the token that looks like an SMS sender header.
    final List<String> likelyHeaders = tokens
        .where((String token) => RegExp(r'^[A-Z][A-Z0-9]{4,9}$').hasMatch(token))
        .toList();
    if (likelyHeaders.isNotEmpty) {
      likelyHeaders.sort((String a, String b) => b.length.compareTo(a.length));
      candidate = likelyHeaders.first;
    } else {
      tokens.sort((String a, String b) => b.length.compareTo(a.length));
      candidate = tokens.first;
    }

    // Handle sender IDs like ADHDFCBK where first 2 chars are telecom prefix.
    final RegExp prefixedHeaderPattern = RegExp(r'^[A-Z]{2}[A-Z0-9]{6}$');
    if (prefixedHeaderPattern.hasMatch(candidate)) {
      candidate = candidate.substring(2);
    }

    return candidate;
  }

  static BankInfo? fromSenderId(String senderId) {
    final String normalized = normalizeSenderId(senderId);
    return _senderMap[normalized];
  }

  static bool isBank(String senderId) => fromSenderId(senderId) != null;

  static String? bankName(String senderId) => fromSenderId(senderId)?.name;

  static const Map<String, BankInfo> _senderMap = {
    'HDFCBK': BankInfo(
      name: 'HDFC Bank',
      category: BankCategory.privateSector,
    ),
    'HDFCBN': BankInfo(
      name: 'HDFC Bank',
      category: BankCategory.privateSector,
    ),
    'HDFCSC': BankInfo(
      name: 'HDFC Bank',
      category: BankCategory.privateSector,
    ),
    'HDFCLP': BankInfo(
      name: 'HDFC Bank',
      category: BankCategory.privateSector,
    ),
    'HDFCCC': BankInfo(
      name: 'HDFC Bank',
      category: BankCategory.privateSector,
    ),
    'ICICIB': BankInfo(
      name: 'ICICI Bank',
      category: BankCategory.privateSector,
    ),
    'ICICIN': BankInfo(
      name: 'ICICI Bank',
      category: BankCategory.privateSector,
    ),
    'ICICIS': BankInfo(
      name: 'ICICI Bank',
      category: BankCategory.privateSector,
    ),
    'ICICIT': BankInfo(
      name: 'ICICI Bank',
      category: BankCategory.privateSector,
    ),
    'ICICIG': BankInfo(
      name: 'ICICI Bank',
      category: BankCategory.privateSector,
    ),
    'SBIPSG': BankInfo(
      name: 'State Bank of India',
      category: BankCategory.publicSector,
    ),
    'SBIINB': BankInfo(
      name: 'State Bank of India',
      category: BankCategory.publicSector,
    ),
    'SBMSMS': BankInfo(
      name: 'State Bank of India',
      category: BankCategory.publicSector,
    ),
    'SBIBNK': BankInfo(
      name: 'State Bank of India',
      category: BankCategory.publicSector,
    ),
    'SBICC': BankInfo(
      name: 'State Bank of India',
      category: BankCategory.publicSector,
    ),
    'AXISBK': BankInfo(
      name: 'Axis Bank',
      category: BankCategory.privateSector,
    ),
    'AXISBN': BankInfo(
      name: 'Axis Bank',
      category: BankCategory.privateSector,
    ),
    'AXISNF': BankInfo(
      name: 'Axis Bank',
      category: BankCategory.privateSector,
    ),
    'AXISCC': BankInfo(
      name: 'Axis Bank',
      category: BankCategory.privateSector,
    ),
    'KOTAKB': BankInfo(
      name: 'Kotak Mahindra Bank',
      category: BankCategory.privateSector,
    ),
    'KOTKCC': BankInfo(
      name: 'Kotak Mahindra Bank',
      category: BankCategory.privateSector,
    ),
    'KOTKNB': BankInfo(
      name: 'Kotak Mahindra Bank',
      category: BankCategory.privateSector,
    ),
    'KOTAK': BankInfo(
      name: 'Kotak Mahindra Bank',
      category: BankCategory.privateSector,
    ),
    'PNBSMS': BankInfo(
      name: 'Punjab National Bank',
      category: BankCategory.publicSector,
    ),
    'PNBALS': BankInfo(
      name: 'Punjab National Bank',
      category: BankCategory.publicSector,
    ),
    'PNBCRD': BankInfo(
      name: 'Punjab National Bank',
      category: BankCategory.publicSector,
    ),
    'BOIIND': BankInfo(
      name: 'Bank of India',
      category: BankCategory.publicSector,
    ),
    'BOISMS': BankInfo(
      name: 'Bank of India',
      category: BankCategory.publicSector,
    ),
    'BOBIBS': BankInfo(
      name: 'Bank of India',
      category: BankCategory.publicSector,
    ),
    'CANBNK': BankInfo(
      name: 'Canara Bank',
      category: BankCategory.publicSector,
    ),
    'CANBKS': BankInfo(
      name: 'Canara Bank',
      category: BankCategory.publicSector,
    ),
    'CANIND': BankInfo(
      name: 'Canara Bank',
      category: BankCategory.publicSector,
    ),
    'UNIONB': BankInfo(
      name: 'Union Bank of India',
      category: BankCategory.publicSector,
    ),
    'UBISMS': BankInfo(
      name: 'Union Bank of India',
      category: BankCategory.publicSector,
    ),
    'BARODM': BankInfo(
      name: 'Bank of Baroda',
      category: BankCategory.publicSector,
    ),
    'BOBACC': BankInfo(
      name: 'Bank of Baroda',
      category: BankCategory.publicSector,
    ),
    'BARBNK': BankInfo(
      name: 'Bank of Baroda',
      category: BankCategory.publicSector,
    ),
    'INDUSB': BankInfo(
      name: 'IndusInd Bank',
      category: BankCategory.privateSector,
    ),
    'INDUSL': BankInfo(
      name: 'IndusInd Bank',
      category: BankCategory.privateSector,
    ),
    'INDIND': BankInfo(
      name: 'IndusInd Bank',
      category: BankCategory.privateSector,
    ),
    'YESBKG': BankInfo(
      name: 'Yes Bank',
      category: BankCategory.privateSector,
    ),
    'YESBNK': BankInfo(
      name: 'Yes Bank',
      category: BankCategory.privateSector,
    ),
    'YESCRD': BankInfo(
      name: 'Yes Bank',
      category: BankCategory.privateSector,
    ),
    'IDBIBK': BankInfo(
      name: 'IDBI Bank',
      category: BankCategory.publicSector,
    ),
    'IDBISM': BankInfo(
      name: 'IDBI Bank',
      category: BankCategory.publicSector,
    ),
    'FEDBNK': BankInfo(
      name: 'Federal Bank',
      category: BankCategory.privateSector,
    ),
    'FEDBKS': BankInfo(
      name: 'Federal Bank',
      category: BankCategory.privateSector,
    ),
    'FEDCRD': BankInfo(
      name: 'Federal Bank',
      category: BankCategory.privateSector,
    ),
    'RBLBNK': BankInfo(
      name: 'RBL Bank',
      category: BankCategory.privateSector,
    ),
    'RBLCRD': BankInfo(
      name: 'RBL Bank',
      category: BankCategory.privateSector,
    ),
    'IDFCBK': BankInfo(
      name: 'IDFC First Bank',
      category: BankCategory.privateSector,
    ),
    'IDFCFS': BankInfo(
      name: 'IDFC First Bank',
      category: BankCategory.privateSector,
    ),
    'IDFCSM': BankInfo(
      name: 'IDFC First Bank',
      category: BankCategory.privateSector,
    ),
    'SCBAND': BankInfo(
      name: 'Standard Chartered Bank',
      category: BankCategory.foreign,
    ),
    'SCBBNK': BankInfo(
      name: 'Standard Chartered Bank',
      category: BankCategory.foreign,
    ),
    'SCBCRD': BankInfo(
      name: 'Standard Chartered Bank',
      category: BankCategory.foreign,
    ),
    'HSBCIN': BankInfo(
      name: 'HSBC Bank',
      category: BankCategory.foreign,
    ),
    'HSBCCC': BankInfo(
      name: 'HSBC Bank',
      category: BankCategory.foreign,
    ),
    'CENTBK': BankInfo(
      name: 'Central Bank of India',
      category: BankCategory.publicSector,
    ),
    'CENBNK': BankInfo(
      name: 'Central Bank of India',
      category: BankCategory.publicSector,
    ),
    'IOBSMS': BankInfo(
      name: 'Indian Overseas Bank',
      category: BankCategory.publicSector,
    ),
    'IOBBNK': BankInfo(
      name: 'Indian Overseas Bank',
      category: BankCategory.publicSector,
    ),
    'UCOBNK': BankInfo(
      name: 'UCO Bank',
      category: BankCategory.publicSector,
    ),
    'UCOSMS': BankInfo(
      name: 'UCO Bank',
      category: BankCategory.publicSector,
    ),
    'CSBBNK': BankInfo(
      name: 'CSB Bank',
      category: BankCategory.privateSector,
    ),
    'CSBSMS': BankInfo(
      name: 'CSB Bank',
      category: BankCategory.privateSector,
    ),
    'DCBBNK': BankInfo(
      name: 'DCB Bank',
      category: BankCategory.privateSector,
    ),
    'DCBSMS': BankInfo(
      name: 'DCB Bank',
      category: BankCategory.privateSector,
    ),
    'CSFBKS': BankInfo(
      name: 'City Union Bank',
      category: BankCategory.privateSector,
    ),
    'CUBBNK': BankInfo(
      name: 'City Union Bank',
      category: BankCategory.privateSector,
    ),
    'KARVYB': BankInfo(
      name: 'Karur Vysya Bank',
      category: BankCategory.privateSector,
    ),
    'KVBNKS': BankInfo(
      name: 'Karur Vysya Bank',
      category: BankCategory.privateSector,
    ),
    'TJSBNK': BankInfo(
      name: 'Tamilnad Mercantile Bank',
      category: BankCategory.privateSector,
    ),
    'TMBLSM': BankInfo(
      name: 'Tamilnad Mercantile Bank',
      category: BankCategory.privateSector,
    ),
    'AUSFIN': BankInfo(
      name: 'AU Small Finance Bank',
      category: BankCategory.privateSector,
    ),
    'AUBNKS': BankInfo(
      name: 'AU Small Finance Bank',
      category: BankCategory.privateSector,
    ),
    'UJJIVN': BankInfo(
      name: 'Ujjivan Small Finance Bank',
      category: BankCategory.privateSector,
    ),
    'EQUITA': BankInfo(
      name: 'Equitas Small Finance Bank',
      category: BankCategory.privateSector,
    ),
    'ESAFBN': BankInfo(
      name: 'ESAF Small Finance Bank',
      category: BankCategory.privateSector,
    ),
    'SARASW': BankInfo(
      name: 'Saraswat Bank',
      category: BankCategory.cooperative,
    ),
    'SARBNK': BankInfo(
      name: 'Saraswat Bank',
      category: BankCategory.cooperative,
    ),
    'SVCBNK': BankInfo(
      name: 'SVC Bank',
      category: BankCategory.cooperative,
    ),
    'JKBBNK': BankInfo(
      name: 'Jammu & Kashmir Bank',
      category: BankCategory.privateSector,
    ),
    'PAYTMB': BankInfo(
      name: 'Paytm Payments Bank',
      category: BankCategory.payments,
    ),
    'PAYTMS': BankInfo(
      name: 'Paytm Payments Bank',
      category: BankCategory.payments,
    ),
    'AIRBNK': BankInfo(
      name: 'Airtel Payments Bank',
      category: BankCategory.payments,
    ),
    'AIRPAY': BankInfo(
      name: 'Airtel Payments Bank',
      category: BankCategory.payments,
    ),
    'JIOPAY': BankInfo(
      name: 'Jio Payments Bank',
      category: BankCategory.payments,
    ),
    'FINOPB': BankInfo(
      name: 'Fino Payments Bank',
      category: BankCategory.payments,
    ),
    'INDPAY': BankInfo(
      name: 'India Post Payments Bank',
      category: BankCategory.payments,
    ),
    'IPPBSM': BankInfo(
      name: 'India Post Payments Bank',
      category: BankCategory.payments,
    ),
    'NSDLPB': BankInfo(
      name: 'NSDL Payments Bank',
      category: BankCategory.payments,
    ),
  };
}
