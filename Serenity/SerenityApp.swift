//
//  SerenityApp.swift
//  Serenity
//
//  Created by Mario Moschetta on 30/08/25.
//

import SwiftUI
import SwiftData

@main
struct SerenityApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Conversation.self,
            ChatMessage.self,
            MemorySummary.self,
            Attachment.self,
            MoodEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupNotifications()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func setupNotifications() {
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            if granted {
                NotificationManager.shared.rescheduleAll()
            }
        }
    }
}
