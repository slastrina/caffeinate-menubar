# Spec: Caffeinate Menubar

A macOS menubar app that wraps the system `caffeinate` command with a configurable
flag picker, timed sessions, and the ability to tie a session to a running app.

---

## Objective

**What:** A lightweight macOS menubar app that lets the user start a `caffeinate`
session with their chosen combination of flags (prevent idle sleep, display sleep,
disk sleep, system sleep), an optional duration, and an optional "stay awake while
this app runs" target.

**Why:** The built-in `caffeinate` CLI is powerful but inaccessible to non-terminal
users, and existing menubar tools (e.g. Amphetamine, KeepingYouAwake) don't expose
the full flag matrix or feel native on modern macOS. This app gives power users a
small, native, SwiftUI-based control surface for the exact behavior they want.

**Who:** The author (primary), plus anyone who finds the GitHub release.

**User stories:**
- As a developer, I want to keep my Mac awake only while a specific app (e.g. a
  long-running build, Zoom call, or simulator) is running, so I don't have to
  remember to disable it.
- As a presenter, I want to prevent display sleep for exactly 2 hours during a
  meeting, then have it auto-stop.
- As a user who already understands `caffeinate`, I want explicit control over
  which flags are passed, not a single "Activate" button that hides them.

---

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI with `MenuBarExtra` (the modern menubar API)
- **Minimum macOS:** 13.0 (Ventura) — required for `MenuBarExtra` and the modern
  `SMAppService` launch-at-login API
- **Build system:** Swift Package Manager (executable product). Xcode is
  optional; the project builds and runs with `swift build` / `swift run` using
  Command Line Tools alone.
- **Process control:** `Foundation.Process` to spawn `/usr/bin/caffeinate`
- **Running-app enumeration:** `NSWorkspace.shared.runningApplications`
- **Launch at login:** `ServiceManagement.SMAppService.mainApp`
- **Persistence:** `UserDefaults` (last-used flags, preferences) — no database
- **No third-party runtime dependencies.** Dev-only tools (SwiftLint, SwiftFormat)
  are acceptable; flag in a PR before adding.

---

## Commands

```bash
# Build (Debug)
swift build

# Build (Release, for GitHub distribution)
swift build -c release

# Run from terminal (foreground; Ctrl-C to quit)
swift run

# Run unit tests
swift test

# Lint (if SwiftLint is added later)
swiftlint

# Open in Xcode (optional — Xcode auto-generates a workspace for SPM packages)
open Package.swift
```

---

## Project Structure

```
caffeinate_menubar/
├── SPEC.md                              → This document
├── README.md                            → User-facing install + usage
├── Package.swift                        → SPM manifest (executable, macOS 13+)
├── Sources/
│   └── CaffeinateMenubar/               → App source
│       ├── CaffeinateMenubarApp.swift   → @main App + MenuBarExtra
│       │                                  + NSApp.setActivationPolicy(.accessory)
│       ├── Models/
│       │   ├── CaffeinateFlags.swift    → OptionSet (-i, -d, -m, -s) → argv
│       │   ├── SessionConfig.swift      → Flags + duration + optional target PID
│       │   └── SessionState.swift       → Idle / Running(config, startedAt)
│       ├── Services/
│       │   ├── CaffeinateController.swift  → Owns the Process, start/stop logic
│       │   ├── RunningAppsService.swift    → Wraps NSWorkspace for app picker
│       │   └── LaunchAtLoginService.swift  → SMAppService wrapper
│       └── Views/
│           ├── MenuBarRootView.swift    → The dropdown content
│           ├── FlagPickerView.swift     → Toggles for each caffeinate flag
│           ├── DurationPickerView.swift → None / 30m / 1h / 2h / custom
│           └── AppPickerView.swift      → "Stay awake while X runs"
├── Tests/
│   └── CaffeinateMenubarTests/          → XCTest target
│       ├── CaffeinateFlagsTests.swift   → Flag → argv string array
│       ├── SessionConfigTests.swift     → Config validation
│       └── CaffeinateControllerTests.swift  → Start/stop with a mock process
└── .github/
    └── workflows/
        └── release.yml                  → Build + zip + attach to GitHub release
                                          (signing/notarization added in a
                                          follow-up release)
```

