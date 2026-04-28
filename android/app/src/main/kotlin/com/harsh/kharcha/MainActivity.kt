package com.harsh.kharcha

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.harsh.kharcha/background"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingNoteUpdates" -> {
                    val noteUpdates = getPendingNoteUpdates()
                    result.success(noteUpdates)
                }
                "removePendingNoteUpdate" -> {
                    val transactionId = call.argument<String>("transactionId")
                    if (transactionId != null) {
                        removePendingNoteUpdate(transactionId)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Transaction ID is required", null)
                    }
                }
                "getPendingTransactions" -> {
                    val transactions = getPendingTransactions()
                    result.success(transactions)
                }
                "removePendingTransaction" -> {
                    val transactionId = call.argument<String>("transactionId")
                    if (transactionId != null) {
                        removePendingTransaction(transactionId)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Transaction ID is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun getPendingNoteUpdates(): Map<String, String> {
        val prefs = getSharedPreferences("kharcha_background", Context.MODE_PRIVATE)
        val allKeys = prefs.all.keys
        val noteUpdates = mutableMapOf<String, String>()
        
        for (key in allKeys) {
            if (key.startsWith("pending_note_update_") && !key.contains("timestamp")) {
                val transactionId = key.substring("pending_note_update_".length)
                val note = prefs.getString(key, null)
                if (note != null && note.isNotEmpty()) {
                    noteUpdates[transactionId] = note
                }
            }
        }
        
        return noteUpdates
    }
    
    private fun removePendingNoteUpdate(transactionId: String) {
        val prefs = getSharedPreferences("kharcha_background", Context.MODE_PRIVATE)
        prefs.edit()
            .remove("pending_note_update_$transactionId")
            .remove("pending_note_update_timestamp_$transactionId")
            .apply()
    }
    
    private fun getPendingTransactions(): Map<String, String> {
        val prefs = getSharedPreferences("kharcha_background", Context.MODE_PRIVATE)
        val allKeys = prefs.all.keys
        val transactions = mutableMapOf<String, String>()
        
        for (key in allKeys) {
            if (key.startsWith("pending_transaction_")) {
                val transactionId = key.substring("pending_transaction_".length)
                val json = prefs.getString(key, null)
                if (json != null && json.isNotEmpty()) {
                    transactions[transactionId] = json
                }
            }
        }
        
        return transactions
    }
    
    private fun removePendingTransaction(transactionId: String) {
        val prefs = getSharedPreferences("kharcha_background", Context.MODE_PRIVATE)
        prefs.edit()
            .remove("pending_transaction_$transactionId")
            .apply()
    }
}
