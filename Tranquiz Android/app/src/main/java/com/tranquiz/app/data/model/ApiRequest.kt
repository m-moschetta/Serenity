package com.tranquiz.app.data.model

import com.google.gson.annotations.SerializedName

enum class AIProvider(val displayName: String, val baseUrl: String, val authHeader: String) {
    OPENAI("OpenAI", "https://api.openai.com/", "Authorization"),
    ANTHROPIC("Anthropic", "https://api.anthropic.com/", "x-api-key"),
    PERPLEXITY("Perplexity", "https://api.perplexity.ai/", "Authorization"),
    GROQ("Groq", "https://api.groq.com/", "Authorization")
}

data class ProviderConfig(
    val provider: AIProvider,
    val apiKey: String,
    val defaultModel: String
)

data class ChatRequest(
    @SerializedName("model")
    val model: String = "gpt-3.5-turbo",
    @SerializedName("messages")
    val messages: List<ChatMessage>,
    @SerializedName("max_tokens")
    val maxTokens: Int = 1000,
    @SerializedName("temperature")
    val temperature: Double = 0.7,
    @SerializedName("stream")
    val stream: Boolean = false,
    @SerializedName("provider")
    val provider: String? = null // OpenAI, Anthropic, Perplexity, Groq
)

data class ChatMessage(
    @SerializedName("role")
    val role: String, // "user", "assistant", "system"
    @SerializedName("content")
    val content: String
)

data class ChatResponse(
    @SerializedName("id")
    val id: String,
    @SerializedName("object")
    val objectType: String,
    @SerializedName("created")
    val created: Long,
    @SerializedName("model")
    val model: String,
    @SerializedName("choices")
    val choices: List<Choice>,
    @SerializedName("usage")
    val usage: Usage?
)

data class Choice(
    @SerializedName("index")
    val index: Int,
    @SerializedName("message")
    val message: ChatMessage,
    @SerializedName("finish_reason")
    val finishReason: String?
)

data class Usage(
    @SerializedName("prompt_tokens")
    val promptTokens: Int,
    @SerializedName("completion_tokens")
    val completionTokens: Int,
    @SerializedName("total_tokens")
    val totalTokens: Int
)

// OpenAI-compatible models listing
data class ModelsResponse(
    @SerializedName("data")
    val data: List<ModelItem>
)

data class ModelItem(
    @SerializedName("id")
    val id: String
)