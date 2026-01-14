package com.tranquiz.app.data.database

import androidx.lifecycle.LiveData
import androidx.room.*
import com.tranquiz.app.data.model.MoodEntry
import com.tranquiz.app.data.model.CheckInType

@Dao
interface MoodDao {
    
    @Query("SELECT * FROM mood_entries ORDER BY date DESC")
    fun getAllEntries(): LiveData<List<MoodEntry>>
    
    @Query("SELECT * FROM mood_entries WHERE date >= :startDate ORDER BY date DESC")
    fun getEntriesSince(startDate: Long): LiveData<List<MoodEntry>>
    
    @Query("SELECT * FROM mood_entries WHERE checkInType = :type ORDER BY date DESC")
    fun getEntriesByType(type: CheckInType): LiveData<List<MoodEntry>>
    
    @Query("SELECT * FROM mood_entries WHERE checkInType = :type AND date >= :startDate ORDER BY date DESC")
    fun getEntriesByTypeSince(type: CheckInType, startDate: Long): LiveData<List<MoodEntry>>
    
    @Query("SELECT AVG(moodScore) FROM mood_entries WHERE checkInType = 'EVENING' AND date >= :startDate")
    suspend fun getAverageMoodSince(startDate: Long): Double?
    
    @Query("SELECT COUNT(*) FROM mood_entries WHERE date >= :startDate")
    suspend fun getEntryCountSince(startDate: Long): Int
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEntry(entry: MoodEntry): Long
    
    @Update
    suspend fun updateEntry(entry: MoodEntry)
    
    @Delete
    suspend fun deleteEntry(entry: MoodEntry)
    
    @Query("DELETE FROM mood_entries WHERE id = :id")
    suspend fun deleteEntryById(id: String)
}
