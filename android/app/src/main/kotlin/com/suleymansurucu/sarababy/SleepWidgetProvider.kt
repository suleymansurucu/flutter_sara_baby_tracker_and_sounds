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

/**
 * Sleep ana ekran widget'ı.
 *
 * Veri akışı:
 *   Flutter [WidgetBridgeService] → SharedPreferences (home_widget)
 *   → bu sınıf okur → RemoteViews günceller
 *
 * Önemli: home_widget paketi SharedPreferences'ı context.packageName adıyla saklar.
 * Key'ler WidgetDataContract sabitleriyle birebir eşleşmelidir.
 */
class SleepWidgetProvider : AppWidgetProvider() {

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
            // home_widget paketi veriyi context.packageName adlı SharedPreferences'a yazar
            val prefs = context.getSharedPreferences(context.packageName, Context.MODE_PRIVATE)

            val isRunning    = prefs.getBoolean("sleep_running", false)
            val startTsMs    = prefs.getLong("sleep_start_ts", 0L)
            val lastDurSec   = prefs.getInt("sleep_last_dur_sec", 0)
            val strSleep     = prefs.getString("w_str_sleep", "Sleep") ?: "Sleep"
            val strStart     = prefs.getString("w_str_start", "Tap to start") ?: "Tap to start"
            val strStop      = prefs.getString("w_str_stop", "Tap to pause") ?: "Tap to pause"
            val strLastSleep = prefs.getString("w_str_last_sleep", "Last sleep") ?: "Last sleep"

            val views = RemoteViews(context.packageName, R.layout.sleep_widget)

            // Lokalize edilmiş başlık
            views.setTextViewText(R.id.tv_sleep_label, strSleep)

            when {
                isRunning && startTsMs > 0 -> {
                    // Chronometer base: elapsed realtime cinsinden başlangıç anını hesapla
                    val elapsedSinceStart = System.currentTimeMillis() - startTsMs
                    val base = SystemClock.elapsedRealtime() - elapsedSinceStart
                    views.setChronometer(R.id.chrono_sleep, base, null, true)
                    views.setViewVisibility(R.id.chrono_sleep, View.VISIBLE)
                    views.setTextViewText(R.id.tv_stop_hint, strStop)
                    views.setViewVisibility(R.id.tv_stop_hint, View.VISIBLE)
                    views.setViewVisibility(R.id.tv_last_duration, View.GONE)
                    views.setViewVisibility(R.id.tv_last_sleep_label, View.GONE)
                    views.setViewVisibility(R.id.tv_start_hint, View.GONE)
                }

                lastDurSec > 0 -> {
                    views.setViewVisibility(R.id.chrono_sleep, View.GONE)
                    views.setViewVisibility(R.id.tv_stop_hint, View.GONE)
                    views.setTextViewText(R.id.tv_last_duration, formatDuration(lastDurSec))
                    views.setViewVisibility(R.id.tv_last_duration, View.VISIBLE)
                    views.setTextViewText(R.id.tv_last_sleep_label, strLastSleep)
                    views.setViewVisibility(R.id.tv_last_sleep_label, View.VISIBLE)
                    views.setViewVisibility(R.id.tv_start_hint, View.GONE)
                }

                else -> {
                    views.setViewVisibility(R.id.chrono_sleep, View.GONE)
                    views.setViewVisibility(R.id.tv_stop_hint, View.GONE)
                    views.setViewVisibility(R.id.tv_last_duration, View.GONE)
                    views.setViewVisibility(R.id.tv_last_sleep_label, View.GONE)
                    views.setTextViewText(R.id.tv_start_hint, strStart)
                    views.setViewVisibility(R.id.tv_start_hint, View.VISIBLE)
                }
            }

            // Tap → uygulamayı sleep ekranında aç (deep link)
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("sarababy://sleep")).apply {
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, appWidgetId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.sleep_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun formatDuration(seconds: Int): String {
            val h = seconds / 3600
            val m = (seconds % 3600) / 60
            return if (h > 0) "${h}h ${m}m" else "${m}m"
        }
    }
}
