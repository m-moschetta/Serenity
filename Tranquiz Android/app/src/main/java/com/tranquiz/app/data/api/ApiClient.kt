package com.tranquiz.app.data.api

import android.content.Context
import android.content.SharedPreferences
import com.tranquiz.app.BuildConfig
import com.tranquiz.app.R
import com.tranquiz.app.data.model.AIProvider
import com.tranquiz.app.util.Constants
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

object ApiClient {

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = if (BuildConfig.DEBUG) {
            HttpLoggingInterceptor.Level.BODY
        } else {
            HttpLoggingInterceptor.Level.NONE
        }
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val retrofitInstances = mutableMapOf<String, Pair<Retrofit, ChatApiService>>()

    fun getChatApiService(context: Context): ChatApiService {
        var baseUrl = getGatewayBaseUrl(context)
        if (!baseUrl.endsWith("/")) baseUrl += "/"

        val key = baseUrl
        return retrofitInstances.getOrPut(key) {
            val retrofit = Retrofit.Builder()
                .baseUrl(baseUrl)
                .client(okHttpClient)
                .addConverterFactory(GsonConverterFactory.create())
                .build()
            val service = retrofit.create(ChatApiService::class.java)
            Pair(retrofit, service)
        }.second
    }

    fun getProviderConfig(context: Context, provider: AIProvider): com.tranquiz.app.data.model.ProviderConfig {
        // Leggi override del modello da SharedPreferences; fallback alle stringhe di default
        val prefs = androidx.preference.PreferenceManager.getDefaultSharedPreferences(context)
        val defaultModel = when (provider) {
            AIProvider.OPENAI -> prefs.getString("pref_model_openai", context.getString(R.string.provider_openai_default_model))
            AIProvider.ANTHROPIC -> prefs.getString("pref_model_anthropic", context.getString(R.string.provider_anthropic_default_model))
            AIProvider.PERPLEXITY -> prefs.getString("pref_model_perplexity", context.getString(R.string.provider_perplexity_default_model))
            AIProvider.GROQ -> prefs.getString("pref_model_groq", context.getString(R.string.provider_groq_default_model))
        } ?: context.getString(R.string.provider_openai_default_model)

        val gatewayKey = context.getString(R.string.gateway_api_key)
        return com.tranquiz.app.data.model.ProviderConfig(provider, gatewayKey, defaultModel)
    }

    fun getCurrentProvider(context: Context): AIProvider {
        val prefs = androidx.preference.PreferenceManager.getDefaultSharedPreferences(context)
        val providerPref = prefs.getString("pref_current_provider", context.getString(R.string.current_provider))
        val providerName = (providerPref ?: context.getString(R.string.current_provider)).uppercase()
        return try {
            AIProvider.valueOf(providerName)
        } catch (e: IllegalArgumentException) {
            AIProvider.OPENAI // fallback
        }
    }

    fun getGatewayBaseUrl(context: Context): String {
        val prefs = androidx.preference.PreferenceManager.getDefaultSharedPreferences(context)
        val defaultUrl = context.getString(R.string.gateway_base_url)
        return prefs.getString("pref_gateway_base_url", defaultUrl) ?: defaultUrl
    }

    private fun isPlaceholderToken(token: String): Boolean {
        val t = token.trim()
        return t.isEmpty() || t.contains("your-", ignoreCase = true) || t.endsWith("-here", ignoreCase = true)
    }

    fun getGatewayHeaders(context: Context, provider: AIProvider? = null): Map<String, String> {
        val prefs = androidx.preference.PreferenceManager.getDefaultSharedPreferences(context)
        val configuredToken = prefs.getString("pref_gateway_api_key", context.getString(R.string.gateway_api_key))
        val apiKey = configuredToken ?: ""
        val headers = mutableMapOf<String, String>()
        headers["Accept"] = "application/json"
        if (apiKey.isNotEmpty() && !isPlaceholderToken(apiKey)) {
            headers["Authorization"] = "Bearer $apiKey"
        }
        provider?.let {
            headers["x-provider"] = it.name.lowercase()
        }
        return headers
    }

