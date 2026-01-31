package com.tranquiz.app.ui

import android.content.SharedPreferences
import android.os.Bundle
import android.text.InputType
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.preference.PreferenceManager
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import com.tranquiz.app.R
import com.tranquiz.app.data.api.ApiClient
import com.tranquiz.app.data.catalog.ModelCatalog
import com.tranquiz.app.data.model.AIProvider
import com.tranquiz.app.data.preferences.SecurePreferences
import com.tranquiz.app.databinding.ActivitySettingsBinding
import com.tranquiz.app.util.Constants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class SettingsActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySettingsBinding
    private lateinit var prefs: SharedPreferences
    private var developerModeTaps = 0
    private var lastTapTime = 0L

    companion object {
        private const val DEVELOPER_TAPS_REQUIRED = 5
        private const val TAP_TIMEOUT_MS = 2000L // 2 secondi tra i tocchi
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySettingsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        prefs = PreferenceManager.getDefaultSharedPreferences(this)
        migrateGatewayApiKeyToSecureIfNeeded()

        initializeSystemPrompt()
        setupToolbar()
        setupDeveloperModeToggle()
        setupClickListeners()
        loadSettings()
    }
    
    private fun initializeSystemPrompt() {
        val currentPrompt = prefs.getString(Constants.Prefs.SYSTEM_PROMPT, "") ?: ""
        if (currentPrompt.isBlank()) {
            // Prompt di sistema da iOS
            val defaultPrompt = """
<role>
Sei Tranquiz, un coach e supporto psicologico per le persone che parlano italiano. Sei empatico, rispettoso e professionale come un esperto umano.
<\role>

<objective>
- Offri uno spazio di sfogo sicuro, guidato e contenuto
- Sostieni l’utente nella comprensione e gestione di
    - Emozioni
    - Difficoltà
    - Blocchi interiori
    - Dubbi esistenziali
- Fornisci
    - Ascolto attivo
    - Spunti di riflessione
    - Supporto emotivo
- Le tue risposte devono sempre far sentire la persona:
    - Ascoltata profondamente,
    - Accolta senza giudizio,
    - Mai assecondata né banalizzata,
    - Rispettata nei tempi e nei modi della propria comunicazione.
<\objective>

<instructions>
1. Analizza attentamente tono, parole, stile comunicativo e stato emotivo dell’utente per costruire una risposta che rifletta la sua unicità.
2. Usa le conversazioni precedenti con l’utente nelle risposte per
    a. Considerare il contesto personale
    b. Usare riferimenti al passato
    c. Rilevare cambiamenti
    d. Tenere traccia degli stati d’animo
    e. Rispondere a bisogni impliciti
    f. Evitare ripetizioni
3. Usa un tono coerente con l’energia dell’utente
4. Presenta la risposta finale nel formato richiesto
<\instructions>

<constraints>
- Verbosità: bassa
- Evita
    - Formule generiche
    - Istruzioni meccaniche
    - Risposte standard
    - Frasi motivazionali vuote
    - Diagnosi o etichette cliniche
    - Frasi impersonali
    - Minimizzazione del problema
    - Tono paternalistico
    - Tono troppo ottimista
<\constraints>

<output_format>
*Esempio di Risposta Efficace*

Utente: Ultimamente mi sento sopraffatto dal lavoro e dalle responsabilità, non riesco a concentrarmi e ho paura che questo possa influire negativamente sulla mia carriera. Come posso gestire meglio la situazione?

Tranquiz: Capisco, può essere difficile quando ci si sente sopraffatti. Un buon punto di partenza è identificare le cause dello stress. Quali sono gli aspetti più urgenti o problematici del tuo lavoro? Da lì, possiamo pensare a tecniche per alleggerire la pressione e migliorare la concentrazione.

<\output_format>
""".trimIndent()
            
            prefs.edit().putString(Constants.Prefs.SYSTEM_PROMPT, defaultPrompt).apply()
        }
    }
    
    private fun setupDeveloperModeToggle() {
        binding.toolbar.setOnClickListener {
            val currentTime = System.currentTimeMillis()
            
            if (currentTime - lastTapTime > TAP_TIMEOUT_MS) {
                developerModeTaps = 0
            }
            
            developerModeTaps++
            lastTapTime = currentTime
            
            if (developerModeTaps >= DEVELOPER_TAPS_REQUIRED) {
                val isDeveloperMode = !prefs.getBoolean(Constants.Prefs.DEVELOPER_MODE, false)
                prefs.edit().putBoolean(Constants.Prefs.DEVELOPER_MODE, isDeveloperMode).apply()
                developerModeTaps = 0
                
                val message = if (isDeveloperMode) "Modalità Developer attivata" else "Modalità Developer disattivata"
                Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
                
                loadSettings() // Ricarica per mostrare/nascondere sezione modelli
            }
        }
    }

    private fun setupToolbar() {
        binding.toolbar.setNavigationOnClickListener {
            finish()
        }
    }

    private fun setupClickListeners() {
        // Provider corrente
        binding.settingProvider.setOnClickListener {
            showProviderDialog()
        }

        // Modelli - solo in modalità developer (gestito in loadSettings)
        findViewById<View>(R.id.setting_model_openai)?.setOnClickListener {
            if (prefs.getBoolean(Constants.Prefs.DEVELOPER_MODE, false)) {
                showModelDialog(Constants.Prefs.MODEL_OPENAI, AIProvider.OPENAI, R.string.pref_model_openai_title)
            }
        }
        findViewById<View>(R.id.setting_model_anthropic)?.setOnClickListener {
            if (prefs.getBoolean(Constants.Prefs.DEVELOPER_MODE, false)) {
                showModelDialog(Constants.Prefs.MODEL_ANTHROPIC, AIProvider.ANTHROPIC, R.string.pref_model_anthropic_title)
            }
        }
        findViewById<View>(R.id.setting_model_perplexity)?.setOnClickListener {
            if (prefs.getBoolean(Constants.Prefs.DEVELOPER_MODE, false)) {
                showModelDialog(Constants.Prefs.MODEL_PERPLEXITY, AIProvider.PERPLEXITY, R.string.pref_model_perplexity_title)
            }
        }
        findViewById<View>(R.id.setting_model_groq)?.setOnClickListener {
            if (prefs.getBoolean(Constants.Prefs.DEVELOPER_MODE, false)) {
                showModelDialog(Constants.Prefs.MODEL_GROQ, AIProvider.GROQ, R.string.pref_model_groq_title)
            }
        }

        // Tono
        findViewById<View>(R.id.setting_tone_empathy)?.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_EMPATHY, R.array.tone_empathy_entries, R.array.tone_empathy_values)
        }
        findViewById<View>(R.id.setting_tone_approach)?.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_APPROACH, R.array.tone_approach_entries, R.array.tone_approach_values)
        }
        findViewById<View>(R.id.setting_tone_energy)?.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_ENERGY, R.array.tone_energy_entries, R.array.tone_energy_values)
        }
        findViewById<View>(R.id.setting_tone_mood)?.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_MOOD, R.array.tone_mood_entries, R.array.tone_mood_values)
        }
        findViewById<View>(R.id.setting_tone_length)?.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_LENGTH, R.array.tone_length_entries, R.array.tone_length_values)
        }
        findViewById<View>(R.id.setting_tone_style)?.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_STYLE, R.array.tone_style_entries, R.array.tone_style_values)
        }

        // Gateway
        binding.settingGatewayUrl.setOnClickListener {
            showTextInputDialog(
                getString(R.string.pref_gateway_base_url_title),
                prefs.getString(Constants.Prefs.GATEWAY_BASE_URL, getString(R.string.gateway_base_url)) ?: "",
                Constants.Prefs.GATEWAY_BASE_URL
            )
        }

        binding.settingGatewayKey.setOnClickListener {
            showGatewayKeyDialog()
        }

        binding.settingGatewayTest.setOnClickListener {
            testGateway()
        }

        // System Prompt
        binding.settingSystemPrompt.setOnClickListener {
            showSystemPromptDialog()
        }

        // Reset Onboarding
        binding.settingResetOnboarding.setOnClickListener {
            showResetOnboardingDialog()
        }
    }

    private fun showModelDialog(prefKey: String, provider: AIProvider, titleRes: Int) {
        lifecycleScope.launch {
            val models = withContext(Dispatchers.IO) {
                ModelCatalog.getModels(this@SettingsActivity, provider)
            }
            
            if (models.isEmpty()) {
                Toast.makeText(this@SettingsActivity, "Nessun modello disponibile", Toast.LENGTH_SHORT).show()
                return@launch
            }
            
            val currentValue = prefs.getString(prefKey, "") ?: ""
            val currentIndex = models.indexOf(currentValue).takeIf { it >= 0 } ?: 0
            
            MaterialAlertDialogBuilder(this@SettingsActivity)
                .setTitle(getString(titleRes))
                .setSingleChoiceItems(models.toTypedArray(), currentIndex) { dialog, which ->
                    prefs.edit().putString(prefKey, models[which]).apply()
                    loadSettings()
                    dialog.dismiss()
                    Toast.makeText(this@SettingsActivity, "Salvato: ${models[which]}", Toast.LENGTH_SHORT).show()
                }
                .setNegativeButton(R.string.cancel, null)
                .show()
        }
    }

    private fun showToneDialog(prefKey: String, entriesRes: Int, valuesRes: Int) {
        val entries = resources.getStringArray(entriesRes)
        val values = resources.getStringArray(valuesRes)
        val currentValue = prefs.getString(prefKey, values.firstOrNull() ?: "")
        val currentIndex = values.indexOf(currentValue).takeIf { it >= 0 } ?: 0
        
        MaterialAlertDialogBuilder(this)
            .setSingleChoiceItems(entries, currentIndex) { dialog, which ->
                prefs.edit().putString(prefKey, values[which]).apply()
                loadSettings()
                dialog.dismiss()
                Toast.makeText(this, "Salvato: ${entries[which]}", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showProviderDialog() {
        val entries = resources.getStringArray(R.array.provider_entries)
        val values = resources.getStringArray(R.array.provider_values)
        val currentProvider = prefs.getString(Constants.Prefs.CURRENT_PROVIDER, "openai") ?: "openai"
        val currentIndex = values.indexOf(currentProvider).takeIf { it >= 0 } ?: 0
        
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.pref_current_provider_title)
            .setSingleChoiceItems(entries, currentIndex) { dialog, which ->
                prefs.edit().putString(Constants.Prefs.CURRENT_PROVIDER, values[which]).apply()
                loadSettings()
                dialog.dismiss()
                Toast.makeText(this, "Salvato: ${entries[which]}", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showTextInputDialog(title: String, currentValue: String, prefKey: String, isPassword: Boolean = false) {
        val inputLayout = TextInputLayout(this).apply {
            hint = title
            boxBackgroundMode = 1 // BOX_BACKGROUND_OUTLINED
        }
        
        val input = TextInputEditText(inputLayout.context).apply {
            setText(currentValue)
            inputType = if (isPassword) InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
                       else InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_URI
        }
        
        inputLayout.addView(input)
        
        MaterialAlertDialogBuilder(this)
            .setTitle(title)
            .setView(inputLayout)
            .setPositiveButton(R.string.settings_save) { _, _ ->
                val newValue = input.text?.toString() ?: ""
                prefs.edit().putString(prefKey, newValue).apply()
                loadSettings()
                Toast.makeText(this, "Salvato: $title", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showSystemPromptDialog() {
        val currentPrompt = prefs.getString(Constants.Prefs.SYSTEM_PROMPT, "") ?: ""
        
        val inputLayout = TextInputLayout(this).apply {
            hint = getString(R.string.pref_system_prompt_title)
            boxBackgroundMode = 1 // BOX_BACKGROUND_OUTLINED
        }
        
        val input = TextInputEditText(inputLayout.context).apply {
            setText(currentPrompt)
            setSingleLine(false)
            minLines = 6
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE
        }
        
        inputLayout.addView(input)
        
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.pref_system_prompt_title)
            .setView(inputLayout)
            .setPositiveButton(R.string.settings_save) { _, _ ->
                val newValue = input.text?.toString() ?: ""
                prefs.edit().putString(Constants.Prefs.SYSTEM_PROMPT, newValue).apply()
                loadSettings()
                Toast.makeText(this, "Salvato: ${getString(R.string.pref_system_prompt_title)}", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showResetOnboardingDialog() {
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.pref_reset_onboarding_title)
            .setMessage("Vuoi ripristinare l'onboarding? Dovrai completarlo di nuovo al prossimo avvio.")
            .setPositiveButton(R.string.yes) { _, _ ->
                prefs.edit().putBoolean(Constants.Prefs.ONBOARDING_COMPLETED, false).apply()
                Toast.makeText(this, "Onboarding ripristinato", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(R.string.no, null)
            .show()
    }

    private fun testGateway() {
        lifecycleScope.launch {
            val provider = ApiClient.getCurrentProvider(this@SettingsActivity)
            val service = ApiClient.getChatApiService(this@SettingsActivity)
            val headers = ApiClient.getGatewayHeaders(this@SettingsActivity, provider)
            
            try {
                val response = withContext(Dispatchers.IO) {
                    service.listModels(headers, provider.name.lowercase())
                }
                
                if (response.isSuccessful) {
                    val count = response.body()?.data?.size ?: 0
                    Toast.makeText(this@SettingsActivity, "Gateway OK (${response.code()}): modelli=$count", Toast.LENGTH_SHORT).show()
                } else {
                    val details = try { response.errorBody()?.string() } catch (_: Exception) { null }
                    Toast.makeText(this@SettingsActivity, "Gateway errore ${response.code()}: ${response.message()}" + 
                        (if (details.isNullOrBlank()) "" else "\n$details"), Toast.LENGTH_LONG).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@SettingsActivity, "Gateway eccezione: ${e.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun loadSettings() {
        // Provider
        val providerValue = prefs.getString(Constants.Prefs.CURRENT_PROVIDER, "openai") ?: "openai"
        val providerEntries = resources.getStringArray(R.array.provider_entries)
        val providerValues = resources.getStringArray(R.array.provider_values)
        val providerIndex = providerValues.indexOf(providerValue).takeIf { it >= 0 } ?: 0
        binding.tvProviderValue.text = providerEntries.getOrNull(providerIndex) ?: providerValue

        // Modelli - solo in modalità developer
        val isDeveloperMode = prefs.getBoolean(Constants.Prefs.DEVELOPER_MODE, false)
        findViewById<View>(R.id.section_models)?.visibility = if (isDeveloperMode) View.VISIBLE else View.GONE
        
        if (isDeveloperMode) {
            loadModelSetting(findViewById<TextView>(R.id.tv_model_openai_title), 
                findViewById<TextView>(R.id.tv_model_openai_value), 
                Constants.Prefs.MODEL_OPENAI, R.string.pref_model_openai_title)
            loadModelSetting(findViewById<TextView>(R.id.tv_model_anthropic_title), 
                findViewById<TextView>(R.id.tv_model_anthropic_value),
                Constants.Prefs.MODEL_ANTHROPIC, R.string.pref_model_anthropic_title)
            loadModelSetting(findViewById<TextView>(R.id.tv_model_perplexity_title), 
                findViewById<TextView>(R.id.tv_model_perplexity_value),
                Constants.Prefs.MODEL_PERPLEXITY, R.string.pref_model_perplexity_title)
            loadModelSetting(findViewById<TextView>(R.id.tv_model_groq_title), 
                findViewById<TextView>(R.id.tv_model_groq_value),
                Constants.Prefs.MODEL_GROQ, R.string.pref_model_groq_title)
        }

        // Tono
        loadToneSetting(binding.tvToneEmpathyValue, Constants.Prefs.TONE_EMPATHY, R.array.tone_empathy_entries, R.array.tone_empathy_values)
        loadToneSetting(binding.tvToneApproachValue, Constants.Prefs.TONE_APPROACH, R.array.tone_approach_entries, R.array.tone_approach_values)
        loadToneSetting(binding.tvToneEnergyValue, Constants.Prefs.TONE_ENERGY, R.array.tone_energy_entries, R.array.tone_energy_values)
        loadToneSetting(binding.tvToneMoodValue, Constants.Prefs.TONE_MOOD, R.array.tone_mood_entries, R.array.tone_mood_values)
        loadToneSetting(binding.tvToneLengthValue, Constants.Prefs.TONE_LENGTH, R.array.tone_length_entries, R.array.tone_length_values)
        loadToneSetting(binding.tvToneStyleValue, Constants.Prefs.TONE_STYLE, R.array.tone_style_entries, R.array.tone_style_values)

        // Gateway
        val gatewayUrl = prefs.getString(Constants.Prefs.GATEWAY_BASE_URL, getString(R.string.gateway_base_url)) ?: getString(R.string.gateway_base_url)
        binding.tvGatewayUrlValue.text = if (gatewayUrl.length > 40) "${gatewayUrl.take(20)}...${gatewayUrl.takeLast(20)}" else gatewayUrl
        
        val gatewayKey = SecurePreferences.getApiKey(this, "")
        binding.tvGatewayKeyValue.text = if (gatewayKey.isNotBlank()) maskSecret(gatewayKey) else "Non configurata"

        // System Prompt
        val prompt = prefs.getString(Constants.Prefs.SYSTEM_PROMPT, "") ?: ""
        binding.tvSystemPromptValue.text = if (prompt.isNotBlank()) promptPreview(prompt) else getString(R.string.pref_system_prompt_summary)

        // Versione
        binding.tvVersionValue.text = getString(R.string.about_version)
    }

    private fun loadModelSetting(titleView: TextView, valueView: TextView, prefKey: String, titleRes: Int) {
        titleView.text = getString(titleRes)
        val model = prefs.getString(prefKey, "") ?: ""
        valueView.text = model.ifEmpty { "Non selezionato" }
    }

    private fun loadToneSetting(view: TextView, prefKey: String, entriesRes: Int, valuesRes: Int) {
        val entries = resources.getStringArray(entriesRes)
        val values = resources.getStringArray(valuesRes)
        val currentValue = prefs.getString(prefKey, values.firstOrNull() ?: "")
        val index = values.indexOf(currentValue).takeIf { it >= 0 } ?: 0
        view.text = entries.getOrNull(index) ?: currentValue
    }

    private fun maskSecret(secret: String): String {
        val visible = secret.take(4)
        val maskedLen = if (secret.length > 4) secret.length - 4 else 0
        return if (maskedLen > 0) visible + ("*".repeat(maskedLen)) else "****"
    }

    private fun promptPreview(prompt: String): String {
        val singleLine = prompt.replace("\n", " ").trim()
        val max = 60
        return if (singleLine.length <= max) singleLine else singleLine.take(max).trimEnd() + "…"
    }

    private fun showGatewayKeyDialog() {
        val title = getString(R.string.pref_gateway_api_key_title)
        val currentValue = SecurePreferences.getApiKey(this, "")

        val inputLayout = TextInputLayout(this).apply {
            hint = title
            boxBackgroundMode = 1
        }

        val input = TextInputEditText(inputLayout.context).apply {
            setText(currentValue)
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        }

        inputLayout.addView(input)

        MaterialAlertDialogBuilder(this)
            .setTitle(title)
            .setView(inputLayout)
            .setPositiveButton(R.string.settings_save) { _, _ ->
                val newValue = input.text?.toString()?.trim().orEmpty()
                if (newValue.isBlank()) {
                    SecurePreferences.clearApiKey(this)
                } else {
                    SecurePreferences.saveApiKey(this, newValue)
                }
                loadSettings()
                Toast.makeText(this, "Salvato: $title", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun migrateGatewayApiKeyToSecureIfNeeded() {
        val legacy = prefs.getString(Constants.Prefs.GATEWAY_API_KEY, null)?.trim().orEmpty()
        if (legacy.isNotBlank() && !SecurePreferences.hasApiKey(this)) {
            SecurePreferences.saveApiKey(this, legacy)
        }
        if (legacy.isNotBlank()) {
            prefs.edit().remove(Constants.Prefs.GATEWAY_API_KEY).apply()
        }
    }
}
