import Foundation

enum SessionState: Equatable {
    case idle
    case running(config: SessionConfig, startedAt: Date)

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    var runningConfig: SessionConfig? {
        if case .running(let config, _) = self { return config }
        return nil
    }
}
