package com.tranquiz.app.data.database

import android.content.Context
import androidx.room.*
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.tranquiz.app.data.model.Message
import com.tranquiz.app.data.model.MoodEntry

@Database(
    entities = [Message::class, MoodEntry::class],
    version = 3,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    
    abstract fun messageDao(): MessageDao
    abstract fun moodDao(): MoodDao
    
    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null
        
        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("ALTER TABLE messages ADD COLUMN isError INTEGER NOT NULL DEFAULT 0")
            }
        }
        
        private val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS mood_entries (
                        id TEXT NOT NULL PRIMARY KEY,
                        date INTEGER NOT NULL,
                        checkInType TEXT NOT NULL,
                        moodScore INTEGER NOT NULL DEFAULT 0,
                        selectedMoodIds TEXT NOT NULL DEFAULT '',
                        morningMotivation TEXT,
                        morningFear TEXT,
                        weeklyAIResponse TEXT,
                        weeklyMoodSummary TEXT,
                        createdAt INTEGER NOT NULL
                    )
                """.trimIndent())
            }
        }

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "tranquiz_database"
                )
                .addMigrations(MIGRATION_1_2, MIGRATION_2_3)
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}