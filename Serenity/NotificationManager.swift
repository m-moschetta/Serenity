//
//  NotificationManager.swift
//  Serenity
//
//  Manager singleton per gestire le notifiche locali dell'app
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    // Identificatori notifiche
    private enum Identifiers {
        static let morningCheckIn = "com.tranquiz.morning-checkin"
        static let eveningCheckIn = "com.tranquiz.evening-checkin"
        static let weeklyCheckIn = "com.tranquiz.weekly-checkin"
    }

    // Stato per gestire apertura da notifica
    @Published var pendingCheckInType: CheckInType?
    @Published var permissionGranted: Bool = false

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkPermissionStatus()
    }

    // MARK: - Permission

    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.permissionGranted = granted
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    // MARK: - Schedule Morning

    func scheduleMorningCheckIn(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Buongiorno!"
        content.body = "Prenditi un momento per riflettere sulla giornata che ti aspetta."
        content.sound = .default
        content.userInfo = ["type": "morning"]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifiers.morningCheckIn,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling morning notification: \(error)")
            }
        }
    }

    // MARK: - Schedule Evening

    func scheduleEveningCheckIn(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Come e andata la giornata?"
        content.body = "Raccontami come ti senti stasera."
        content.sound = .default
        content.userInfo = ["type": "evening"]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifiers.eveningCheckIn,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling evening notification: \(error)")
            }
        }
    }

    // MARK: - Schedule Weekly

    func scheduleWeeklyCheckIn(weekday: Int = 1, hour: Int = 10) {
        // weekday: 1 = Domenica, 7 = Sabato (iOS Calendar)
        let content = UNMutableNotificationContent()
        content.title = "Riepilogo settimanale"
        content.body = "Vediamo insieme come e andata questa settimana."
        content.sound = .default
        content.userInfo = ["type": "weekly"]

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifiers.weeklyCheckIn,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling weekly notification: \(error)")
            }
        }
    }

    // MARK: - Cancel

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancelMorning() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Identifiers.morningCheckIn]
        )
    }

    func cancelEvening() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Identifiers.eveningCheckIn]
        )
    }

    func cancelWeekly() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Identifiers.weeklyCheckIn]
        )
    }

    // MARK: - Reschedule All

    func rescheduleAll() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "notificationsEnabled") else {
            cancelAll()
            return
        }

        let morningHour = defaults.integer(forKey: "morningCheckInHour")
        let morningMinute = defaults.integer(forKey: "morningCheckInMinute")
        let eveningHour = defaults.integer(forKey: "eveningCheckInHour")
        let eveningMinute = defaults.integer(forKey: "eveningCheckInMinute")
        let weeklyEnabled = defaults.bool(forKey: "weeklyCheckInEnabled")

        cancelAll()

        scheduleMorningCheckIn(
            hour: morningHour == 0 ? 8 : morningHour,
            minute: morningMinute
        )
        scheduleEveningCheckIn(
            hour: eveningHour == 0 ? 21 : eveningHour,
            minute: eveningMinute
        )

        if weeklyEnabled {
            scheduleWeeklyCheckIn()
        }
    }

    func clearPending() {
        pendingCheckInType = nil
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String {
            DispatchQueue.main.async {
                switch type {
                case "morning":
                    self.pendingCheckInType = .morning
                case "evening":
                    self.pendingCheckInType = .evening
                case "weekly":
                    self.pendingCheckInType = .weekly
                default:
                    break
                }
            }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostra notifica anche quando app e in foreground
        completionHandler([.banner, .sound])
    }
}
