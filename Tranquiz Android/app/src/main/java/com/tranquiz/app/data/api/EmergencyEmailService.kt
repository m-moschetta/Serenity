package com.tranquiz.app.data.api

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * Service for sending crisis alert emails via worker endpoint
 * Email content and Resend API key are handled server-side for security
 */
object EmergencyEmailService {
    // Worker endpoint (to be configured - can be updated later)
    // TODO: Replace with actual worker URL once deployed
    private const val WORKER_ENDPOINT = "https://YOUR_WORKER_URL/send-crisis-email"

    private val client = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()

    /**
     * Sends crisis alert email to emergency contact
     * @param toEmail Emergency contact email address
     * @param userName User's name (used in email message personalization)
     * @return Result<Unit> Success or failure with error
     */
    suspend fun sendCrisisAlert(
        toEmail: String,
        userName: String
    ): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            val jsonBody = JSONObject().apply {
                put("toEmail", toEmail)
                put("userName", userName)
            }

            val requestBody = jsonBody.toString()
                .toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url(WORKER_ENDPOINT)
                .addHeader("Content-Type", "application/json")
                .post(requestBody)
                .build()

            val response = client.newCall(request).execute()

            if (response.isSuccessful) {
                // Optional: Parse response for success confirmation
                val responseBody = response.body?.string()
                val responseJson = responseBody?.let { JSONObject(it) }
                val success = responseJson?.optBoolean("success", true) ?: true

                if (success) {
                    Result.success(Unit)
                } else {
                    val message = responseJson?.optString("message", "Unknown error")
                    Result.failure(Exception("Worker error: $message"))
                }
            } else {
                Result.failure(Exception("Email send failed: ${response.code} ${response.message}"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
