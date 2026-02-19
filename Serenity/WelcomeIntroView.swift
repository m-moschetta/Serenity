//
//  WelcomeIntroView.swift
//  Serenity
//
//  Schermata di benvenuto a 3 slide prima del flusso di onboarding.
//

import SwiftUI

// MARK: - Data Model

private struct IntroSlide {
    let systemIcon: String
    let headline: String
    let subtitle: String?
    let body: String?
    let features: [(icon: String, title: String, desc: String)]?
    let badges: [String]?

    init(
        systemIcon: String,
        headline: String,
        subtitle: String? = nil,
        body: String? = nil,
        features: [(icon: String, title: String, desc: String)]? = nil,
        badges: [String]? = nil
    ) {
        self.systemIcon = systemIcon
        self.headline = headline
        self.subtitle = subtitle
        self.body = body
        self.features = features
        self.badges = badges
    }
}

// MARK: - Main View

struct WelcomeIntroView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let slides: [IntroSlide] = [
        IntroSlide(
            systemIcon: "brain.head.profile",
            headline: "Le tue emozioni\nmeritano ascolto.",
            subtitle: "24 ore su 24.",
            body: "Nessuno dovrebbe sentirsi solo con le proprie emozioni, specialmente quando il mondo sembra troppo rumoroso."
        ),
        IntroSlide(
            systemIcon: "heart.text.square",
            headline: "La tua salute mentale\nnon aspetta il lunedì",
            subtitle: "Le sedute di terapia hanno orari. Tranquiz no.",
            features: [
                ("heart.fill", "Empatia", "Ogni parola è pensata per validare, mai per giudicare."),
                ("lock.fill", "Privacy", "Quello che dici resta tuo, protetto sul tuo dispositivo."),
                ("shield.fill", "Sicurezza", "Sistemi di rilevamento crisi integrati per la tua sicurezza.")
            ]
        ),
        IntroSlide(
            systemIcon: "quote.bubble.fill",
            headline: "Un luogo sicuro\nper dire tutto.",
            body: "\"Un luogo sicuro dove poter dire tutto quello che ti passa per la testa, senza mai sentirti giudicato o giudicata.\"\n\n— Team Tranquiz",
            badges: ["✓  Sempre disponibile, 24/7", "✓  100% privacy sul device", "✓  Dalla tua parte, sempre"]
        )
    ]

    private var isLastPage: Bool { currentPage == slides.count - 1 }

    private let bgGradient = LinearGradient(
        colors: [
            Color(red: 55 / 255, green: 15 / 255, blue: 95 / 255),
            Color(red: 20 / 255, green: 8 / 255, blue: 50 / 255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let accentGradient = LinearGradient(
        colors: [
            Color(red: 210 / 255, green: 170 / 255, blue: 255 / 255),
            Color(red: 160 / 255, green: 100 / 255, blue: 245 / 255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack(alignment: .top) {
            bgGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button("Salta") { onComplete() }
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.trailing, 24)
                    }
                }
                .frame(height: 50)
                .padding(.top, 4)

                // Slides carousel
                ZStack {
                    ForEach(slides.indices, id: \.self) { i in
                        slideContent(slides[i])
                            .opacity(i == currentPage ? 1 : 0)
                            .offset(x: i == currentPage ? 0 : (i < currentPage ? -40 : 40))
                            .animation(.easeInOut(duration: 0.35), value: currentPage)
                    }
                }

                // Bottom bar
                bottomBar
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Slide Content

    @ViewBuilder
    private func slideContent(_ slide: IntroSlide) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer(minLength: 16)

                // Icon
                Image(systemName: slide.systemIcon)
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundStyle(accentGradient)
                    .symbolRenderingMode(.hierarchical)

                // Headline + subtitle
                VStack(spacing: 10) {
                    Text(slide.headline)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    if let subtitle = slide.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 28)

                // Body text
                if let body = slide.body {
                    Text(body)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }

                // Features card
                if let features = slide.features {
                    featuresCard(features)
                }

                // Badges
                if let badges = slide.badges {
                    VStack(spacing: 12) {
                        ForEach(badges, id: \.self) { badge in
                            Text(badge)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }

                Spacer(minLength: 20)
            }
        }
    }

    private func featuresCard(_ features: [(icon: String, title: String, desc: String)]) -> some View {
        VStack(spacing: 18) {
            ForEach(features, id: \.title) { feature in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accentGradient)
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(feature.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text(feature.desc)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 22) {
            // Dots indicator
            HStack(spacing: 8) {
                ForEach(slides.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? Color.white : Color.white.opacity(0.3))
                        .frame(width: i == currentPage ? 22 : 8, height: 8)
                        .animation(.spring(duration: 0.35), value: currentPage)
                }
            }

            // Action button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if isLastPage {
                        onComplete()
                    } else {
                        currentPage += 1
                    }
                }
            } label: {
                Text(isLastPage ? "Inizia ora 🌱" : "Avanti")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255),
                                Color(red: 88 / 255, green: 28 / 255, blue: 200 / 255)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    WelcomeIntroView(onComplete: {})
}
