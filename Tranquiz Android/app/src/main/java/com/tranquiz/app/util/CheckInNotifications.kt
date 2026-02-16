package com.tranquiz.app.util

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.preference.PreferenceManager
import com.tranquiz.app.R
import com.tranquiz.app.ui.MainActivity
import java.util.Calendar

object CheckInNotificationScheduler {
    const val CHANNEL_ID = "check_in_reminders"
    const val EXTRA_TYPE = "type"
    const val TYPE_MORNING = "morning"
    const val TYPE_EVENING = "evening"

    private const val REQUEST_CODE_MORNING = 501
    private const val REQUEST_CODE_EVENING = 502

    fun scheduleAll(context: Context) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val enabled = prefs.getBoolean(Constants.Prefs.CHECKIN_REMINDERS_ENABLED, false)

        val (morningHour, morningMinute) = parseTime(
            prefs.getString(Constants.Prefs.CHECKIN_MORNING_TIME, null),
            8,
            0
        )
        val (eveningHour, eveningMinute) = parseTime(
            prefs.getString(Constants.Prefs.CHECKIN_EVENING_TIME, null),
            21,
            0
        )

        scheduleReminder(context, TYPE_MORNING, morningHour, morningMinute, enabled)
        scheduleReminder(context, TYPE_EVENING, eveningHour, eveningMinute, enabled)
    }

    private fun scheduleReminder(
        context: Context,
        type: String,
        hour: Int,
        minute: Int,
        enabled: Boolean
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = createPendingIntent(context, type)

        if (!enabled) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
            return
        }

        val triggerAt = nextTriggerAt(hour, minute)
        alarmManager.setInexactRepeating(
            AlarmManager.RTC_WAKEUP,
            triggerAt,
            AlarmManager.INTERVAL_DAY,
            pendingIntent
        )
    }

    private fun createPendingIntent(context: Context, type: String): PendingIntent {
        val requestCode = if (type == TYPE_MORNING) REQUEST_CODE_MORNING else REQUEST_CODE_EVENING
        val intent = Intent(context, CheckInReminderReceiver::class.java).putExtra(EXTRA_TYPE, type)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }

    private fun nextTriggerAt(hour: Int, minute: Int): Long {
        val now = Calendar.getInstance()
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (calendar.before(now)) {
            calendar.add(Calendar.DAY_OF_YEAR, 1)
        }
        return calendar.timeInMillis
    }

    private fun parseTime(value: String?, defaultHour: Int, defaultMinute: Int): Pair<Int, Int> {
        if (value.isNullOrBlank()) return Pair(defaultHour, defaultMinute)
        val parts = value.split(":")
        val hour = parts.getOrNull(0)?.toIntOrNull() ?: defaultHour
        val minute = parts.getOrNull(1)?.toIntOrNull() ?: defaultMinute
        return Pair(hour.coerceIn(0, 23), minute.coerceIn(0, 59))
    }
}

class CheckInReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        if (!prefs.getBoolean(Constants.Prefs.CHECKIN_REMINDERS_ENABLED, false)) return

        val type = intent.getStringExtra(CheckInNotificationScheduler.EXTRA_TYPE) ?: return
        val (title, message, notificationId) = when (type) {
            CheckInNotificationScheduler.TYPE_MORNING -> Triple(
                context.getString(R.string.checkin_notification_morning_title),
                context.getString(R.string.checkin_notification_morning_body),
                901
            )
            CheckInNotificationScheduler.TYPE_EVENING -> Triple(
                context.getString(R.string.checkin_notification_evening_title),
                context.getString(R.string.checkin_notification_evening_body),
                902
            )
            else -> return
        }

        ensureChannel(context)

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CheckInNotificationScheduler.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(message)
            .setContentIntent(openPendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        NotificationManagerCompat.from(context).notify(notificationId, notification)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(CheckInNotificationScheduler.CHANNEL_ID)
        if (existing != null) return
        val channel = NotificationChannel(
            CheckInNotificationScheduler.CHANNEL_ID,
            context.getString(R.string.checkin_notification_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT
        )
        manager.createNotificationChannel(channel)
    }
}

class CheckInBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            CheckInNotificationScheduler.scheduleAll(context)
        }
    }
}
