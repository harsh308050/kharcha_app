package com.harsh.kharcha

import io.flutter.app.FlutterApplication
import com.harsh.kharcha.background.NotificationHelper
import androidx.work.Configuration
import android.util.Log

class KharchaApplication : FlutterApplication(), Configuration.Provider {
    
    override fun onCreate() {
        super.onCreate()
        
        // Initialize notification channel for background SMS tracking
        NotificationHelper.createNotificationChannel(this)
        Log.d("KharchaBackground", "KharchaApplication initialized and notification channel created")
    }

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setMinimumLoggingLevel(Log.INFO)
            .build()
}
