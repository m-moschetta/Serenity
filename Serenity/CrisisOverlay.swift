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

    private var primaryNumber: String {
        let trimmed = (overridePrimaryNumber ?? crisisPrimaryNumber).trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        // Fallback predefinito: 112 (numero unico emergenze in molti paesi europei)
        return "112"
    }

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(.yellow)
                Text("Serve aiuto immediato")
                    .font(.title2).bold()
                VStack(spacing: 10) {
                    if let msg = customMessage, !msg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(msg)
                    } else {
                        Text("Capisco che in questo momento potresti sentirti sopraffatt* da emozioni molto intense. Non sei sol*: chiedere aiuto è un atto di grande forza.")
                        Text("È importante che tu parli con una persona reale in grado di aiutarti davvero. Ti invito subito a contattare uno di questi numeri ufficiali.")
                    }
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal)

                VStack(spacing: 10) {
                    Button(action: { dial(primaryNumber) }) {
                        HStack { Image(systemName: "phone.fill"); Text("Chiama " + primaryNumber) }
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    let extraNumber = (overrideExtraNumber ?? crisisExtraNumber).trimmingCharacters(in: .whitespacesAndNewlines)
                    let extraLabel = (overrideExtraLabel ?? crisisExtraLabel)
                    if !extraNumber.isEmpty {
                        Button(action: { dial(extraNumber) }) {
                            HStack {
                                Image(systemName: "phone");
                                Text((extraLabel.isEmpty ? "Numero di supporto" : extraLabel) + " " + extraNumber)
                            }.frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)

                Button("Chiudi") { isPresented = false }
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)))
            .padding()
        }
    }

    private func dial(_ number: String) {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
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
