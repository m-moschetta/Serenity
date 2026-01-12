package com.tranquiz.app.data.api

import com.tranquiz.app.data.model.ChatRequest
import com.tranquiz.app.data.model.ChatResponse
import com.tranquiz.app.data.model.ModelsResponse
import com.tranquiz.app.data.therapeutic.TherapeuticPrompt
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.HeaderMap
import retrofit2.http.Headers
import retrofit2.http.POST
import retrofit2.http.Streaming

interface ChatApiService {

    // Endpoint OpenAI-compatibile del gateway/worker
    @POST("v1/chat/completions")
    @Headers("Content-Type: application/json")
    suspend fun sendMessage(
        @HeaderMap headers: Map<String, String>,
        @Body request: ChatRequest
    ): Response<ChatResponse>

    @POST("v1/chat/completions")
    @Streaming
    @Headers("Content-Type: application/json", "Accept: text/event-stream", "Cache-Control: no-cache")
    suspend fun sendMessageStream(
        @HeaderMap headers: Map<String, String>,
        @Body request: ChatRequest
    ): Response<ResponseBody>

    @GET("v1/models")
    suspend fun listModels(
        @HeaderMap headers: Map<String, String>,
        @retrofit2.http.Query("provider") provider: String?
    ): Response<ModelsResponse>
}

object ApiConstants {
    // Prompt di sistema principale allineato con iOS
    val SYSTEM_PROMPT = TherapeuticPrompt.systemPrompt
}