**Notes on SPM vs Xcode project:**
- No `Info.plist` is committed. The "no Dock icon" behavior comes from calling
  `NSApp.setActivationPolicy(.accessory)` in the App's initializer — this is
  the SPM-friendly equivalent of `LSUIElement=YES`.
- No `Assets.xcassets`. Icons use SF Symbols via SwiftUI's `Image(systemName:)`.
- Distribution is a built `.app` bundle assembled by the release workflow
  (binary + minimal generated `Info.plist`), not a raw SPM binary.

---

## Code Style

Swift API Design Guidelines, with these specifics:

```swift
// Models are value types. Use enums with associated values for state machines.
enum SessionState: Equatable {
    case idle
    case running(config: SessionConfig, startedAt: Date)
}

// Flags are an OptionSet — composable, testable, maps cleanly to argv.
struct CaffeinateFlags: OptionSet {
    let rawValue: Int
    static let preventIdleSleep    = CaffeinateFlags(rawValue: 1 << 0)  // -i
    static let preventDisplaySleep = CaffeinateFlags(rawValue: 1 << 1)  // -d
    static let preventDiskSleep    = CaffeinateFlags(rawValue: 1 << 2)  // -m
    static let preventSystemSleep  = CaffeinateFlags(rawValue: 1 << 3)  // -s

    var arguments: [String] {
        var args: [String] = []
        if contains(.preventIdleSleep)    { args.append("-i") }
        if contains(.preventDisplaySleep) { args.append("-d") }
        if contains(.preventDiskSleep)    { args.append("-m") }
        if contains(.preventSystemSleep)  { args.append("-s") }
        return args
    }
}

// Services are classes with a clear single responsibility and protocol-backed
// so they can be mocked in tests.
protocol CaffeinateControlling: AnyObject {
    var state: SessionState { get }
    func start(_ config: SessionConfig) throws
    func stop()
}
```

Conventions:
- 4-space indent, no tabs
- `final class` by default; only drop `final` when subclassing is intentional
- `@MainActor` on UI/service types that touch UIKit/SwiftUI state
- Force-unwrap (`!`) and force-try (`try!`) require an inline comment justifying
  the invariant, or they don't get merged
- No `print()` in committed code — use `os_log` / `Logger`

---

## Testing Strategy

**Framework:** XCTest (built in).

