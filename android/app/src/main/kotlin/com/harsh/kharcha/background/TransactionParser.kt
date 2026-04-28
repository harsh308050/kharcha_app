package com.harsh.kharcha.background

import android.util.Log
import java.util.Locale

/**
 * Transaction parser that mirrors Dart SmsParser regex patterns
 * 
 * This parser extracts transaction details from bank SMS messages using
 * the same regex patterns as the Dart implementation to ensure consistency.
 * 
 * Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6
 */
object TransactionParser {
    private const val TAG = "KharchaBackground"

    // Regex patterns mirroring Dart SmsParser
    private val amountRegex = Regex(
        """(?:Rs\.?|INR)\s*([0-9]+(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?)""",
        RegexOption.IGNORE_CASE
    )
    
    private val maskedAccountRegex = Regex(
        """(?:X|\*){1,4}(\d{4})""",
        RegexOption.IGNORE_CASE
    )
    
    private val accountRegex = Regex(
        """(?:A/c|Acct|AC|account)\s*(?:No\.?\s*)?(\d{4})""",
        RegexOption.IGNORE_CASE
    )
    
    private val dateRegex = Regex(
        """(\d{2}[-/][A-Za-z]{3}[-/]\d{2,4}|\d{2}[-/]\d{2}[-/]\d{2,4})"""
    )
    
    private val refRegex = Regex(
        """\b(?:ref|reference|rrn|utr|txn|txnid|transaction\s*id|txn\s*id|upi\s*ref)\b\s*[:\-#]*\s*([A-Za-z0-9-]{6,})""",
        RegexOption.IGNORE_CASE
    )
    
    private val debitKeywordsRegex = Regex(
        """\b(?:debited|debit|sent|paid|spent|purchase|withdrawn|deducted|charged|dr\.?)\b""",
        RegexOption.IGNORE_CASE
    )
    
    private val creditKeywordsRegex = Regex(
        """\b(?:credited|credit|received|deposit|deposited|refund|reversed|repayment|salary|cr\.?)\b""",
        RegexOption.IGNORE_CASE
    )
    
    private val balanceRegex = Regex(
        """(?:Rs\.?|INR)?\s*([0-9]+(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?)""",
        RegexOption.IGNORE_CASE
    )

    // Bank name mapping - synchronized with Flutter's BankSenderMapper for consistent display
    private val bankNameMap = mapOf(
        "icici" to "ICICI Bank",
        "hdfc" to "HDFC Bank",
        "sbi" to "State Bank of India",
        "axis" to "Axis Bank",
        "kotak" to "Kotak Mahindra Bank",
        "indusind" to "IndusInd Bank",
        "indus" to "IndusInd Bank",
        "yes" to "Yes Bank",
        "yesbank" to "Yes Bank",
        "federal" to "Federal Bank",
        "idbi" to "IDBI Bank",
        "boi" to "Bank of India",
        "bob" to "Bank of Baroda",
        "baroda" to "Bank of Baroda",
        "pnb" to "Punjab National Bank",
        "union" to "Union Bank of India",
        "canara" to "Canara Bank",
        "hsbc" to "HSBC Bank",
        "sc" to "Standard Chartered Bank",
        "dbs" to "DBS Bank",
        "citi" to "Citibank",
        "idfc" to "IDFC First Bank",
        "rbl" to "RBL Bank",
        "dcb" to "DCB Bank",
        "csb" to "CSB Bank",
        "uco" to "UCO Bank",
        "iob" to "Indian Overseas Bank",
        "central" to "Central Bank of India",
        "au" to "AU Small Finance Bank",
        "ujjivan" to "Ujjivan Small Finance Bank",
        "equitas" to "Equitas Small Finance Bank",
        "paytm" to "Paytm Payments Bank",
        "airtel" to "Airtel Payments Bank",
        "jio" to "Jio Payments Bank",
        "fino" to "Fino Payments Bank",
        "upi" to "UPI",
        "rupay" to "RuPay"
    )

