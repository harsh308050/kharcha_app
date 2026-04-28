package com.harsh.kharcha.background

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.harsh.kharcha.MainActivity

/**
 * Helper object for creating and managing transaction notifications
 * 
 * This helper manages notification channels and displays rich notifications
 * with category selection buttons for immediate transaction categorization.
 * 
 * Requirements: 16.1, 16.2, 16.3, 16.4, 16.5
 */
object NotificationHelper {
    private const val TAG = "KharchaBackground"
    private const val CHANNEL_ID = "transaction_alerts"
    private const val CHANNEL_NAME = "Transaction Alerts"
    private const val CHANNEL_DESCRIPTION = "Notifications for bank transaction SMS messages"
    
    // Notification colors
    private const val COLOR_DEBIT = 0xFFEF4444.toInt()   // Red for debit
    private const val COLOR_CREDIT = 0xFF10B981.toInt()  // Green for credit
    
    /**
     * Create notification channel for transaction alerts
     * 
     * This method creates a notification channel with HIGH importance to ensure
     * heads-up display on Android 8.0+ devices. The channel enables sound and
     * vibration by default, and allows users to customize these settings.
     * 
     * Requirements: 16.1, 16.2, 16.3, 16.4, 16.5
     * 
     * @param context Android context
     */
    fun createNotificationChannel(context: Context) {
        // Notification channels are only required on Android 8.0 (API 26) and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH  // HIGH importance for heads-up display
            ).apply {
                description = CHANNEL_DESCRIPTION
                enableVibration(true)  // Enable vibration by default
                enableLights(true)     // Enable LED lights
                setShowBadge(true)     // Show badge on app icon
                // Sound is enabled by default for HIGH importance channels
            }
            
