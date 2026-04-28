package com.harsh.kharcha.background

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log

/**
 * BroadcastReceiver for intercepting incoming SMS messages
 * 
 * This receiver listens for SMS_RECEIVED broadcasts and filters messages
 * from known bank senders. Valid bank SMS messages are passed to the
 * TransactionParser for extraction of transaction details.
 * 
 * The receiver operates even when the app is completely closed, enabling
 * background transaction tracking without user intervention.
 * 
 * Requirements: 1.1, 1.2, 1.3, 1.4, 12.4
 */
class SmsReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "KharchaBackground"
        
        /**
         * Known bank sender IDs for filtering SMS messages
         * 
         * This list includes common sender IDs used by major Indian banks
         * and payment services for transaction notifications.
         */
        private val KNOWN_BANK_SENDERS = setOf(
            // Major Banks
            "HDFCBK", "ICICIB", "SBIIN", "AXISBK", "KOTAKB",
            "INDUSB", "YESBK", "FEDBK", "IDBIBK", "BOIIND",
            "BOBIND", "PNBSMS", "UNIONB", "CANBNK", "HSBCIN",
            "SCBANK", "DBSBNK", "CITIBK",
            
            // Payment Services
            "PAYTM", "GPAY", "PHONEPE", "AMAZONP", "AIRTEL",
            
            // Alternative formats
            "HDFC", "ICICI", "SBI", "AXIS", "KOTAK",
            "INDUS", "YES", "FEDERAL", "IDBI", "BOI",
            "BOB", "PNB", "UNION", "CANARA"
        )
    }
    
    /**
     * Handle incoming SMS broadcasts
     * 
     * This method is called by the Android system when an SMS message arrives.
     * It extracts the SMS messages from the intent, filters for known bank
     * senders, and processes valid transaction SMS messages.
     * 
     * Requirements: 1.1, 1.2, 1.3
     * 
     * @param context Android context
     * @param intent SMS_RECEIVED broadcast intent
     */
    override fun onReceive(context: Context, intent: Intent) {
        // Verify this is an SMS_RECEIVED broadcast
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            Log.w(TAG, "Received non-SMS intent: ${intent.action}")
            return
        }
        
        try {
            // Extract SMS messages from intent
            val messages = extractSmsMessages(intent)
            
            if (messages.isEmpty()) {
                Log.w(TAG, "No SMS messages found in intent")
                return
            }
            
            // Process each SMS message
            for (message in messages) {
                processSmsMessage(context, message)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error processing SMS broadcast", e)
        }
    }
    
    /**
     * Extract SMS messages from the broadcast intent
     * 
     * This method handles the platform-specific SMS extraction logic,
     * supporting both modern (API 19+) and legacy SMS APIs.
     * 
     * Requirements: 1.3
     * 
     * @param intent SMS_RECEIVED broadcast intent
     * @return List of SmsMessage objects
     */
    private fun extractSmsMessages(intent: Intent): List<SmsMessage> {
        val messages = mutableListOf<SmsMessage>()
        
        try {
            // Use modern API for Android 4.4+ (API 19+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                val smsMessages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                if (smsMessages != null) {
                    messages.addAll(smsMessages)
                }
            } else {
                // Fallback for older Android versions (though our minSdk is 24)
                val pdus = intent.extras?.get("pdus") as? Array<*>
                if (pdus != null) {
                    for (pdu in pdus) {
                        if (pdu is ByteArray) {
                            @Suppress("DEPRECATION")
                            val message = SmsMessage.createFromPdu(pdu)
                            messages.add(message)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting SMS messages from intent", e)
        }
        
        return messages
    }
    
    /**
     * Process a single SMS message
     * 
     * This method filters the SMS by sender ID and message content,
     * ensuring only valid bank transaction messages are processed.
     * 
     * Requirements: 1.4, 1.5
     * 
     * @param context Android context
     * @param message SmsMessage to process
     */
    private fun processSmsMessage(context: Context, message: SmsMessage) {
        val senderId = message.originatingAddress ?: ""
        val messageBody = message.messageBody ?: ""
        
        // Log SMS interception for debugging
        Log.d(TAG, "SMS intercepted from $senderId (length: ${messageBody.length})")
        
        // Filter by known bank senders
        if (!isKnownBankSender(senderId)) {
            Log.d(TAG, "Ignoring SMS from unknown sender: $senderId")
            return
        }
        
        // Filter by message content (basic check for transaction keywords)
        if (!looksLikeTransactionSms(messageBody)) {
            Log.d(TAG, "Ignoring non-transaction SMS from $senderId")
            return
        }
        
        Log.i(TAG, "Valid bank SMS detected from $senderId")
        
        // Parse transaction with TransactionParser
        val parsedTransaction = TransactionParser.parse(messageBody, senderId)
        
        if (parsedTransaction == null) {
            Log.w(TAG, "Failed to parse transaction from $senderId")
            return
        }
        
        Log.d(TAG, "Successfully parsed transaction: ${parsedTransaction.transactionId}")
        
        // Deduplication check and store in SharedPreferencesStore
        val transactionId = SharedPreferencesStore.storePendingTransaction(context, parsedTransaction)
        
        if (transactionId == null) {
            Log.w(TAG, "Duplicate transaction detected, skipping: ${parsedTransaction.transactionId}")
            return
        }
        
        Log.i(TAG, "Stored pending transaction: $transactionId")
        
        // Display notification via NotificationHelper
        try {
            NotificationHelper.showTransactionNotification(context, parsedTransaction, transactionId)
            Log.i(TAG, "Displayed notification for transaction: $transactionId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to display notification for transaction: $transactionId", e)
            // Don't fail the entire pipeline if notification fails
            // Transaction is still stored and will be processed on app startup
        }
    }
    
    /**
     * Check if sender ID matches a known bank sender
     * 
     * This method performs case-insensitive matching against the list
     * of known bank sender IDs.
     * 
     * Requirements: 1.4
     * 
     * @param senderId SMS sender ID (originating address)
     * @return True if sender is a known bank, false otherwise
     */
    private fun isKnownBankSender(senderId: String): Boolean {
        val normalizedSender = senderId.uppercase().replace(Regex("[^A-Z0-9]"), "")
        
        // Check for exact match
        if (KNOWN_BANK_SENDERS.contains(normalizedSender)) {
            return true
        }
        
        // Check for partial match (sender ID contains known bank code)
        for (knownSender in KNOWN_BANK_SENDERS) {
            if (normalizedSender.contains(knownSender)) {
                return true
            }
        }
        
        return false
    }
    
    /**
     * Check if message body looks like a transaction SMS
     * 
     * This method performs a basic heuristic check for transaction-related
     * keywords to filter out non-transaction messages from banks (e.g.,
     * promotional messages, OTPs, alerts).
     * 
     * Requirements: 1.5
     * 
     * @param messageBody SMS message body
     * @return True if message appears to be a transaction notification
     */
    private fun looksLikeTransactionSms(messageBody: String): Boolean {
        val lower = messageBody.lowercase()
        
        // Check for amount indicators
        val hasAmount = lower.contains("rs.") || 
                       lower.contains("rs ") || 
                       lower.contains("inr") ||
                       Regex("""\d+\.\d{2}""").containsMatchIn(messageBody)
        
        // Check for transaction keywords
        val hasTransactionKeyword = lower.contains("debited") ||
                                   lower.contains("credited") ||
                                   lower.contains("debit") ||
                                   lower.contains("credit") ||
                                   lower.contains("paid") ||
                                   lower.contains("received") ||
                                   lower.contains("sent") ||
                                   lower.contains("withdrawn") ||
                                   lower.contains("deposit")
        
        return hasAmount && hasTransactionKeyword
    }
}
