package com.tranquiz.app.ui.onboarding

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.tranquiz.app.databinding.FragmentWelcomeIntroBinding

/**
 * Fragment di benvenuto con 3 slide illustrative prima del flusso di onboarding.
 * Mostra la value proposition di Tranquiz con copy autentico dal sito tranquiz.eu.
 */
class WelcomeIntroFragment : Fragment() {

    private var _binding: FragmentWelcomeIntroBinding? = null
    private val binding get() = _binding!!

    private var currentPage = 0
    private val totalPages = 3

    private var callback: WelcomeIntroCallback? = null

    interface WelcomeIntroCallback {
        fun onWelcomeIntroCompleted()
        fun onWelcomeIntroSkipped()
    }

    override fun onAttach(context: Context) {
        super.onAttach(context)
        callback = context as? WelcomeIntroCallback
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentWelcomeIntroBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        savedInstanceState?.let { currentPage = it.getInt(KEY_PAGE, 0) }

        setupDotCorners()
        updatePage(animate = false)

        binding.btnAction.setOnClickListener {
            if (currentPage < totalPages - 1) {
                navigateToPage(currentPage + 1)
            } else {
                callback?.onWelcomeIntroCompleted()
            }
        }

        binding.btnSkip.setOnClickListener {
            callback?.onWelcomeIntroSkipped()
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putInt(KEY_PAGE, currentPage)
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    // ── Navigation ──────────────────────────────────────────────────────────

    private fun navigateToPage(page: Int) {
        currentPage = page
        updatePage(animate = true)
    }

    private fun updatePage(animate: Boolean) {
        val pages = listOf(binding.page1, binding.page2, binding.page3)
        val dots = listOf(binding.dot0, binding.dot1, binding.dot2)
        val isLast = currentPage == totalPages - 1

        // Show/hide pages with crossfade
        pages.forEachIndexed { index, pageView ->
            if (index == currentPage) {
                if (animate) fadeIn(pageView) else pageView.visibility = View.VISIBLE
            } else {
                if (animate) fadeOut(pageView) else pageView.visibility = View.GONE
            }
        }

        // Update dots
        dots.forEachIndexed { index, dot ->
            val isActive = index == currentPage
            animateDot(dot, isActive, animate)
        }

        // Update button label
        binding.btnAction.text = if (isLast) "Inizia ora 🌱" else "Avanti"

        // Hide/show skip button
        binding.btnSkip.visibility = if (isLast) View.INVISIBLE else View.VISIBLE
    }

    // ── Dot Animations ───────────────────────────────────────────────────────

    private fun setupDotCorners() {
        listOf(binding.dot0, binding.dot1, binding.dot2).forEach { dot ->
            dot.post {
                dot.background = roundedDotDrawable(dot.width, dot.height, "#FFFFFFFF")
            }
        }
    }

    private fun animateDot(dot: View, active: Boolean, animate: Boolean) {
        val targetWidth = if (active) dpToPx(22) else dpToPx(8)
        val targetAlpha = if (active) 1f else 0.3f
        val activeColor = "#FFFFFFFF"

        dot.background = roundedDotDrawable(targetWidth, dpToPx(8), activeColor)

        if (animate) {
            val widthAnim = ObjectAnimator.ofInt(dot, "width", dot.width, targetWidth)
            val alphaAnim = ObjectAnimator.ofFloat(dot, "alpha", dot.alpha, targetAlpha)
            AnimatorSet().apply {
                playTogether(widthAnim, alphaAnim)
                duration = 250
                start()
            }
        } else {
            dot.layoutParams = dot.layoutParams.also { it.width = targetWidth }
            dot.alpha = targetAlpha
            dot.requestLayout()
        }
    }

    private fun roundedDotDrawable(width: Int, height: Int, colorHex: String): android.graphics.drawable.GradientDrawable {
        return android.graphics.drawable.GradientDrawable().apply {
            shape = android.graphics.drawable.GradientDrawable.RECTANGLE
            cornerRadius = height / 2f
            setColor(android.graphics.Color.parseColor(colorHex))
        }
    }

    // ── Fade helpers ─────────────────────────────────────────────────────────

    private fun fadeIn(view: View) {
        if (view.visibility == View.VISIBLE) return
        view.alpha = 0f
        view.visibility = View.VISIBLE
        view.animate().alpha(1f).setDuration(280).start()
    }

    private fun fadeOut(view: View) {
        if (view.visibility == View.GONE) return
        view.animate().alpha(0f).setDuration(200).withEndAction {
            view.visibility = View.GONE
        }.start()
    }

    private fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return (dp * density).toInt()
    }

    companion object {
        private const val KEY_PAGE = "welcome_intro_page"

        fun newInstance(): WelcomeIntroFragment = WelcomeIntroFragment()
    }
}
