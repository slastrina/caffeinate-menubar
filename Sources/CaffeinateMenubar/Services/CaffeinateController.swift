import Foundation
import os

protocol CaffeinateProcess: AnyObject {
    var arguments: [String] { get }
    var terminationHandler: ((CaffeinateProcess) -> Void)? { get set }
    func run() throws
    func terminate()
}

typealias CaffeinateProcessFactory = @Sendable (_ arguments: [String]) -> CaffeinateProcess

enum CaffeinateError: Error, Equatable {
    case invalidConfig
}

@MainActor
final class CaffeinateController: ObservableObject {
    @Published private(set) var state: SessionState = .idle

    private let processFactory: CaffeinateProcessFactory
    private var process: CaffeinateProcess?
    private let logger = Logger(subsystem: "com.samuellastrina.caffeinatemenubar", category: "controller")

    init(processFactory: @escaping CaffeinateProcessFactory = defaultCaffeinateProcessFactory) {
        self.processFactory = processFactory
    }

    func start(_ config: SessionConfig) throws {
        guard config.isValid else {
            throw CaffeinateError.invalidConfig
        }

        if state.isRunning {
            stop()
        }

        let newProcess = processFactory(config.arguments)
        newProcess.terminationHandler = { [weak self] terminated in
            Task { @MainActor [weak self] in
                self?.handleTermination(of: terminated)
            }
        }

        try newProcess.run()
        process = newProcess
        state = .running(config: config, startedAt: Date())
        logger.info("started caffeinate with arguments \(config.arguments.joined(separator: " "), privacy: .public)")
    }

    func stop() {
        guard state.isRunning, let process else { return }
        logger.info("stopping caffeinate")
        process.terminate()
        self.process = nil
        state = .idle
    }

    private func handleTermination(of terminated: CaffeinateProcess) {
        guard process === terminated else { return }
        logger.info("caffeinate exited; returning to idle")
        process = nil
        state = .idle
    }
}

private final class RealCaffeinateProcess: CaffeinateProcess {
    let arguments: [String]
    var terminationHandler: ((CaffeinateProcess) -> Void)?

    private let process: Process

    init(arguments: [String]) {
        self.arguments = arguments
        self.process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = arguments
        process.standardOutput = nil
        process.standardError = nil
        process.terminationHandler = { [weak self] _ in
            guard let self else { return }
            self.terminationHandler?(self)
        }
    }

    func run() throws {
        try process.run()
    }

    func terminate() {
        if process.isRunning {
            process.terminate()
        }
    }
}

let defaultCaffeinateProcessFactory: CaffeinateProcessFactory = { arguments in
    RealCaffeinateProcess(arguments: arguments)
}