    // Balance keywords (mirroring Dart availableBalanceKeywords and outstandingBalanceKeywords)
    private val balanceKeywords = listOf(
        "balance",
        "available balance",
        "available",
        "avail bal",
        "acc bal",
        "acct bal",
        "outstanding balance",
        "outstanding amount",
        "outstanding",
        "amt due",
        "due amount"
    )

    /**
     * Parse SMS message to extract transaction details
     * 
     * @param message SMS message body
     * @param senderId SMS sender ID
     * @return ParsedTransaction if parsing succeeds, null otherwise
     */
    fun parse(message: String, senderId: String): ParsedTransaction? {
        try {
            val normalized = normalize(message)
            
            // Extract amount (required)
            val amount = extractAmount(normalized)
            if (amount <= 0.0) {
                return null
            }
            
            // Detect transaction type (required)
            val type = detectTransactionType(normalized)
            if (type == TransactionType.UNKNOWN) {
                return null
            }
            
            // Extract other fields (optional)
            val method = extractMethod(normalized)
            val bank = extractBank(normalized, senderId)
            val account = extractAccount(normalized)
            val counterparty = extractCounterparty(normalized)
            val reference = extractReference(normalized)
            val date = extractDate(normalized)
            val balance = extractBalance(normalized)
            
            val timestamp = System.currentTimeMillis()
            val transactionId = ParsedTransaction.generateTransactionId(senderId, amount, timestamp)
            
            return ParsedTransaction(
                transactionId = transactionId,
                rawMessage = message,
                senderId = senderId,
                amount = amount,
                type = type,
                method = method,
                bank = bank,
                account = account,
                counterparty = counterparty,
                reference = reference,
                date = date,
                balance = balance,
                timestamp = timestamp
            )
        } catch (e: Exception) {
            // Log error in production, but don't fail in tests
            try {
                Log.e(TAG, "Error parsing transaction: ${e.message}", e)
            } catch (logError: Exception) {
                // Ignore logging errors in unit tests
            }
            return null
        }
    }

    /**
     * Normalize message by collapsing whitespace
     */
    private fun normalize(message: String): String {
        return message.replace(Regex("""\s+"""), " ").trim()
    }

    /**
     * Extract transaction amount from message
     * Mirrors Dart TransactionParser.getTransactionAmount
     */
    private fun extractAmount(message: String): Double {
        val match = amountRegex.find(message)
        val amountStr = match?.groupValues?.get(1) ?: return 0.0
        return parseAmount(amountStr)
    }

    /**
     * Parse amount string to double, removing commas
     */
    private fun parseAmount(value: String): Double {
        if (value.isEmpty()) return 0.0
        val normalized = value.replace(",", "")
        return normalized.toDoubleOrNull() ?: 0.0
    }

    /**
     * Detect transaction type (debit or credit)
     * Mirrors Dart TransactionParser.getTransactionType
     */
    private fun detectTransactionType(message: String): TransactionType {
        val lower = message.lowercase(Locale.getDefault())
        
        if (debitKeywordsRegex.containsMatchIn(lower)) {
            return TransactionType.DEBIT
        }
        
        if (creditKeywordsRegex.containsMatchIn(lower)) {
            return TransactionType.CREDIT
        }
        
        return TransactionType.UNKNOWN
    }

    /**
     * Extract transaction method (UPI, NEFT, IMPS, RTGS, CARD, WALLET)
     * Mirrors Dart SmsParser._inferMethod
     */
    private fun extractMethod(message: String): String {
        val lower = message.lowercase(Locale.getDefault())
        
        return when {
            lower.contains("upi") -> "UPI"
            lower.contains("neft") -> "NEFT"
            lower.contains("imps") -> "IMPS"
            lower.contains("rtgs") -> "RTGS"
            lower.contains("card") -> "CARD"
            lower.contains("wallet") || 
            lower.contains("paytm") || 
            lower.contains("phonepe") || 
            lower.contains("gpay") || 
            lower.contains("google pay") -> "WALLET"
            else -> "OTHER"
        }
    }

