package com.harsh.kharcha.background

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver for handling notification action button taps
 * 
 * This receiver handles category selection from transaction notifications,
 * updates the transaction in SharedPreferences, and dismisses the notification.
 * 
 * Requirements: 5.3, 5.4, 5.5, 5.6, 11.1, 11.2, 11.3, 11.4, 11.5, 11.6
 */
class NotificationActionReceiver : BroadcastReceiver() {
    
    companion object {
        const val TAG = "KharchaBackground"
        const val ACTION_CATEGORY_SELECTED = "com.harsh.kharcha.CATEGORY_SELECTED"
        const val ACTION_SHOW_MORE_CATEGORIES = "com.harsh.kharcha.SHOW_MORE_CATEGORIES"
        const val ACTION_ADD_NOTE = "com.harsh.kharcha.ADD_NOTE"
        const val ACTION_NOTE_SUBMITTED = "com.harsh.kharcha.NOTE_SUBMITTED"
        const val EXTRA_TRANSACTION_ID = "transaction_id"
        const val EXTRA_CATEGORY = "category"
        const val KEY_NOTE_INPUT = "note_input"
        
        // Valid category names - matching the Flutter app
        val VALID_CATEGORIES = setOf(
            "Food", "Travel", "Shopping", "Leisure", 
            "Transport", "Bills", "Salary", "Other"
        )
    }
    
