package com.tranquiz.app.ui

import android.content.Intent
import android.content.res.ColorStateList
import android.os.Bundle
import android.text.InputType
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.util.TypedValue
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.preference.PreferenceManager
import com.google.android.material.card.MaterialCardView
import com.google.android.material.color.MaterialColors
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import com.tranquiz.app.R
import com.tranquiz.app.data.database.AppDatabase
import com.tranquiz.app.data.model.CheckInType
import com.tranquiz.app.data.model.MoodEntry
import com.tranquiz.app.databinding.FragmentProfileBinding
import com.tranquiz.app.ui.adapter.CheckInAdapter
import com.tranquiz.app.ui.onboarding.adapter.OnboardingAdapter
import com.tranquiz.app.ui.onboarding.model.OnboardingOption
import com.tranquiz.app.ui.onboarding.model.OnboardingQuestionKind
import com.tranquiz.app.util.Constants
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.util.Calendar

class ProfileFragment : Fragment() {

    private var _binding: FragmentProfileBinding? = null
    private val binding get() = _binding!!
    
    private lateinit var checkInAdapter: CheckInAdapter
    private var selectedPeriod = TimePeriod.WEEK

    enum class TimePeriod(val days: Int) {
        WEEK(7),
        MONTH(30),
        YEAR(365)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentProfileBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupToolbar()
        setupRecyclerView()
        setupPeriodSelector()
        setupClickListeners()
        setupToneSettings()
        loadProfileData()
    }

