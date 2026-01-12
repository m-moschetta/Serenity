package com.tranquiz.app.ui.onboarding

import android.app.TimePickerDialog
import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.core.widget.doAfterTextChanged
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.preference.PreferenceManager
import androidx.recyclerview.widget.LinearLayoutManager
import com.tranquiz.app.R
import com.tranquiz.app.data.database.AppDatabase
import com.tranquiz.app.data.model.Message
import com.tranquiz.app.databinding.FragmentOnboardingBinding
import com.tranquiz.app.databinding.LayoutOnboardingNotificationsBinding
import com.tranquiz.app.databinding.LayoutOnboardingToneBinding
import com.tranquiz.app.ui.onboarding.adapter.OnboardingAdapter
import com.tranquiz.app.ui.onboarding.model.*
import com.tranquiz.app.util.Constants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.*

class OnboardingFragment : Fragment() {

    private var _binding: FragmentOnboardingBinding? = null
    private val binding get() = _binding!!

    private lateinit var toneBinding: LayoutOnboardingToneBinding
    private lateinit var notificationsBinding: LayoutOnboardingNotificationsBinding
    private lateinit var adapter: OnboardingAdapter

    private var questions = mutableListOf<OnboardingQuestion>()
    private var currentIndex = 0
    private var selectionAnswers = mutableMapOf<String, MutableSet<String>>()
    private var textAnswers = mutableMapOf<String, String>()
    
    private var selectedReasons = mutableListOf<OnboardingReason>()
    private var didAppendFlows = false
    private var safetyAsked = false
    private var safetyFlagged = false

    // Steps state
    private var showingToneStep = false
    private var showingNotificationsStep = false

    private var callback: OnboardingCallback? = null

    interface OnboardingCallback {
        fun onOnboardingCompleted()
        fun onOnboardingSkipped()
    }

    override fun onAttach(context: Context) {
        super.onAttach(context)
        callback = context as? OnboardingCallback
            ?: throw IllegalStateException("Activity must implement OnboardingCallback")
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        _binding = FragmentOnboardingBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupRecyclerView()
        setupInputs()
        setupStepsLayouts()
        setupClickListeners()
        
        // Initialize questions
        questions.clear()
        questions.addAll(OnboardingFlowLibrary.commonQuestions)
        questions.add(OnboardingFlowLibrary.rootQuestion)
        
        updateUI()
    }

    private fun setupRecyclerView() {
        adapter = OnboardingAdapter { option ->
            toggleSelection(option)
        }
        binding.rvOnboardingOptions.layoutManager = LinearLayoutManager(requireContext())
        binding.rvOnboardingOptions.adapter = adapter
    }

    private fun setupInputs() {
        binding.etOnboardingInput.doAfterTextChanged { 
            val question = questions.getOrNull(currentIndex) ?: return@doAfterTextChanged
            textAnswers[question.id] = it?.toString() ?: ""
            updatePrimaryButtonState()
        }
    }

    private fun setupStepsLayouts() {
        toneBinding = LayoutOnboardingToneBinding.inflate(layoutInflater, binding.toneSelectionContainer, true)
        notificationsBinding = LayoutOnboardingNotificationsBinding.inflate(layoutInflater, binding.notificationsSetupContainer, true)
        
        // Notifications time pickers
        notificationsBinding.tvMorningTime.setOnClickListener { showTimePicker(true) }
        notificationsBinding.tvEveningTime.setOnClickListener { showTimePicker(false) }
    }

    private fun setupClickListeners() {
        binding.tvOnboardingBack.setOnClickListener { goBack() }
        binding.tvOnboardingSkip.setOnClickListener { callback?.onOnboardingSkipped() }
        binding.btnOnboardingPrimary.setOnClickListener { next() }
    }

    private fun updateUI() {
        if (showingNotificationsStep) {
            showNotificationsUI()
        } else if (showingToneStep) {
            showToneUI()
        } else {
            showQuestionUI()
        }
    }