    /**
     * Handle incoming broadcast intents
     * 
     * Requirements: 11.3, 11.4
     * 
     * @param context Android context
     * @param intent Broadcast intent
     */
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "NotificationActionReceiver.onReceive: action=${intent.action}")
        
        when (intent.action) {
            ACTION_CATEGORY_SELECTED -> {
                val transactionId = intent.getStringExtra(EXTRA_TRANSACTION_ID)
                val category = intent.getStringExtra(EXTRA_CATEGORY)
                
                if (transactionId.isNullOrEmpty() || category.isNullOrEmpty()) {
                    Log.e(TAG, "Invalid transaction ID or category")
                    return
                }
                
                handleCategorySelection(context, transactionId, category)
            }
            
            ACTION_SHOW_MORE_CATEGORIES -> {
                val transactionId = intent.getStringExtra(EXTRA_TRANSACTION_ID)
                
                if (transactionId.isNullOrEmpty()) {
                    Log.e(TAG, "Invalid transaction ID")
                    return
                }
                
                handleShowMoreCategories(context, transactionId)
            }
            
            ACTION_ADD_NOTE -> {
                val transactionId = intent.getStringExtra(EXTRA_TRANSACTION_ID)
                
                if (transactionId.isNullOrEmpty()) {
                    Log.e(TAG, "Invalid transaction ID")
                    return
                }
                
                handleAddNote(context, transactionId)
            }
            
            ACTION_NOTE_SUBMITTED -> {
                val transactionId = intent.getStringExtra(EXTRA_TRANSACTION_ID)
                
                if (transactionId.isNullOrEmpty()) {
                    Log.e(TAG, "Invalid transaction ID")
                    return
                }
                
                handleNoteSubmitted(context, intent, transactionId)
            }
            
            else -> {
                Log.w(TAG, "Received unexpected action: ${intent.action}")
            }
        }
    }
    
    /**
     * Handle category selection for a transaction
     * 
     * Requirements: 5.4, 5.5, 5.6, 11.5, 11.6
     * 
     * @param context Android context
     * @param transactionId Unique transaction ID
     * @param category Selected category name
     */
    private fun handleCategorySelection(
        context: Context,
        transactionId: String,
        category: String
    ) {
        Log.d(TAG, "Category selected: $category for transaction $transactionId")
        
        // Validate category, use "Other" as fallback for invalid categories
        val validCategory = if (VALID_CATEGORIES.contains(category)) {
            category
        } else {
            Log.w(TAG, "Invalid category '$category', using 'Other' as fallback")
            "Other"
        }
        
        // Update transaction category in SharedPreferences
        val success = SharedPreferencesStore.updateTransactionCategory(context, transactionId, validCategory)
        
        if (!success) {
            Log.e(TAG, "Failed to update transaction category")
            return
        }
        
        // Increment category frequency counter
        SharedPreferencesStore.incrementCategoryFrequency(context, validCategory)
        
        // Dismiss the notification
        dismissNotification(context, transactionId)
        
        Log.d(TAG, "Category selection complete for transaction $transactionId")
        Log.d(TAG, "Transaction will be synced to Drive when user opens the app")
    }
    
    /**
     * Handle "Show More Categories" action
     * 
     * @param context Android context
     * @param transactionId Unique transaction ID
     */
    private fun handleShowMoreCategories(
        context: Context,
        transactionId: String
    ) {
        Log.d(TAG, "Show more categories for transaction $transactionId")
        
        // Retrieve the transaction from SharedPreferences
        val transaction = SharedPreferencesStore.getTransaction(context, transactionId)
        
        if (transaction == null) {
            Log.e(TAG, "Transaction not found: $transactionId")
            return
        }
        
        // Show expanded notification with all categories
        NotificationHelper.showExpandedCategoryNotification(context, transaction, transactionId)
    }
    
    /**
     * Handle "Add Note" action
     * 
     * @param context Android context
     * @param transactionId Unique transaction ID
     */
    private fun handleAddNote(
        context: Context,
        transactionId: String
    ) {
        Log.d(TAG, "Add note for transaction $transactionId")
        
        // Retrieve the transaction from SharedPreferences
        val transaction = SharedPreferencesStore.getTransaction(context, transactionId)
        
        if (transaction == null) {
            Log.e(TAG, "Transaction not found: $transactionId")
            return
        }
        
        // Show notification with note input
        NotificationHelper.showNoteInputNotification(context, transaction, transactionId)
    }
    
    /**
     * Handle note submission from RemoteInput
     * 
     * @param context Android context
     * @param intent Broadcast intent containing RemoteInput
     * @param transactionId Unique transaction ID
     */
    private fun handleNoteSubmitted(
        context: Context,
        intent: Intent,
        transactionId: String
    ) {
        Log.d(TAG, "Note submitted for transaction $transactionId")
        
        // Extract note text from RemoteInput
        val remoteInput = androidx.core.app.RemoteInput.getResultsFromIntent(intent)
        val noteText = remoteInput?.getCharSequence(KEY_NOTE_INPUT)?.toString()
        
        if (noteText.isNullOrEmpty()) {
            Log.w(TAG, "Empty note submitted")
            return
        }
        
        Log.d(TAG, "Note text: $noteText")
        
        // Update transaction note in SharedPreferences
        val success = SharedPreferencesStore.updateTransactionNote(context, transactionId, noteText)
        
        if (!success) {
            Log.e(TAG, "Failed to update transaction note in SharedPreferences")
            return
        }
        
        Log.d(TAG, "Updated transaction note in SharedPreferences: $transactionId")
        
        // Store note update request for Flutter to process when app opens
        val prefs = context.getSharedPreferences("kharcha_background", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("pending_note_update_$transactionId", noteText)
            .putLong("pending_note_update_timestamp_$transactionId", System.currentTimeMillis())
            .apply()
        
        Log.d(TAG, "Stored note update request for Flutter to process")
        
        // Dismiss the notification
        dismissNotification(context, transactionId)
        
        Log.d(TAG, "Note submission complete for transaction $transactionId")
        Log.d(TAG, "Note will be synced to Drive when user opens the app")
    }
    
    /**
     * Dismiss the notification for a transaction
     * 
     * Requirements: 5.5
     * 
     * @param context Android context
     * @param transactionId Unique transaction ID
     */
    private fun dismissNotification(context: Context, transactionId: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Generate notification ID from transaction ID hash (same as in NotificationHelper)
        val notificationId = transactionId.hashCode()
        
        // Cancel the notification
        notificationManager.cancel(notificationId)
        
        Log.d(TAG, "Dismissed notification for transaction $transactionId (ID: $notificationId)")
    }
}
