import Testing
@testable import CaffeinateMenubar

@Suite("SessionConfig")
struct SessionConfigTests {
    @Test("Empty flags is invalid")
    func emptyFlagsInvalid() {
        let config = SessionConfig(flags: [])
        #expect(!config.isValid)
    }

    @Test("Flags only is valid")
    func flagsOnlyValid() {
        let config = SessionConfig(flags: .preventIdleSleep)
        #expect(config.isValid)
        #expect(config.arguments == ["-i"])
    }

    @Test("Zero duration is invalid")
    func zeroDurationInvalid() {
        let config = SessionConfig(flags: .preventIdleSleep, durationSeconds: 0)
        #expect(!config.isValid)
    }

    @Test("Negative duration is invalid")
    func negativeDurationInvalid() {
        let config = SessionConfig(flags: .preventIdleSleep, durationSeconds: -5)
        #expect(!config.isValid)
    }

    @Test("Positive duration appends -t in seconds")
    func durationArguments() {
        let config = SessionConfig(flags: .preventIdleSleep, durationSeconds: 3600)
        #expect(config.isValid)
        #expect(config.arguments == ["-i", "-t", "3600"])
    }

    @Test("Zero PID is invalid")
    func zeroPIDInvalid() {
        let config = SessionConfig(flags: .preventIdleSleep, targetPID: 0)
        #expect(!config.isValid)
    }

    @Test("Target PID appends -w")
    func targetPIDArguments() {
        let config = SessionConfig(flags: .preventIdleSleep, targetPID: 1234)
        #expect(config.isValid)
        #expect(config.arguments == ["-i", "-w", "1234"])
    }

    @Test("Flags + duration + PID combine in order: flags, -t, -w")
    func allArguments() {
        let config = SessionConfig(
            flags: [.preventIdleSleep, .preventDisplaySleep],
            durationSeconds: 1800,
            targetPID: 999
        )
        #expect(config.isValid)
        #expect(config.arguments == ["-i", "-d", "-t", "1800", "-w", "999"])
    }
}
