import Testing
@testable import CaffeinateMenubar

@Suite("MenuBarLabelView.compactRemaining")
struct MenuBarLabelViewTests {
    @Test("Sub-minute renders as seconds", arguments: [
        (0, "0s"),
        (1, "1s"),
        (45, "45s"),
        (59, "59s"),
    ])
    func seconds(input: Int, expected: String) {
        #expect(MenuBarLabelView.compactRemaining(seconds: input) == expected)
    }

    @Test("Sub-hour renders as minutes", arguments: [
        (60, "1m"),
        (90, "1m"),
        (1500, "25m"),
        (3599, "59m"),
    ])
    func minutes(input: Int, expected: String) {
        #expect(MenuBarLabelView.compactRemaining(seconds: input) == expected)
    }

    @Test("Hour-plus renders as hours + minutes", arguments: [
        (3600, "1h"),
        (3660, "1h 1m"),
        (5400, "1h 30m"),
        (7200, "2h"),
        (9015, "2h 30m"),
    ])
    func hours(input: Int, expected: String) {
        #expect(MenuBarLabelView.compactRemaining(seconds: input) == expected)
    }
}
