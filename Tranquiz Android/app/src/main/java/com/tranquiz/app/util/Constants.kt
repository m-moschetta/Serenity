package com.tranquiz.app.util

/**
 * Costanti centralizzate per l'applicazione.
 * Evita magic strings e numbers sparsi nel codice.
 */
object Constants {

    // ==================== Chiavi SharedPreferences ====================

    object Prefs {
        // Onboarding
        const val ONBOARDING_COMPLETED = "pref_onboarding_completed"
        const val ONBOARDING_NAME = "pref_onboarding_name"
        const val ONBOARDING_FEELING = "pref_onboarding_feeling"
        const val ONBOARDING_GOAL = "pref_onboarding_goal"

        // Provider e modelli
        const val CURRENT_PROVIDER = "pref_current_provider"
        const val MODEL_OPENAI = "pref_model_openai"
        const val MODEL_ANTHROPIC = "pref_model_anthropic"
        const val MODEL_PERPLEXITY = "pref_model_perplexity"
        const val MODEL_GROQ = "pref_model_groq"

        // Gateway
        const val GATEWAY_BASE_URL = "pref_gateway_base_url"
        const val GATEWAY_API_KEY = "pref_gateway_api_key"

        // Sistema
        const val SYSTEM_PROMPT = "pref_system_prompt"

        // Tone preferences
        const val TONE_EMPATHY = "pref_tone_empathy"      // "empathetic" | "neutral"
        const val TONE_APPROACH = "pref_tone_approach"    // "gentle" | "direct"
        const val TONE_ENERGY = "pref_tone_energy"        // "calm" | "energetic"
        const val TONE_MOOD = "pref_tone_mood"            // "serious" | "light"
        const val TONE_LENGTH = "pref_tone_length"        // "brief" | "detailed"
        const val TONE_STYLE = "pref_tone_style"          // "intimate" | "professional"
    }

    // ==================== Configurazione API ====================

    object Api {
        /** Numero massimo di messaggi da includere nella cronologia per il contesto AI */
        const val MAX_HISTORY_MESSAGES = 12

        /** Token massimi per risposta AI normale */
        const val DEFAULT_MAX_TOKENS = 1000

        /** Token massimi per safety check (risposta breve) */
        const val SAFETY_MAX_TOKENS = 220

        /** Temperatura per safety classifier (deterministica) */
        const val SAFETY_TEMPERATURE = 0.0f

        /** Temperatura default per risposte AI */
        const val DEFAULT_TEMPERATURE = 0.7f

        /** Timeout connessione in secondi */
        const val CONNECTION_TIMEOUT_SECONDS = 30L

        /** Timeout lettura in secondi */
        const val READ_TIMEOUT_SECONDS = 30L

        /** Timeout scrittura in secondi */
        const val WRITE_TIMEOUT_SECONDS = 30L
    }

    // ==================== Conversazione ====================

    object Conversation {
        /** ID conversazione default (per ora singola conversazione) */
        const val DEFAULT_CONVERSATION_ID = 1L

        /** Ruolo sistema nei messaggi API */
        const val ROLE_SYSTEM = "system"

        /** Ruolo utente nei messaggi API */
        const val ROLE_USER = "user"

        /** Ruolo assistente nei messaggi API */
        const val ROLE_ASSISTANT = "assistant"
    }

    // ==================== Safety ====================

    object Safety {
        /** Risposta del classifier quando blocca la conversazione */
        const val BLOCK_RESPONSE = "BLOCK"

        /** Risposta del classifier quando la conversazione è sicura */
        const val OK_RESPONSE = "OK"

        /** Marcatore interno per conversazione bloccata */
        const val CONVERSATION_BLOCKED_MARKER = "CONVERSATION_BLOCKED"
    }

    // ==================== UI ====================

    object Ui {
        /** Numero massimo di linee per input messaggio */
        const val MAX_INPUT_LINES = 4

        /** Lunghezza massima preview nelle impostazioni */
        const val SETTINGS_PREVIEW_MAX_LENGTH = 80

        /** Numero di step onboarding */
        const val ONBOARDING_STEPS = 4
    }

    // ==================== Logging Tags ====================

    object Tags {
        const val API_CLIENT = "ApiClient"
        const val CHAT_REPOSITORY = "ChatRepository"
        const val CHAT_VIEW_MODEL = "ChatViewModel"
        const val MAIN_ACTIVITY = "MainActivity"
        const val SETTINGS_ACTIVITY = "SettingsActivity"
    }
}
