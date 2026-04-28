package com.harsh.kharcha.background

import org.json.JSONObject

/**
 * Transaction type enum matching Dart SmsTransactionType
 */
enum class TransactionType {
    DEBIT,
    CREDIT,
    UNKNOWN;

    companion object {
        fun fromString(value: String): TransactionType {
            return when (value.uppercase()) {
                "DEBIT" -> DEBIT
                "CREDIT" -> CREDIT
                else -> UNKNOWN
            }
        }
    }

    fun toJsonString(): String {
        return when (this) {
            DEBIT -> "debit"
            CREDIT -> "credit"
            UNKNOWN -> "unknown"
        }
    }
}

/**
 * Parsed transaction data class matching Dart SmsTransaction structure
 * 
 * This class mirrors the Dart SmsTransaction model to ensure compatibility
 * when storing transactions in SharedPreferences for cross-platform access.
 * 
 * Requirements: 2.1, 2.2
 */
data class ParsedTransaction(
    val transactionId: String,
    val rawMessage: String,
    val senderId: String,
    val amount: Double,
    val type: TransactionType,
    val method: String,
    val bank: String,
    val account: String,
    val counterparty: String,
    val reference: String,
    val date: String,
    val balance: Double,
    val category: String = "Other",
    val note: String = "Imported from SMS",
    val synced: Boolean = false,
    val timestamp: Long = System.currentTimeMillis()
) {
    /**
     * Serialize transaction to JSON for SharedPreferences storage
     * 
     * The JSON format matches the Dart SmsTransaction.toJson() structure
     * to ensure Flutter can deserialize it correctly.
     */
    fun toJson(): String {
        val json = JSONObject()
        json.put("transactionId", transactionId)
        json.put("rawMessage", rawMessage)
        json.put("senderId", senderId)
        json.put("amount", amount)
        json.put("type", type.toJsonString())
        json.put("method", method)
        json.put("bank", bank)
        json.put("account", account)
        json.put("counterparty", counterparty)
        json.put("reference", reference)
        json.put("date", date)
        json.put("balance", balance)
        json.put("category", category)
        json.put("synced", synced)
        json.put("timestamp", timestamp)
        json.put("currency", "INR")
        json.put("note", note)
        return json.toString()
    }

    companion object {
        /**
         * Deserialize transaction from JSON string
         * 
         * @param json JSON string from SharedPreferences
         * @return ParsedTransaction instance or null if parsing fails
         */
        fun fromJson(json: String): ParsedTransaction? {
            return try {
                val jsonObject = JSONObject(json)
                ParsedTransaction(
                    transactionId = jsonObject.getString("transactionId"),
                    rawMessage = jsonObject.getString("rawMessage"),
                    senderId = jsonObject.getString("senderId"),
                    amount = jsonObject.getDouble("amount"),
                    type = TransactionType.fromString(jsonObject.getString("type")),
                    method = jsonObject.getString("method"),
                    bank = jsonObject.getString("bank"),
                    account = jsonObject.getString("account"),
                    counterparty = jsonObject.getString("counterparty"),
                    reference = jsonObject.getString("reference"),
                    date = jsonObject.getString("date"),
                    balance = jsonObject.getDouble("balance"),
                    category = jsonObject.optString("category", "Other"),
                    note = jsonObject.optString("note", "Imported from SMS"),
                    synced = jsonObject.optBoolean("synced", false),
                    timestamp = jsonObject.optLong("timestamp", System.currentTimeMillis())
                )
            } catch (e: Exception) {
                null
            }
        }

        /**
         * Generate unique transaction ID
         * 
         * Format: sms_{senderId}_{amount}_{timestamp}
         * 
         * Requirements: 14.1
         */
        fun generateTransactionId(senderId: String, amount: Double, timestamp: Long): String {
            val amountStr = String.format("%.2f", amount).replace(".", "_")
            return "sms_${senderId}_${amountStr}_$timestamp"
        }
    }
}