    /**
     * Extract bank name from message and sender ID
     * Mirrors Dart AccountParser._extractBankName
     */
    private fun extractBank(message: String, senderId: String): String {
        val lower = message.lowercase(Locale.getDefault())
        val senderLower = senderId.lowercase(Locale.getDefault())
        
        // Check sender ID first
        for ((key, value) in bankNameMap) {
            if (senderLower.contains(key)) {
                return value
            }
        }
        
        // Check message body
        for ((key, value) in bankNameMap) {
            if (lower.contains(key)) {
                return value
            }
        }
        
        return ""
    }

    /**
     * Extract account number from message
     * Mirrors Dart AccountParser._extractAccountNumber
     */
    private fun extractAccount(message: String): String {
        // Try masked account pattern first (e.g., XX1234)
        val maskedMatch = maskedAccountRegex.find(message)
        if (maskedMatch != null) {
            return maskedMatch.groupValues[1]
        }
        
        // Try account keyword pattern (e.g., A/c 1234)
        val accountMatch = accountRegex.find(message)
        if (accountMatch != null) {
            return accountMatch.groupValues[1]
        }
        
        return ""
    }

    /**
     * Extract counterparty (merchant or recipient) from message
     * Mirrors Dart MerchantParser._extractMerchant
     */
    private fun extractCounterparty(message: String): String {
        // Try "at" pattern (e.g., "at Amazon", "at McDonald's")
        val atPattern = Regex(
            """at\s+([a-z\s']+?)(?:\s+on|\.|,|;|\n|\d)""",
            RegexOption.IGNORE_CASE
        )
        val atMatch = atPattern.find(message)
        if (atMatch != null) {
            val merchant = atMatch.groupValues[1].trim()
            if (merchant.isNotEmpty()) {
                return merchant
            }
        }
        
        // Try simple "sent to" or "paid to" pattern (e.g., "sent to John")
        val simpleToPattern = Regex(
            """(?:sent|paid)\s+to\s+([a-z\s']+?)(?:\s+via|\.|,|;|\n|\d)""",
            RegexOption.IGNORE_CASE
        )
        val simpleToMatch = simpleToPattern.find(message)
        if (simpleToMatch != null) {
            val merchant = simpleToMatch.groupValues[1].trim()
            if (merchant.isNotEmpty()) {
                return merchant
            }
        }
        
        // Try "via <method> to" pattern (e.g., "via UPI to Amazon", "via PhonePe to McDonald's")
        val viaToPattern = Regex(
            """via\s+(?:upi|neft|imps|rtgs|card|paytm|phonepe|gpay|google\s+pay)\s+to\s+([a-z\s']+?)(?:\.|,|;|\n|\d)""",
            RegexOption.IGNORE_CASE
        )
        val viaToMatch = viaToPattern.find(message)
        if (viaToMatch != null) {
            val merchant = viaToMatch.groupValues[1].trim()
            if (merchant.isNotEmpty()) {
                return merchant
            }
        }
        
        return ""
    }

    /**
     * Extract reference number from message
     * Mirrors Dart MerchantParser._extractReferenceNumber
     */
    private fun extractReference(message: String): String {
        val match = refRegex.find(message)
        return match?.groupValues?.get(1) ?: ""
    }

    /**
     * Extract transaction date from message
     * Mirrors Dart SmsParser._parseDate
     */
    private fun extractDate(message: String): String {
        val match = dateRegex.find(message)
        return match?.groupValues?.get(1) ?: ""
    }

    /**
     * Extract balance from message
     * Mirrors Dart BalanceParser.getBalance
     */
    private fun extractBalance(message: String): Double {
        val lower = message.lowercase(Locale.getDefault())
        
        for (keyword in balanceKeywords) {
            val idx = lower.indexOf(keyword.lowercase(Locale.getDefault()))
            if (idx != -1) {
                val startIdx = idx + keyword.length
                if (startIdx < message.length) {
                    val substring = message.substring(startIdx).trim()
                    val match = balanceRegex.find(substring)
                    if (match != null) {
                        val balanceStr = match.groupValues[1]
                        val balance = parseAmount(balanceStr)
                        if (balance > 0.0) {
                            return balance
                        }
                    }
                }
            }
        }
        
        return 0.0
    }
}
