package com.tranquiz.app.util

import android.content.Context
import android.content.SharedPreferences

/**
 * Tracks when crisis emails were sent to enforce 24-hour rate limiting
 * Prevents spam and ensures emergency contacts are not overwhelmed
 */
object CrisisEmailTracker {
    private const val PREFS_NAME = "crisis_email_tracker"
    private const val KEY_LAST_EMAIL_SENT = "last_crisis_email_sent"
    private const val HOURS_24_IN_MILLIS = 24 * 60 * 60 * 1000L

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    /**
     * Checks if enough time has passed since last email (24 hours)
     * @return true if email can be sent, false if still within 24h window
     */
    fun canSendEmail(context: Context): Boolean {
        val lastSent = getPrefs(context).getLong(KEY_LAST_EMAIL_SENT, 0L)
        if (lastSent == 0L) return true // Never sent before

        val timeSinceLast = System.currentTimeMillis() - lastSent
        return timeSinceLast >= HOURS_24_IN_MILLIS
    }

    /**
     * Records the current timestamp as when an email was sent
     */
    fun recordEmailSent(context: Context) {
        getPrefs(context)
            .edit()
            .putLong(KEY_LAST_EMAIL_SENT, System.currentTimeMillis())
            .apply()
    }

    /**
     * Gets the time remaining until next email can be sent (in milliseconds)
     * @return Milliseconds remaining, or null if email can be sent now
     */
    fun timeUntilNextEmail(context: Context): Long? {
        val lastSent = getPrefs(context).getLong(KEY_LAST_EMAIL_SENT, 0L)
        if (lastSent == 0L) return null // Can send now

        val timeSinceLast = System.currentTimeMillis() - lastSent
        val remaining = HOURS_24_IN_MILLIS - timeSinceLast

        return if (remaining > 0) remaining else null
    }

    /**
     * Clears the tracking data (useful for testing)
     */
    fun reset(context: Context) {
        getPrefs(context)
            .edit()
            .remove(KEY_LAST_EMAIL_SENT)
            .apply()
    }
}
