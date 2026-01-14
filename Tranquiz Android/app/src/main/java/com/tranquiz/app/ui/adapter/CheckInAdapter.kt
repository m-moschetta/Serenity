package com.tranquiz.app.ui.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.tranquiz.app.R
import com.tranquiz.app.data.model.CheckInType
import com.tranquiz.app.data.model.MoodEntry
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.*

class CheckInAdapter(private var entries: List<MoodEntry>) : RecyclerView.Adapter<CheckInAdapter.ViewHolder>() {
    
    private val dateFormat = SimpleDateFormat("dd MMM yyyy", Locale.getDefault())
    private val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
    
    fun updateEntries(newEntries: List<MoodEntry>) {
        entries = newEntries
        notifyDataSetChanged()
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_check_in, parent, false)
        return ViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(entries[position])
    }
    
    override fun getItemCount() = entries.size
    
    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvType: TextView = itemView.findViewById(R.id.tv_check_in_type)
        private val tvDate: TextView = itemView.findViewById(R.id.tv_check_in_date)
        private val tvTime: TextView = itemView.findViewById(R.id.tv_check_in_time)
        private val tvContent: TextView = itemView.findViewById(R.id.tv_check_in_content)
        
        fun bind(entry: MoodEntry) {
            val date = Date(entry.date)
            tvType.text = entry.checkInType.displayName
            tvDate.text = SimpleDateFormat("dd MMM yyyy", Locale.getDefault()).format(date)
            tvTime.text = SimpleDateFormat("HH:mm", Locale.getDefault()).format(date)
            
            when (entry.checkInType) {
                CheckInType.MORNING -> {
                    tvContent.text = entry.morningMotivation ?: "Nessuna motivazione"
                }
                CheckInType.EVENING -> {
                    val moodIds = try {
                        JSONArray(entry.selectedMoodIds).let { arr ->
                            (0 until arr.length()).map { arr.getString(it) }
                        }
                    } catch (e: Exception) {
                        emptyList()
                    }
                    val moodLabels = moodIds.map { getMoodLabel(it) }
                    tvContent.text = if (moodLabels.isNotEmpty()) {
                        moodLabels.joinToString(", ")
                    } else {
                        getMoodEmoji(entry.moodScore.toDouble())
                    }
                }
                CheckInType.WEEKLY -> {
                    tvContent.text = entry.weeklyMoodSummary ?: "Nessun riepilogo"
                }
            }
        }
        
        private fun getMoodLabel(id: String): String {
            return when (id) {
                "very_happy" -> "Molto felice"
                "happy" -> "Felice"
                "calm" -> "Calmo"
                "peaceful" -> "Sereno"
                "grateful" -> "Gratificato"
                "hopeful" -> "Speranzoso"
                "content" -> "Contento"
                "motivated" -> "Motivato"
                "loved" -> "Amato"
                "confident" -> "Sicuro"
                "neutral" -> "Neutrale"
                "tired" -> "Stanco"
                "anxious" -> "Ansioso"
                "stressed" -> "Stressato"
                "frustrated" -> "Frustrato"
                "uncertain" -> "Incertezza"
                "lonely" -> "Solo"
                "sad" -> "Triste"
                "very_sad" -> "Molto triste"
                "overwhelmed" -> "Sopraffatto"
                else -> id
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
    }
}
