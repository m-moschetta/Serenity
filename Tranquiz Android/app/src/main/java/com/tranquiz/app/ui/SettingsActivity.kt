package com.tranquiz.app.ui

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.preference.ListPreference
import androidx.preference.EditTextPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import androidx.lifecycle.lifecycleScope
import com.tranquiz.app.data.api.ApiClient
import com.tranquiz.app.data.model.AIProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import com.tranquiz.app.R
import android.widget.Toast
import android.text.InputType

class SettingsActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.settings_activity)

        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        title = getString(R.string.menu_settings)

        if (savedInstanceState == null) {
            supportFragmentManager
                .beginTransaction()
                .replace(R.id.settings_container, SettingsFragment())
                .commit()
        }
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }
}

class SettingsFragment : PreferenceFragmentCompat() {
    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.preferences, rootKey)
        setupPreferenceFeedback()
        refreshModelSelectors()
    }

    private fun setupPreferenceFeedback() {
        val providerPref = findPreference<ListPreference>("pref_current_provider")
        providerPref?.let { pref ->
            pref.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { p, newValue ->
                val lp = p as ListPreference
                // Mostra conferma; il riepilogo è gestito da useSimpleSummaryProvider
                val newVal = newValue as String
                val newLabel = lp.entries?.get(lp.findIndexOfValue(newVal)) ?: newVal
                Toast.makeText(requireContext(), "Salvato: ${lp.title} = ${newLabel}", Toast.LENGTH_SHORT).show()
                true
            }
        }

        listOf(
            "pref_model_openai",
            "pref_model_anthropic",
            "pref_model_perplexity",
            "pref_model_groq"
        ).forEach { key ->
            val modelPref = findPreference<ListPreference>(key)
            modelPref?.let { pref ->
                pref.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { p, newValue ->
                    val lp = p as ListPreference
                    val newVal = newValue as String
                    val newLabel = lp.entries?.get(lp.findIndexOfValue(newVal)) ?: newVal
                    Toast.makeText(requireContext(), "Salvato: ${lp.title} = ${newLabel}", Toast.LENGTH_SHORT).show()
                    true
                }
            }
        }

        // Gateway: API Key (riepilogo mascherato) e Base URL (summary provider semplice)
        val apiKeyPref = findPreference<EditTextPreference>("pref_gateway_api_key")
        apiKeyPref?.let { pref ->
            val current = pref.text ?: ""
            pref.summary = if (current.isNotBlank()) maskSecret(current) else getString(R.string.pref_gateway_api_key_summary)
            pref.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { p, newValue ->
                val text = (newValue as? String) ?: ""
                p.summary = if (text.isNotBlank()) maskSecret(text) else getString(R.string.pref_gateway_api_key_summary)
                Toast.makeText(requireContext(), "Salvato: ${p.title}", Toast.LENGTH_SHORT).show()
                true
            }
        }

        val promptPref = findPreference<EditTextPreference>("pref_system_prompt")
        promptPref?.let { pref ->
            val current = pref.text ?: ""
            pref.summary = if (current.isNotBlank()) promptPreview(current) else getString(R.string.pref_system_prompt_summary)
            pref.setOnBindEditTextListener { editText ->
                editText.setSingleLine(false)
                editText.minLines = 6
                editText.inputType = InputType.TYPE_CLASS_TEXT or
                    InputType.TYPE_TEXT_FLAG_MULTI_LINE or
                    InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
            }
            pref.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { p, newValue ->
                val text = (newValue as? String) ?: ""
                p.summary = if (text.isNotBlank()) promptPreview(text) else getString(R.string.pref_system_prompt_summary)
                Toast.makeText(requireContext(), "Salvato: ${p.title}", Toast.LENGTH_SHORT).show()
                true
            }
        }

        val testPref = findPreference<Preference>("pref_gateway_test")
        testPref?.onPreferenceClickListener = Preference.OnPreferenceClickListener {
            lifecycleScope.launch {
                val provider = ApiClient.getCurrentProvider(requireContext())
                val service = ApiClient.getChatApiService(requireContext())
                val headers = ApiClient.getGatewayHeaders(requireContext(), provider)
                try {
                    val response = withContext(Dispatchers.IO) {
                        service.listModels(headers, provider.name.lowercase())
                    }
                    if (response.isSuccessful) {
                        val count = response.body()?.data?.size ?: 0
                        Toast.makeText(requireContext(), "Gateway OK (${response.code()}): modelli=$count", Toast.LENGTH_SHORT).show()
                    } else {
                        val details = try { response.errorBody()?.string() } catch (_: Exception) { null }
                        Toast.makeText(requireContext(), "Gateway errore ${response.code()}: ${response.message()}" + (if (details.isNullOrBlank()) "" else "\n$details"), Toast.LENGTH_LONG).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(requireContext(), "Gateway eccezione: ${e.message}", Toast.LENGTH_LONG).show()
                }
            }
            true
        }
    }

    private fun maskSecret(secret: String): String {
        val visible = secret.take(4)
        val maskedLen = if (secret.length > 4) secret.length - 4 else 0
        return if (maskedLen > 0) visible + ("*".repeat(maskedLen)) else "****"
    }

    private fun promptPreview(prompt: String): String {
        val singleLine = prompt.replace("\n", " ").trim()
        val max = 80
        return if (singleLine.length <= max) singleLine else singleLine.take(max).trimEnd() + "…"
    }

    private fun refreshModelSelectors() {
        // Usa il lifecycleScope del Fragment per evitare accessi al viewLifecycleOwner prima della creazione della view
        lifecycleScope.launch {
            val providers = listOf(
                AIProvider.OPENAI to "pref_model_openai",
                AIProvider.ANTHROPIC to "pref_model_anthropic",
                AIProvider.PERPLEXITY to "pref_model_perplexity",
                AIProvider.GROQ to "pref_model_groq"
            )

            providers.forEach { (provider, key) ->
                val models = withContext(Dispatchers.IO) {
                    com.tranquiz.app.data.catalog.ModelCatalog.getModels(requireContext(), provider)
                }

                try {
                    val pref = findPreference<ListPreference>(key)
                    val entries = if (models.isNotEmpty()) models.toTypedArray() else null
                    entries?.let {
                        // Aggiorna lista
                        pref?.entries = it
                        pref?.entryValues = it

                        // Mantieni il valore salvato se ancora valido; altrimenti imposta il primo disponibile
                        val currentValue = pref?.value
                        val newValues = it.toList()
                        val selected = when {
                            currentValue != null && newValues.contains(currentValue) -> currentValue
                            newValues.isNotEmpty() -> newValues.first()
                            else -> null
                        }
                        selected?.let { sel -> pref?.value = sel }
                    }
                } catch (e: Exception) {
                    android.util.Log.e("SettingsFragment", "Errore aggiornando ListPreference $key: ${e.message}", e)
                }
            }
        }
    }

}
