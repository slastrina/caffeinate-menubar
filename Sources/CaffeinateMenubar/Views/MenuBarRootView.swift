import SwiftUI
import AppKit

struct MenuBarRootView: View {
    @EnvironmentObject var controller: CaffeinateController
    @EnvironmentObject var runningApps: RunningAppsService
    @EnvironmentObject var launchAtLogin: LaunchAtLoginService
    @EnvironmentObject var updateChecker: UpdateCheckerService

    @AppStorage("flags.rawValue") private var flagsRawValue: Int = CaffeinateFlags.preventIdleSleep.rawValue
    @AppStorage("duration.option") private var durationOption: DurationOption = .indefinite
    @AppStorage("duration.customMinutes") private var customMinutes: Int = 60
    @State private var targetApp: RunningApp?

    private var flagsBinding: Binding<CaffeinateFlags> {
        Binding(
            get: { CaffeinateFlags(rawValue: flagsRawValue) },
            set: { flagsRawValue = $0.rawValue }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            if controller.state.isRunning {
                runningSection
            } else {
                FlagPickerView(flags: flagsBinding)
                DurationPickerView(option: $durationOption, customMinutes: $customMinutes)
                AppPickerView(service: runningApps, selection: $targetApp)
            }

            Divider()
            actionRow

            Divider()
            launchAtLoginRow

            if let update = updateChecker.availableUpdate {
                updateBanner(for: update)
            }

            Button("Quit") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
                .buttonStyle(.borderless)
        }
        .padding(14)
        .frame(width: 280)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: controller.state.isRunning ? "cup.and.saucer.fill" : "cup.and.saucer")
            Text("CaffeinateMenubar")
                .font(.headline)
            Spacer()
            Text(controller.state.isRunning ? "Active" : "Idle")
                .font(.caption)
                .foregroundStyle(controller.state.isRunning ? Color.accentColor : .secondary)
        }
    }

    @ViewBuilder
    private var runningSection: some View {
        if case .running(let config, let startedAt) = controller.state {
            VStack(alignment: .leading, spacing: 6) {
                Text("Running")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(config.flags.arguments.joined(separator: " "))
                    .font(.callout.monospaced())
                if let duration = config.durationSeconds {
                    CountdownView(startedAt: startedAt, totalSeconds: duration)
                } else if config.targetPID == nil {
                    Text("No time limit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let appName = config.targetAppName {
                    Label("While \(appName) runs", systemImage: "app.dashed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var actionRow: some View {
        HStack {
            if controller.state.isRunning {
                Button("Stop") { controller.stop() }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
            } else {
                Button("Start") { startSession() }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .disabled(!proposedConfig.isValid)
            }
            Spacer()
        }
    }

    private var proposedConfig: SessionConfig {
        SessionConfig(
            flags: CaffeinateFlags(rawValue: flagsRawValue),
            durationSeconds: DurationOption.resolveSeconds(
                option: durationOption,
                customMinutes: customMinutes
            ),
            targetPID: targetApp?.pid,
            targetAppName: targetApp?.name
        )
    }

    private var launchAtLoginRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            )) {
                Text("Launch at login")
            }
            .toggleStyle(.checkbox)
            if let error = launchAtLogin.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func updateBanner(for update: AvailableUpdate) -> some View {
        Button {
            NSWorkspace.shared.open(update.releasePageURL)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.circle")
                Text("Update available — v\(update.version)")
                    .font(.caption)
            }
            .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.borderless)
    }

    private func startSession() {
        do {
            try controller.start(proposedConfig)
        } catch {
            NSSound.beep()
        }
    }
}

private struct CountdownView: View {
    let startedAt: Date
    let totalSeconds: Int

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
            Text(remainingString)
                .font(.callout.monospaced())
        }
        .foregroundStyle(.secondary)
        .onReceive(timer) { now = $0 }
    }

    private var remainingString: String {
        let elapsed = Int(now.timeIntervalSince(startedAt))
        let remaining = max(0, totalSeconds - elapsed)
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d remaining", hours, minutes, seconds)
        }
        return String(format: "%d:%02d remaining", minutes, seconds)
    }
}
