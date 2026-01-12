package com.tranquiz.app.ui.onboarding

import android.content.Context
import android.os.Bundle
import android.text.InputType
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.preference.PreferenceManager
import com.tranquiz.app.R
import com.tranquiz.app.databinding.FragmentOnboardingBinding
import com.tranquiz.app.util.Constants

/**
 * Fragment per gestire il flusso di onboarding in 4 step.
 * Estrae la logica di onboarding da MainActivity per migliorare la separazione delle responsabilità.
 */
class OnboardingFragment : Fragment() {

    private var _binding: FragmentOnboardingBinding? = null
    private val binding get() = _binding!!

    private var currentStep: Int = 0
    private var userName: String = ""
    private var userFeeling: String = ""
    private var userGoal: String = ""

    // Tone preferences
    private var toneEmpathy: String = "empathetic"
    private var toneApproach: String = "gentle"
    private var toneEnergy: String = "calm"
    private var toneMood: String = "serious"
    private var toneLength: String = "brief"
    private var toneStyle: String = "intimate"

    private var callback: OnboardingCallback? = null

    /**
     * Callback per comunicare con l'Activity host.
     */
    interface OnboardingCallback {
        fun onOnboardingCompleted(name: String, feeling: String, goal: String)
        fun onOnboardingSkipped()
    }

    override fun onAttach(context: Context) {
        super.onAttach(context)
        callback = context as? OnboardingCallback
            ?: throw IllegalStateException("Activity must implement OnboardingCallback")
    }

