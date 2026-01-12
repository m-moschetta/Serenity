//
//  NotificationSettingsSection.swift
//  Serenity
//
//  Sezione impostazioni per le notifiche di check-in
//

import SwiftUI

struct NotificationSettingsSection: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("morningCheckInHour") private var morningHour: Int = 8
    @AppStorage("morningCheckInMinute") private var morningMinute: Int = 0
    @AppStorage("eveningCheckInHour") private var eveningHour: Int = 21
    @AppStorage("eveningCheckInMinute") private var eveningMinute: Int = 0
    @AppStorage("weeklyCheckInEnabled") private var weeklyEnabled: Bool = true

    @State private var morningTime: Date = Date()
    @State private var eveningTime: Date = Date()
    @State private var showingPermissionAlert = false

    var body: some View {
        Section("Notifiche Check-in") {
            Toggle("Attiva notifiche", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, newValue in
                    if newValue {
                        requestPermissionAndSchedule()
                    } else {
                        NotificationManager.shared.cancelAll()
                    }
                }

            if notificationsEnabled {
                // Orario mattutino
                HStack {
                    Label("Check-in mattutino", systemImage: "sun.max.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    DatePicker(
                        "",
                        selection: $morningTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .onChange(of: morningTime) { _, newValue in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        morningHour = components.hour ?? 8
                        morningMinute = components.minute ?? 0
                        NotificationManager.shared.rescheduleAll()
                    }
                }

                // Orario serale
                HStack {
                    Label("Check-in serale", systemImage: "moon.fill")
                        .foregroundStyle(.indigo)
                    Spacer()
                    DatePicker(
                        "",
                        selection: $eveningTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .onChange(of: eveningTime) { _, newValue in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        eveningHour = components.hour ?? 21
                        eveningMinute = components.minute ?? 0
                        NotificationManager.shared.rescheduleAll()
                    }
                }

                // Riepilogo settimanale
                Toggle(isOn: $weeklyEnabled) {
                    Label("Riepilogo settimanale", systemImage: "calendar")
                        .foregroundStyle(.purple)
                }
                .onChange(of: weeklyEnabled) { _, _ in
                    NotificationManager.shared.rescheduleAll()
                }

                Text("Riceverai un riepilogo ogni domenica mattina con consigli personalizzati.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            setupInitialTimes()
        }
        .alert("Permesso notifiche", isPresented: $showingPermissionAlert) {
            Button("Apri Impostazioni") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Annulla", role: .cancel) {
                notificationsEnabled = false
            }
        } message: {
            Text("Per ricevere i promemoria di check-in, abilita le notifiche nelle impostazioni del dispositivo.")
        }
    }

    private func setupInitialTimes() {
        var morningComponents = DateComponents()
        morningComponents.hour = morningHour
        morningComponents.minute = morningMinute
        if let date = Calendar.current.date(from: morningComponents) {
            morningTime = date
        }

        var eveningComponents = DateComponents()
        eveningComponents.hour = eveningHour
        eveningComponents.minute = eveningMinute
        if let date = Calendar.current.date(from: eveningComponents) {
            eveningTime = date
        }
    }

    private func requestPermissionAndSchedule() {
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            await MainActor.run {
                if granted {
                    NotificationManager.shared.rescheduleAll()
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
}
