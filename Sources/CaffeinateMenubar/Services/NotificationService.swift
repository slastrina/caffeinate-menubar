import Foundation
import UserNotifications
import os

@MainActor
final class NotificationService {
    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.samuellastrina.caffeinatemenubar", category: "notifications")

    /// Best-effort authorization request. Repeat calls are cheap — the system
    /// only shows the prompt the first time. If the user denies we silently
    /// skip future notifications.
    func requestAuthorizationIfNeeded() {
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            if let error {
                self?.logger.error("notification authorization request failed: \(error.localizedDescription, privacy: .public)")
                return
            }
            self?.logger.info("notification authorization \(granted ? "granted" : "denied", privacy: .public)")
        }
    }

    func notifySessionEnded(args: String) {
        let content = UNMutableNotificationContent()
        content.title = "Caffeinate session ended"
        content.body = args.isEmpty ? "Your Mac is free to sleep again." : "Stopped \(args). Your Mac is free to sleep again."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request) { [weak self] error in
            if let error {
                self?.logger.error("failed to post session-ended notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