            // Register the channel with the system
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            
            Log.d(TAG, "Notification channel created: $CHANNEL_ID")
        } else {
            Log.d(TAG, "Notification channel not required for API < 26")
        }
    }
    
    /**
     * Display a transaction notification with Add Note button
     * 
     * This method creates and displays a notification with a single "Add Note" button
     * that allows users to add notes directly from the notification.
     * 
     * Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 18.1, 18.2, 18.3, 18.4
     * 
     * @param context Android context
     * @param transaction ParsedTransaction to display
     * @param transactionId Unique transaction ID
     */
    fun showTransactionNotification(
        context: Context,
        transaction: ParsedTransaction,
        transactionId: String
    ) {
        // Build the notification with Add Note button
        val notification = buildNotification(context, transaction, transactionId)
        
        // Get notification manager
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Generate unique notification ID from transaction ID hash
        val notificationId = transactionId.hashCode()
        
        // Display the notification
        notificationManager.notify(notificationId, notification)
        
        Log.d(TAG, "Displayed transaction notification: $transactionId (ID: $notificationId) with Add Note button")
    }
    
    /**
     * Build notification with transaction details and Add Note button
     * 
     * Requirements: 4.2, 4.3, 4.4, 4.5, 4.6, 5.1, 5.2, 18.1, 18.2
     * 
     * @param context Android context
     * @param transaction ParsedTransaction to display
     * @param transactionId Unique transaction ID
     * @return Notification object
     */
    private fun buildNotification(
        context: Context,
        transaction: ParsedTransaction,
        transactionId: String
    ): android.app.Notification {
        // Format notification title with transaction amount and type
        val title = formatNotificationTitle(transaction)
        
        // Format notification body with bank, merchant, and method
        val body = formatNotificationBody(transaction)
        
        // Determine notification color based on transaction type
        val color = when (transaction.type) {
            TransactionType.DEBIT -> COLOR_DEBIT
            TransactionType.CREDIT -> COLOR_CREDIT
            TransactionType.UNKNOWN -> COLOR_DEBIT  // Default to red for unknown
        }
        
        // Create tap intent to open app to Ledger tab
        val tapIntent = createTapIntent(context)
        
        // Create RemoteInput for note entry
        val remoteInput = androidx.core.app.RemoteInput.Builder(NotificationActionReceiver.KEY_NOTE_INPUT)
            .setLabel("Add note for this transaction")
            .build()
        
        // Create intent for note submission
        val noteIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_NOTE_SUBMITTED
            putExtra(NotificationActionReceiver.EXTRA_TRANSACTION_ID, transactionId)
        }
        
        val notePendingIntent = PendingIntent.getBroadcast(
            context,
            (transactionId + "submit_note").hashCode(),
            noteIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE  // MUTABLE for RemoteInput
        )
        
        val noteAction = NotificationCompat.Action.Builder(
            0,
            "Add Note",
            notePendingIntent
        )
            .addRemoteInput(remoteInput)
            .build()
        
        // Build notification
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(getNotificationIcon(context))
            .setContentTitle(title)
            .setContentText(body)
            .setColor(color)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setAutoCancel(false)  // Don't dismiss on tap, only after note is added
            .setContentIntent(tapIntent)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .addAction(noteAction)
        
        Log.d(TAG, "Built notification with Add Note button")
        
        return builder.build()
    }
    
    /**
     * Format notification title with transaction amount and type
     * 
     * Format: "₹1,250.50 Debited" or "₹500.00 Credited"
     * 
     * Requirements: 4.2
     * 
     * @param transaction ParsedTransaction
     * @return Formatted title string
     */
    private fun formatNotificationTitle(transaction: ParsedTransaction): String {
        val amountStr = String.format("%.2f", transaction.amount)
        val typeStr = when (transaction.type) {
            TransactionType.DEBIT -> "Debited"
            TransactionType.CREDIT -> "Credited"
            TransactionType.UNKNOWN -> "Transaction"
        }
        return "₹$amountStr $typeStr"
    }
    
    /**
     * Format notification body with bank, merchant, and method
     * 
     * Format: "HDFC Bank • Amazon • UPI"
     * 
     * Requirements: 4.3, 4.4
     * 
     * @param transaction ParsedTransaction
     * @return Formatted body string
     */
    private fun formatNotificationBody(transaction: ParsedTransaction): String {
        val parts = mutableListOf<String>()
        
        // Add bank name if available
        if (transaction.bank.isNotEmpty()) {
            parts.add(transaction.bank)
        }
        
        // Add counterparty (merchant) if available
        if (transaction.counterparty.isNotEmpty()) {
            parts.add(transaction.counterparty)
        }
        
        // Add transaction method if available
        if (transaction.method.isNotEmpty()) {
            parts.add(transaction.method)
        }
        
        // Join with bullet separator
        return parts.joinToString(" • ")
    }
    
    /**
     * Create a category action button for the notification
     * 
     * Requirements: 5.1, 5.2, 5.3, 5.4
     * 
     * @param context Android context
     * @param transactionId Unique transaction ID
     * @param category Category name
     * @return NotificationCompat.Action
     */
    private fun createCategoryAction(
        context: Context,
        transactionId: String,
        category: String
    ): NotificationCompat.Action {
        // Create intent for NotificationActionReceiver
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_CATEGORY_SELECTED
            putExtra(NotificationActionReceiver.EXTRA_TRANSACTION_ID, transactionId)
            putExtra(NotificationActionReceiver.EXTRA_CATEGORY, category)
        }
        
        // Create PendingIntent with unique request code based on transaction ID and category
        val requestCode = (transactionId + category).hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Create action with category name as label
        return NotificationCompat.Action.Builder(
            0,  // No icon for action buttons
            category,
            pendingIntent
        ).build()
    }
    
    /**
     * Create tap intent to open app to Ledger tab
     * 
     * Requirements: 18.1, 18.2, 18.3, 18.4
     * 
     * @param context Android context
     * @return PendingIntent to launch MainActivity
     */
    private fun createTapIntent(context: Context): PendingIntent {
        // Create intent to launch MainActivity
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            // Add extra to indicate we should navigate to Ledger tab
            putExtra("open_ledger_tab", true)
        }
        
        // Create PendingIntent
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
    
    /**
     * Get notification icon resource ID
     * 
     * @param context Android context
     * @return Resource ID for notification icon
     */
    private fun getNotificationIcon(context: Context): Int {
        // Try to get the custom notification logo first
        val iconId = context.resources.getIdentifier("ic_notification_logo", "drawable", context.packageName)
        return if (iconId != 0) {
            iconId
        } else {
            // Fallback to app launcher icon
            context.applicationInfo.icon
        }
    }
    
    /**
     * Create "More Categories" action button
     * 
     * @param context Android context
     * @param transactionId Unique transaction ID
     * @return NotificationCompat.Action
     */
    private fun createMoreCategoriesAction(
        context: Context,
        transactionId: String
    ): NotificationCompat.Action {
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_SHOW_MORE_CATEGORIES
            putExtra(NotificationActionReceiver.EXTRA_TRANSACTION_ID, transactionId)
        }
        
        val requestCode = (transactionId + "more").hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Action.Builder(
            0,
            "More",
            pendingIntent
        ).build()
    }
    
    /**
     * Create "Add Note" action button
     * 
     * @param context Android context
     * @param transactionId Unique transaction ID
     * @return NotificationCompat.Action
     */
    private fun createAddNoteAction(
        context: Context,
        transactionId: String
    ): NotificationCompat.Action {
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_ADD_NOTE
            putExtra(NotificationActionReceiver.EXTRA_TRANSACTION_ID, transactionId)
        }
        
        val requestCode = (transactionId + "note").hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Action.Builder(
            0,
            "Add Note",
            pendingIntent
        ).build()
    }
    
    /**
     * Show expanded notification with all category options + Add Note
     * 
     * This is shown when user taps "More" button from the initial notification.
     * Shows all 8 categories + Add Note button.
     * 
     * @param context Android context
     * @param transaction ParsedTransaction to display
     * @param transactionId Unique transaction ID
     */
    fun showExpandedCategoryNotification(
        context: Context,
        transaction: ParsedTransaction,
        transactionId: String
    ) {
        val allCategories = listOf("Food", "Travel", "Shopping", "Leisure", "Transport", "Bills", "Salary", "Other")
        
        val title = formatNotificationTitle(transaction)
        val body = formatNotificationBody(transaction)
        
        val color = when (transaction.type) {
            TransactionType.DEBIT -> COLOR_DEBIT
            TransactionType.CREDIT -> COLOR_CREDIT
            TransactionType.UNKNOWN -> COLOR_DEBIT
        }
        
        val tapIntent = createTapIntent(context)
        
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(getNotificationIcon(context))
            .setContentTitle("Select Category - $title")
            .setContentText(body)
            .setColor(color)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setAutoCancel(false)
            .setContentIntent(tapIntent)
            .setStyle(NotificationCompat.BigTextStyle().bigText("Select a category for this transaction:\n$body"))
        
        // Add all 8 category buttons
        // Note: Only first 3 will be visible due to Android limitation
        for (category in allCategories) {
            val action = createCategoryAction(context, transactionId, category)
            builder.addAction(action)
        }
        
        // Add "Add Note" button as the 9th action
        val noteAction = createAddNoteAction(context, transactionId)
        builder.addAction(noteAction)
        
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notificationId = transactionId.hashCode()
        
        notificationManager.notify(notificationId, builder.build())
        
        Log.d(TAG, "Displayed expanded category notification: $transactionId with ${allCategories.size} categories + Add Note")
    }
    
    /**
     * Show notification with note input using RemoteInput
     * 
     * @param context Android context
     * @param transaction ParsedTransaction to display
     * @param transactionId Unique transaction ID
     */
    fun showNoteInputNotification(
        context: Context,
        transaction: ParsedTransaction,
        transactionId: String
    ) {
        val title = formatNotificationTitle(transaction)
        val body = formatNotificationBody(transaction)
        
        val color = when (transaction.type) {
            TransactionType.DEBIT -> COLOR_DEBIT
            TransactionType.CREDIT -> COLOR_CREDIT
            TransactionType.UNKNOWN -> COLOR_DEBIT
        }
        
        val tapIntent = createTapIntent(context)
        
        // Create RemoteInput for note entry
        val remoteInput = androidx.core.app.RemoteInput.Builder(NotificationActionReceiver.KEY_NOTE_INPUT)
            .setLabel("Add note for this transaction")
            .build()
        
        // Create intent for note submission
        val noteIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_NOTE_SUBMITTED
            putExtra(NotificationActionReceiver.EXTRA_TRANSACTION_ID, transactionId)
        }
        
        val notePendingIntent = PendingIntent.getBroadcast(
            context,
            (transactionId + "submit_note").hashCode(),
            noteIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE  // MUTABLE for RemoteInput
        )
        
        val noteAction = NotificationCompat.Action.Builder(
            0,
            "Submit Note",
            notePendingIntent
        )
            .addRemoteInput(remoteInput)
            .build()
        
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(getNotificationIcon(context))
            .setContentTitle("Add Note - $title")
            .setContentText(body)
            .setColor(color)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setAutoCancel(false)
            .setContentIntent(tapIntent)
            .setStyle(NotificationCompat.BigTextStyle().bigText("Add a note for this transaction:\n$body"))
            .addAction(noteAction)
        
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notificationId = transactionId.hashCode()
        
        notificationManager.notify(notificationId, builder.build())
        
        Log.d(TAG, "Displayed note input notification: $transactionId")
    }
}
