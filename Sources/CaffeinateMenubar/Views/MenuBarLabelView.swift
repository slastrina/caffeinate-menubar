import SwiftUI

struct MenuBarLabelView: View {
    let state: SessionState

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// Tint everything red once the session has fewer than this many seconds
    /// left, giving peripheral awareness without needing to open the dropdown.
    private static let urgencyWindow: Int = 5 * 60

    var body: some View {
        // Single, type-stable HStack so MenuBarExtra doesn't pre-allocate a
        // hidden slot from a @ViewBuilder conditional. Text("") collapses to
        // zero width when idle, giving us just the icon; running-with-timer
        // populates the Text with the countdown.
        HStack(spacing: countdownText.isEmpty ? 0 : 4) {
            Image(systemName: state.isRunning ? "cup.and.saucer.fill" : "cup.and.saucer")
                .symbolRenderingMode(isNearingEnd ? .palette : .monochrome)
                .foregroundStyle(isNearingEnd ? Color.red : Color.primary)
            Text(countdownText)
                .monospacedDigit()
                .foregroundStyle(isNearingEnd ? Color.red : Color.primary)
        }
        .onReceive(timer) { now = $0 }
    }

    private var countdownText: String {
        guard let remaining = remainingSeconds else { return "" }
        return Self.compactRemaining(seconds: remaining)
    }

    private var isNearingEnd: Bool {
        guard let remaining = remainingSeconds else { return false }
        return remaining > 0 && remaining <= Self.urgencyWindow
    }

    private var remainingSeconds: Int? {
        guard case .running(let config, let startedAt) = state,
              let duration = config.durationSeconds else {
            return nil
        }
        return max(0, duration - Int(now.timeIntervalSince(startedAt)))
    }

    /// Glanceable countdown for the menubar — minute-resolution above 1m,
    /// seconds in the final stretch. Examples: "1h 23m", "23m", "45s".
    static func compactRemaining(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        return mins == 0 ? "\(hours)h" : "\(hours)h \(mins)m"
    }
}
