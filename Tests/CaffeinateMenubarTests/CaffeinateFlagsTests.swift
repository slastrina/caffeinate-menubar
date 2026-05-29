import Testing
@testable import CaffeinateMenubar

@Suite("CaffeinateFlags")
struct CaffeinateFlagsTests {
    @Test("Empty flags produce no arguments")
    func emptyFlags() {
        #expect(CaffeinateFlags().arguments == [])
    }

    @Test("Single flag emits its short option", arguments: [
        (CaffeinateFlags.preventIdleSleep,    "-i"),
        (CaffeinateFlags.preventDisplaySleep, "-d"),
        (CaffeinateFlags.preventDiskSleep,    "-m"),
        (CaffeinateFlags.preventSystemSleep,  "-s"),
    ])
    func singleFlag(flag: CaffeinateFlags, expected: String) {
        #expect(flag.arguments == [expected])
    }

    @Test("Flags emit in a stable order: -i, -d, -m, -s")
    func stableOrder() {
        let all: CaffeinateFlags = [
            .preventSystemSleep,
            .preventDiskSleep,
            .preventDisplaySleep,
            .preventIdleSleep,
        ]
        #expect(all.arguments == ["-i", "-d", "-m", "-s"])
    }

    @Test("Two-flag combinations include both options")
    func twoFlagCombination() {
        let combo: CaffeinateFlags = [.preventIdleSleep, .preventDisplaySleep]
        #expect(combo.arguments == ["-i", "-d"])
    }

    @Test("OptionSet contains works as expected")
    func containsSemantics() {
        let combo: CaffeinateFlags = [.preventIdleSleep, .preventDisplaySleep]
        #expect(combo.contains(.preventIdleSleep))
        #expect(combo.contains(.preventDisplaySleep))
        #expect(!combo.contains(.preventDiskSleep))
        #expect(!combo.contains(.preventSystemSleep))
    }
}