    private fun showQuestionUI() {
        val question = questions[currentIndex]
        
        binding.tvOnboardingBack.visibility = if (currentIndex > 0) View.VISIBLE else View.INVISIBLE
        binding.onboardingProgress.progress = (((currentIndex + 1).toFloat() / questions.size) * 100).toInt()
        
        binding.tvOnboardingQuestion.text = question.title
        if (question.subtitle != null) {
            binding.tvOnboardingSubtitle.visibility = View.VISIBLE
            binding.tvOnboardingSubtitle.text = question.subtitle
        } else {
            binding.tvOnboardingSubtitle.visibility = View.GONE
        }
        
        if (question.reason != null) {
            binding.tvOnboardingReason_tag.visibility = View.VISIBLE
            binding.tvOnboardingReason_tag.text = question.reason.label
        } else {
            binding.tvOnboardingReason_tag.visibility = View.GONE
        }

        // Switch between types
        when (question.kind) {
            is OnboardingQuestionKind.FreeText -> {
                binding.rvOnboardingOptions.visibility = View.GONE
                binding.tilOnboardingInput.visibility = View.VISIBLE
                binding.tilOnboardingInput.hint = question.kind.placeholder ?: "Scrivi qui"
                binding.etOnboardingInput.setText(textAnswers[question.id] ?: "")
            }
            else -> {
                binding.rvOnboardingOptions.visibility = View.VISIBLE
                binding.tilOnboardingInput.visibility = View.GONE
                adapter.submitList(question.options, selectionAnswers[question.id] ?: emptySet(), question.kind)
            }
        }
        
        binding.toneSelectionContainer.visibility = View.GONE
        binding.notificationsSetupContainer.visibility = View.GONE
        binding.btnOnboardingPrimary.setText(if (currentIndex == questions.size - 1) "Concludi" else "Avanti")
        updatePrimaryButtonState()
    }

    private fun showToneUI() {
        binding.tvOnboardingBack.visibility = View.VISIBLE
        binding.onboardingProgress.progress = 90
        binding.tvOnboardingQuestion.setText(R.string.onboarding_tone_title)
        binding.tvOnboardingSubtitle.visibility = View.VISIBLE
        binding.tvOnboardingSubtitle.setText(R.string.onboarding_tone_subtitle)
        binding.tvOnboardingReason_tag.visibility = View.GONE
        
        binding.rvOnboardingOptions.visibility = View.GONE
        binding.tilOnboardingInput.visibility = View.GONE
        binding.toneSelectionContainer.visibility = View.VISIBLE
        binding.notificationsSetupContainer.visibility = View.GONE
        
        binding.btnOnboardingPrimary.text = "Avanti"
        binding.btnOnboardingPrimary.isEnabled = true
    }

    private fun showNotificationsUI() {
        binding.tvOnboardingBack.visibility = View.VISIBLE
        binding.onboardingProgress.progress = 100
        binding.tvOnboardingQuestion.text = "Vuoi attivare i promemoria giornalieri?"
        binding.tvOnboardingSubtitle.visibility = View.VISIBLE
        binding.tvOnboardingSubtitle.text = "Ti aiuteranno a riflettere sul tuo stato d'animo"
        binding.tvOnboardingReason_tag.visibility = View.GONE
        
        binding.rvOnboardingOptions.visibility = View.GONE
        binding.tilOnboardingInput.visibility = View.GONE
        binding.toneSelectionContainer.visibility = View.GONE
        binding.notificationsSetupContainer.visibility = View.VISIBLE
        
        binding.btnOnboardingPrimary.text = "Inizia"
        binding.btnOnboardingPrimary.isEnabled = true
    }

    private fun toggleSelection(option: OnboardingOption) {
        val question = questions[currentIndex]
        val currentSelections = selectionAnswers.getOrPut(question.id) { mutableSetOf() }
        
        when (val kind = question.kind) {
            is OnboardingQuestionKind.MultiChoice -> {
                if (currentSelections.contains(option.id)) {
                    currentSelections.remove(option.id)
                } else {
                    if (currentSelections.size >= kind.max) {
                        currentSelections.remove(currentSelections.first())
                    }
                    currentSelections.add(option.id)
                }
            }
            else -> {
                if (currentSelections.contains(option.id)) {
                    currentSelections.clear()
                } else {
                    currentSelections.clear()
                    currentSelections.add(option.id)
                }
            }
        }
        adapter.submitList(question.options, currentSelections, question.kind)
        updatePrimaryButtonState()
    }

    private fun updatePrimaryButtonState() {
        val question = questions.getOrNull(currentIndex) ?: return
        val isValid = when (question.kind) {
            is OnboardingQuestionKind.FreeText -> textAnswers[question.id]?.isNotBlank() == true
            else -> selectionAnswers[question.id]?.isNotEmpty() == true
        }
        binding.btnOnboardingPrimary.isEnabled = isValid
    }

