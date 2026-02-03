package com.tranquiz.app.data.repository

import android.content.Context
import android.util.Log
import androidx.preference.PreferenceManager
import androidx.lifecycle.LiveData
import com.google.gson.GsonBuilder
import com.tranquiz.app.BuildConfig
import com.tranquiz.app.R
import com.tranquiz.app.data.api.ApiClient
import com.tranquiz.app.data.api.ChatApiService
import com.tranquiz.app.data.database.MessageDao
import com.tranquiz.app.data.model.*
import com.tranquiz.app.data.preferences.SecurePreferences
import com.tranquiz.app.data.therapeutic.SafetyClassifierPrompt
import com.tranquiz.app.util.CrisisEmailTracker
import com.tranquiz.app.util.Constants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class ChatRepository(
    private val messageDao: MessageDao,
    private val context: Context
) {

    companion object {
        private const val TAG = Constants.Tags.CHAT_REPOSITORY
        private val gson = GsonBuilder().disableHtmlEscaping().create()
    }

    fun getMessages(conversationId: Long): LiveData<List<Message>> {
        return messageDao.getMessagesForConversation(conversationId)
    }

    suspend fun sendMessage(
        userMessage: String,
        conversationId: Long = Constants.Conversation.DEFAULT_CONVERSATION_ID,
        provider: AIProvider? = null
    ): Result<String> {
        return withContext(Dispatchers.IO) {
            try {
                // Salva il messaggio dell'utente nel database
                val userMsg = Message(
                    content = userMessage,
                    isFromUser = true,
                    conversationId = conversationId
                )
                messageDao.insertMessage(userMsg)

                // Determina il provider da utilizzare
                val selectedProvider = provider ?: ApiClient.getCurrentProvider(context)
                val providerConfig = ApiClient.getProviderConfig(context, selectedProvider)
                val headers = ApiClient.getGatewayHeaders(context, selectedProvider)
                val apiService = ApiClient.getChatApiService(context)

                val messageHistory = messageDao.getMessagesForConversationSync(conversationId)
                val conversationalMessages = buildConversationalMessages(messageHistory)

                // Safety check
                val shouldBlock = performSafetyCheck(
                    apiService = apiService,
                    headers = headers,
                    provider = selectedProvider,
                    model = providerConfig.defaultModel,
                    conversationalMessages = conversationalMessages
                )

                if (shouldBlock) {
                    return@withContext handleConversationBlocked(conversationId)
                }

                // Prepara la richiesta API
                val apiMessages = mutableListOf<ChatMessage>()
                apiMessages.add(ChatMessage(Constants.Conversation.ROLE_SYSTEM, ApiClient.getSystemPrompt(context)))
                apiMessages.addAll(conversationalMessages)

                val request = ChatRequest(
                    model = providerConfig.defaultModel,
                    messages = apiMessages,
                    maxTokens = Constants.Api.DEFAULT_MAX_TOKENS,
                    temperature = resolveTemperature(
                        provider = selectedProvider,
                        model = providerConfig.defaultModel,
                        desired = Constants.Api.DEFAULT_TEMPERATURE.toString().toDouble()
                    ),
                    stream = false
                )

                val response = apiService.sendMessage(headers, request)
                val (finalRequest, finalResponse, finalErrorDetails) = resolveFinalResponse(
                    provider = selectedProvider,
                    initialRequest = request,
                    initialResponse = response,
                    send = { req -> apiService.sendMessage(headers, req) }
                )

                if (isDeveloperModeEnabled()) {
                    insertDeveloperTrace(
                        userInput = userMessage,
                        request = finalRequest,
                        response = finalResponse.body(),
                        responseCode = finalResponse.code(),
                        responseError = finalErrorDetails,
                        conversationId = conversationId
                    )
                }

                when {
                    finalResponse.isSuccessful && finalResponse.body() != null -> {
                        handleSuccessfulResponse(
                            response = finalResponse.body()!!,
                            conversationId = conversationId,
                            debugUserInput = userMessage,
                            debugRequest = finalRequest
                        )
                    }
                    else -> {
                        val apiError = ApiError.fromHttpCode(finalResponse.code(), finalErrorDetails.orEmpty())
                        handleApiError(apiError, selectedProvider, conversationId)
                    }
                }

            } catch (e: Exception) {
                val apiError = ApiError.fromException(e)
                logError("sendMessage", apiError)
                insertErrorMessage(apiError.getUserMessage(context), conversationId)
                Result.failure(Exception(apiError.getUserMessage(context)))
            }
        }
    }

    suspend fun requestWelcomeFromAI(
        conversationId: Long = Constants.Conversation.DEFAULT_CONVERSATION_ID,
        provider: AIProvider? = null
    ): Result<String> {
        return withContext(Dispatchers.IO) {
            try {
                val selectedProvider = provider ?: ApiClient.getCurrentProvider(context)
                val providerConfig = ApiClient.getProviderConfig(context, selectedProvider)
                val headers = ApiClient.getGatewayHeaders(context, selectedProvider)
                val apiService = ApiClient.getChatApiService(context)

                val messages = listOf(
                    ChatMessage(Constants.Conversation.ROLE_SYSTEM, ApiClient.getSystemPrompt(context)),
                    ChatMessage(
                        Constants.Conversation.ROLE_USER,
                        "Avvia la chat con un messaggio di benvenuto molto breve (1-2 frasi) e una domanda iniziale."
                    )
                )

                val request = ChatRequest(
                    model = providerConfig.defaultModel,
                    messages = messages,
                    maxTokens = Constants.Api.SAFETY_MAX_TOKENS,
                    temperature = resolveTemperature(
                        provider = selectedProvider,
                        model = providerConfig.defaultModel,
                        desired = Constants.Api.DEFAULT_TEMPERATURE.toString().toDouble()
                    ),
                    stream = false
                )

                val response = apiService.sendMessage(headers, request)
                val (finalRequest, finalResponse, finalErrorDetails) = resolveFinalResponse(
                    provider = selectedProvider,
                    initialRequest = request,
                    initialResponse = response,
                    send = { req -> apiService.sendMessage(headers, req) }
                )

                if (isDeveloperModeEnabled()) {
                    insertDeveloperTrace(
                        userInput = messages.lastOrNull()?.content,
                        request = finalRequest,
                        response = finalResponse.body(),
                        responseCode = finalResponse.code(),
                        responseError = finalErrorDetails,
                        conversationId = conversationId
                    )
                }

                when {
                    finalResponse.isSuccessful && finalResponse.body() != null -> {
                        handleSuccessfulResponse(
                            response = finalResponse.body()!!,
                            conversationId = conversationId,
                            debugUserInput = messages.lastOrNull()?.content,
                            debugRequest = finalRequest
                        )
                    }
                    else -> {
                        val apiError = ApiError.fromHttpCode(finalResponse.code(), finalErrorDetails.orEmpty())
                        handleApiError(apiError, selectedProvider, conversationId)
                    }
                }
            } catch (e: Exception) {
                val apiError = ApiError.fromException(e)
                logError("requestWelcomeFromAI", apiError)
                insertErrorMessage(apiError.getUserMessage(context), conversationId)
                Result.failure(Exception(apiError.getUserMessage(context)))
            }
        }
    }

    private fun buildConversationalMessages(history: List<Message>): List<ChatMessage> {
        val clean = history
            .filter { !it.isError && !it.isTyping && it.content.isNotBlank() }
            .takeLast(Constants.Api.MAX_HISTORY_MESSAGES)

        return clean.map { msg ->
            val role = if (msg.isFromUser) Constants.Conversation.ROLE_USER else Constants.Conversation.ROLE_ASSISTANT
            ChatMessage(role, msg.content)
        }
    }

    private suspend fun performSafetyCheck(
        apiService: ChatApiService,
        headers: Map<String, String>,
        provider: AIProvider,
        model: String,
        conversationalMessages: List<ChatMessage>
    ): Boolean {
        return try {
            val safetyMessages = mutableListOf<ChatMessage>()
            safetyMessages.add(ChatMessage(Constants.Conversation.ROLE_SYSTEM, SafetyClassifierPrompt.systemPrompt))
            safetyMessages.addAll(conversationalMessages.takeLast(6))

            val request = ChatRequest(
                model = model,
                messages = safetyMessages,
                maxTokens = 8,
                temperature = resolveTemperature(
                    provider = provider,
                    model = model,
                    desired = Constants.Api.SAFETY_TEMPERATURE.toString().toDouble()
                ),
                stream = false
            )

            val response = apiService.sendMessage(headers, request)
            val finalResponse = if (!response.isSuccessful && provider == AIProvider.OPENAI && response.code() == 400) {
                val details = safeErrorBody(response)
                if (isTemperatureUnsupported(details)) {
                    apiService.sendMessage(headers, request.copy(temperature = null))
                } else {
                    response
                }
            } else {
                response
            }
            if (!finalResponse.isSuccessful || finalResponse.body() == null) return false
            val content = finalResponse.body()!!.choices.firstOrNull()?.message?.content?.trim()
            content.equals(Constants.Safety.BLOCK_RESPONSE, ignoreCase = true)
        } catch (e: Exception) {
            logDebug("performSafetyCheck", "Safety check failed: ${e.message}")
            false
        }
    }


    private suspend fun handleConversationBlocked(conversationId: Long): Result<String> {
        val blockMessage = context.getString(R.string.safety_block_message)
        messageDao.insertMessage(
            Message(
                content = blockMessage,
                isFromUser = false,
                conversationId = conversationId
            )
        )

        // Send emergency email if configured
        sendEmergencyEmailIfNeeded()

        return Result.failure(Exception(Constants.Safety.CONVERSATION_BLOCKED_MARKER))
    }

    /**
     * Sends emergency email if configured and rate limit allows
     * Fails silently to avoid interrupting crisis flow
     */
    private suspend fun sendEmergencyEmailIfNeeded() {
        try {
            // Check if emergency contact is configured
            val emergencyEmail = SecurePreferences.getEmergencyContactEmail(context)
                ?: return

            // Check rate limiting
            if (!CrisisEmailTracker.canSendEmail(context)) {
                logDebug("sendEmergencyEmailIfNeeded", "Crisis email already sent in last 24h")
                return
            }

            // Get user name with fallback
            val prefs = androidx.preference.PreferenceManager.getDefaultSharedPreferences(context)
            val userName = prefs.getString(Constants.Prefs.ONBOARDING_NAME, "la persona che stai seguendo")
                ?: "la persona che stai seguendo"

            // Send email via worker
            val result = com.tranquiz.app.data.api.EmergencyEmailService.sendCrisisAlert(
                toEmail = emergencyEmail,
                userName = userName
            )

            if (result.isSuccess) {
                CrisisEmailTracker.recordEmailSent(context)
                logDebug("sendEmergencyEmailIfNeeded", "Emergency contact notified successfully: $emergencyEmail")
            } else {
                logDebug("sendEmergencyEmailIfNeeded", "Failed to send emergency email: ${result.exceptionOrNull()?.message}")
            }
        } catch (e: Exception) {
            logDebug("sendEmergencyEmailIfNeeded", "Error sending emergency email: ${e.message}")
            // Fail silently - don't interrupt crisis flow
        }
    }

    private suspend fun handleSuccessfulResponse(
        response: ChatResponse,
        conversationId: Long,
        debugUserInput: String? = null,
        debugRequest: ChatRequest? = null
    ): Result<String> {
        val firstChoice = response.choices.firstOrNull()
        val aiMessage = firstChoice?.message?.content?.takeIf { it.isNotBlank() }
            ?: firstChoice?.text?.takeIf { it.isNotBlank() }

        return if (!aiMessage.isNullOrBlank()) {
            messageDao.insertMessage(
                Message(
                    content = aiMessage,
                    isFromUser = false,
                    conversationId = conversationId
                )
            )
            Result.success(aiMessage)
        } else {
            val error = ApiError.EmptyResponse
            val isDeveloperMode = PreferenceManager
                .getDefaultSharedPreferences(context)
                .getBoolean(Constants.Prefs.DEVELOPER_MODE, false)

            val userMessage = if (BuildConfig.DEBUG || isDeveloperMode) {
                val requestJson = debugRequest?.let { runCatching { gson.toJson(it) }.getOrNull() }
                val responseJson = runCatching { gson.toJson(response) }.getOrNull()

                buildString {
                    append("Risposta vuota dal server\n")
                    append("User: ").append(debugUserInput ?: "(n/a)").append("\n")
                    append("Request: ").append(requestJson ?: "(n/a)").append("\n")
                    append("Response: ").append(responseJson ?: "(n/a)")
                }
            } else {
                error.getUserMessage(context)
            }
            insertErrorMessage(userMessage, conversationId)
            Result.failure(Exception(userMessage))
        }
    }

    private suspend fun handleApiError(
        error: ApiError,
        provider: AIProvider,
        conversationId: Long
    ): Result<String> {
        logError("handleApiError", error)

        // In debug mostra più dettagli, in release messaggi generici
        val userMessage = if (BuildConfig.DEBUG) {
            "${provider.displayName}: ${error.getDebugMessage()}"
        } else {
            error.getUserMessage(context)
        }

        insertErrorMessage(userMessage, conversationId)
        return Result.failure(Exception(userMessage))
    }

    private suspend fun insertErrorMessage(content: String, conversationId: Long) {
        messageDao.insertMessage(
            Message(
                content = content,
                isFromUser = false,
                isError = true,
                conversationId = conversationId
            )
        )
    }

    private fun logError(method: String, error: ApiError) {
        if (BuildConfig.DEBUG) {
            Log.e(TAG, "$method: ${error.getDebugMessage()}")
        }
    }

    private fun logDebug(method: String, message: String) {
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "$method: $message")
        }
    }

    private fun safeErrorBody(response: retrofit2.Response<*>): String {
        val msg = response.message().orEmpty()
        val body = try { response.errorBody()?.string().orEmpty() } catch (_: Exception) { "" }
        return listOf(msg, body).filter { it.isNotBlank() }.joinToString("\n")
    }

    private fun resolveTemperature(provider: AIProvider, model: String, desired: Double): Double? {
        if (provider != AIProvider.OPENAI) return desired
        val m = model.lowercase().trim()
        val supportsCustomTemperature = !(m.startsWith("o1") || m.startsWith("o3"))
        return if (supportsCustomTemperature) desired else null
    }

    private fun isTemperatureUnsupported(details: String): Boolean {
        val d = details.lowercase()
        return d.contains("\"param\":\"temperature\"") ||
            (d.contains("temperature") && d.contains("only the default (1) value is supported"))
    }

    private fun isDeveloperModeEnabled(): Boolean {
        return PreferenceManager
            .getDefaultSharedPreferences(context)
            .getBoolean(Constants.Prefs.DEVELOPER_MODE, false)
    }

    private suspend fun insertDeveloperTrace(
        userInput: String?,
        request: ChatRequest,
        response: ChatResponse?,
        responseCode: Int,
        responseError: String?,
        conversationId: Long
    ) {
        val requestJson = runCatching { gson.toJson(request) }.getOrNull()
        val responseBodyJson = response?.let { runCatching { gson.toJson(it) }.getOrNull() }

        val content = buildString {
            append("DEV TRACE\n")
            append("User: ").append(userInput ?: "(n/a)").append("\n")
            append("Request: ").append(requestJson ?: "(n/a)").append("\n")
            append("HTTP: ").append(responseCode).append("\n")
            append("Response: ").append(responseBodyJson ?: responseError ?: "(n/a)")
        }.truncateForChat(12000)

        messageDao.insertMessage(
            Message(
                content = content,
                isFromUser = false,
                isError = true,
                conversationId = conversationId
            )
        )
    }

    private fun String.truncateForChat(maxLen: Int): String {
        return if (length <= maxLen) this else take(maxLen) + "\n…(troncato)"
    }

    private suspend fun resolveFinalResponse(
        provider: AIProvider,
        initialRequest: ChatRequest,
        initialResponse: retrofit2.Response<ChatResponse>,
        send: suspend (ChatRequest) -> retrofit2.Response<ChatResponse>
    ): Triple<ChatRequest, retrofit2.Response<ChatResponse>, String?> {
        if (provider == AIProvider.OPENAI && !initialResponse.isSuccessful && initialResponse.code() == 400) {
            val details = safeErrorBody(initialResponse)
            if (isTemperatureUnsupported(details)) {
                val retryRequest = initialRequest.copy(temperature = null)
                val retryResponse = send(retryRequest)
                val retryDetails = if (retryResponse.isSuccessful) null else safeErrorBody(retryResponse).takeIf { it.isNotBlank() }
                return Triple(retryRequest, retryResponse, retryDetails)
            }
            return Triple(initialRequest, initialResponse, details.takeIf { it.isNotBlank() })
        }

        val details = if (initialResponse.isSuccessful) null else safeErrorBody(initialResponse).takeIf { it.isNotBlank() }
        return Triple(initialRequest, initialResponse, details)
    }

    suspend fun clearConversation(conversationId: Long = Constants.Conversation.DEFAULT_CONVERSATION_ID) {
        withContext(Dispatchers.IO) {
            messageDao.clearConversation(conversationId)
        }
    }

    suspend fun insertMessage(message: Message) {
        withContext(Dispatchers.IO) {
            messageDao.insertMessage(message)
        }
    }
}
