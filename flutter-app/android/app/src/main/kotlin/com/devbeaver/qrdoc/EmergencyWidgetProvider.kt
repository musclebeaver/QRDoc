package com.devbeaver.qrdoc

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class EmergencyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val sharedPref = context.getSharedPreferences("emergency_pref", Context.MODE_PRIVATE)
        val name = sharedPref.getString("name", "미등록") ?: "미등록"
        val blood = sharedPref.getString("blood", "미등록") ?: "미등록"
        val contact = sharedPref.getString("contact", "미등록") ?: "미등록"

        // Construct the RemoteViews object
        val views = RemoteViews(context.packageName, R.layout.emergency_widget)
        views.setTextViewText(R.id.widget_name, "이름: $name")
        views.setTextViewText(R.id.widget_blood, "혈액형: $blood")
        views.setTextViewText(R.id.widget_contact, "비상연락: $contact")

        // Setup PendingIntent to open MainActivity
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("route", "emergency")
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Bind click event to the main card container
        views.setOnClickPendingIntent(R.id.widget_card, pendingIntent)

        // Instruct the widget manager to update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
