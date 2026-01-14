package com.tranquiz.app.ui

import android.os.Bundle
import android.view.View
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.fragment.app.Fragment
import androidx.preference.PreferenceManager
import com.tranquiz.app.R
import com.tranquiz.app.data.api.ApiClient
import com.tranquiz.app.databinding.ActivityMainBinding
import com.tranquiz.app.ui.onboarding.OnboardingFragment
import com.tranquiz.app.ui.viewmodel.ChatViewModel
import com.tranquiz.app.util.Constants

/**
 * Activity principale con Bottom Navigation.
 * Gestisce la navigazione tra Chat e Profilo.
 * L'onboarding è delegato a OnboardingFragment.
 */
class MainActivity : AppCompatActivity(), OnboardingFragment.OnboardingCallback {

    private lateinit var binding: ActivityMainBinding
    private val viewModel: ChatViewModel by viewModels()
    
    private var currentFragmentTag: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable Edge-to-Edge display
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupEdgeToEdge()
        checkOnboarding()
    }
    
    private fun setupEdgeToEdge() {
        // Handle system bars insets for Edge-to-Edge
        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            
            // Add padding top to FragmentContainerView to respect status bar
            binding.navHostFragment.setPadding(
                binding.navHostFragment.paddingLeft,
                systemBars.top,
                binding.navHostFragment.paddingRight,
                binding.navHostFragment.paddingBottom
            )
            
            // Handle Bottom Navigation insets to prevent icons from being hidden behind gesture bar
            binding.bottomNavigation.setPadding(
                binding.bottomNavigation.paddingLeft,
                binding.bottomNavigation.paddingTop,
                binding.bottomNavigation.paddingRight,
                systemBars.bottom
            )
            
            insets
        }
    }

    override fun onResume() {
        super.onResume()
        viewModel.setProvider(ApiClient.getCurrentProvider(this))
    }

    // ==================== Onboarding ====================

    private fun checkOnboarding() {
        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        val onboardingCompleted = prefs.getBoolean(Constants.Prefs.ONBOARDING_COMPLETED, false)

        if (onboardingCompleted) {
            showMainInterface()
        } else {
            showOnboarding()
        }
    }

    private fun showOnboarding() {
        // Nascondi interfaccia principale
        binding.navHostFragment.visibility = View.GONE
        binding.bottomNavigation.visibility = View.GONE
        binding.fragmentContainerOnboarding.visibility = View.VISIBLE

        // Aggiungi fragment onboarding se non esiste già
        if (supportFragmentManager.findFragmentById(R.id.fragment_container_onboarding) == null) {
            supportFragmentManager.beginTransaction()
                .replace(R.id.fragment_container_onboarding, OnboardingFragment.newInstance())
                .commit()
        }
    }

    private fun showMainInterface() {
        // Rimuovi fragment onboarding se presente
        supportFragmentManager.findFragmentById(R.id.fragment_container_onboarding)?.let {
            supportFragmentManager.beginTransaction()
                .remove(it)
                .commit()
        }

        // Mostra interfaccia principale
        binding.fragmentContainerOnboarding.visibility = View.GONE
        binding.navHostFragment.visibility = View.VISIBLE
        binding.bottomNavigation.visibility = View.VISIBLE

        setupBottomNavigation()
        
        // Mostra il fragment iniziale (Chat)
        if (currentFragmentTag == null) {
            showFragment(ChatFragment.newInstance(), TAG_CHAT)
        }
    }

    private fun setupBottomNavigation() {
        binding.bottomNavigation.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.nav_chat -> {
                    showFragment(ChatFragment.newInstance(), TAG_CHAT)
                    true
                }
                R.id.nav_profile -> {
                    showFragment(ProfileFragment.newInstance(), TAG_PROFILE)
                    true
                }
                else -> false
            }
        }
    }

    private fun showFragment(fragment: Fragment, tag: String) {
        if (currentFragmentTag == tag) return
        
        currentFragmentTag = tag
        
        supportFragmentManager.beginTransaction()
            .setCustomAnimations(
                android.R.anim.fade_in,
                android.R.anim.fade_out
            )
            .replace(R.id.nav_host_fragment, fragment, tag)
            .commit()
    }

    // ==================== Onboarding Callbacks ====================

    override fun onOnboardingCompleted(name: String, feeling: String, goal: String) {
        showMainInterface()
        viewModel.onboardingCompleted()
    }

    override fun onOnboardingSkipped() {
        // Salva onboarding come completato anche se skippato
        val prefs = PreferenceManager.getDefaultSharedPreferences(this)
        prefs.edit()
            .putBoolean(Constants.Prefs.ONBOARDING_COMPLETED, true)
            .apply()

        showMainInterface()
        viewModel.onboardingCompleted()
    }

    companion object {
        private const val TAG_CHAT = "chat"
        private const val TAG_PROFILE = "profile"
    }
}