    private fun goBack() {
        if (showingNotificationsStep) {
            showingNotificationsStep = false
            showingToneStep = true
        } else if (showingToneStep) {
            showingToneStep = false
        } else if (currentIndex > 0) {
            currentIndex--
        }
        updateUI()
    }

    private fun next() {
        if (showingNotificationsStep) {
            finishOnboarding()
            return
        }
        
        if (showingToneStep) {
            saveTonePreferences()
            showingToneStep = false
            showingNotificationsStep = true
            updateUI()
            return
        }

        val question = questions[currentIndex]
        
        // Handle logic for root question
        if (question.id == "q1_root") {
            val ids = selectionAnswers[question.id] ?: emptySet()
            selectedReasons = ids.mapNotNull { OnboardingReason.fromId(it) }.toMutableList()
            appendReasonFlows()
        }
        
        evaluateSafety(question)
        
        if (currentIndex == questions.size - 1) {
            showingToneStep = true
        } else {
            currentIndex++
        }
        updateUI()
    }

    private fun appendReasonFlows() {
        if (didAppendFlows) return
        didAppendFlows = true
        val newQuestions = mutableListOf<OnboardingQuestion>()
        for (reason in selectedReasons) {
            newQuestions.addAll(OnboardingFlowLibrary.getFlow(reason))
        }
        questions.addAll(newQuestions)
    }

    private fun evaluateSafety(question: OnboardingQuestion) {
        if (safetyAsked) return
        val selections = selectionAnswers[question.id] ?: emptySet()
        val risky = question.options.any { selections.contains(it.id) && it.triggersSafety }
        if (risky) {
            showSafetyCheckDialog()
        }
    }

    private fun showSafetyCheckDialog() {
        val safetyQuestion = OnboardingFlowLibrary.safetyQuestion
        val options = safetyQuestion.options.map { it.title }.toTypedArray()
        
        AlertDialog.Builder(requireContext())
            .setTitle(safetyQuestion.title)
            .setItems(options) { _, which ->
                val selected = safetyQuestion.options[which]
                selectionAnswers[safetyQuestion.id] = mutableSetOf(selected.id)
                safetyAsked = true
                if (selected.id == "often" || selected.id == "sometimes") {
                    safetyFlagged = true
                    showCrisisDialog()
                }
            }
            .setCancelable(false)
            .show()
    }

    private fun showCrisisDialog() {
        AlertDialog.Builder(requireContext())
            .setTitle("Supporto immediato")
            .setMessage("Capisco che in questo momento potresti sentirti sopraffatto. Non sei solo, e chiedere aiuto è un atto di grande forza.\n\nContatta subito il 112 o Telefono Amico (02 2327 2327).")
            .setPositiveButton("Ho capito", null)
            .show()
    }

    private fun showTimePicker(isMorning: Boolean) {
        val calendar = Calendar.getInstance()
        val hour = if (isMorning) 8 else 21
        val minute = 0
        
        TimePickerDialog(requireContext(), { _, h, m ->
            val time = String.format("%02d:%02d", h, m)
            if (isMorning) {
                notificationsBinding.tvMorningTime.text = time
            } else {
                notificationsBinding.tvEveningTime.text = time
            }
        }, hour, minute, true).show()
    }

    private fun saveTonePreferences() {
        val prefs = PreferenceManager.getDefaultSharedPreferences(requireContext())
        val toneEmpathy = if (toneBinding.chipEmpathetic.isChecked) "empathetic" else "neutral"
        val toneApproach = if (toneBinding.chipGentle.isChecked) "gentle" else "direct"
        val toneEnergy = if (toneBinding.chipCalm.isChecked) "calm" else "energetic"
        val toneMood = if (toneBinding.chipSerious.isChecked) "serious" else "light"
        val toneLength = if (toneBinding.chipBrief.isChecked) "brief" else "detailed"
        val toneStyle = if (toneBinding.chipIntimate.isChecked) "intimate" else "professional"

        prefs.edit()
            .putString(Constants.Prefs.TONE_EMPATHY, toneEmpathy)
            .putString(Constants.Prefs.TONE_APPROACH, toneApproach)
            .putString(Constants.Prefs.TONE_ENERGY, toneEnergy)
            .putString(Constants.Prefs.TONE_MOOD, toneMood)
            .putString(Constants.Prefs.TONE_LENGTH, toneLength)
            .putString(Constants.Prefs.TONE_STYLE, toneStyle)
            .apply()
    }

