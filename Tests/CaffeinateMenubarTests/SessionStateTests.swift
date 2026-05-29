import Foundation
import Testing
@testable import CaffeinateMenubar

@Suite("SessionState")
struct SessionStateTests {
    @Test("idle is not running and has no config")
    func idle() {
        let state = SessionState.idle
        #expect(!state.isRunning)
        #expect(state.runningConfig == nil)
    }

    @Test("running exposes config")
    func running() {
        let config = SessionConfig(flags: .preventIdleSleep, durationSeconds: 60)
        let state = SessionState.running(config: config, startedAt: Date())
        #expect(state.isRunning)
        #expect(state.runningConfig == config)
    }
}