    fun getSystemPrompt(context: Context): String {
        val prefs = androidx.preference.PreferenceManager.getDefaultSharedPreferences(context)
        val customPrompt = prefs.getString("pref_system_prompt", null)?.trim().orEmpty()
        val base = if (customPrompt.isNotBlank()) customPrompt else ApiConstants.SYSTEM_PROMPT

        // Build tone instructions
        val toneInstructions = buildToneInstructions(prefs)

        // Build user context
        val name = prefs.getString(Constants.Prefs.ONBOARDING_NAME, null)?.trim().orEmpty()
        val feeling = prefs.getString(Constants.Prefs.ONBOARDING_FEELING, null)?.trim().orEmpty()
        val goal = prefs.getString(Constants.Prefs.ONBOARDING_GOAL, null)?.trim().orEmpty()

        val contextParts = buildList {
            if (name.isNotBlank()) add("Nome: $name")
            if (feeling.isNotBlank()) add("Oggi si sente: $feeling")
            if (goal.isNotBlank()) add("Obiettivo: $goal")
        }

        val contextSection = if (contextParts.isEmpty()) ""
            else "\n\nContesto utente:\n" + contextParts.joinToString("\n")

        val finalPrompt = base + "\n\n" + toneInstructions + contextSection
        android.util.Log.d("ApiClient", "System Prompt Length: ${finalPrompt.length}")
        return finalPrompt
    }

    private fun buildToneInstructions(prefs: SharedPreferences): String {
        val instructions = mutableListOf<String>()

        // Empatia
        when (prefs.getString(Constants.Prefs.TONE_EMPATHY, "empathetic")) {
            "empathetic" -> instructions.add("Sii empatico, comprensivo e accogliente")
            "neutral" -> instructions.add("Sii neutro, oggettivo e pratico")
        }

        // Approccio
        when (prefs.getString(Constants.Prefs.TONE_APPROACH, "gentle")) {
            "gentle" -> instructions.add("Usa un approccio gentile e delicato")
            "direct" -> instructions.add("Sii diretto e vai al punto")
        }

        // Energia
        when (prefs.getString(Constants.Prefs.TONE_ENERGY, "calm")) {
            "calm" -> instructions.add("Mantieni un tono calmo e riflessivo")
            "energetic" -> instructions.add("Sii energico, motivante e incoraggiante")
        }

        // Tono
        when (prefs.getString(Constants.Prefs.TONE_MOOD, "serious")) {
            "serious" -> instructions.add("Mantieni un tono serio e professionale")
            "light" -> instructions.add("Puoi essere leggero e usare un po' di ironia quando appropriato")
        }

        // Lunghezza
        when (prefs.getString(Constants.Prefs.TONE_LENGTH, "brief")) {
            "brief" -> instructions.add("Dai risposte concise e mirate")
            "detailed" -> instructions.add("Fornisci risposte dettagliate e approfondite")
        }

        // Stile
        when (prefs.getString(Constants.Prefs.TONE_STYLE, "intimate")) {
            "intimate" -> instructions.add("Usa uno stile intimo e amichevole, come un amico fidato")
            "professional" -> instructions.add("Mantieni uno stile professionale e formale")
        }

        return "<communication_style>\n" + instructions.joinToString("\n") + "\n</communication_style>"
    }

    suspend fun fetchAvailableModels(context: Context, provider: AIProvider): List<String> {
        return try {
            val apiService = getChatApiService(context)
            val headers = getGatewayHeaders(context, provider)
            val response = apiService.listModels(headers, provider.name.lowercase())
            if (response.isSuccessful) {
                response.body()?.data?.map { it.id }?.filter { it.isNotBlank() } ?: emptyList()
            } else {
                android.util.Log.w("ApiClient", "listModels failed: code=${response.code()} message=${response.message()}")
                emptyList()
            }
        } catch (e: Exception) {
            android.util.Log.e("ApiClient", "listModels exception: ${e.message}", e)
            emptyList()
        }
    }
}
