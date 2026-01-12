package com.tranquiz.app.data.model

import android.content.Context
import com.tranquiz.app.R

/**
 * Sealed class per gestire in modo tipizzato gli errori API.
 * Ogni tipo di errore può essere mappato a un messaggio user-friendly.
 */
sealed class ApiError {

    /**
     * Errore di rete (connessione, timeout, DNS).
     */
    data class NetworkError(val cause: Exception) : ApiError()

    /**
     * Errore HTTP generico con codice e messaggio.
     */
    data class HttpError(val code: Int, val message: String) : ApiError()

    /**
     * 401 - API key mancante o non valida.
     */
    data object Unauthorized : ApiError()

    /**
     * 403 - Accesso negato.
     */
    data object Forbidden : ApiError()

    /**
     * 404 - Endpoint non trovato.
     */
    data object NotFound : ApiError()

    /**
     * 429 - Rate limit superato.
     */
    data object RateLimited : ApiError()

    /**
     * 500+ - Errore server.
     */
    data class ServerError(val code: Int) : ApiError()

    /**
     * Conversazione bloccata dal safety classifier.
     */
    data object ConversationBlocked : ApiError()

    /**
     * Risposta vuota o malformata dal server.
     */
    data object EmptyResponse : ApiError()

    /**
     * Errore sconosciuto.
     */
    data class Unknown(val message: String) : ApiError()

    companion object {
        /**
         * Crea un ApiError dal codice HTTP.
         */
        fun fromHttpCode(code: Int, message: String = ""): ApiError {
            return when (code) {
                401 -> Unauthorized
                403 -> Forbidden
                404 -> NotFound
                429 -> RateLimited
                in 500..599 -> ServerError(code)
                else -> HttpError(code, message)
            }
        }

        /**
         * Crea un ApiError da un'eccezione.
         */
        fun fromException(e: Exception): ApiError {
            return when (e) {
                is java.net.UnknownHostException,
                is java.net.SocketTimeoutException,
                is java.net.ConnectException -> NetworkError(e)
                else -> Unknown(e.message ?: "Errore sconosciuto")
            }
        }
    }

    /**
     * Ottiene il messaggio user-friendly per l'errore.
     * In release, i messaggi sono generici per non esporre dettagli interni.
     */
    fun getUserMessage(context: Context): String {
        return when (this) {
            is NetworkError -> context.getString(R.string.error_network)
            is Unauthorized -> context.getString(R.string.error_unauthorized)
            is Forbidden -> context.getString(R.string.error_forbidden)
            is NotFound -> context.getString(R.string.error_not_found)
            is RateLimited -> context.getString(R.string.error_rate_limited)
            is ServerError -> context.getString(R.string.error_server)
            is ConversationBlocked -> context.getString(R.string.safety_message)
            is EmptyResponse -> context.getString(R.string.error_empty_response)
            is HttpError -> context.getString(R.string.error_generic)
            is Unknown -> context.getString(R.string.error_generic)
        }
    }

    /**
     * Ottiene il messaggio di debug dettagliato (solo per logging).
     */
    fun getDebugMessage(): String {
        return when (this) {
            is NetworkError -> "NetworkError: ${cause.message}"
            is Unauthorized -> "Unauthorized (401)"
            is Forbidden -> "Forbidden (403)"
            is NotFound -> "NotFound (404)"
            is RateLimited -> "RateLimited (429)"
            is ServerError -> "ServerError ($code)"
            is ConversationBlocked -> "ConversationBlocked by safety classifier"
            is EmptyResponse -> "EmptyResponse from server"
            is HttpError -> "HttpError ($code): $message"
            is Unknown -> "Unknown: $message"
        }
    }
}
