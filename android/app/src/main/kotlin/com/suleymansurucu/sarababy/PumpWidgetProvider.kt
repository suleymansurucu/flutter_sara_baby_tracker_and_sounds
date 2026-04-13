package com.suleymansurucu.sarababy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import java.util.concurrent.TimeUnit

/**
 * Pump ana ekran widget'ı.
 *
 * Total ve Left/Right modlarını destekler.
 * Aktif modu 'pump_mode' key'inden okur ('total' | 'leftRight').
 * Flutter [WidgetBridgeService] tarafından SharedPreferences'a yazılan
 * verileri okuyarak RemoteViews'i günceller.
 */
class PumpWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences(context.packageName, Context.MODE_PRIVATE)

            val isRunning    = prefs.getBoolean("pump_running", false)
            val startTsMs    = prefs.getLong("pump_start_ts", 0L)
            val lastEndMs    = prefs.getLong("pump_last_end_ts", 0L)

            val strPump      = prefs.getString("w_str_pump", "Pump") ?: "Pump"
            val strStart     = prefs.getString("w_str_start", "Tap to start") ?: "Tap to start"
            val strStop      = prefs.getString("w_str_stop", "Tap to pause") ?: "Tap to pause"
            val strLastPump  = prefs.getString("w_str_last_pump", "Last pump") ?: "Last pump"

            val views = RemoteViews(context.packageName, R.layout.pump_widget)

            views.setTextViewText(R.id.tv_pump_label, strPump)

            when {
                isRunning && startTsMs > 0 -> {
                    val elapsed = System.currentTimeMillis() - startTsMs
                    val base = SystemClock.elapsedRealtime() - elapsed
                    views.setChronometer(R.id.chrono_pump, base, null, true)
                    views.setViewVisibility(R.id.chrono_pump, View.VISIBLE)
                    views.setTextViewText(R.id.tv_stop_hint, strStop)
                    views.setViewVisibility(R.id.tv_stop_hint, View.VISIBLE)
                    views.setViewVisibility(R.id.tv_last_pump_label, View.GONE)
                    views.setViewVisibility(R.id.tv_last_pump_ago, View.GONE)
                    views.setViewVisibility(R.id.tv_start_hint, View.GONE)
                }

                lastEndMs > 0 -> {
                    val agoMin = TimeUnit.MILLISECONDS.toMinutes(
                        System.currentTimeMillis() - lastEndMs
                    )
                    val agoText = if (agoMin < 60) "${agoMin}m ago"
                                  else "${agoMin / 60}h ${agoMin % 60}m ago"

                    views.setViewVisibility(R.id.chrono_pump, View.GONE)
                    views.setViewVisibility(R.id.tv_stop_hint, View.GONE)
                    views.setTextViewText(R.id.tv_last_pump_label, strLastPump)
                    views.setViewVisibility(R.id.tv_last_pump_label, View.VISIBLE)
                    views.setTextViewText(R.id.tv_last_pump_ago, agoText)
                    views.setViewVisibility(R.id.tv_last_pump_ago, View.VISIBLE)
                    views.setViewVisibility(R.id.tv_start_hint, View.GONE)
                }

                else -> {
                    views.setViewVisibility(R.id.chrono_pump, View.GONE)
                    views.setViewVisibility(R.id.tv_stop_hint, View.GONE)
                    views.setViewVisibility(R.id.tv_last_pump_label, View.GONE)
                    views.setViewVisibility(R.id.tv_last_pump_ago, View.GONE)
                    views.setTextViewText(R.id.tv_start_hint, strStart)
                    views.setViewVisibility(R.id.tv_start_hint, View.VISIBLE)
                }
            }

            // Tap → uygulamayı pump ekranında aç
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("sarababy://pump")).apply {
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, appWidgetId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.pump_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
