package com.tranquiz.app.ui

import android.os.Bundle
import android.view.MenuItem
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.android.material.chip.Chip
import com.tranquiz.app.R
import com.tranquiz.app.data.database.AppDatabase
import com.tranquiz.app.data.model.CheckInType
import com.tranquiz.app.data.model.MoodEntry
import com.tranquiz.app.databinding.ActivityProfileBinding
import com.tranquiz.app.ui.adapter.CheckInAdapter
import com.tranquiz.app.util.Constants
import kotlinx.coroutines.launch
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Calendar
import org.json.JSONArray

class ProfileActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityProfileBinding
    private lateinit var checkInAdapter: CheckInAdapter
    private var selectedPeriod = TimePeriod.WEEK
    
    enum class TimePeriod(val days: Int, val displayName: String) {
        WEEK(7, "Settimana"),
        MONTH(30, "Mese"),
        YEAR(365, "Anno")
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityProfileBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupToolbar()
        setupRecyclerView()
        setupPeriodSelector()
        setupClickListeners()
        
        loadProfileData()
    }
    
    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.title = getString(R.string.profile_title)
    }
    
    private fun setupRecyclerView() {
        checkInAdapter = CheckInAdapter(emptyList())
        binding.rvCheckIns.layoutManager = LinearLayoutManager(this)
        binding.rvCheckIns.adapter = checkInAdapter
    }
    
    private fun setupPeriodSelector() {
        binding.chipGroupPeriod.setOnCheckedChangeListener { _, checkedId ->
            selectedPeriod = when (checkedId) {
                R.id.chip_week -> TimePeriod.WEEK
                R.id.chip_month -> TimePeriod.MONTH
                R.id.chip_year -> TimePeriod.YEAR
                else -> TimePeriod.WEEK
            }
            loadProfileData()
        }
    }
    
    private fun setupClickListeners() {
        binding.cardMorningCheckIn.setOnClickListener {
            showMorningCheckInDialog()
        }
        
        binding.cardEveningCheckIn.setOnClickListener {
            showEveningCheckInDialog()
        }
        
        binding.cardToneSettings.setOnClickListener {
            // Apri impostazioni tono
            Toast.makeText(this, "Apri impostazioni tono", Toast.LENGTH_SHORT).show()
        }
        
        binding.cardOnboardingSummary.setOnClickListener {
            // Mostra riepilogo onboarding
            Toast.makeText(this, "Riepilogo onboarding", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun loadProfileData() {
        val database = AppDatabase.getDatabase(this)
        val moodDao = database.moodDao()
        
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -selectedPeriod.days)
        val startDate = calendar.timeInMillis
        
        moodDao.getEntriesSince(startDate).observe(this) { entries ->
            updateStats(entries, startDate)
            updateCheckInList(entries)
        }
    }
    
    private fun updateStats(entries: List<MoodEntry>, startDate: Long) {
        lifecycleScope.launch {
            val database = AppDatabase.getDatabase(this@ProfileActivity)
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
            binding.statTrendValue.setTextColor(getColor(trend.colorRes))
            
            if (entries.isEmpty()) {
                binding.emptyState.visibility = View.VISIBLE
                binding.statsContainer.visibility = View.GONE
                binding.chartContainer.visibility = View.GONE
                binding.rvCheckIns.visibility = View.GONE
            } else {
                binding.emptyState.visibility = View.GONE
                binding.statsContainer.visibility = View.VISIBLE
                binding.chartContainer.visibility = View.VISIBLE
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
    
    private fun showMorningCheckInDialog() {
        val dialog = MorningCheckInDialogFragment()
        dialog.setOnSaveListener { motivation, fear ->
            saveMorningCheckIn(motivation, fear)
        }
        dialog.show(supportFragmentManager, "morning_check_in")
    }
    
    private fun showEveningCheckInDialog() {
        val dialog = EveningCheckInDialogFragment()
        dialog.setOnSaveListener { moodIds ->
            saveEveningCheckIn(moodIds)
        }
        dialog.show(supportFragmentManager, "evening_check_in")
    }
    
    private fun saveMorningCheckIn(motivation: String, fear: String?) {
        lifecycleScope.launch {
            val entry = MoodEntry(
                checkInType = CheckInType.MORNING,
                morningMotivation = motivation,
                morningFear = fear,
                moodScore = 0
            )
            
            withContext(Dispatchers.IO) {
                AppDatabase.getDatabase(this@ProfileActivity).moodDao().insertEntry(entry)
            }
            
            Toast.makeText(this@ProfileActivity, "Check-in mattutino salvato", Toast.LENGTH_SHORT).show()
            loadProfileData()
        }
    }
    
    private fun saveEveningCheckIn(moodIds: List<String>) {
        lifecycleScope.launch {
            val score = calculateMoodScore(moodIds)
            val entry = MoodEntry(
                checkInType = CheckInType.EVENING,
                selectedMoodIds = JSONArray(moodIds).toString(),
                moodScore = score
            )
            
            withContext(Dispatchers.IO) {
                AppDatabase.getDatabase(this@ProfileActivity).moodDao().insertEntry(entry)
            }
            
            Toast.makeText(this@ProfileActivity, "Check-in serale salvato", Toast.LENGTH_SHORT).show()
            loadProfileData()
        }
    }
    
    private fun calculateMoodScore(moodIds: List<String>): Int {
        // Mapping semplificato degli aggettivi a score (-2 a +2)
        val moodScores = mapOf(
            "very_happy" to 2,
            "happy" to 1,
            "calm" to 1,
            "peaceful" to 1,
            "grateful" to 1,
            "hopeful" to 1,
            "content" to 0,
            "motivated" to 1,
            "loved" to 1,
            "confident" to 1,
            "neutral" to 0,
            "tired" to -1,
            "anxious" to -1,
            "stressed" to -1,
            "frustrated" to -1,
            "uncertain" to -1,
            "lonely" to -1,
            "sad" to -2,
            "very_sad" to -2,
            "overwhelmed" to -2
        )
        
        if (moodIds.isEmpty()) return 0
        
        val total = moodIds.sumOf { moodScores[it] ?: 0 }
        return (total.toDouble() / moodIds.size).toInt().coerceIn(-2, 2)
    }
    
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        if (item.itemId == android.R.id.home) {
            finish()
            return true
        }
        return super.onOptionsItemSelected(item)
    }
    
    enum class MoodTrend(val label: String, val colorRes: Int) {
        IMPROVING("In crescita", R.color.trend_improving),
        STABLE("Stabile", R.color.trend_stable),
        DECLINING("In calo", R.color.trend_declining)
    }
}
