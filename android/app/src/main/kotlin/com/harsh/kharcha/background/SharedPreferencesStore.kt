package com.harsh.kharcha.background

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONObject

/**
 * SharedPreferences-based storage for pending transactions
 * 
 * This store manages pending transactions that are accessible by both
 * native Kotlin code and Flutter/Dart code. Transactions are stored as
 * JSON strings with unique transaction IDs.
 * 
 * Requirements: 3.1, 3.2, 3.3, 14.1, 14.2, 14.3
 */
object SharedPreferencesStore {
    private const val TAG = "KharchaBackground"
    private const val PREFS_NAME = "kharcha_background"
    private const val KEY_PREFIX_PENDING = "pending_transaction_"
    private const val KEY_CATEGORY_FREQ = "category_frequency"
    
    /**
     * Get SharedPreferences instance
     */
    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    /**
     * Generate unique transaction ID
     * 
     * Format: sms_{senderId}_{amount}_{timestamp}
     * 
     * Requirements: 14.1
     * 
     * @param senderId SMS sender ID (e.g., "HDFCBK")
     * @param amount Transaction amount
     * @param timestamp Unix timestamp in milliseconds
     * @return Unique transaction ID
     */
    fun generateTransactionId(senderId: String, amount: Double, timestamp: Long): String {
        val amountStr = String.format("%.2f", amount).replace(".", "_")
        return "sms_${senderId}_${amountStr}_$timestamp"
    }
    
    /**
     * Store a pending transaction in SharedPreferences
     * 
     * Performs deduplication check before storing. If a transaction with
     * the same ID already exists, the new transaction is ignored.
     * 
     * Requirements: 3.1, 3.2, 14.2, 14.3
     * 
     * @param context Android context
     * @param transaction ParsedTransaction to store
     * @return Transaction ID if stored successfully, null if duplicate
     */
    fun storePendingTransaction(context: Context, transaction: ParsedTransaction): String? {
        val prefs = getPrefs(context)
        val transactionId = transaction.transactionId
        val key = KEY_PREFIX_PENDING + transactionId
        
        // Deduplication check
        if (prefs.contains(key)) {
            Log.w(TAG, "Duplicate transaction detected: $transactionId")
            return null
        }
        
        // Serialize transaction to JSON
        val json = transaction.toJson()
        
        // Store in SharedPreferences
        prefs.edit().putString(key, json).apply()
        
        Log.d(TAG, "Stored pending transaction: $transactionId")
        return transactionId
    }
    
    /**
     * Update the category of a pending transaction
     * 
     * Requirements: 3.3
     * 
     * @param context Android context
     * @param transactionId Transaction ID
     * @param category Category name (e.g., "Food", "Shopping")
     * @return True if update was successful, false otherwise
     */
    fun updateTransactionCategory(context: Context, transactionId: String, category: String): Boolean {
        val prefs = getPrefs(context)
        val key = KEY_PREFIX_PENDING + transactionId
        
        // Read existing transaction
        val json = prefs.getString(key, null)
        if (json == null) {
            Log.w(TAG, "Transaction not found for category update: $transactionId")
            return false
        }
        
        // Parse transaction
        val transaction = ParsedTransaction.fromJson(json)
        if (transaction == null) {
            Log.e(TAG, "Failed to parse transaction for category update: $transactionId")
            return false
        }
        
        // Update category
        val updatedTransaction = transaction.copy(category = category)
        
        // Store updated transaction
        prefs.edit().putString(key, updatedTransaction.toJson()).apply()
        
        Log.d(TAG, "Updated transaction category: $transactionId -> $category")
        return true
    }
    
    /**
     * Update the note of a pending transaction
     * 
     * @param context Android context
     * @param transactionId Transaction ID
     * @param note Note text
     * @return True if update was successful, false otherwise
     */
    fun updateTransactionNote(context: Context, transactionId: String, note: String): Boolean {
        val prefs = getPrefs(context)
        val key = KEY_PREFIX_PENDING + transactionId
        
        // Read existing transaction
        val json = prefs.getString(key, null)
        if (json == null) {
            Log.w(TAG, "Transaction not found for note update: $transactionId")
            return false
        }
        
        // Parse transaction
        val transaction = ParsedTransaction.fromJson(json)
        if (transaction == null) {
            Log.e(TAG, "Failed to parse transaction for note update: $transactionId")
            return false
        }
        
        // Update note using the data class copy method for consistent serialization
        val updatedTransaction = transaction.copy(note = note)
        
        // Store updated transaction
        prefs.edit().putString(key, updatedTransaction.toJson()).apply()
        
        Log.d(TAG, "Updated transaction note: $transactionId -> $note")
        return true
    }
    
