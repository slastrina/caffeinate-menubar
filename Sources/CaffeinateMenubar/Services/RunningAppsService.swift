import Foundation
import AppKit
import Combine

struct RunningApp: Identifiable, Hashable {
    let pid: Int32
    let name: String
    let bundleIdentifier: String?

    var id: Int32 { pid }
}

@MainActor
final class RunningAppsService: ObservableObject {
    @Published private(set) var apps: [RunningApp] = []

    private var observers: [NSObjectProtocol] = []

    init() {
        refresh()
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        })
        observers.append(center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        })
    }

    // The service is an app-lifetime singleton (SharedServices), so explicit
    // observer cleanup in deinit is unnecessary — the observers are released
    // with the process. Skipping the deinit also avoids a Swift 6 nonisolated-
    // deinit error on the non-Sendable [any NSObjectProtocol] array.

    func refresh() {
        let running = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> RunningApp? in
                guard let name = app.localizedName else { return nil }
                return RunningApp(
                    pid: app.processIdentifier,
                    name: name,
                    bundleIdentifier: app.bundleIdentifier
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        apps = running
    }
}
