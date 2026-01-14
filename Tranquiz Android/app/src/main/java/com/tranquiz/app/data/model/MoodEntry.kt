package com.tranquiz.app.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

enum class CheckInType(val displayName: String, val icon: String) {
    MORNING("Mattutino", "sun_horizon"),
    EVENING("Serale", "moon_stars"),
    WEEKLY("Settimanale", "calendar")
}

@Entity(tableName = "mood_entries")
data class MoodEntry(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val date: Long = System.currentTimeMillis(),
    val checkInType: CheckInType = CheckInType.EVENING,
    val moodScore: Int = 0, // -2 a +2 per calcolo grafico
    
    // Evening check-in
    val selectedMoodIds: String = "", // JSON array come stringa
    
    // Morning check-in
    val morningMotivation: String? = null,
    val morningFear: String? = null,
    
    // Weekly
    val weeklyAIResponse: String? = null,
    val weeklyMoodSummary: String? = null,
    
    val createdAt: Long = System.currentTimeMillis()
)