    private fun finishOnboarding() {
        val prefs = PreferenceManager.getDefaultSharedPreferences(requireContext())
        
        // Save notification settings
        val notificationsEnabled = notificationsBinding.switchNotifications.isChecked
        val weeklyEnabled = notificationsBinding.switchWeekly.isChecked
        val morningTime = notificationsBinding.tvMorningTime.text.toString()
        val eveningTime = notificationsBinding.tvEveningTime.text.toString()
        
        val morningParts = morningTime.split(":")
        val eveningParts = eveningTime.split(":")

        prefs.edit()
            .putBoolean(Constants.Prefs.NOTIFICATIONS_ENABLED, notificationsEnabled)
            .putBoolean(Constants.Prefs.WEEKLY_SUMMARY_ENABLED, weeklyEnabled)
            .putInt(Constants.Prefs.MORNING_CHECKIN_HOUR, morningParts[0].toInt())
            .putInt(Constants.Prefs.MORNING_CHECKIN_MINUTE, morningParts[1].toInt())
            .putInt(Constants.Prefs.EVENING_CHECKIN_HOUR, eveningParts[0].toInt())
            .putInt(Constants.Prefs.EVENING_CHECKIN_MINUTE, eveningParts[1].toInt())
            .putBoolean(Constants.Prefs.ONBOARDING_COMPLETED, true)
            .apply()

        // Build profile and save summary
        val profile = buildProfile()
        prefs.edit().putString(Constants.Prefs.ONBOARDING_SUMMARY, profile.summaryText()).apply()
        
        // Send welcome message
        sendWelcomeMessage(profile)
        
        callback?.onOnboardingCompleted()
    }

    private fun buildProfile(): OnboardingProfile {
        val allAnswers = mutableListOf<OnboardingAnswer>()
        for (q in questions) {
            val selections = selectionAnswers[q.id]
            val text = textAnswers[q.id]
            
            if (selections != null && selections.isNotEmpty()) {
                val answers = selections.mapNotNull { id -> q.options.find { it.id == id }?.title }
                val risky = q.options.any { selections.contains(it.id) && it.triggersSafety }
                allAnswers.add(OnboardingAnswer(q.id, q.title, answers, q.reason, risky))
            } else if (!text.isNullOrBlank()) {
                allAnswers.add(OnboardingAnswer(q.id, q.title, listOf(text), q.reason, false))
            }
        }
        
        // Add safety check answer if exists
        selectionAnswers[OnboardingFlowLibrary.safetyQuestion.id]?.let { safetySet ->
            val risky = safetySet.contains("often") || safetySet.contains("sometimes")
            val answers = safetySet.mapNotNull { id -> OnboardingFlowLibrary.safetyQuestion.options.find { it.id == id }?.title }
            allAnswers.add(OnboardingAnswer(OnboardingFlowLibrary.safetyQuestion.id, OnboardingFlowLibrary.safetyQuestion.title, answers, null, risky))
        }

        return OnboardingProfile(
            createdAt = Date(),
            answers = allAnswers,
            primaryReason = selectedReasons.firstOrNull(),
            otherReasons = selectedReasons.drop(1),
            safetyFlag = safetyFlagged
        )
    }

    private fun sendWelcomeMessage(profile: OnboardingProfile) {
        var intro = "Grazie per aver condiviso qualcosa di te. Ho preso nota di quello che hai raccontato per personalizzare il supporto."
        profile.primaryReason?.let {
            intro += " Ho capito che il motivo principale è: ${it.label.lowercase()}."
        }
        if (profile.safetyFlag) {
            intro += " Se in qualsiasi momento senti che le cose diventano troppo pesanti, scrivilo pure e ti indicherò subito numeri e risorse di emergenza."
        }
        intro += " Ti va di raccontarmi cosa ti pesa di più in questo momento o da dove vorresti iniziare?"

        lifecycleScope.launch(Dispatchers.IO) {
            val db = AppDatabase.getDatabase(requireContext())
            val message = Message(
                conversationId = Constants.Conversation.DEFAULT_CONVERSATION_ID,
                role = Constants.Conversation.ROLE_ASSISTANT,
                content = intro,
                timestamp = System.currentTimeMillis()
            )
            db.messageDao().insertMessage(message)
            // Note: In a real app, you'd also create the conversation if it doesn't exist.
            // Here we assume it exists or will be created by MainActivity.
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
