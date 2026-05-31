import Foundation
import os

struct AvailableUpdate: Equatable {
    let version: String
    let releasePageURL: URL
}

@MainActor
final class UpdateCheckerService: ObservableObject {
    @Published private(set) var availableUpdate: AvailableUpdate?
    @Published private(set) var isChecking: Bool = false

    private let logger = Logger(subsystem: "com.samuellastrina.caffeinatemenubar", category: "updates")
    private let endpoint = URL(string: "https://api.github.com/repos/slastrina/caffeinate-menubar/releases/latest")!
    private let recheckInterval: TimeInterval = 24 * 60 * 60
    private var periodicTask: Task<Void, Never>?

    /// CFBundleShortVersionString from the .app bundle. Returns nil for unbundled
    /// `swift run` builds — in that case the checker stays quiet to avoid
    /// flagging every release as an update during development.
    var currentVersion: String? {
        guard let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              v != "0.0.0", !v.isEmpty else { return nil }
        return v
    }

    func start() {
        guard currentVersion != nil else {
            logger.debug("no bundle version — skipping update checks")
            return
        }
        Task { await self.checkNow() }
        let intervalNanos = UInt64(recheckInterval * 1_000_000_000)
        periodicTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: intervalNanos)
                await self?.checkNow()
            }
        }
    }

    func checkNow() async {
        guard let current = currentVersion else { return }
        isChecking = true
        defer { isChecking = false }

        var request = URLRequest(url: endpoint)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("CaffeinateMenubar/\(current)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                logger.error("update check non-200: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return
            }
            let payload = try JSONDecoder().decode(GitHubReleasePayload.self, from: data)
            let remote = Self.stripV(payload.tagName)
            if Self.isNewer(remote: remote, current: current) {
                availableUpdate = AvailableUpdate(version: remote, releasePageURL: payload.htmlURL)
                logger.info("update available: \(remote, privacy: .public) (running \(current, privacy: .public))")
            } else {
                availableUpdate = nil
            }
        } catch {
            logger.error("update check failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    nonisolated static func stripV(_ tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    /// Numeric semver-ish comparison. "0.1.10" > "0.1.2" because of `.numeric`.
    nonisolated static func isNewer(remote: String, current: String) -> Bool {
        remote.compare(current, options: .numeric) == .orderedDescending
    }
}

private struct GitHubReleasePayload: Decodable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
