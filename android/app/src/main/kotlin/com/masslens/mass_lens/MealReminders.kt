package com.masslens.mass_lens

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.util.Calendar

/**
 * One optional daily "log your meal" reminder.
 *
 * Uses an inexact alarm window (no exact-alarm permission needed) and
 * reschedules itself after each reminder, reboot, app update or time change.
 * The reminder is skipped when a meal was logged in the last few hours.
 */
internal object MealReminders {
    private const val PREFS = "masslens_meal_reminders"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_HOUR = "hour"
    private const val KEY_MINUTE = "minute"
    private const val KEY_TITLE = "title"
    private const val KEY_BODY = "body"
    private const val KEY_CHANNEL_NAME = "channel_name"
    private const val KEY_LAST_MEAL_MS = "last_meal_ms"
    const val CHANNEL_ID = "meal_reminders"
    const val ACTION_REMIND = "com.masslens.mass_lens.MEAL_REMINDER"
    private const val NOTIFICATION_ID = 4101
    private const val REQUEST_CODE = 4101
    const val SKIP_IF_LOGGED_WITHIN_MS = 3L * 60 * 60 * 1000
    private const val WINDOW_MS = 15L * 60 * 1000

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun configure(
        context: Context,
        hour: Int,
        minute: Int,
        title: String,
        body: String,
        channelName: String,
    ) {
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, true)
            .putInt(KEY_HOUR, hour.coerceIn(0, 23))
            .putInt(KEY_MINUTE, minute.coerceIn(0, 59))
            .putString(KEY_TITLE, title)
            .putString(KEY_BODY, body)
            .putString(KEY_CHANNEL_NAME, channelName)
            .apply()
        ensureChannel(context, channelName)
        scheduleNext(context)
    }

    fun disable(context: Context) {
        prefs(context).edit().putBoolean(KEY_ENABLED, false).apply()
        alarmManager(context)?.cancel(pendingIntent(context))
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    fun noteMealLogged(context: Context, atMillis: Long) {
        prefs(context).edit().putLong(KEY_LAST_MEAL_MS, atMillis).apply()
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    fun canPostNotifications(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) return false
        return NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    fun scheduleNext(context: Context) {
        val prefs = prefs(context)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return
        val trigger = nextTriggerMillis(
            System.currentTimeMillis(),
            prefs.getInt(KEY_HOUR, 12),
            prefs.getInt(KEY_MINUTE, 30),
        )
        alarmManager(context)?.setWindow(
            AlarmManager.RTC_WAKEUP, trigger, WINDOW_MS, pendingIntent(context),
        )
    }

    fun onAlarm(context: Context) {
        val prefs = prefs(context)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return
        try {
            val lastMeal = prefs.getLong(KEY_LAST_MEAL_MS, 0L)
            if (shouldNotify(System.currentTimeMillis(), lastMeal) && canPostNotifications(context)) {
                showNotification(
                    context,
                    prefs.getString(KEY_TITLE, null) ?: "Log your meal",
                    prefs.getString(KEY_BODY, null) ?: "Snap your plate to keep your streak going.",
                    prefs.getString(KEY_CHANNEL_NAME, null) ?: "Meal reminders",
                )
            }
        } finally {
            scheduleNext(context)
        }
    }

    fun shouldNotify(nowMillis: Long, lastMealMillis: Long): Boolean {
        if (lastMealMillis <= 0L) return true
        val elapsed = nowMillis - lastMealMillis
        return elapsed < 0L || elapsed >= SKIP_IF_LOGGED_WITHIN_MS
    }

    /** Next occurrence of hour:minute strictly after [nowMillis], in local time. */
    fun nextTriggerMillis(nowMillis: Long, hour: Int, minute: Int): Long {
        val calendar = Calendar.getInstance().apply {
            timeInMillis = nowMillis
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (calendar.timeInMillis <= nowMillis) calendar.add(Calendar.DAY_OF_YEAR, 1)
        return calendar.timeInMillis
    }

    private fun showNotification(context: Context, title: String, body: String, channelName: String) {
        ensureChannel(context, channelName)
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
            ?: return
        val content = PendingIntent.getActivity(
            context, REQUEST_CODE, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_masslens)
            .setColor(0xFF121B36.toInt())
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(content)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // Permission revoked between the check and the post.
        }
    }

    private fun ensureChannel(context: Context, name: String) {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_DEFAULT)
        )
    }

    private fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

    private fun pendingIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        REQUEST_CODE,
        Intent(context, MealReminderReceiver::class.java).setAction(ACTION_REMIND),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

class MealReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            MealReminders.ACTION_REMIND -> MealReminders.onAlarm(context)
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> MealReminders.scheduleNext(context)
        }
    }
}
