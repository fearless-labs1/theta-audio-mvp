package com.fearlesslabs.theta_audio_mvp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * THETA AUDIO MVP - ALARM BROADCAST RECEIVER
 * 
 * This receiver is triggered when the alarm time is reached.
 * It opens the MainActivity with a special intent flag to auto-start prayers.
 * 
 * FILE: android/app/src/main/kotlin/com/fearlesslabs/theta_audio_mvp/AlarmReceiver.kt
 */
class AlarmReceiver : BroadcastReceiver() {
    
    companion object {
        const val ACTION_ALARM_TRIGGER = "com.fearlesslabs.theta_audio_mvp.ALARM_TRIGGER"
        const val EXTRA_START_PRAYERS = "start_prayers"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AlarmReceiver", "⏰ Alarm broadcast received!")
        
        // Create intent to open MainActivity
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            // Add flags to create new task and bring to front
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            
            // Add extra to tell MainActivity to auto-start prayers
            putExtra(EXTRA_START_PRAYERS, true)
            
            // Set action to identify this is from alarm
            action = ACTION_ALARM_TRIGGER
        }
        
        try {
            // Launch the app
            context.startActivity(launchIntent)
            Log.d("AlarmReceiver", "✅ MainActivity launched with alarm intent")
        } catch (e: Exception) {
            Log.e("AlarmReceiver", "❌ Error launching MainActivity: ${e.message}")
        }
    }
}
