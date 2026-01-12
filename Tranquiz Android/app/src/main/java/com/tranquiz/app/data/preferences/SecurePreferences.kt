package com.tranquiz.app.data.preferences

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * Gestisce le SharedPreferences crittografate per dati sensibili come API key.
 * Usa AES256-GCM per la crittografia dei valori e AES256-SIV per le chiavi.
 */
object SecurePreferences {

    private const val SECURE_PREFS_FILE = "secure_prefs"

    // Chiavi per i dati sensibili
    const val KEY_GATEWAY_API_KEY = "secure_gateway_api_key"

    @Volatile
    private var encryptedPrefs: SharedPreferences? = null

    /**
     * Ottiene le SharedPreferences crittografate.
     * Usa un singleton thread-safe per evitare creazioni multiple.
     */
    fun getEncryptedPrefs(context: Context): SharedPreferences {
        return encryptedPrefs ?: synchronized(this) {
            encryptedPrefs ?: createEncryptedPrefs(context).also {
                encryptedPrefs = it
            }
        }
    }

    private fun createEncryptedPrefs(context: Context): SharedPreferences {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        return EncryptedSharedPreferences.create(
            context,
            SECURE_PREFS_FILE,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    /**
     * Salva la API key in modo sicuro.
     */
    fun saveApiKey(context: Context, apiKey: String) {
        getEncryptedPrefs(context)
            .edit()
            .putString(KEY_GATEWAY_API_KEY, apiKey)
            .apply()
    }

    /**
     * Recupera la API key crittografata.
     * @param defaultValue valore di fallback se non presente
     */
    fun getApiKey(context: Context, defaultValue: String = ""): String {
        return getEncryptedPrefs(context)
            .getString(KEY_GATEWAY_API_KEY, defaultValue) ?: defaultValue
    }

    /**
     * Verifica se esiste una API key salvata.
     */
    fun hasApiKey(context: Context): Boolean {
        return getEncryptedPrefs(context).contains(KEY_GATEWAY_API_KEY)
    }

    /**
     * Rimuove la API key salvata.
     */
    fun clearApiKey(context: Context) {
        getEncryptedPrefs(context)
            .edit()
            .remove(KEY_GATEWAY_API_KEY)
            .apply()
    }
}
