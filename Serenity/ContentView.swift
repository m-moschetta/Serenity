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
    @State private var showOnboarding = false
    
    var body: some View {
        NavigationStack {
            MainChatView()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onAppear {
            showOnboarding = !onboardingCompleted
        }
        .onChange(of: onboardingCompleted) { completed in
            showOnboarding = !completed
        }
    }
}

#Preview {
    ContentView()
}