**What gets unit-tested (must have tests):**
- `CaffeinateFlags.arguments` — exhaustive coverage of flag combinations
- `SessionConfig` validation (e.g. duration > 0, no conflicting flags)
- `CaffeinateController` start/stop state transitions, using a `Process`-injectable
  seam (protocol over `Process`, so tests don't actually spawn `/usr/bin/caffeinate`)
- Duration arithmetic (1h = 3600 seconds → `-t 3600`)

**What gets manually verified (documented in README):**
- Menubar icon swaps between active and inactive states
- Selecting an app via the picker and quitting that app stops caffeinate
- Launch-at-login toggle survives reboot
- Notarized build opens cleanly on a clean Mac (no Gatekeeper prompt)

**Coverage target:** ≥80% on `Models/` and `Services/`. No coverage requirement
on `Views/` — UI is verified manually.

**Test location:** `CaffeinateMenubarTests/` — one test file per source file,
matching name + `Tests` suffix.

---

## Boundaries

**Always do:**
- Run `swift test` locally before pushing
- Add tests for every new flag, duration, or state transition
- Use `Logger` (`os.log`) for diagnostics — never `print()`
- Update SPEC.md when scope or design changes, in the same PR as the code
- Reference the spec section in PR descriptions ("implements §Features → Timed sessions")

**Ask first:**
- Adding any third-party dependency (SPM package)
- Raising the minimum macOS version above 13.0
- Changing the `UserDefaults` schema (must include a migration)
- Modifying `.github/workflows/release.yml` or signing config
- Adding any feature not listed in this spec

**Never do:**
- Commit secrets, signing certificates, provisioning profiles, or App Store Connect
  API keys — these go in GitHub Actions secrets only
- Use `sudo` from inside the app or spawn anything other than `/usr/bin/caffeinate`
- Remove or skip failing tests without an accompanying issue and approval
- Add signing/notarization to v1 without an explicit scope-change decision
  (v1 is intentionally unsigned; signing is a follow-up release)

---

## Features (v1 scope)

Derived from the answers given:

1. **Configurable flag picker.** Toggles for `-i`, `-d`, `-m`, `-s` shown in the
   menubar dropdown. At least one flag must be selected to enable "Start".
   Last-used selection persists in `UserDefaults`.

2. **Timed sessions.** Duration picker: `Indefinite` / `30 min` / `1 hour` /
   `2 hours` / `Custom…` (custom = number input in minutes). When a duration is
   set, the app passes `-t <seconds>` to caffeinate and shows a countdown in the
   dropdown.

3. **"Stay awake while this app runs".** Optional app picker populated from
   `NSWorkspace.shared.runningApplications` (filtered to apps with a regular
   activation policy). Selecting an app passes `-w <PID>` to caffeinate; when
   that PID exits, caffeinate exits and the menubar returns to idle state.
   Mutually exclusive with timed sessions (caffeinate stops on whichever
   condition is met first; if both are set, surface that to the user).

4. **Active state indicator.** Menubar icon shows two distinct states: idle
   (outlined) and running (filled). The running icon could also show a small
   countdown badge if a timer is active — design TBD.

5. **Launch at login.** Toggle in the dropdown using `SMAppService.mainApp`.
   Reflects current registration state on launch.

6. **Quit.** Standard menu item.

---

## Success Criteria

- [ ] Releasing a `.zip` on GitHub that opens on a clean Mac running macOS 13+
      via right-click → Open (Gatekeeper warning is expected for v1; README
      documents the one-time workaround)
- [ ] Selecting one or more flags + clicking "Start" launches `/usr/bin/caffeinate`
      with exactly the chosen flags (verifiable with `ps aux | grep caffeinate`)
- [ ] Selecting a 1-hour duration causes caffeinate to exit at the 60-minute mark
      and the menubar to return to idle, ±5s
- [ ] Selecting an app target causes caffeinate to exit within 2 seconds of that
      app quitting
- [ ] Toggling launch-at-login persists across reboot
- [ ] Quitting the app terminates any running caffeinate process (no orphans)
- [ ] All unit tests pass; coverage ≥80% on `Models/` and `Services/`
- [ ] App is sandbox-safe enough to run, but **not** sandboxed (Mac App Store
      sandbox rules block spawning external binaries — see Open Questions)

---

## Resolved Decisions

1. **Name + bundle ID.** App name is `CaffeinateMenubar`. Bundle ID is
   `com.samuellastrina.caffeinatemenubar`.
2. **Signing.** v1 ships **unsigned**. README documents the right-click → Open
   workaround for first launch. Signing + notarization is a follow-up release
   (tracked separately, not in v1 scope).
3. **Icons.** SF Symbols only — no custom artwork. Default pair:
   `cup.and.saucer` (idle) / `cup.and.saucer.fill` (running). Subject to taste
   during implementation but no custom asset work.
4. **Duration + app target both set.** Allowed. Whichever condition fires first
   ends the session. The dropdown surfaces both (countdown + target app name)
   while running.
5. **`-s` AC-power caveat.** Surfaced in the UI as a small info tooltip / help
   text next to the `-s` toggle. Does not block selection.
6. **Custom duration upper bound.** Unlimited (no cap). UI input is minutes,
   stored as seconds (`Int`). Allow any positive integer.
