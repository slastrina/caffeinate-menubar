import SwiftUI

struct MenuBarLabelView: View {
    let state: SessionState

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if case .running(let config, let startedAt) = state,
           let duration = config.durationSeconds {
            let remaining = max(0, duration - Int(now.timeIntervalSince(startedAt)))
            Label {
                Text(Self.compactRemaining(seconds: remaining))
            } icon: {
                Image(systemName: "cup.and.saucer.fill")
            }
            .onReceive(timer) { now = $0 }
        } else {
            Image(systemName: state.isRunning ? "cup.and.saucer.fill" : "cup.and.saucer")
        }
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
