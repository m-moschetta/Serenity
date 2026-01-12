package com.tranquiz.app.data.repository

import android.content.Context
import android.util.Log
import androidx.lifecycle.LiveData
import com.tranquiz.app.BuildConfig
import com.tranquiz.app.R
import com.tranquiz.app.data.api.ApiClient
import com.tranquiz.app.data.api.ChatApiService
import com.tranquiz.app.data.database.MessageDao
import com.tranquiz.app.data.model.*
import com.tranquiz.app.data.therapeutic.SafetyClassifierPrompt
import com.tranquiz.app.util.Constants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class ChatRepository(
    private val messageDao: MessageDao,
    private val context: Context
) {

    companion object {
        private const val TAG = Constants.Tags.CHAT_REPOSITORY
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
                    temperature = Constants.Api.DEFAULT_TEMPERATURE.toDouble(),
                    stream = false
                )

                val response = apiService.sendMessage(headers, request)

                when {
                    response.isSuccessful && response.body() != null -> {
                        handleSuccessfulResponse(response.body()!!, conversationId)
                    }
                    else -> {
                        val apiError = ApiError.fromHttpCode(response.code(), response.message())
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
                    temperature = Constants.Api.DEFAULT_TEMPERATURE.toDouble(),
                    stream = false
                )

                val response = apiService.sendMessage(headers, request)

                when {
                    response.isSuccessful && response.body() != null -> {
                        handleSuccessfulResponse(response.body()!!, conversationId)
                    }
                    else -> {
                        val apiError = ApiError.fromHttpCode(response.code(), response.message())
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
                temperature = Constants.Api.SAFETY_TEMPERATURE.toDouble(),
                stream = false
            )

            val response = apiService.sendMessage(headers, request)
            if (!response.isSuccessful || response.body() == null) return false

            val content = response.body()!!.choices.firstOrNull()?.message?.content?.trim()
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
        return Result.failure(Exception(Constants.Safety.CONVERSATION_BLOCKED_MARKER))
    }

    private suspend fun handleSuccessfulResponse(
        response: ChatResponse,
        conversationId: Long
    ): Result<String> {
        val aiMessage = response.choices.firstOrNull()?.message?.content

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
            insertErrorMessage(error.getUserMessage(context), conversationId)
            Result.failure(Exception(error.getUserMessage(context)))
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
