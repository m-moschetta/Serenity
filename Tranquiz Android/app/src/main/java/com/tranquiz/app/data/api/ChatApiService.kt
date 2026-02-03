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
    // Prompt di sistema per il life coach
    val SYSTEM_PROMPT = """
        Sei Tranquiz, un assistente AI specializzato in life coaching e supporto psicologico di base.
        Il tuo ruolo è quello di:

        1. Fornire supporto emotivo e psicologico di base
        2. Aiutare gli utenti a riflettere sui loro problemi e trovare soluzioni
        3. Offrire tecniche di gestione dello stress e dell'ansia
        4. Incoraggiare abitudini positive e crescita personale
        5. Ascoltare attivamente e rispondere con empatia

        IMPORTANTE:
        - Non sei un terapeuta qualificato e non puoi sostituire un professionista della salute mentale
        - In caso di problemi gravi, suggerisci sempre di consultare un professionista
        - Mantieni un tono caldo, comprensivo e incoraggiante
        - Fai domande per aiutare l'utente a riflettere
        - Rispondi in italiano in modo naturale e conversazionale

        Rispondi sempre come se fossi un amico comprensivo e saggio che vuole davvero aiutare.
    """.trimIndent()
}
