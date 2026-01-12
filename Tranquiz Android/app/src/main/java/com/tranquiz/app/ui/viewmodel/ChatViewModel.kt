package com.tranquiz.app.ui.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.map
import androidx.lifecycle.viewModelScope
import androidx.preference.PreferenceManager
import com.tranquiz.app.data.api.ApiClient
import com.tranquiz.app.data.database.AppDatabase
import com.tranquiz.app.data.model.AIProvider
import com.tranquiz.app.data.model.Message
import com.tranquiz.app.data.repository.ChatRepository
import com.tranquiz.app.util.Constants
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Stato UI consolidato per la chat.
 * Invece di 6 LiveData separati, un singolo stato immutabile.
 */
data class ChatUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val isTyping: Boolean = false,
    val isConversationBlocked: Boolean = false,
    val currentProvider: AIProvider = AIProvider.OPENAI
)

class ChatViewModel(application: Application) : AndroidViewModel(application) {

    private val database = AppDatabase.getDatabase(application)
    private val repository = ChatRepository(database.messageDao(), application)

    // Messaggi come LiveData separato (proviene dal database, osservato con Room)
    val messages: LiveData<List<Message>> = repository.getMessages(Constants.Conversation.DEFAULT_CONVERSATION_ID)

    // Stato UI consolidato
    private val _uiState = MutableLiveData(ChatUiState())
    val uiState: LiveData<ChatUiState> = _uiState

    // Convenience accessors per retrocompatibilità durante la migrazione
    val isLoading: LiveData<Boolean> = _uiState.map { it.isLoading }
    val error: LiveData<String?> = _uiState.map { it.error }
    val isTyping: LiveData<Boolean> = _uiState.map { it.isTyping }
    val isConversationBlocked: LiveData<Boolean> = _uiState.map { it.isConversationBlocked }
    val currentProvider: LiveData<AIProvider> = _uiState.map { it.currentProvider }

    init {
        val context = getApplication<Application>()
        updateState { copy(currentProvider = ApiClient.getCurrentProvider(context)) }

        viewModelScope.launch {
            val messageCount = database.messageDao().getMessageCount(Constants.Conversation.DEFAULT_CONVERSATION_ID)
            val prefs = PreferenceManager.getDefaultSharedPreferences(context)
            val onboardingCompleted = prefs.getBoolean(Constants.Prefs.ONBOARDING_COMPLETED, false)
            if (messageCount == 0 && onboardingCompleted) {
                generateWelcomeFromAI()
            }
        }
    }

    fun onboardingCompleted() {
        viewModelScope.launch {
            val messageCount = database.messageDao().getMessageCount(Constants.Conversation.DEFAULT_CONVERSATION_ID)
            if (messageCount == 0) {
                generateWelcomeFromAI()
            }
        }
    }

    fun sendMessage(content: String) {
        if (content.trim().isEmpty()) {
            updateState { copy(error = "Il messaggio non può essere vuoto") }
            return
        }

        viewModelScope.launch {
            try {
                updateState { copy(isLoading = true, error = null) }
                showTypingIndicator()

                val provider = _uiState.value?.currentProvider ?: AIProvider.OPENAI
                val result = repository.sendMessage(content.trim(), provider = provider)

                if (result.isFailure) {
                    val errorMessage = result.exceptionOrNull()?.message
                    if (errorMessage == Constants.Safety.CONVERSATION_BLOCKED_MARKER) {
                        updateState { copy(isConversationBlocked = true) }
                    } else {
                        updateState { copy(error = errorMessage ?: "Errore sconosciuto") }
                    }
                }
            } catch (e: Exception) {
                updateState { copy(error = e.message ?: "Errore durante l'invio del messaggio") }
            } finally {
                updateState { copy(isLoading = false) }
                hideTypingIndicator()
            }
        }
    }

    fun setProvider(provider: AIProvider) {
        updateState { copy(currentProvider = provider) }
        // Salva la preferenza utente
        val prefs = PreferenceManager.getDefaultSharedPreferences(getApplication())
        prefs.edit().putString(Constants.Prefs.CURRENT_PROVIDER, provider.name).apply()
    }

    fun getAvailableProviders(): List<AIProvider> {
        return AIProvider.entries
    }

    fun clearConversation() {
        viewModelScope.launch {
            repository.clearConversation(Constants.Conversation.DEFAULT_CONVERSATION_ID)
            generateWelcomeFromAI()
            updateState { copy(isConversationBlocked = false) }
        }
    }

    fun clearError() {
        updateState { copy(error = null) }
    }

    private fun generateWelcomeFromAI() {
        viewModelScope.launch {
            try {
                updateState { copy(isLoading = true, error = null) }
                showTypingIndicator()

                val provider = _uiState.value?.currentProvider
                    ?: ApiClient.getCurrentProvider(getApplication())
                val result = repository.requestWelcomeFromAI(provider = provider)

                if (result.isFailure) {
                    updateState { copy(error = result.exceptionOrNull()?.message) }
                }
            } catch (e: Exception) {
                updateState { copy(error = e.message) }
            } finally {
                updateState { copy(isLoading = false) }
                hideTypingIndicator()
            }
        }
    }

    private suspend fun showTypingIndicator() {
        updateState { copy(isTyping = true) }
        delay(500)
    }

    private suspend fun hideTypingIndicator() {
        updateState { copy(isTyping = false) }
    }

    /**
     * Aggiorna lo stato UI in modo thread-safe.
     */
    private inline fun updateState(transform: ChatUiState.() -> ChatUiState) {
        val currentState = _uiState.value ?: ChatUiState()
        _uiState.value = currentState.transform()
    }
}
