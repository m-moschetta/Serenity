//
//  CrisisEmailTracker.swift
//  Serenity
//
//  Tracks when crisis emails were sent to enforce 24-hour rate limiting
//

import Foundation

final class CrisisEmailTracker {
    static let shared = CrisisEmailTracker()
    private init() {}

    private let lastEmailKey = "lastCrisisEmailSent"
    private let hours24InSeconds: TimeInterval = 24 * 60 * 60

    /// Checks if enough time has passed since last email (24 hours)
    /// - Returns: true if email can be sent, false if still within 24h window
    func canSendEmail() -> Bool {
        guard let lastSent = UserDefaults.standard.object(forKey: lastEmailKey) as? Date else {
            return true // Never sent before
        }

        let timeSinceLastEmail = Date().timeIntervalSince(lastSent)
        return timeSinceLastEmail >= hours24InSeconds
    }

    /// Records the current timestamp as when an email was sent
    func recordEmailSent() {
        UserDefaults.standard.set(Date(), forKey: lastEmailKey)
    }

    /// Gets the time remaining until next email can be sent (in seconds)
    /// - Returns: Seconds remaining, or nil if email can be sent now
    func timeUntilNextEmail() -> TimeInterval? {
        guard let lastSent = UserDefaults.standard.object(forKey: lastEmailKey) as? Date else {
            return nil // Can send now
        }

        let timeSinceLastEmail = Date().timeIntervalSince(lastSent)
        let remaining = hours24InSeconds - timeSinceLastEmail

        return remaining > 0 ? remaining : nil
    }

    /// Clears the tracking data (useful for testing)
    func reset() {
        UserDefaults.standard.removeObject(forKey: lastEmailKey)
    }
}
