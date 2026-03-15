package com.auroclime.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Native Android AppWidgetProvider for the Auroclime home screen widget.
 *
 * Reads weather data saved by Flutter's [WidgetService] via SharedPreferences
 * (using the home_widget package convention) and renders it into RemoteViews.
 */
class AuroclimeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        // home_widget stores data under this SharedPreferences file name.
        private const val PREFS_NAME = "HomeWidgetPreferences"

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.auroclime_widget_layout)

            // --- Main weather data ---
            views.setTextViewText(
                R.id.widget_location,
                prefs.getString("widget_location", "Auroclime")
            )
            views.setTextViewText(
                R.id.widget_temp,
                prefs.getString("widget_temp", "--°")
            )
            views.setTextViewText(
                R.id.widget_condition,
                prefs.getString("widget_condition", "Tap to open")
            )
            val iconName = prefs.getString("widget_condition_icon", "ic_widget_cloudy")
            val iconId = context.resources.getIdentifier(iconName, "drawable", context.packageName)
            if (iconId != 0) {
                views.setImageViewResource(R.id.widget_icon, iconId)
            }

            views.setTextViewText(
                R.id.widget_feels_like,
                prefs.getString("widget_feels_like", "Feels --°")
            )
            views.setTextViewText(
                R.id.widget_high,
                prefs.getString("widget_high", "H:--°")
            )
            views.setTextViewText(
                R.id.widget_low,
                prefs.getString("widget_low", "L:--°")
            )
            views.setTextViewText(
                R.id.widget_updated,
                prefs.getString("widget_updated_at", "--")
            )

            // --- Hourly forecast ---
            val hourlyTimeIds = intArrayOf(
                R.id.widget_h_time_0, R.id.widget_h_time_1,
                R.id.widget_h_time_2, R.id.widget_h_time_3
            )
            val hourlyTempIds = intArrayOf(
                R.id.widget_h_temp_0, R.id.widget_h_temp_1,
                R.id.widget_h_temp_2, R.id.widget_h_temp_3
            )
            val hourlyIconIds = intArrayOf(
                R.id.widget_h_icon_0, R.id.widget_h_icon_1,
                R.id.widget_h_icon_2, R.id.widget_h_icon_3
            )

            for (i in 0..3) {
                views.setTextViewText(
                    hourlyTimeIds[i],
                    prefs.getString("widget_hourly_time_$i", "--")
                )
                views.setTextViewText(
                    hourlyTempIds[i],
                    prefs.getString("widget_hourly_temp_$i", "--°")
                )
                
                val hIconName = prefs.getString("widget_hourly_icon_$i", "ic_widget_cloudy")
                val hIconId = context.resources.getIdentifier(hIconName, "drawable", context.packageName)
                if (hIconId != 0) {
                    views.setImageViewResource(hourlyIconIds[i], hIconId)
                }
            }

            // --- Tap → open app ---
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
