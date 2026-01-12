//
//  ContentView.swift
//  Serenity
//
//  Created by Mario Moschetta on 30/08/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("preferredAppearance") private var preferredAppearance: String = "system"
    @ObservedObject private var notificationManager = NotificationManager.shared
    @Environment(\.modelContext) private var context

    @State private var showOnboarding = false
    @State private var showEveningCheckIn = false
    @State private var showMorningCheckIn = false
    @State private var selectedTab = 0
    @State private var triggerWeeklyResponse = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Chat
            NavigationStack {
                MainChatView(triggerWeeklyResponse: $triggerWeeklyResponse)
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(0)

            // Tab 2: Profilo
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profilo", systemImage: "person.crop.circle.fill")
            }
            .tag(1)
        }
        .tint(ChatStyle.accentPurpleDark)
        .preferredColorScheme(appearance)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showEveningCheckIn) {
            EveningCheckInSheet()
        }
        .sheet(isPresented: $showMorningCheckIn) {
            MorningCheckInSheet()
        }
        .onAppear {
            showOnboarding = !onboardingCompleted
            checkPendingNotification()
        }
        .onChange(of: onboardingCompleted) { _, completed in
            showOnboarding = !completed
        }
        .onReceive(notificationManager.$pendingCheckInType) { type in
            handlePendingCheckIn(type)
        }
    }

    private var appearance: ColorScheme? {
        switch preferredAppearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private func checkPendingNotification() {
        if let pending = notificationManager.pendingCheckInType {
            handlePendingCheckIn(pending)
        }
    }

    private func handlePendingCheckIn(_ type: CheckInType?) {
        guard let type = type else { return }

        // Delay to allow UI to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            switch type {
            case .morning:
                showMorningCheckIn = true
            case .evening:
                showEveningCheckIn = true
            case .weekly:
                selectedTab = 0
                triggerWeeklyResponse = true
            }
            notificationManager.clearPending()
        }
    }
}

#Preview {
    ContentView()
}
