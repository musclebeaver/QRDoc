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
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
