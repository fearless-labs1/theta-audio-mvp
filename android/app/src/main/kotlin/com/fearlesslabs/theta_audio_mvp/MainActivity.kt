package com.fearlesslabs.theta_audio_mvp

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * THETA AUDIO MVP - MAIN ACTIVITY
 * 
 * Handles alarm intents and communicates with Flutter to auto-start prayers.
 * 
 * FILE: android/app/src/main/kotlin/com/fearlesslabs/theta_audio_mvp/MainActivity.kt
 */
class MainActivity: FlutterActivity() {
    
    companion object {
        private const val CHANNEL = "com.fearlesslabs.theta_audio_mvp/alarm"
        private const val TAG = "MainActivity"
    }
    
    private var methodChannel: MethodChannel? = null
    private var shouldStartPrayers = false
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Check if this launch is from an alarm
        checkAlarmIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // Handle alarm intent when app is already running
        checkAlarmIntent(intent)
        
        // Notify Flutter if prayers should start
        if (shouldStartPrayers) {
            notifyFlutterToStartPrayers()
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel for Flutter communication
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        
        Log.d(TAG, "✅ Method channel configured")
        
        // If we have a pending alarm, notify Flutter after a short delay
        if (shouldStartPrayers) {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                notifyFlutterToStartPrayers()
            }, 1000) // Wait 1 second for Flutter to initialize
        }
    }
    
    /**
     * Check if the intent is from an alarm trigger
     */
    private fun checkAlarmIntent(intent: Intent?) {
        if (intent?.action == AlarmReceiver.ACTION_ALARM_TRIGGER) {
            shouldStartPrayers = intent.getBooleanExtra(AlarmReceiver.EXTRA_START_PRAYERS, false)
            
            if (shouldStartPrayers) {
                Log.d(TAG, "⏰ Alarm intent detected - prayers will auto-start")
            }
        }
    }
    
    /**
     * Notify Flutter to auto-start prayers
     */
    private fun notifyFlutterToStartPrayers() {
        methodChannel?.invokeMethod("startPrayers", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                Log.d(TAG, "✅ Flutter notified to start prayers")
                shouldStartPrayers = false // Reset flag
            }
            
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.e(TAG, "❌ Error notifying Flutter: $errorMessage")
            }
            
            override fun notImplemented() {
                Log.e(TAG, "❌ Flutter method not implemented")
            }
        })
    }
}
