package com.tranquiz.app.ui

import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.MarginLayoutParams
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.view.ContextThemeWrapper
import androidx.appcompat.widget.PopupMenu
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.widget.addTextChangedListener
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.tranquiz.app.R
import com.tranquiz.app.databinding.FragmentChatBinding
import com.tranquiz.app.ui.adapter.MessageAdapter
import com.tranquiz.app.ui.viewmodel.ChatViewModel

class ChatFragment : Fragment() {

    private var _binding: FragmentChatBinding? = null
    private val binding get() = _binding!!
    
    private lateinit var messageAdapter: MessageAdapter
    private val viewModel: ChatViewModel by activityViewModels()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentChatBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupRecyclerView()
        setupMessageInput()
        setupMenu()
        setupKeyboardInsets()
        observeViewModel()
    }
    
    private fun setupKeyboardInsets() {
        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            val imeInsets = insets.getInsets(WindowInsetsCompat.Type.ime())
            
            // Get bottom navigation height from parent activity
            val bottomNav = (activity as? MainActivity)?.findViewById<View>(R.id.bottom_navigation)
            val bottomNavHeight = bottomNav?.height ?: 0
            
            // Calculate margin: IME height minus bottom nav height (if IME is visible)
            // This ensures input moves up above keyboard while bottom nav stays fixed
            val marginBottom = if (imeInsets.bottom > 0) {
                if (bottomNavHeight > 0) {
                    (imeInsets.bottom - bottomNavHeight).coerceAtLeast(0)
                } else {
                    // Bottom nav not measured yet, use post to recalculate
                    bottomNav?.post {
                        val measuredHeight = bottomNav.height
                        val recalculatedMargin = (imeInsets.bottom - measuredHeight).coerceAtLeast(0)
                        updateInputMargin(recalculatedMargin)
                    }
                    imeInsets.bottom // Temporary: use full IME height
                }
            } else {
                0
            }
            
            updateInputMargin(marginBottom)
            
            insets
        }
    }
    
    private fun updateInputMargin(marginBottom: Int) {
        val layoutParams = binding.cardInput.layoutParams as? MarginLayoutParams
        layoutParams?.let {
            it.bottomMargin = marginBottom
            binding.cardInput.layoutParams = it
        }
        
        // Update RecyclerView padding to prevent messages from being hidden under input field
        // Padding = input field height + margin bottom (when keyboard is open)
        binding.cardInput.post {
            val inputHeight = binding.cardInput.height
            val defaultPadding = (160 * resources.displayMetrics.density).toInt() // 160dp default
            
            val totalPadding = if (marginBottom > 0 && inputHeight > 0) {
                // Keyboard is open: padding = input height + margin
                inputHeight + marginBottom
            } else {
                // Keyboard is closed: use default padding
                defaultPadding
            }
            
            binding.rvMessages.setPadding(
                binding.rvMessages.paddingLeft,
                binding.rvMessages.paddingTop,
                binding.rvMessages.paddingRight,
                totalPadding
            )
            
            // Scroll to bottom if keyboard just opened and there are messages
            if (marginBottom > 0 && messageAdapter.itemCount > 0) {
                binding.rvMessages.post {
                    binding.rvMessages.smoothScrollToPosition(messageAdapter.itemCount - 1)
                }
            }
        }
    }

    private fun setupRecyclerView() {
        messageAdapter = MessageAdapter()
        binding.rvMessages.apply {
            adapter = messageAdapter
            layoutManager = LinearLayoutManager(requireContext()).apply {
                stackFromEnd = true
            }
        }
    }

    private fun setupMessageInput() {
        binding.fabSend.setOnClickListener {
            sendMessage()
        }

        binding.etMessageInput.addTextChangedListener { text ->
            val isEmpty = text.isNullOrBlank()
            binding.fabSend.visibility = if (isEmpty) View.GONE else View.VISIBLE
        }

        binding.etMessageInput.setOnEditorActionListener { _, _, _ ->
            sendMessage()
            true
        }
    }

    private fun setupMenu() {
        binding.btnMenu.setOnClickListener { view ->
            // Use M3 styled context for PopupMenu
            val themedContext = ContextThemeWrapper(requireContext(), R.style.Widget_Tranquiz_PopupMenu)
            val popup = PopupMenu(themedContext, view, Gravity.END)
            popup.menuInflater.inflate(R.menu.chat_menu, popup.menu)
            
            // Enable icons in popup menu
            try {
                val method = popup.menu.javaClass.getDeclaredMethod("setOptionalIconsVisible", Boolean::class.javaPrimitiveType)
                method.isAccessible = true
                method.invoke(popup.menu, true)
            } catch (e: Exception) {
                // Ignore if method not found
            }
            
            // Apply text color for better contrast (M3)
            val textColor = androidx.core.content.ContextCompat.getColor(requireContext(), R.color.md_theme_onSurface)
            for (i in 0 until popup.menu.size()) {
                val item = popup.menu.getItem(i)
                val spannable = android.text.SpannableString(item.title)
                spannable.setSpan(
                    android.text.style.ForegroundColorSpan(textColor),
                    0,
                    spannable.length,
                    android.text.Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                )
                item.title = spannable
            }
            
            popup.setOnMenuItemClickListener { item ->
                when (item.itemId) {
                    R.id.action_clear_chat -> {
                        showClearChatDialog()
                        true
                    }
                    R.id.action_settings -> {
                        startActivity(android.content.Intent(requireContext(), SettingsActivity::class.java))
                        true
                    }
                    R.id.action_about -> {
                        showAboutDialog()
                        true
                    }
                    else -> false
                }
            }
            popup.show()
        }
    }

    private fun observeViewModel() {
        viewModel.messages.observe(viewLifecycleOwner) { messages ->
            messageAdapter.submitList(messages) {
                if (messages.isNotEmpty()) {
                    binding.rvMessages.smoothScrollToPosition(messages.size - 1)
                }
            }
        }

        viewModel.isLoading.observe(viewLifecycleOwner) { isLoading ->
            binding.tvAiStatus.text = if (isLoading) {
                getString(R.string.ai_status_typing)
            } else {
                getString(R.string.ai_status_online)
            }
            
            binding.tvAiStatus.setTextColor(
                if (isLoading) {
                    resources.getColor(R.color.md_theme_primary, null)
                } else {
                    resources.getColor(R.color.online_color, null)
                }
            )
        }

        viewModel.error.observe(viewLifecycleOwner) { errorMessage ->
            errorMessage?.let {
                showError(it)
                viewModel.clearError()
            }
        }
    }

    private fun sendMessage() {
        val messageText = binding.etMessageInput.text?.toString()?.trim() ?: return
        if (messageText.isEmpty()) return

        binding.etMessageInput.text?.clear()
        viewModel.sendMessage(messageText)
    }

    private fun showClearChatDialog() {
        AlertDialog.Builder(requireContext())
            .setTitle(R.string.confirm_clear_chat)
            .setMessage(R.string.confirm_clear_chat_message)
            .setPositiveButton(R.string.yes) { _, _ ->
                viewModel.clearConversation()
            }
            .setNegativeButton(R.string.no, null)
            .show()
    }

    private fun showAboutDialog() {
        AlertDialog.Builder(requireContext())
            .setTitle(R.string.menu_about)
            .setMessage("${getString(R.string.about_description)}\n\n${getString(R.string.about_version)}")
            .setPositiveButton(android.R.string.ok, null)
            .show()
    }

    private fun showError(message: String) {
        Toast.makeText(requireContext(), message, Toast.LENGTH_LONG).show()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    companion object {
        fun newInstance() = ChatFragment()
    }
}