    /**
     * Get a specific transaction by ID
     * 
     * @param context Android context
     * @param transactionId Transaction ID
     * @return ParsedTransaction or null if not found
     */
    fun getTransaction(context: Context, transactionId: String): ParsedTransaction? {
        val prefs = getPrefs(context)
        val key = KEY_PREFIX_PENDING + transactionId
        
        val json = prefs.getString(key, null)
        if (json == null) {
            Log.w(TAG, "Transaction not found: $transactionId")
            return null
        }
        
        return ParsedTransaction.fromJson(json)
    }
    
    /**
     * Get all pending transactions
     * 
     * Requirements: 3.3
     * 
     * @param context Android context
     * @return Map of transaction ID to JSON string
     */
    fun getPendingTransactions(context: Context): Map<String, String> {
        val prefs = getPrefs(context)
        val allPrefs = prefs.all
        val pendingTransactions = mutableMapOf<String, String>()
        
        for ((key, value) in allPrefs) {
            if (key.startsWith(KEY_PREFIX_PENDING) && value is String) {
                val transactionId = key.removePrefix(KEY_PREFIX_PENDING)
                pendingTransactions[transactionId] = value
            }
        }
        
        Log.d(TAG, "Retrieved ${pendingTransactions.size} pending transactions")
        return pendingTransactions
    }
    
    /**
     * Remove a pending transaction from SharedPreferences
     * 
     * Requirements: 3.3
     * 
     * @param context Android context
     * @param transactionId Transaction ID
     */
    fun removePendingTransaction(context: Context, transactionId: String) {
        val prefs = getPrefs(context)
        val key = KEY_PREFIX_PENDING + transactionId
        
        if (!prefs.contains(key)) {
            Log.w(TAG, "Transaction not found for removal: $transactionId")
            return
        }
        
        prefs.edit().remove(key).apply()
        
        Log.d(TAG, "Removed pending transaction: $transactionId")
    }
    
    /**
     * Increment the usage frequency counter for a category
     * 
     * Requirements: 17.1, 17.2
     * 
     * @param context Android context
     * @param category Category name
     */
    fun incrementCategoryFrequency(context: Context, category: String) {
        val prefs = getPrefs(context)
        val json = prefs.getString(KEY_CATEGORY_FREQ, null)
        
        // Parse existing frequency map or create new one
        val frequencyMap = if (json != null) {
            try {
                val jsonObject = JSONObject(json)
                val map = mutableMapOf<String, Int>()
                jsonObject.keys().forEach { key ->
                    map[key] = jsonObject.getInt(key)
                }
                map
            } catch (e: Exception) {
                Log.e(TAG, "Failed to parse category frequency map", e)
                mutableMapOf()
            }
        } else {
            mutableMapOf()
        }
        
        // Increment category count
        val currentCount = frequencyMap[category] ?: 0
        frequencyMap[category] = currentCount + 1
        
        // Serialize back to JSON
        val jsonObject = JSONObject()
        for ((key, value) in frequencyMap) {
            jsonObject.put(key, value)
        }
        
        // Store updated map
        prefs.edit().putString(KEY_CATEGORY_FREQ, jsonObject.toString()).apply()
        
        Log.d(TAG, "Incremented category frequency: $category -> ${frequencyMap[category]}")
    }
    
    /**
     * Get the top N most frequently used categories
     * 
     * Requirements: 17.3, 17.4, 17.5
     * 
     * @param context Android context
     * @param count Number of top categories to return
     * @return List of category names sorted by frequency (descending)
     */
    fun getTopCategories(context: Context, count: Int): List<String> {
        val prefs = getPrefs(context)
        val json = prefs.getString(KEY_CATEGORY_FREQ, null)
        
        // Parse frequency map
        val frequencyMap = if (json != null) {
            try {
                val jsonObject = JSONObject(json)
                val map = mutableMapOf<String, Int>()
                jsonObject.keys().forEach { key ->
                    map[key] = jsonObject.getInt(key)
                }
                map
            } catch (e: Exception) {
                Log.e(TAG, "Failed to parse category frequency map", e)
                mutableMapOf()
            }
        } else {
            mutableMapOf()
        }
        
        // Sort by frequency (descending) and take top N
        val topCategories = frequencyMap.entries
            .sortedByDescending { it.value }
            .take(count)
            .map { it.key }
        
        // If fewer than count categories, fill with defaults
        val defaultCategories = listOf("Food", "Shopping", "Transport")
        val result = if (topCategories.size < count) {
            val combined = topCategories.toMutableList()
            for (default in defaultCategories) {
                if (!combined.contains(default) && combined.size < count) {
                    combined.add(default)
                }
            }
            combined
        } else {
            topCategories
        }
        
        Log.d(TAG, "Top $count categories: $result")
        return result
    }
}
