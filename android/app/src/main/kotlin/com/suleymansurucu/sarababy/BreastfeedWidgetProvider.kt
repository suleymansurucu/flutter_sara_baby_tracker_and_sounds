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
 * Breastfeed ana ekran widget'ı.
 *
 * Sol ve sağ taraf timer'larını yan yana gösterir.
 * Her iki tarafın state'i Flutter [WidgetBridgeService] tarafından
 * SharedPreferences'a yazılır; bu sınıf okur ve RemoteViews günceller.
 */
class BreastfeedWidgetProvider : AppWidgetProvider() {

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

            val leftRunning    = prefs.getBoolean("bf_left_running", false)
            val leftTsMs       = prefs.getLong("bf_left_start_ts", 0L)
            val rightRunning   = prefs.getBoolean("bf_right_running", false)
            val rightTsMs      = prefs.getLong("bf_right_start_ts", 0L)
            val lastEndMs      = prefs.getLong("bf_last_end_ts", 0L)

            val babyName       = prefs.getString("w_baby_name", "") ?: ""
            val strFeed        = prefs.getString("w_str_feed", "Breastfeed") ?: "Breastfeed"
            val strLeftSide    = prefs.getString("w_str_left_side", "Left") ?: "Left"
            val strRightSide   = prefs.getString("w_str_right_side", "Right") ?: "Right"
            val strStart       = prefs.getString("w_str_start", "Tap to start") ?: "Tap to start"
            val strLastFeed    = prefs.getString("w_str_last_feed", "Last feed") ?: "Last feed"

            val views = RemoteViews(context.packageName, R.layout.breastfeed_widget)

            views.setTextViewText(R.id.tv_feed_label, strFeed)
            views.setTextViewText(R.id.tv_baby_name, babyName)
            views.setTextViewText(R.id.tv_left_label, strLeftSide)
            views.setTextViewText(R.id.tv_right_label, strRightSide)

            // ── Sol taraf ──────────────────────────────────────────────────
            if (leftRunning && leftTsMs > 0) {
                val elapsedLeft = System.currentTimeMillis() - leftTsMs
                val baseLeft = SystemClock.elapsedRealtime() - elapsedLeft
                views.setChronometer(R.id.chrono_left, baseLeft, null, true)
                views.setViewVisibility(R.id.chrono_left, View.VISIBLE)
                views.setViewVisibility(R.id.tv_left_idle, View.GONE)
                views.setInt(R.id.layout_left, "setBackgroundResource",
                    R.drawable.side_timer_bg_active)
            } else {
                views.setChronometer(R.id.chrono_left, 0, null, false)
                views.setViewVisibility(R.id.chrono_left, View.GONE)
                views.setTextViewText(R.id.tv_left_idle, strStart)
                views.setViewVisibility(R.id.tv_left_idle, View.VISIBLE)
                views.setInt(R.id.layout_left, "setBackgroundResource",
                    R.drawable.side_timer_bg_idle)
            }

            // ── Sağ taraf ──────────────────────────────────────────────────
            if (rightRunning && rightTsMs > 0) {
                val elapsedRight = System.currentTimeMillis() - rightTsMs
                val baseRight = SystemClock.elapsedRealtime() - elapsedRight
                views.setChronometer(R.id.chrono_right, baseRight, null, true)
                views.setViewVisibility(R.id.chrono_right, View.VISIBLE)
                views.setViewVisibility(R.id.tv_right_idle, View.GONE)
                views.setInt(R.id.layout_right, "setBackgroundResource",
                    R.drawable.side_timer_bg_active)
            } else {
                views.setChronometer(R.id.chrono_right, 0, null, false)
                views.setViewVisibility(R.id.chrono_right, View.GONE)
                views.setTextViewText(R.id.tv_right_idle, strStart)
                views.setViewVisibility(R.id.tv_right_idle, View.VISIBLE)
                views.setInt(R.id.layout_right, "setBackgroundResource",
                    R.drawable.side_timer_bg_idle)
            }

            // ── Son besleme zamanı ─────────────────────────────────────────
            if (!leftRunning && !rightRunning && lastEndMs > 0) {
                val agoMin = TimeUnit.MILLISECONDS.toMinutes(
                    System.currentTimeMillis() - lastEndMs
                )
                val agoText = if (agoMin < 60) "${agoMin}m ago"
                              else "${agoMin / 60}h ${agoMin % 60}m ago"
                views.setTextViewText(R.id.tv_last_feed, "$strLastFeed: $agoText")
                views.setViewVisibility(R.id.tv_last_feed, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.tv_last_feed, View.GONE)
            }

            // ── Tap → uygulamayı breastfeed ekranında aç ──────────────────
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("sarababy://breastfeed")).apply {
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, appWidgetId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.breastfeed_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
