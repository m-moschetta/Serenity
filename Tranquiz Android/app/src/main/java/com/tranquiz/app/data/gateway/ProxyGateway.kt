package com.tranquiz.app.data.gateway

import android.content.Context
import com.tranquiz.app.data.api.ApiClient
import com.tranquiz.app.data.model.AIProvider

/**
 * Replica dell'architettura ProxyGateway di Serenity (iOS) per Android.
 * Fornisce un builder di endpoint con baseURL del gateway e headers coerenti
 * (Authorization + x-provider), mantenendo la logica centralizzata.
 */
object ProxyGateway {

    data class Endpoint(
        val baseUrl: String,
        val headers: Map<String, String>
    )

    fun endpoint(context: Context, provider: AIProvider?): Endpoint {
        val baseUrl = ApiClient.getGatewayBaseUrl(context)
        val headers = ApiClient.getGatewayHeaders(context, provider)
        return Endpoint(baseUrl = baseUrl, headers = headers)
    }
}