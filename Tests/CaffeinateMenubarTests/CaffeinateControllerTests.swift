import Foundation
import Testing
@testable import CaffeinateMenubar

@MainActor
final class MockCaffeinateProcess: CaffeinateProcess {
    let arguments: [String]
    var terminationHandler: ((CaffeinateProcess) -> Void)?
    private(set) var runCallCount = 0
    private(set) var terminateCallCount = 0
    private(set) var isRunning = false

    init(arguments: [String]) {
        self.arguments = arguments
    }

    func run() throws {
        runCallCount += 1
        isRunning = true
    }

    func terminate() {
        terminateCallCount += 1
        guard isRunning else { return }
        isRunning = false
        terminationHandler?(self)
    }

    func simulateExit() {
        guard isRunning else { return }
        isRunning = false
        terminationHandler?(self)
    }
}

@MainActor
final class ProcessRecorder {
    private(set) var spawned: [MockCaffeinateProcess] = []

    nonisolated func makeFactory() -> CaffeinateProcessFactory {
        return { [weak self] arguments in
            MainActor.assumeIsolated {
                let process = MockCaffeinateProcess(arguments: arguments)
                self?.spawned.append(process)
                return process
            }
        }
    }
}

@Suite("CaffeinateController")
@MainActor
struct CaffeinateControllerTests {
    @Test("Starts idle")
    func startsIdle() {
        let recorder = ProcessRecorder()
        let controller = CaffeinateController(processFactory: recorder.makeFactory())
        #expect(controller.state == .idle)
    }

    @Test("Invalid config throws and leaves state idle")
    func invalidConfigThrows() {
        let recorder = ProcessRecorder()
        let controller = CaffeinateController(processFactory: recorder.makeFactory())
        let invalid = SessionConfig(flags: [])
        #expect(throws: CaffeinateError.invalidConfig) {
            try controller.start(invalid)
        }
        #expect(controller.state == .idle)
        #expect(recorder.spawned.isEmpty)
    }

    @Test("Valid config starts process and transitions to running")
    func startTransitions() throws {
        let recorder = ProcessRecorder()
        let controller = CaffeinateController(processFactory: recorder.makeFactory())
        let config = SessionConfig(flags: .preventIdleSleep, durationSeconds: 60)

        try controller.start(config)

        #expect(controller.state.isRunning)
        #expect(controller.state.runningConfig == config)
        #expect(recorder.spawned.count == 1)
        #expect(recorder.spawned[0].arguments == ["-i", "-t", "60"])
        #expect(recorder.spawned[0].runCallCount == 1)
    }

    @Test("Stop terminates the process and returns to idle")
    func stopTerminates() throws {
        let recorder = ProcessRecorder()
        let controller = CaffeinateController(processFactory: recorder.makeFactory())
        try controller.start(SessionConfig(flags: .preventIdleSleep))

        controller.stop()

        #expect(controller.state == .idle)
        #expect(recorder.spawned[0].terminateCallCount == 1)
    }

    @Test("Stop on idle is a no-op")
    func stopIdleNoOp() {
        let recorder = ProcessRecorder()
        let controller = CaffeinateController(processFactory: recorder.makeFactory())
        controller.stop()
        #expect(controller.state == .idle)
        #expect(recorder.spawned.isEmpty)
    }

    @Test("Process exiting on its own transitions back to idle")
    func autoTerminateOnExit() async throws {
        let recorder = ProcessRecorder()
        let controller = CaffeinateController(processFactory: recorder.makeFactory())
        try controller.start(SessionConfig(flags: .preventIdleSleep, durationSeconds: 1))

        recorder.spawned[0].simulateExit()
        await Task.yield()

        #expect(controller.state == .idle)
    }

    @Test("Starting while already running stops the previous process")
    func startReplacesRunning() throws {
        let recorder = ProcessRecorder()
        let controller = CaffeinateController(processFactory: recorder.makeFactory())
        try controller.start(SessionConfig(flags: .preventIdleSleep))
        try controller.start(SessionConfig(flags: .preventDisplaySleep))

        #expect(recorder.spawned.count == 2)
        #expect(recorder.spawned[0].terminateCallCount == 1)
        #expect(recorder.spawned[1].arguments == ["-d"])
        #expect(controller.state.runningConfig?.flags == .preventDisplaySleep)
    }

    @Test("Natural termination publishes didEndSessionNaturally")
    func naturalEndPublishes() async throws {
        let recorder = ProcessRecorder()
        let controller = CaffeinateController(processFactory: recorder.makeFactory())
        let config = SessionConfig(flags: .preventIdleSleep, durationSeconds: 1)

        var received: [SessionConfig] = []
        let cancellable = controller.didEndSessionNaturally.sink { received.append($0) }
        defer { cancellable.cancel() }

        try controller.start(config)
        recorder.spawned[0].simulateExit()
        await Task.yield()

        #expect(received == [config])
    }

    @Test("Manual stop does not publish didEndSessionNaturally")
    func manualStopDoesNotPublish() throws {
        let recorder = ProcessRecorder()
        let controller = CaffeinateController(processFactory: recorder.makeFactory())

        var received: [SessionConfig] = []
        let cancellable = controller.didEndSessionNaturally.sink { received.append($0) }
        defer { cancellable.cancel() }

        try controller.start(SessionConfig(flags: .preventIdleSleep, durationSeconds: 60))
        controller.stop()

        #expect(received.isEmpty)
    }
}
