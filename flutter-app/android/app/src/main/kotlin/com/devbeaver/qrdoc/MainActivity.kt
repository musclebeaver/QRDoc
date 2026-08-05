package com.devbeaver.qrdoc

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.app.AlarmManager
import android.app.PendingIntent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.devbeaver.qrdoc/emergency"
    private var initialRoute: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
        
        // Allow this activity to display on top of the lockscreen when triggered
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        // If app is running in background, immediately trigger navigation callback to Flutter
        if (initialRoute == "emergency") {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("navigateToEmergency", null)
            }
            initialRoute = null // Consume it
        }
    }

    private fun handleIntent(intent: Intent?) {
        val route = intent?.getStringExtra("route")
        if (route == "emergency") {
            initialRoute = "emergency"
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialRoute" -> {
                    val route = initialRoute
                    initialRoute = null // Consume it
                    result.success(route)
                }
                "startEmergencyService" -> {
                    val name = call.argument<String>("name") ?: ""
                    val blood = call.argument<String>("blood") ?: ""
                    val contact = call.argument<String>("contact") ?: ""
                    
                    val intent = Intent(this, EmergencyNotificationService::class.java).apply {
                        action = EmergencyNotificationService.ACTION_START
                        putExtra(EmergencyNotificationService.EXTRA_NAME, name)
                        putExtra(EmergencyNotificationService.EXTRA_BLOOD, blood)
                        putExtra(EmergencyNotificationService.EXTRA_CONTACT, contact)
                    }
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    
                    // Force immediate update to any active homescreen widgets
                    val widgetIntent = Intent(this, EmergencyWidgetProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    }
                    val ids = AppWidgetManager.getInstance(application).getAppWidgetIds(
                        ComponentName(application, EmergencyWidgetProvider::class.java)
                    )
                    widgetIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    sendBroadcast(widgetIntent)
                    
                    result.success(true)
                }
                "stopEmergencyService" -> {
                    val intent = Intent(this, EmergencyNotificationService::class.java).apply {
                        action = EmergencyNotificationService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                "scheduleMedicationAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val title = call.argument<String>("title") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val hour = call.argument<Int>("hour") ?: 8
                    val minute = call.argument<Int>("minute") ?: 0

                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val intent = Intent(this, AlarmReceiver::class.java).apply {
                        putExtra("id", id)
                        putExtra("title", title)
                        putExtra("message", message)
                    }

                    val pendingIntent = PendingIntent.getBroadcast(
                        this,
                        id,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )

                    // Calculate trigger time calendar
                    val calendar = java.util.Calendar.getInstance().apply {
                        timeInMillis = System.currentTimeMillis()
                        set(java.util.Calendar.HOUR_OF_DAY, hour)
                        set(java.util.Calendar.MINUTE, minute)
                        set(java.util.Calendar.SECOND, 0)
                        
                        // If the scheduled time is in the past today, schedule it for tomorrow
                        if (timeInMillis <= System.currentTimeMillis()) {
                            add(java.util.Calendar.DAY_OF_YEAR, 1)
                        }
                    }

                    // Set daily repeating alarm
                    alarmManager.setRepeating(
                        AlarmManager.RTC_WAKEUP,
                        calendar.timeInMillis,
                        AlarmManager.INTERVAL_DAY,
                        pendingIntent
                    )

                    result.success(true)
                }
                "cancelMedicationAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val intent = Intent(this, AlarmReceiver::class.java)
                    val pendingIntent = PendingIntent.getBroadcast(
                        this,
                        id,
                        intent,
                        PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                    )
                    if (pendingIntent != null) {
                        alarmManager.cancel(pendingIntent)
                        pendingIntent.cancel()
                    }
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
