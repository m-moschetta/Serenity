package com.tranquiz.app.ui

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.widget.addTextChangedListener
import androidx.preference.PreferenceManager
import androidx.recyclerview.widget.LinearLayoutManager
import com.tranquiz.app.R
import com.tranquiz.app.data.api.ApiClient
import com.tranquiz.app.databinding.ActivityMainBinding
import com.tranquiz.app.ui.adapter.MessageAdapter
import com.tranquiz.app.ui.onboarding.OnboardingFragment
import com.tranquiz.app.ui.viewmodel.ChatViewModel
import com.tranquiz.app.util.Constants

/**
 * Activity principale per la chat.
 * Gestisce la visualizzazione dei messaggi e l'interazione con l'AI.
 * L'onboarding è delegato a OnboardingFragment.
 */
class MainActivity : AppCompatActivity(), OnboardingFragment.OnboardingCallback {

    private lateinit var binding: ActivityMainBinding
    private lateinit var messageAdapter: MessageAdapter
    private val viewModel: ChatViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupToolbar()
        setupRecyclerView()
        setupMessageInput()
        observeViewModel()

        checkOnboarding()
    }

    override fun onResume() {
        super.onResume()
        viewModel.setProvider(ApiClient.getCurrentProvider(this))
    }

    // ==================== Onboarding ====================

    private fun checkOnboarding() {
        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        val onboardingCompleted = prefs.getBoolean(Constants.Prefs.ONBOARDING_COMPLETED, false)

        if (onboardingCompleted) {
            showChatInterface()
        } else {
            showOnboarding()
        }
    }

    private fun showOnboarding() {
        // Nascondi interfaccia chat
        binding.toolbar.visibility = View.GONE
        binding.rvMessages.visibility = View.GONE
        binding.layoutMessageInput.visibility = View.GONE
        binding.fragmentContainerOnboarding.visibility = View.VISIBLE

        // Aggiungi fragment se non esiste già
        if (supportFragmentManager.findFragmentById(R.id.fragment_container_onboarding) == null) {
            supportFragmentManager.beginTransaction()
                .replace(R.id.fragment_container_onboarding, OnboardingFragment.newInstance())
                .commit()
        }
    }

    private fun showChatInterface() {
        // Rimuovi fragment onboarding se presente
        supportFragmentManager.findFragmentById(R.id.fragment_container_onboarding)?.let {
            supportFragmentManager.beginTransaction()
                .remove(it)
                .commit()
        }

        // Mostra interfaccia chat
        binding.fragmentContainerOnboarding.visibility = View.GONE
        binding.toolbar.visibility = View.VISIBLE
        binding.rvMessages.visibility = View.VISIBLE
        binding.layoutMessageInput.visibility = View.VISIBLE
    }

    override fun onOnboardingCompleted(name: String, feeling: String, goal: String) {
        showChatInterface()
        viewModel.onboardingCompleted()
    }

    override fun onOnboardingSkipped() {
        // Salva onboarding come completato anche se skippato
        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        prefs.edit()
            .putBoolean(Constants.Prefs.ONBOARDING_COMPLETED, true)
            .apply()

        showChatInterface()
        viewModel.onboardingCompleted()
    }

    // ==================== Setup UI ====================

    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayShowTitleEnabled(false)
    }

    private fun setupRecyclerView() {
        messageAdapter = MessageAdapter()
        binding.rvMessages.apply {
            adapter = messageAdapter
            layoutManager = LinearLayoutManager(this@MainActivity).apply {
                stackFromEnd = true
            }
        }
    }

    private fun setupMessageInput() {
        binding.fabSend.setOnClickListener {
            sendMessage()
        }

        binding.etMessageInput.addTextChangedListener { text ->
            val isEmpty = text.isNullOrBlank()
            binding.fabSend.visibility = if (isEmpty) View.GONE else View.VISIBLE
        }

        binding.etMessageInput.setOnEditorActionListener { _, _, _ ->
            sendMessage()
            true
        }
    }

    // ==================== ViewModel Observers ====================

    private fun observeViewModel() {
        viewModel.messages.observe(this) { messages ->
            messageAdapter.submitList(messages) {
                if (messages.isNotEmpty()) {
                    binding.rvMessages.smoothScrollToPosition(messages.size - 1)
                }
            }
        }

        viewModel.isLoading.observe(this) { isLoading ->
            binding.fabSend.isEnabled = !isLoading
        }

        viewModel.error.observe(this) { error ->
            error?.let {
                showError(it)
                viewModel.clearError()
            }
        }

        viewModel.isTyping.observe(this) { isTyping ->
            binding.tvAiStatus.text = if (isTyping) {
                getString(R.string.ai_status_typing)
            } else {
                getString(R.string.ai_status_online)
            }
        }
    }

    // ==================== Actions ====================

    private fun sendMessage() {
        val messageText = binding.etMessageInput.text.toString().trim()
        if (messageText.isNotEmpty()) {
            viewModel.sendMessage(messageText)
            binding.etMessageInput.text.clear()
        }
    }

    private fun showError(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_LONG).show()
    }

    // ==================== Menu ====================

    override fun onCreateOptionsMenu(menu: Menu?): Boolean {
        menuInflater.inflate(R.menu.main_menu, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_clear_chat -> {
                showClearChatDialog()
                true
            }
            R.id.action_settings -> {
                startActivity(android.content.Intent(this, SettingsActivity::class.java))
                true
            }
            R.id.action_about -> {
                showAboutDialog()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun showClearChatDialog() {
        AlertDialog.Builder(this)
            .setTitle(R.string.menu_clear_chat)
            .setMessage(R.string.confirm_clear_chat)
            .setPositiveButton(R.string.yes) { _, _ ->
                viewModel.clearConversation()
            }
            .setNegativeButton(R.string.no, null)
            .show()
    }

    private fun showAboutDialog() {
        AlertDialog.Builder(this)
            .setTitle(R.string.menu_about)
            .setMessage(getString(R.string.about_description) + "\n\n" + getString(R.string.about_version))
            .setPositiveButton("OK", null)
            .show()
    }
}