    override fun onDetach() {
        super.onDetach()
        callback = null
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentOnboardingBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Ripristina stato salvato
        savedInstanceState?.let {
            currentStep = it.getInt(KEY_STEP, 0)
            userName = it.getString(KEY_NAME, "") ?: ""
            userFeeling = it.getString(KEY_FEELING, "") ?: ""
            userGoal = it.getString(KEY_GOAL, "") ?: ""
            toneEmpathy = it.getString(KEY_TONE_EMPATHY, "empathetic") ?: "empathetic"
            toneApproach = it.getString(KEY_TONE_APPROACH, "gentle") ?: "gentle"
            toneEnergy = it.getString(KEY_TONE_ENERGY, "calm") ?: "calm"
            toneMood = it.getString(KEY_TONE_MOOD, "serious") ?: "serious"
            toneLength = it.getString(KEY_TONE_LENGTH, "brief") ?: "brief"
            toneStyle = it.getString(KEY_TONE_STYLE, "intimate") ?: "intimate"
        }

        setupClickListeners()
        showStep(currentStep)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        saveCurrentInput()
        outState.putInt(KEY_STEP, currentStep)
        outState.putString(KEY_NAME, userName)
        outState.putString(KEY_FEELING, userFeeling)
        outState.putString(KEY_GOAL, userGoal)
        outState.putString(KEY_TONE_EMPATHY, toneEmpathy)
        outState.putString(KEY_TONE_APPROACH, toneApproach)
        outState.putString(KEY_TONE_ENERGY, toneEnergy)
        outState.putString(KEY_TONE_MOOD, toneMood)
        outState.putString(KEY_TONE_LENGTH, toneLength)
        outState.putString(KEY_TONE_STYLE, toneStyle)
        super.onSaveInstanceState(outState)
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    private fun setupClickListeners() {
        binding.tvOnboardingSkip.setOnClickListener {
            saveCurrentInput()
            callback?.onOnboardingSkipped()
        }

        binding.tvOnboardingBack.setOnClickListener {
            if (currentStep > 0) {
                saveCurrentInput()
                currentStep--
                showStep(currentStep)
            }
        }

        binding.btnOnboardingPrimary.setOnClickListener {
            saveCurrentInput()
            if (currentStep >= TOTAL_STEPS - 1) {
                completeOnboarding()
            } else {
                currentStep++
                showStep(currentStep)
            }
        }
    }

    private fun showStep(step: Int) {
        currentStep = step.coerceIn(0, TOTAL_STEPS - 1)

        // Step 3 (tone selection) ha un layout diverso
        if (currentStep == 3) {
            // Mostra tone selection, nascondi input text
            binding.tilOnboardingInput.visibility = View.GONE
            binding.toneSelectionContainer.visibility = View.VISIBLE
            binding.tvOnboardingQuestion.setText(R.string.onboarding_tone_title)
            binding.btnOnboardingPrimary.setText(R.string.finish)

            // Ripristina le selezioni dei chip
            restoreToneSelections()
        } else {
            // Steps 0-2: mostra input text, nascondi tone selection
            binding.tilOnboardingInput.visibility = View.VISIBLE
            binding.toneSelectionContainer.visibility = View.GONE

            val config = getStepConfig(currentStep)
            binding.tvOnboardingQuestion.setText(config.titleRes)
            binding.tilOnboardingInput.hint = getString(config.hintRes)
            binding.etOnboardingInput.inputType = config.inputType
            binding.etOnboardingInput.setText(config.value)
            binding.etOnboardingInput.setSelection(binding.etOnboardingInput.text?.length ?: 0)
            binding.btnOnboardingPrimary.setText(config.buttonRes)
        }

        // Mostra/nascondi pulsante back
        binding.tvOnboardingBack.visibility = if (currentStep == 0) View.INVISIBLE else View.VISIBLE

        // Aggiorna indicatori di progresso
        updateProgressDots(currentStep)
    }

    private fun restoreToneSelections() {
        // Ripristina le selezioni dai valori salvati
        when (toneEmpathy) {
            "empathetic" -> binding.chipEmpathetic.isChecked = true
            "neutral" -> binding.chipNeutral.isChecked = true
        }
        when (toneApproach) {
            "gentle" -> binding.chipGentle.isChecked = true
            "direct" -> binding.chipDirect.isChecked = true
        }
        when (toneEnergy) {
            "calm" -> binding.chipCalm.isChecked = true
            "energetic" -> binding.chipEnergetic.isChecked = true
        }
        when (toneMood) {
            "serious" -> binding.chipSerious.isChecked = true
            "light" -> binding.chipLight.isChecked = true
        }
        when (toneLength) {
            "brief" -> binding.chipBrief.isChecked = true
            "detailed" -> binding.chipDetailed.isChecked = true
        }
        when (toneStyle) {
            "intimate" -> binding.chipIntimate.isChecked = true
            "professional" -> binding.chipProfessional.isChecked = true
        }
    }

    private fun getStepConfig(step: Int): StepConfig {
        return when (step) {
            0 -> StepConfig(
                titleRes = R.string.onboarding_name_title,
                hintRes = R.string.onboarding_name_hint,
                inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_WORDS,
                value = userName,
                buttonRes = R.string.next
            )
            1 -> StepConfig(
                titleRes = R.string.onboarding_feeling_title,
                hintRes = R.string.onboarding_feeling_hint,
                inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES,
                value = userFeeling,
                buttonRes = R.string.next
            )
            else -> StepConfig(
                titleRes = R.string.onboarding_goal_title,
                hintRes = R.string.onboarding_goal_hint,
                inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES or InputType.TYPE_TEXT_FLAG_MULTI_LINE,
                value = userGoal,
                buttonRes = R.string.next  // Now "next" since step 3 follows
            )
        }
    }

    private fun updateProgressDots(activeStep: Int) {
        val activeColor = ContextCompat.getColor(requireContext(), R.color.primary_color)
        val inactiveColor = ContextCompat.getColor(requireContext(), R.color.text_hint)

        binding.dot1.setCardBackgroundColor(if (activeStep == 0) activeColor else inactiveColor)
        binding.dot2.setCardBackgroundColor(if (activeStep == 1) activeColor else inactiveColor)
        binding.dot3.setCardBackgroundColor(if (activeStep == 2) activeColor else inactiveColor)
        binding.dot4.setCardBackgroundColor(if (activeStep == 3) activeColor else inactiveColor)
    }

    private fun saveCurrentInput() {
        if (currentStep == 3) {
            // Save tone selections from ChipGroups
            saveToneSelections()
        } else {
            val value = binding.etOnboardingInput.text?.toString()?.trim().orEmpty()
            when (currentStep) {
                0 -> userName = value
                1 -> userFeeling = value
                2 -> userGoal = value
            }
        }
    }

    private fun saveToneSelections() {
        // Empathy
        toneEmpathy = when (binding.chipGroupEmpathy.checkedChipId) {
            R.id.chip_empathetic -> "empathetic"
            R.id.chip_neutral -> "neutral"
            else -> "empathetic"
        }
        // Approach
        toneApproach = when (binding.chipGroupApproach.checkedChipId) {
            R.id.chip_gentle -> "gentle"
            R.id.chip_direct -> "direct"
            else -> "gentle"
        }
        // Energy
        toneEnergy = when (binding.chipGroupEnergy.checkedChipId) {
            R.id.chip_calm -> "calm"
            R.id.chip_energetic -> "energetic"
            else -> "calm"
        }
        // Mood
        toneMood = when (binding.chipGroupMood.checkedChipId) {
            R.id.chip_serious -> "serious"
            R.id.chip_light -> "light"
            else -> "serious"
        }
        // Length
        toneLength = when (binding.chipGroupLength.checkedChipId) {
            R.id.chip_brief -> "brief"
            R.id.chip_detailed -> "detailed"
            else -> "brief"
        }
        // Style
        toneStyle = when (binding.chipGroupStyle.checkedChipId) {
            R.id.chip_intimate -> "intimate"
            R.id.chip_professional -> "professional"
            else -> "intimate"
        }
    }

    private fun completeOnboarding() {
        // Salva i dati nelle SharedPreferences
        val prefs = PreferenceManager.getDefaultSharedPreferences(requireContext())
        prefs.edit()
            .putString(Constants.Prefs.ONBOARDING_NAME, userName)
            .putString(Constants.Prefs.ONBOARDING_FEELING, userFeeling)
            .putString(Constants.Prefs.ONBOARDING_GOAL, userGoal)
            // Tone preferences
            .putString(Constants.Prefs.TONE_EMPATHY, toneEmpathy)
            .putString(Constants.Prefs.TONE_APPROACH, toneApproach)
            .putString(Constants.Prefs.TONE_ENERGY, toneEnergy)
            .putString(Constants.Prefs.TONE_MOOD, toneMood)
            .putString(Constants.Prefs.TONE_LENGTH, toneLength)
            .putString(Constants.Prefs.TONE_STYLE, toneStyle)
            .putBoolean(Constants.Prefs.ONBOARDING_COMPLETED, true)
            .apply()

        callback?.onOnboardingCompleted(userName, userFeeling, userGoal)
    }

    /**
     * Configurazione per ogni step dell'onboarding.
     */
    private data class StepConfig(
        val titleRes: Int,
        val hintRes: Int,
        val inputType: Int,
        val value: String,
        val buttonRes: Int
    )

    companion object {
        private const val TOTAL_STEPS = 4
        private const val KEY_STEP = "onboarding_step"
        private const val KEY_NAME = "onboarding_name"
        private const val KEY_FEELING = "onboarding_feeling"
        private const val KEY_GOAL = "onboarding_goal"
        private const val KEY_TONE_EMPATHY = "onboarding_tone_empathy"
        private const val KEY_TONE_APPROACH = "onboarding_tone_approach"
        private const val KEY_TONE_ENERGY = "onboarding_tone_energy"
        private const val KEY_TONE_MOOD = "onboarding_tone_mood"
        private const val KEY_TONE_LENGTH = "onboarding_tone_length"
        private const val KEY_TONE_STYLE = "onboarding_tone_style"

        fun newInstance(): OnboardingFragment {
            return OnboardingFragment()
        }
    }
}
