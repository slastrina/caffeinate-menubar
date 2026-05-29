import Foundation

struct SessionConfig: Equatable {
    var flags: CaffeinateFlags
    var durationSeconds: Int?
    var targetPID: Int32?
    var targetAppName: String?

    var isValid: Bool {
        guard !flags.isEmpty else { return false }
        if let duration = durationSeconds, duration <= 0 { return false }
        if let pid = targetPID, pid <= 0 { return false }
        return true
    }

    var arguments: [String] {
        var args = flags.arguments
        if let duration = durationSeconds {
            args.append("-t")
            args.append(String(duration))
        }
        if let pid = targetPID {
            args.append("-w")
            args.append(String(pid))
        }
        return args
    }
}
