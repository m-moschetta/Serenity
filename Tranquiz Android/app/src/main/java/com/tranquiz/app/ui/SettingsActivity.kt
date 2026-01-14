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

        initializeSystemPrompt()
        setupToolbar()
        setupDeveloperModeToggle()
        setupClickListeners()
        loadSettings()
    }
    
    private fun initializeSystemPrompt() {
        val currentPrompt = prefs.getString("pref_system_prompt", "") ?: ""
        if (currentPrompt.isBlank()) {
            // Prompt di sistema da iOS
            val defaultPrompt = """
Sei un chatbot progettato per supportare le persone attraverso un dialogo empatico, personalizzato e rispettoso, ispirato al modo in cui un terapeuta umano esperto si relaziona con i propri pazienti. Il tuo scopo è offrire uno spazio di sfogo sicuro, guidato e contenuto, che possa sostenere l'utente nella comprensione e gestione delle proprie emozioni, difficoltà quotidiane, dubbi esistenziali e blocchi interiori, nel rispetto dei limiti del tuo ruolo non terapeutico.

🎯 Obiettivo principale
Fornire ascolto attivo, supporto emotivo e spunti di riflessione attraverso un linguaggio personalizzato e umano. Le tue risposte devono sempre far sentire la persona:

- ascoltata profondamente,
- accolta senza giudizio,
- mai asseconda né banalizzata,
- rispettata nei tempi e nei modi della propria comunicazione.

Tu non sei un sostituto di un terapeuta. Non diagnostichi, non dai consigli clinici, non ti sostituisci a percorsi terapeutici reali. Sei un facilitatore, un diario emotivo intelligente, un alleato gentile nel percorso dell'utente.

🔐 Sicurezza e gestione delle emergenze
Se ricevi segnali anche minimi di ideazione suicidaria, autolesionismo, disturbi dell'umore gravi, disordini alimentari conclamati o altri segnali di emergenza psicologica:

- Blocca immediatamente la conversazione.
- Rispondi con tono empatico ma fermo:
"Capisco che in questo momento potresti sentirti sopraffatt* da emozioni molto intense. Non sei sol*, e chiedere aiuto è un atto di grande forza. È importante che tu parli con una persona reale in grado di aiutarti davvero. Ti invito subito a contattare uno di questi numeri:

📞 Dove chiedere aiuto
Se sei in una situazione di emergenza, chiama il numero 112.
Se tu o qualcuno che conosci ha dei pensieri suicidi, puoi chiamare:
- Telefono Amico: 02 2327 2327 (tutti i giorni dalle 10 alle 24)
- Samaritans: 06 77208977 (tutti i giorni dalle 13 alle 22)"

- Non offrire alternative, non indagare ulteriormente, non proseguire la conversazione.
- Mostra solo numeri ufficiali e fonti certificate.

🧠 Modalità di risposta
Ogni risposta deve essere profondamente personalizzata. Analizza attentamente tono, parole, stile comunicativo e stato emotivo dell'utente per costruire una risposta che rifletta la sua unicità.
Non usare formule generiche, istruzioni meccaniche o risposte standard. Mai sembrare "robotico".
Imita lo stile comunicativo del terapeuta umano: diretto ma delicato, empatico ma non compiacente, caldo ma centrato.

📌 Lunghezza e coinvolgimento
- Nella maggior parte dei casi rispondi in modo conciso (circa 2–5 frasi). Evita spiegazioni lunghe e liste estese.
- Procedi per piccoli passi: valida un punto centrale, poi fai una sola domanda aperta e leggera per invitare l'utente a continuare.
- Aumenta il livello di dettaglio solo se l'utente lo chiede esplicitamente o se serve per chiarezza/sicurezza.
- In caso di crisi, ignora queste regole e segui il protocollo di sicurezza sopra.

📚 Tecniche da utilizzare
Applica i seguenti principi psicologici nel rispondere:

- Ascolto riflessivo: parafrasa ciò che l'utente dice per dimostrargli che lo hai capito, senza distorcere il significato.
- Domande aperte (senza pressare): "Cosa senti in questo momento?", "Ti va di raccontarmi di più?".
- Normalizzazione (senza banalizzare): "Molte persone attraversano momenti come questo, e ogni emozione ha diritto di esistere."
- Validazione emotiva: "È comprensibile sentirsi così dopo quello che hai vissuto."
- Micro-suggerimenti: offri spunti gentili e non direttivi per aiutare l'utente ad avvicinarsi a nuove prospettive ("Hai mai notato se…?", "Cosa succede in te quando pensi a…?").
- Silenzio utile: se l'utente esprime qualcosa di molto profondo, puoi rispondere anche con frasi brevi e centrate. Non riempire sempre lo spazio.

🧭 Tono di voce
- Sempre calmo, accogliente, maturo, profondo.
- Usa un tono coerente con l'energia dell'utente: se è vulnerabile, sii morbido; se è ironico, puoi essere lievemente più leggero ma sempre centrato; se è agitato, aiutalo a rallentare.
- Evita frasi motivazionali vuote, cliché psicologici, o toni forzatamente positivi.

❌ Evita sempre:
- Diagnosi o etichette cliniche.
- Frasi impersonali ("Come assistente virtuale…", "Mi dispiace che ti senti così.").
- Offerte di soluzione immediate ("Devi solo pensare positivo", "Prova a fare yoga.").
- Minimizzazione del problema ("Capita a tutti", "Andrà tutto bene.").
- Tono paternalistico o troppo ottimista.
""".trimIndent()
            
            prefs.edit().putString("pref_system_prompt", defaultPrompt).apply()
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
                showModelDialog("pref_model_openai", AIProvider.OPENAI, R.string.pref_model_openai_title)
            }
        }
        findViewById<View>(R.id.setting_model_anthropic)?.setOnClickListener {
            if (prefs.getBoolean(Constants.Prefs.DEVELOPER_MODE, false)) {
                showModelDialog("pref_model_anthropic", AIProvider.ANTHROPIC, R.string.pref_model_anthropic_title)
            }
        }
        findViewById<View>(R.id.setting_model_perplexity)?.setOnClickListener {
            if (prefs.getBoolean(Constants.Prefs.DEVELOPER_MODE, false)) {
                showModelDialog("pref_model_perplexity", AIProvider.PERPLEXITY, R.string.pref_model_perplexity_title)
            }
        }
        findViewById<View>(R.id.setting_model_groq)?.setOnClickListener {
            if (prefs.getBoolean(Constants.Prefs.DEVELOPER_MODE, false)) {
                showModelDialog("pref_model_groq", AIProvider.GROQ, R.string.pref_model_groq_title)
            }
        }

        // Tono
        findViewById<View>(R.id.setting_tone_empathy)?.setOnClickListener {
            showToneDialog("pref_tone_empathy", R.array.tone_empathy_entries, R.array.tone_empathy_values)
        }
        findViewById<View>(R.id.setting_tone_approach)?.setOnClickListener {
            showToneDialog("pref_tone_approach", R.array.tone_approach_entries, R.array.tone_approach_values)
        }
        findViewById<View>(R.id.setting_tone_energy)?.setOnClickListener {
            showToneDialog("pref_tone_energy", R.array.tone_energy_entries, R.array.tone_energy_values)
        }
        findViewById<View>(R.id.setting_tone_mood)?.setOnClickListener {
            showToneDialog("pref_tone_mood", R.array.tone_mood_entries, R.array.tone_mood_values)
        }
        findViewById<View>(R.id.setting_tone_length)?.setOnClickListener {
            showToneDialog("pref_tone_length", R.array.tone_length_entries, R.array.tone_length_values)
        }
        findViewById<View>(R.id.setting_tone_style)?.setOnClickListener {
            showToneDialog("pref_tone_style", R.array.tone_style_entries, R.array.tone_style_values)
        }

        // Gateway
        binding.settingGatewayUrl.setOnClickListener {
            showTextInputDialog(
                getString(R.string.pref_gateway_base_url_title),
                prefs.getString("pref_gateway_base_url", getString(R.string.gateway_base_url)) ?: "",
                "pref_gateway_base_url"
            )
        }

        binding.settingGatewayKey.setOnClickListener {
            showTextInputDialog(
                getString(R.string.pref_gateway_api_key_title),
                prefs.getString("pref_gateway_api_key", "") ?: "",
                "pref_gateway_api_key",
                isPassword = true
            )
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
        val currentProvider = prefs.getString("pref_current_provider", "openai") ?: "openai"
        val currentIndex = values.indexOf(currentProvider).takeIf { it >= 0 } ?: 0
        
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.pref_current_provider_title)
            .setSingleChoiceItems(entries, currentIndex) { dialog, which ->
                prefs.edit().putString("pref_current_provider", values[which]).apply()
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
        val currentPrompt = prefs.getString("pref_system_prompt", "") ?: ""
        
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
                prefs.edit().putString("pref_system_prompt", newValue).apply()
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
        val providerValue = prefs.getString("pref_current_provider", "openai") ?: "openai"
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
                "pref_model_openai", R.string.pref_model_openai_title)
            loadModelSetting(findViewById<TextView>(R.id.tv_model_anthropic_title), 
                findViewById<TextView>(R.id.tv_model_anthropic_value),
                "pref_model_anthropic", R.string.pref_model_anthropic_title)
            loadModelSetting(findViewById<TextView>(R.id.tv_model_perplexity_title), 
                findViewById<TextView>(R.id.tv_model_perplexity_value),
                "pref_model_perplexity", R.string.pref_model_perplexity_title)
            loadModelSetting(findViewById<TextView>(R.id.tv_model_groq_title), 
                findViewById<TextView>(R.id.tv_model_groq_value),
                "pref_model_groq", R.string.pref_model_groq_title)
        }

        // Tono
        loadToneSetting(binding.tvToneEmpathyValue, "pref_tone_empathy", R.array.tone_empathy_entries, R.array.tone_empathy_values)
        loadToneSetting(binding.tvToneApproachValue, "pref_tone_approach", R.array.tone_approach_entries, R.array.tone_approach_values)
        loadToneSetting(binding.tvToneEnergyValue, "pref_tone_energy", R.array.tone_energy_entries, R.array.tone_energy_values)
        loadToneSetting(binding.tvToneMoodValue, "pref_tone_mood", R.array.tone_mood_entries, R.array.tone_mood_values)
        loadToneSetting(binding.tvToneLengthValue, "pref_tone_length", R.array.tone_length_entries, R.array.tone_length_values)
        loadToneSetting(binding.tvToneStyleValue, "pref_tone_style", R.array.tone_style_entries, R.array.tone_style_values)

        // Gateway
        val gatewayUrl = prefs.getString("pref_gateway_base_url", getString(R.string.gateway_base_url)) ?: getString(R.string.gateway_base_url)
        binding.tvGatewayUrlValue.text = if (gatewayUrl.length > 40) "${gatewayUrl.take(20)}...${gatewayUrl.takeLast(20)}" else gatewayUrl
        
        val gatewayKey = prefs.getString("pref_gateway_api_key", "") ?: ""
        binding.tvGatewayKeyValue.text = if (gatewayKey.isNotBlank()) maskSecret(gatewayKey) else "Non configurata"

        // System Prompt
        val prompt = prefs.getString("pref_system_prompt", "") ?: ""
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
}
