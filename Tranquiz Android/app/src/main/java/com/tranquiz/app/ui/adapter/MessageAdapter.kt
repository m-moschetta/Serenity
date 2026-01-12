package com.tranquiz.app.ui.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.tranquiz.app.R
import com.tranquiz.app.data.model.Message
import com.tranquiz.app.databinding.ItemMessageAiBinding
import com.tranquiz.app.databinding.ItemMessageErrorBinding
import com.tranquiz.app.databinding.ItemMessageUserBinding
import org.ocpsoft.prettytime.PrettyTime
import java.util.*

/**
 * Adapter per la lista dei messaggi nella chat.
 * Supporta 3 tipi di messaggi: utente, AI, errore.
 * Usa View Binding e un singolo PrettyTime cached.
 */
class MessageAdapter : ListAdapter<Message, MessageAdapter.MessageViewHolder>(MessageDiffCallback()) {

    // Cache PrettyTime a livello adapter per evitare creazioni multiple
    private val prettyTime = PrettyTime(Locale.getDefault())

    override fun getItemViewType(position: Int): Int {
        val message = getItem(position)
        return when {
            message.isFromUser -> VIEW_TYPE_USER
            message.isError -> VIEW_TYPE_ERROR
            else -> VIEW_TYPE_AI
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MessageViewHolder {
        val inflater = LayoutInflater.from(parent.context)
        return when (viewType) {
            VIEW_TYPE_USER -> {
                val binding = ItemMessageUserBinding.inflate(inflater, parent, false)
                UserViewHolder(binding)
            }
            VIEW_TYPE_AI -> {
                val binding = ItemMessageAiBinding.inflate(inflater, parent, false)
                AiViewHolder(binding)
            }
            VIEW_TYPE_ERROR -> {
                val binding = ItemMessageErrorBinding.inflate(inflater, parent, false)
                ErrorViewHolder(binding)
            }
            else -> throw IllegalArgumentException("Unknown view type: $viewType")
        }
    }

    override fun onBindViewHolder(holder: MessageViewHolder, position: Int) {
        holder.bind(getItem(position), prettyTime)
    }

    /**
     * ViewHolder base astratto per tutti i tipi di messaggio.
     */
    abstract class MessageViewHolder(itemView: android.view.View) : RecyclerView.ViewHolder(itemView) {
        abstract fun bind(message: Message, prettyTime: PrettyTime)
    }

    /**
     * ViewHolder per messaggi utente.
     */
    class UserViewHolder(
        private val binding: ItemMessageUserBinding
    ) : MessageViewHolder(binding.root) {

        override fun bind(message: Message, prettyTime: PrettyTime) {
            binding.tvMessageText.text = message.content
            binding.tvMessageTime.text = prettyTime.format(Date(message.timestamp))
        }
    }

    /**
     * ViewHolder per messaggi AI.
     */
    class AiViewHolder(
        private val binding: ItemMessageAiBinding
    ) : MessageViewHolder(binding.root) {

        override fun bind(message: Message, prettyTime: PrettyTime) {
            binding.tvMessageText.text = message.content
            binding.tvMessageTime.text = prettyTime.format(Date(message.timestamp))
        }
    }

    /**
     * ViewHolder per messaggi di errore.
     */
    class ErrorViewHolder(
        private val binding: ItemMessageErrorBinding
    ) : MessageViewHolder(binding.root) {

        override fun bind(message: Message, prettyTime: PrettyTime) {
            binding.tvMessageText.text = message.content
            binding.tvMessageTime.text = prettyTime.format(Date(message.timestamp))
        }
    }

    companion object {
        private const val VIEW_TYPE_USER = 1
        private const val VIEW_TYPE_AI = 2
        private const val VIEW_TYPE_ERROR = 3
    }
}

/**
 * DiffUtil callback per calcolare differenze tra liste di messaggi.
 */
class MessageDiffCallback : DiffUtil.ItemCallback<Message>() {

    override fun areItemsTheSame(oldItem: Message, newItem: Message): Boolean {
        return oldItem.id == newItem.id
    }

    override fun areContentsTheSame(oldItem: Message, newItem: Message): Boolean {
        return oldItem == newItem
    }
}
