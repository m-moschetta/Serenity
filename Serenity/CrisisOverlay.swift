import SwiftUI
import UIKit

struct CrisisOverlayView: View {
    @Binding var isPresented: Bool
    // Optional overrides from tool use
    var overridePrimaryNumber: String? = nil
    var customMessage: String? = nil
    var overrideExtraLabel: String? = nil
    var overrideExtraNumber: String? = nil
    @AppStorage("crisisPrimaryNumber") private var crisisPrimaryNumber: String = ""
    @AppStorage("crisisExtraLabel") private var crisisExtraLabel: String = ""
    @AppStorage("crisisExtraNumber") private var crisisExtraNumber: String = ""

    // Numeri di emergenza predefiniti per l'Italia
    private let emergencyContacts = [
        EmergencyContact(
            number: "112",
            label: "Emergenze",
            description: "Numero Unico Emergenze",
            icon: "exclamationmark.triangle.fill",
            color: Color.red
        ),
        EmergencyContact(
            number: "0223272327",
            label: "Telefono Amico",
            description: "Supporto psicologico 10-24",
            icon: "heart.fill",
            color: Color.blue
        ),
        EmergencyContact(
            number: "0677208977",
            label: "Samaritans",
            description: "Ascolto 13-22",
            icon: "person.2.fill",
            color: Color.green
        )
    ]

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { /* Prevent dismiss on background tap */ }

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white, .red)
                        .shadow(radius: 10)

                    Text("Non sei sol*")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text("Chiedere aiuto è un atto di coraggio")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .background(
                    LinearGradient(
                        colors: [.red.opacity(0.8), .red.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                // Content
                VStack(spacing: 20) {
                    // Custom message or default
                    VStack(spacing: 8) {
                        if let msg = customMessage, !msg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(msg)
                                .font(.body)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("È importante che tu parli con una persona reale in grado di aiutarti. Questi numeri sono gestiti da professionisti preparati:")
                                .font(.body)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)

                    // Emergency contacts
                    VStack(spacing: 12) {
                        ForEach(emergencyContacts) { contact in
                            EmergencyButton(contact: contact) {
                                dial(contact.number)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Additional info
                    VStack(spacing: 8) {
                        Text("📞 Puoi chiamare subito con un tap")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Questi servizi sono gratuiti e riservati")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 20)
                .background(Color(.systemBackground))

                // Close button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Chiudi")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gray.opacity(0.8))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
            .padding(.horizontal, 20)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
    }

    private func dial(_ number: String) {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)") else { return }

        // Aggiungi un feedback tattile quando l'utente tocca per chiamare
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        UIApplication.shared.open(url)
    }
}

// MARK: - Supporting Types

struct EmergencyContact: Identifiable {
    let id = UUID()
    let number: String
    let label: String
    let description: String
    let icon: String
    let color: Color
}

struct EmergencyButton: View {
    let contact: EmergencyContact
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: contact.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(contact.color)
                            .shadow(color: contact.color.opacity(0.3), radius: 4, x: 0, y: 2)
                    )

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.label)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(contact.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(contact.number)
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Call icon
                Image(systemName: "phone.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.green)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(contact.color.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .buttonStyle(PlainButtonStyle())
    }
}

struct CrisisSettingsView: View {
    @AppStorage("crisisPrimaryNumber") private var crisisPrimaryNumber: String = ""
    @AppStorage("crisisExtraLabel") private var crisisExtraLabel: String = ""
    @AppStorage("crisisExtraNumber") private var crisisExtraNumber: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Numero principale emergenze (es. 112)", text: $crisisPrimaryNumber)
                .keyboardType(.phonePad)
            TextField("Etichetta numero secondario (es. Servizio Ascolto)", text: $crisisExtraLabel)
            TextField("Numero secondario (facoltativo)", text: $crisisExtraNumber)
                .keyboardType(.phonePad)
            Text("Usa solo numeri ufficiali e fonti certificate.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
