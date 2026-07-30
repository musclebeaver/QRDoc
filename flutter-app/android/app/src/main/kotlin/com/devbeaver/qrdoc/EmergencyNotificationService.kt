package com.devbeaver.qrdoc

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder

class EmergencyNotificationService : Service() {

    companion object {
        const val CHANNEL_ID = "emergency_notification_channel"
        const val NOTIFICATION_ID = 911
        
        // Actions
        const val ACTION_START = "ACTION_START_EMERGENCY_SERVICE"
        const val ACTION_STOP = "ACTION_STOP_EMERGENCY_SERVICE"
        
        // Extras
        const val EXTRA_NAME = "EXTRA_PATIENT_NAME"
        const val EXTRA_BLOOD = "EXTRA_PATIENT_BLOOD"
        const val EXTRA_CONTACT = "EXTRA_PATIENT_CONTACT"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            val action = intent.action
            if (action == ACTION_START) {
                val name = intent.getStringExtra(EXTRA_NAME) ?: "미등록"
                val blood = intent.getStringExtra(EXTRA_BLOOD) ?: "미등록"
                val contact = intent.getStringExtra(EXTRA_CONTACT) ?: "미등록"

                // Save data to SharedPreferences so widget can read it too
                val sharedPref = getSharedPreferences("emergency_pref", Context.MODE_PRIVATE)
                sharedPref.edit().apply {
                    putString("name", name)
                    putString("blood", blood)
                    putString("contact", contact)
                    apply()
                }

                startForegroundService(name, blood, contact)
            } else if (action == ACTION_STOP) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun startForegroundService(name: String, blood: String, contact: String) {
        val notificationIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("route", "emergency")
        }

        // PendingIntent FLAG_IMMUTABLE is required for Android 12+
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationText = "환자: $name | 혈액형: $blood | 비상전화: $contact"

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val notification = builder
            .setContentTitle("🚨 VitalPass 비상 의료 카드")
            .setContentText(notificationText)
            .setSmallIcon(android.R.drawable.ic_dialog_alert) // System native alert icon
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setVisibility(Notification.VISIBILITY_PUBLIC) // Visible on lock screen
            .setPriority(Notification.PRIORITY_MAX)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Emergency Medical Pass Channel",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows patient vital medical info on the lock screen."
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