    private fun setupToolbar() {
        binding.toolbar.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_settings -> {
                    startActivity(Intent(requireContext(), SettingsActivity::class.java))
                    true
                }
                R.id.action_about -> {
                    showAboutDialog()
                    true
                }
                else -> false
            }
        }
    }

    private fun setupRecyclerView() {
        checkInAdapter = CheckInAdapter(emptyList())
        binding.rvCheckIns.layoutManager = LinearLayoutManager(requireContext())
        binding.rvCheckIns.adapter = checkInAdapter
    }

    private fun setupPeriodSelector() {
        binding.chipGroupPeriod.setOnCheckedStateChangeListener { _, checkedIds ->
            if (checkedIds.isEmpty()) return@setOnCheckedStateChangeListener
            
            selectedPeriod = when (checkedIds.first()) {
                R.id.chip_week -> TimePeriod.WEEK
                R.id.chip_month -> TimePeriod.MONTH
                R.id.chip_year -> TimePeriod.YEAR
                else -> TimePeriod.WEEK
            }
            loadProfileData()
        }
    }

    private fun setupClickListeners() {
        binding.cardOnboardingName.setOnClickListener {
            showEditNameConfirmation()
        }
        binding.cardMorningCheckIn.setOnClickListener {
            showMorningCheckInDialog()
        }
        
        binding.cardEveningCheckIn.setOnClickListener {
            showEveningCheckInDialog()
        }
    }

    private fun setupToneSettings() {
        binding.settingToneEmpathy.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_EMPATHY, R.array.tone_empathy_entries, R.array.tone_empathy_values)
        }
        binding.settingToneApproach.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_APPROACH, R.array.tone_approach_entries, R.array.tone_approach_values)
        }
        binding.settingToneEnergy.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_ENERGY, R.array.tone_energy_entries, R.array.tone_energy_values)
        }
        binding.settingToneMood.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_MOOD, R.array.tone_mood_entries, R.array.tone_mood_values)
        }
        binding.settingToneLength.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_LENGTH, R.array.tone_length_entries, R.array.tone_length_values)
        }
        binding.settingToneStyle.setOnClickListener {
            showToneDialog(Constants.Prefs.TONE_STYLE, R.array.tone_style_entries, R.array.tone_style_values)
        }
        loadToneSettings()
    }

    private fun loadProfileData() {
        updateOnboardingAnswers()
        val database = AppDatabase.getDatabase(requireContext())
        val moodDao = database.moodDao()
        
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -selectedPeriod.days)
        val startDate = calendar.timeInMillis
        
        moodDao.getEntriesSince(startDate).observe(viewLifecycleOwner) { entries ->
            updateStats(entries, startDate)
            updateCheckInList(entries)
        }
    }

    private fun updateStats(entries: List<MoodEntry>, startDate: Long) {
        viewLifecycleOwner.lifecycleScope.launch {
            val database = AppDatabase.getDatabase(requireContext())
            val moodDao = database.moodDao()
            
            val eveningEntries = entries.filter { it.checkInType == CheckInType.EVENING }
            val checkInCount = entries.size
            val averageMood = withContext(Dispatchers.IO) {
                moodDao.getAverageMoodSince(startDate) ?: 0.0
            }
            
            val trend = calculateTrend(eveningEntries)
            
            binding.statCheckInValue.text = checkInCount.toString()
            binding.statMoodValue.text = getMoodEmoji(averageMood)
            binding.statTrendValue.text = trend.label
            binding.statTrendValue.setTextColor(requireContext().getColor(trend.colorRes))
            
            if (entries.isEmpty()) {
                binding.emptyState.visibility = View.VISIBLE
                binding.statsContainer.visibility = View.GONE
                binding.rvCheckIns.visibility = View.GONE
            } else {
                binding.emptyState.visibility = View.GONE
                binding.statsContainer.visibility = View.VISIBLE
                binding.rvCheckIns.visibility = View.VISIBLE
            }
        }
    }

    private fun calculateTrend(entries: List<MoodEntry>): MoodTrend {
        if (entries.size < 2) return MoodTrend.STABLE
        
        val sorted = entries.sortedBy { it.date }
        val midpoint = sorted.size / 2
        val firstHalf = sorted.take(midpoint)
        val secondHalf = sorted.drop(midpoint)
        
        val firstAvg = firstHalf.map { it.moodScore }.average()
        val secondAvg = secondHalf.map { it.moodScore }.average()
        
        val diff = secondAvg - firstAvg
        return when {
            diff > 0.3 -> MoodTrend.IMPROVING
            diff < -0.3 -> MoodTrend.DECLINING
            else -> MoodTrend.STABLE
        }
    }

    private fun getMoodEmoji(score: Double): String {
        return when {
            score >= 1.5 -> "😊"
            score >= 0.5 -> "🙂"
            score >= -0.5 -> "😐"
            score >= -1.5 -> "😔"
            else -> "😢"
        }
    }

    private fun updateCheckInList(entries: List<MoodEntry>) {
        checkInAdapter.updateEntries(entries.take(10))
    }

    private fun updateOnboardingAnswers() {
        val prefs = PreferenceManager.getDefaultSharedPreferences(requireContext())
        val name = prefs.getString(Constants.Prefs.ONBOARDING_NAME, "")?.trim().orEmpty()
        val goal = prefs.getString(Constants.Prefs.ONBOARDING_GOAL, "")?.trim().orEmpty()
        val fallback = getString(R.string.profile_not_set)

        binding.tvOnboardingNameValue.text = if (name.isNotEmpty()) name else fallback
        updateLongTermGoalBoxes(goal, fallback)
    }

    private fun updateLongTermGoalBoxes(goal: String, fallback: String) {
        val goals = goal.split(Regex("[,\\n]"))
            .map { it.trim() }
            .filter { it.isNotEmpty() }
        val items = if (goals.isNotEmpty()) goals else listOf(fallback)
        binding.longTermGoalContainer.removeAllViews()
        items.forEachIndexed { index, value ->
            val addMargin = index < items.lastIndex
            binding.longTermGoalContainer.addView(createGoalCard(value, addMargin))
        }
    }

    private fun createGoalCard(text: String, addBottomMargin: Boolean): MaterialCardView {
        val context = requireContext()
        val card = MaterialCardView(context)
        val layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        if (addBottomMargin) {
            layoutParams.bottomMargin = dpToPx(12)
        }
        card.layoutParams = layoutParams
        card.cardElevation = 0f
        card.radius = dpToPx(16).toFloat()
        card.setCardBackgroundColor(
            MaterialColors.getColor(card, com.google.android.material.R.attr.colorSurfaceContainerLow)
        )
        card.isClickable = true
        card.isFocusable = true
        card.rippleColor = ColorStateList.valueOf(
            MaterialColors.getColor(card, com.google.android.material.R.attr.colorPrimary)
        )
        card.setOnClickListener {
            showEditGoalsConfirmation()
        }

        val content = LinearLayout(context)
        content.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        content.orientation = LinearLayout.HORIZONTAL
        content.gravity = android.view.Gravity.CENTER_VERTICAL
        content.setPadding(dpToPx(16), dpToPx(16), dpToPx(16), dpToPx(16))

        val iconContainer = LinearLayout(context)
        iconContainer.layoutParams = LinearLayout.LayoutParams(dpToPx(40), dpToPx(40)).apply {
            rightMargin = dpToPx(12)
        }
        iconContainer.setBackgroundResource(R.drawable.circle_background)
        iconContainer.gravity = android.view.Gravity.CENTER

        val iconView = TextView(context)
        iconView.text = "🎯"
        iconView.textSize = 18f
        iconContainer.addView(iconView)

        val textView = TextView(context)
        textView.layoutParams = LinearLayout.LayoutParams(
            0,
            LinearLayout.LayoutParams.WRAP_CONTENT,
            1f
        )
        textView.setTextAppearance(R.style.TextAppearance_Tranquiz_BodyMedium)
        textView.setTextColor(
            MaterialColors.getColor(textView, com.google.android.material.R.attr.colorOnSurface)
        )
        textView.setTypeface(textView.typeface, android.graphics.Typeface.BOLD)
        textView.text = text

        content.addView(iconContainer)
        content.addView(textView)
        card.addView(content)
        return card
    }

    private fun dpToPx(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    private fun showEditNameDialog() {
        val prefs = PreferenceManager.getDefaultSharedPreferences(requireContext())
        val currentValue = prefs.getString(Constants.Prefs.ONBOARDING_NAME, "")?.trim().orEmpty()
        val title = getString(R.string.onboarding_name_title)
        val hintText = getString(R.string.onboarding_name_hint)

        val container = LinearLayout(requireContext()).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(24), dpToPx(24), dpToPx(24), dpToPx(8))
        }

        val titleView = TextView(requireContext()).apply {
            text = title
            setTextColor(ContextCompat.getColor(context, R.color.text_primary))
            textSize = 20f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        }

        val inputLayout = TextInputLayout(requireContext()).apply {
            hint = hintText
            boxBackgroundMode = TextInputLayout.BOX_BACKGROUND_OUTLINE
            setBoxCornerRadii(dpToPx(16).toFloat(), dpToPx(16).toFloat(), dpToPx(16).toFloat(), dpToPx(16).toFloat())
            setBoxStrokeColor(ContextCompat.getColor(context, R.color.input_border))
            setHintTextColor(ColorStateList.valueOf(ContextCompat.getColor(context, R.color.text_hint)))
        }

        val input = TextInputEditText(inputLayout.context).apply {
            setText(currentValue)
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_WORDS
            minHeight = dpToPx(56)
            setPadding(dpToPx(16), dpToPx(14), dpToPx(16), dpToPx(14))
            setTextColor(ContextCompat.getColor(context, R.color.text_primary))
            textSize = 16f
        }

        inputLayout.addView(input)
        container.addView(titleView)
        container.addView(inputLayout)

        MaterialAlertDialogBuilder(requireContext())
            .setView(container)
            .setPositiveButton(R.string.settings_save) { _, _ ->
                val newValue = input.text?.toString()?.trim().orEmpty()
                prefs.edit().putString(Constants.Prefs.ONBOARDING_NAME, newValue).apply()
                updateOnboardingAnswers()
                Toast.makeText(requireContext(), "Nome aggiornato", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showEditGoalsDialog() {
        val prefs = PreferenceManager.getDefaultSharedPreferences(requireContext())
        val currentValue = prefs.getString(Constants.Prefs.ONBOARDING_GOAL, "")?.trim().orEmpty()
        val title = getString(R.string.onboarding_goal_title)

        val container = LinearLayout(requireContext()).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(24), dpToPx(24), dpToPx(24), dpToPx(8))
        }

        val titleView = TextView(requireContext()).apply {
            text = title
            setTextColor(ContextCompat.getColor(context, R.color.text_primary))
            textSize = 20f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        }

        val subtitleView = TextView(requireContext()).apply {
            text = getString(R.string.onboarding_multi_subtitle)
            setTextColor(ContextCompat.getColor(context, R.color.text_secondary))
            textSize = 14f
        }

        val options = buildGoalOptions()
        val selectedIds = parseGoalSelections(currentValue, options).toMutableSet()
        lateinit var adapter: OnboardingAdapter
        adapter = OnboardingAdapter { option ->
            val maxSelections = 3
            if (selectedIds.contains(option.id)) {
                selectedIds.remove(option.id)
            } else if (selectedIds.size < maxSelections) {
                selectedIds.add(option.id)
            }
            adapter.submitList(options, selectedIds, OnboardingQuestionKind.MultiChoice(maxSelections))
        }
        adapter.submitList(options, selectedIds, OnboardingQuestionKind.MultiChoice(3))

        val recyclerView = androidx.recyclerview.widget.RecyclerView(requireContext()).apply {
            layoutManager = LinearLayoutManager(requireContext())
            this.adapter = adapter
        }

        container.addView(titleView)
        container.addView(subtitleView)
        container.addView(recyclerView)

        MaterialAlertDialogBuilder(requireContext())
            .setView(container)
            .setPositiveButton(R.string.settings_save) { _, _ ->
                val newValue = selectionsToText(selectedIds, options)
                prefs.edit().putString(Constants.Prefs.ONBOARDING_GOAL, newValue).apply()
                updateOnboardingAnswers()
                Toast.makeText(requireContext(), "Obiettivo aggiornato", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showEditNameConfirmation() {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle(R.string.profile_onboarding_name)
            .setMessage("Vuoi modificare il nome?")
            .setPositiveButton(R.string.yes) { _, _ ->
                showEditNameDialog()
            }
            .setNegativeButton(R.string.no, null)
            .show()
    }

    private fun showEditGoalsConfirmation() {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle(R.string.profile_long_term_goal_title)
            .setMessage("Vuoi modificare l'obiettivo di medio-lungo periodo?")
            .setPositiveButton(R.string.yes) { _, _ ->
                showEditGoalsDialog()
            }
            .setNegativeButton(R.string.no, null)
            .show()
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

    private fun selectionsToText(selections: Set<String>, options: List<OnboardingOption>): String {
        return options.filter { selections.contains(it.id) }
            .joinToString(", ") { it.title }
    }

    private fun parseGoalSelections(text: String, options: List<OnboardingOption>): Set<String> {
        val selectedTitles = text.split(Regex("[,\\n]"))
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .toSet()
        return options.filter { selectedTitles.contains(it.title) }
            .map { it.id }
            .toSet()
    }

    private fun loadToneSettings() {
        val prefs = PreferenceManager.getDefaultSharedPreferences(requireContext())
        loadToneSetting(prefs, binding.tvToneEmpathyValue, Constants.Prefs.TONE_EMPATHY, R.array.tone_empathy_entries, R.array.tone_empathy_values)
        loadToneSetting(prefs, binding.tvToneApproachValue, Constants.Prefs.TONE_APPROACH, R.array.tone_approach_entries, R.array.tone_approach_values)
        loadToneSetting(prefs, binding.tvToneEnergyValue, Constants.Prefs.TONE_ENERGY, R.array.tone_energy_entries, R.array.tone_energy_values)
        loadToneSetting(prefs, binding.tvToneMoodValue, Constants.Prefs.TONE_MOOD, R.array.tone_mood_entries, R.array.tone_mood_values)
        loadToneSetting(prefs, binding.tvToneLengthValue, Constants.Prefs.TONE_LENGTH, R.array.tone_length_entries, R.array.tone_length_values)
        loadToneSetting(prefs, binding.tvToneStyleValue, Constants.Prefs.TONE_STYLE, R.array.tone_style_entries, R.array.tone_style_values)
    }

    private fun loadToneSetting(
        prefs: android.content.SharedPreferences,
        targetView: android.widget.TextView,
        prefKey: String,
        entriesRes: Int,
        valuesRes: Int
    ) {
        val entries = resources.getStringArray(entriesRes)
        val values = resources.getStringArray(valuesRes)
        val currentValue = prefs.getString(prefKey, values.firstOrNull() ?: "")
        val currentIndex = values.indexOf(currentValue).takeIf { it >= 0 } ?: 0
        targetView.text = entries.getOrNull(currentIndex) ?: entries.firstOrNull().orEmpty()
    }

    private fun showToneDialog(prefKey: String, entriesRes: Int, valuesRes: Int) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(requireContext())
        val entries = resources.getStringArray(entriesRes)
        val values = resources.getStringArray(valuesRes)
        val currentValue = prefs.getString(prefKey, values.firstOrNull() ?: "")
        val currentIndex = values.indexOf(currentValue).takeIf { it >= 0 } ?: 0

        MaterialAlertDialogBuilder(requireContext())
            .setSingleChoiceItems(entries, currentIndex) { dialog, which ->
                prefs.edit().putString(prefKey, values[which]).apply()
                loadToneSettings()
                dialog.dismiss()
                Toast.makeText(requireContext(), "Salvato: ${entries[which]}", Toast.LENGTH_SHORT).show()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }

    private fun showAboutDialog() {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle(R.string.menu_about)
            .setMessage("${getString(R.string.about_description)}\n\n${getString(R.string.about_version)}")
            .setPositiveButton(android.R.string.ok, null)
            .show()
    }

    private fun showMorningCheckInDialog() {
        viewLifecycleOwner.lifecycleScope.launch {
            if (hasCheckInToday(CheckInType.MORNING)) {
                Toast.makeText(requireContext(), "Hai già fatto il check-in mattutino di oggi", Toast.LENGTH_SHORT).show()
                return@launch
            }
            val dialog = MorningCheckInDialogFragment()
            dialog.setOnSaveListener { motivation, fear ->
                saveMorningCheckIn(motivation, fear)
            }
            dialog.show(childFragmentManager, "morning_check_in")
        }
    }

    private fun showEveningCheckInDialog() {
        viewLifecycleOwner.lifecycleScope.launch {
            if (hasCheckInToday(CheckInType.EVENING)) {
                Toast.makeText(requireContext(), "Hai già fatto il check-in serale di oggi", Toast.LENGTH_SHORT).show()
                return@launch
            }
            val dialog = EveningCheckInDialogFragment()
            dialog.setOnSaveListener { moodIds ->
                saveEveningCheckIn(moodIds)
            }
            dialog.show(childFragmentManager, "evening_check_in")
        }
    }

    private fun saveMorningCheckIn(motivation: String, fear: String?) {
        viewLifecycleOwner.lifecycleScope.launch {
            if (hasCheckInToday(CheckInType.MORNING)) {
                Toast.makeText(requireContext(), "Check-in mattutino già registrato per oggi", Toast.LENGTH_SHORT).show()
                return@launch
            }
            val entry = MoodEntry(
                checkInType = CheckInType.MORNING,
                morningMotivation = motivation,
                morningFear = fear,
                moodScore = 0
            )
            
            withContext(Dispatchers.IO) {
                AppDatabase.getDatabase(requireContext()).moodDao().insertEntry(entry)
            }
            
            Toast.makeText(requireContext(), "Check-in mattutino salvato", Toast.LENGTH_SHORT).show()
            loadProfileData()
        }
    }

    private fun saveEveningCheckIn(moodIds: List<String>) {
        viewLifecycleOwner.lifecycleScope.launch {
            if (hasCheckInToday(CheckInType.EVENING)) {
                Toast.makeText(requireContext(), "Check-in serale già registrato per oggi", Toast.LENGTH_SHORT).show()
                return@launch
            }
            val score = calculateMoodScore(moodIds)
            val entry = MoodEntry(
                checkInType = CheckInType.EVENING,
                selectedMoodIds = JSONArray(moodIds).toString(),
                moodScore = score
            )
            
            withContext(Dispatchers.IO) {
                AppDatabase.getDatabase(requireContext()).moodDao().insertEntry(entry)
            }
            
            Toast.makeText(requireContext(), "Check-in serale salvato", Toast.LENGTH_SHORT).show()
            loadProfileData()
        }
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

    private suspend fun hasCheckInToday(type: CheckInType): Boolean {
        val (start, end) = todayBounds()
        return withContext(Dispatchers.IO) {
            AppDatabase.getDatabase(requireContext()).moodDao()
                .getEntryCountForTypeBetween(type, start, end) > 0
        }
    }

    private fun todayBounds(): Pair<Long, Long> {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val start = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, 1)
        val end = calendar.timeInMillis
        return start to end
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    enum class MoodTrend(val label: String, val colorRes: Int) {
        IMPROVING("In crescita", R.color.trend_improving),
        STABLE("Stabile", R.color.trend_stable),
        DECLINING("In calo", R.color.trend_declining)
    }

    companion object {
        fun newInstance() = ProfileFragment()
    }
}
