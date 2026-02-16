package com.tranquiz.app.ui.onboarding

import android.content.Context
import android.os.Bundle
import android.text.InputType
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.preference.PreferenceManager
import androidx.recyclerview.widget.LinearLayoutManager
import com.tranquiz.app.R
import com.tranquiz.app.data.database.AppDatabase
import com.tranquiz.app.data.model.CheckInType
import com.tranquiz.app.data.model.MoodEntry
import com.tranquiz.app.databinding.FragmentOnboardingBinding
import com.tranquiz.app.ui.onboarding.adapter.OnboardingAdapter
import com.tranquiz.app.ui.onboarding.model.OnboardingOption
import com.tranquiz.app.ui.onboarding.model.OnboardingQuestionKind
import com.tranquiz.app.util.Constants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray

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

    private lateinit var optionsAdapter: OnboardingAdapter
    private val feelingSelections = mutableSetOf<String>()
    private val goalSelections = mutableSetOf<String>()

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
            feelingSelections.clear()
            feelingSelections.addAll(it.getStringArrayList(KEY_FEELING_SELECTIONS) ?: emptyList())
            goalSelections.clear()
            goalSelections.addAll(it.getStringArrayList(KEY_GOAL_SELECTIONS) ?: emptyList())
        }

        setupClickListeners()
        setupOptionsRecycler()
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
        outState.putStringArrayList(KEY_FEELING_SELECTIONS, ArrayList(feelingSelections))
        outState.putStringArrayList(KEY_GOAL_SELECTIONS, ArrayList(goalSelections))
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
            binding.rvOnboardingOptions.visibility = View.GONE
            binding.toneSelectionContainer.visibility = View.VISIBLE
            binding.tvOnboardingQuestion.setText(R.string.onboarding_tone_title)
            binding.tvOnboardingQuestionSubtitle.visibility = View.GONE
            binding.btnOnboardingPrimary.setText(R.string.finish)

            // Ripristina le selezioni dei chip
            restoreToneSelections()
        } else if (currentStep == 0) {
            // Step 0: mostra input text, nascondi opzioni e tone selection
            binding.tilOnboardingInput.visibility = View.VISIBLE
            binding.rvOnboardingOptions.visibility = View.GONE
            binding.toneSelectionContainer.visibility = View.GONE

            val config = getStepConfig(currentStep)
            binding.tvOnboardingQuestion.setText(config.titleRes)
            binding.tilOnboardingInput.hint = getString(config.hintRes)
            binding.etOnboardingInput.inputType = config.inputType
            binding.etOnboardingInput.setText(config.value)
            binding.etOnboardingInput.setSelection(binding.etOnboardingInput.text?.length ?: 0)
            binding.btnOnboardingPrimary.setText(config.buttonRes)
            binding.tvOnboardingQuestionSubtitle.visibility = View.GONE
        } else {
            // Steps 1-2: mostra opzioni multiple
            binding.tilOnboardingInput.visibility = View.GONE
            binding.rvOnboardingOptions.visibility = View.VISIBLE
            binding.toneSelectionContainer.visibility = View.GONE
            binding.tvOnboardingQuestionSubtitle.visibility = View.VISIBLE
            binding.tvOnboardingQuestionSubtitle.setText(R.string.onboarding_multi_subtitle)

            if (currentStep == 1) {
                binding.tvOnboardingQuestion.setText(R.string.onboarding_feeling_title)
                binding.btnOnboardingPrimary.setText(R.string.next)
            } else {
                binding.tvOnboardingQuestion.setText(R.string.onboarding_goal_title)
                binding.btnOnboardingPrimary.setText(R.string.next)
            }

            updateOptionsUi()
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
        val activeColor = ContextCompat.getColor(binding.root.context, R.color.primary_color)
        val inactiveColor = ContextCompat.getColor(binding.root.context, R.color.text_hint)

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
            when (currentStep) {
                0 -> {
                    val value = binding.etOnboardingInput.text?.toString()?.trim().orEmpty()
                    userName = value
                }
                1 -> userFeeling = selectionsToText(feelingSelections, buildFeelingOptions())
                2 -> userGoal = selectionsToText(goalSelections, buildGoalOptions())
            }
        }
    }

    private fun setupOptionsRecycler() {
        optionsAdapter = OnboardingAdapter { option ->
            handleOptionSelection(option)
        }
        binding.rvOnboardingOptions.layoutManager = LinearLayoutManager(binding.root.context)
        binding.rvOnboardingOptions.adapter = optionsAdapter
    }

    private fun updateOptionsUi() {
        if (!::optionsAdapter.isInitialized) {
            setupOptionsRecycler()
        }
        if (binding.rvOnboardingOptions.layoutManager == null) {
            binding.rvOnboardingOptions.layoutManager = LinearLayoutManager(binding.root.context)
        }
        if (binding.rvOnboardingOptions.adapter == null) {
            binding.rvOnboardingOptions.adapter = optionsAdapter
        }
        val (options, selections) = when (currentStep) {
            1 -> Pair(buildFeelingOptions(), feelingSelections)
            2 -> Pair(buildGoalOptions(), goalSelections)
            else -> Pair(emptyList(), mutableSetOf<String>())
        }
        if (options.isEmpty()) return
        optionsAdapter.submitList(options, selections, OnboardingQuestionKind.MultiChoice(max = 3))
    }

    private fun handleOptionSelection(option: OnboardingOption) {
        val maxSelections = 3
        val selections = when (currentStep) {
            1 -> feelingSelections
            2 -> goalSelections
            else -> return
        }

        if (selections.contains(option.id)) {
            selections.remove(option.id)
        } else if (selections.size < maxSelections) {
            selections.add(option.id)
        }
        updateOptionsUi()
    }

    private fun buildFeelingOptions(): List<OnboardingOption> {
        return listOf(
            OnboardingOption(id = "calm", title = getString(R.string.onboarding_feeling_option_calm)),
            OnboardingOption(id = "anxious", title = getString(R.string.onboarding_feeling_option_anxious)),
            OnboardingOption(id = "tired", title = getString(R.string.onboarding_feeling_option_tired)),
            OnboardingOption(id = "sad", title = getString(R.string.onboarding_feeling_option_sad)),
            OnboardingOption(id = "motivated", title = getString(R.string.onboarding_feeling_option_motivated)),
            OnboardingOption(id = "overwhelmed", title = getString(R.string.onboarding_feeling_option_overwhelmed)),
            OnboardingOption(id = "hopeful", title = getString(R.string.onboarding_feeling_option_hopeful)),
            OnboardingOption(id = "irritable", title = getString(R.string.onboarding_feeling_option_irritable))
        )
    }

    private fun buildGoalOptions(): List<OnboardingOption> {
        return listOf(
            OnboardingOption(id = "anxiety", title = getString(R.string.onboarding_goal_option_anxiety)),
            OnboardingOption(id = "mood", title = getString(R.string.onboarding_goal_option_mood)),
            OnboardingOption(id = "sleep", title = getString(R.string.onboarding_goal_option_sleep)),
            OnboardingOption(id = "stress", title = getString(R.string.onboarding_goal_option_stress)),
            OnboardingOption(id = "motivation", title = getString(R.string.onboarding_goal_option_motivation)),
            OnboardingOption(id = "relationships", title = getString(R.string.onboarding_goal_option_relationships)),
            OnboardingOption(id = "selfesteem", title = getString(R.string.onboarding_goal_option_selfesteem))
        )
    }

    private fun selectionsToText(
        selections: Set<String>,
        options: List<OnboardingOption>
    ): String {
        return options.filter { selections.contains(it.id) }
            .joinToString(", ") { it.title }
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

        saveOnboardingFeelingAsCheckIn()
        callback?.onOnboardingCompleted(userName, userFeeling, userGoal)
    }

    private fun saveOnboardingFeelingAsCheckIn() {
        viewLifecycleOwner.lifecycleScope.launch(Dispatchers.IO) {
            val database = AppDatabase.getDatabase(binding.root.context)
            val moodDao = database.moodDao()
            val mappedMoodIds = mapOnboardingFeelingSelections(feelingSelections)
            val entry = MoodEntry(
                checkInType = CheckInType.ONBOARDING,
                selectedMoodIds = JSONArray(mappedMoodIds).toString(),
                moodScore = calculateMoodScore(mappedMoodIds)
            )
            moodDao.insertEntry(entry)
        }
    }

    private fun mapOnboardingFeelingSelections(selections: Set<String>): List<String> {
        return selections.mapNotNull { id ->
            when (id) {
                "calm" -> "calm"
                "anxious" -> "anxious"
                "tired" -> "tired"
                "sad" -> "sad"
                "motivated" -> "motivated"
                "overwhelmed" -> "overwhelmed"
                "hopeful" -> "hopeful"
                "irritable" -> "frustrated"
                else -> null
            }
        }.distinct()
    }

    private fun calculateMoodScore(moodIds: List<String>): Int {
        val moodScores = mapOf(
            "very_happy" to 2, "happy" to 1, "calm" to 1, "peaceful" to 1,
            "grateful" to 1, "hopeful" to 1, "content" to 0, "motivated" to 1,
            "loved" to 1, "confident" to 1, "neutral" to 0, "tired" to -1,
            "anxious" to -1, "stressed" to -1, "frustrated" to -1, "uncertain" to -1,
            "lonely" to -1, "sad" to -2, "very_sad" to -2, "overwhelmed" to -2
        )

        if (moodIds.isEmpty()) return 0

        val total = moodIds.sumOf { moodScores[it] ?: 0 }
        return (total.toDouble() / moodIds.size).toInt().coerceIn(-2, 2)
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
        private const val KEY_FEELING_SELECTIONS = "onboarding_feeling_selections"
        private const val KEY_GOAL_SELECTIONS = "onboarding_goal_selections"

        fun newInstance(): OnboardingFragment {
            return OnboardingFragment()
        }
    }
}
