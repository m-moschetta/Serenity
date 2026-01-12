package com.tranquiz.app.data.catalog

import android.content.Context
import com.tranquiz.app.data.api.ApiClient
import com.tranquiz.app.data.model.AIProvider

/**
 * Catalogo modelli in stile Serenity (iOS):
 * - tenta il fetch dinamico dal gateway (/v1/models)
 * - fallback a liste predefinite per provider
 * - cache in memoria per ridurre chiamate
 */
object ModelCatalog {

    private val cache: MutableMap<AIProvider, List<String>> = mutableMapOf()

    suspend fun getModels(context: Context, provider: AIProvider): List<String> {
        // Cache
        cache[provider]?.let { return it }

        // Prova fetch dinamico
        val dynamic = ApiClient.fetchAvailableModels(context, provider)
        val models = if (dynamic.isNotEmpty()) dynamic else defaultModels(provider)
        cache[provider] = models
        return models
    }

    fun defaultModels(provider: AIProvider): List<String> {
        return when (provider) {
            AIProvider.OPENAI -> listOf(
                "gpt-5.2",
                "gpt-5-mini",
                "gpt-5",
                "gpt-4.1-mini",
                "gpt-4o-mini",
                "o4-mini",
                "gpt-4o",
                "gpt-4.1"
            )
            AIProvider.GROQ -> listOf(
                "llama3-8b-8192",
                "llama3-70b-8192",
                "mixtral-8x7b-32768",
                "gemma2-9b-it",
                "gemma-7b-it",
                "openai/gpt-oss-120b",
                "openai/gpt-oss-20b"
            )
            AIProvider.ANTHROPIC -> listOf(
                "claude-3-5-sonnet-20241022",
                "claude-3-5-haiku-20241022",
                "claude-3-opus-latest"
            )
            AIProvider.PERPLEXITY -> listOf(
                "llama-3.1-sonar-large-128k-online",
                "llama-3.1-sonar-small-128k-online",
                "sonar-reasoning-latest"
            )
        }
    }
}