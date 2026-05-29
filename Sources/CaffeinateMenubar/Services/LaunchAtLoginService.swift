import Foundation
import ServiceManagement
import os

@MainActor
final class LaunchAtLoginService: ObservableObject {
    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var lastError: String?

    private let logger = Logger(subsystem: "com.samuellastrina.caffeinatemenubar", category: "launch-at-login")

    init() {
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            logger.error("launch-at-login toggle failed: \(error.localizedDescription, privacy: .public)")
        }
        refresh()
    }
}
