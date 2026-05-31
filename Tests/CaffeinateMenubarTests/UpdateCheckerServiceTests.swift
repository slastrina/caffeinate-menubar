import Testing
@testable import CaffeinateMenubar

@Suite("UpdateCheckerService")
struct UpdateCheckerServiceTests {
    @Test("Strips leading v from tag")
    func stripsV() {
        #expect(UpdateCheckerService.stripV("v0.1.2") == "0.1.2")
        #expect(UpdateCheckerService.stripV("0.1.2") == "0.1.2")
        #expect(UpdateCheckerService.stripV("v1.0.0-beta") == "1.0.0-beta")
    }

    @Test("Identifies newer remote version", arguments: [
        ("0.1.2", "0.1.1", true),
        ("0.2.0", "0.1.99", true),
        ("0.1.10", "0.1.2", true),
        ("1.0.0", "0.9.9", true),
    ])
    func newerRemote(remote: String, current: String, expected: Bool) {
        #expect(UpdateCheckerService.isNewer(remote: remote, current: current) == expected)
    }

    @Test("Same or older remote version does not trigger an update", arguments: [
        ("0.1.1", "0.1.1"),
        ("0.1.0", "0.1.1"),
        ("0.1.2", "0.2.0"),
        ("0.1.2", "0.1.10"),
    ])
    func notNewer(remote: String, current: String) {
        #expect(!UpdateCheckerService.isNewer(remote: remote, current: current))
    }
}
