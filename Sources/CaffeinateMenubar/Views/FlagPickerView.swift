import SwiftUI

struct FlagPickerView: View {
    @Binding var flags: CaffeinateFlags

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Prevent")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            flagToggle(.preventIdleSleep,    label: "Idle sleep",    hint: "-i")
            flagToggle(.preventDisplaySleep, label: "Display sleep", hint: "-d")
            flagToggle(.preventDiskSleep,    label: "Disk idle",     hint: "-m")

            HStack(spacing: 4) {
                flagToggle(.preventSystemSleep, label: "System sleep", hint: "-s")
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .help("-s only takes effect when the Mac is on AC power.")
            }
        }
    }

    @ViewBuilder
    private func flagToggle(_ flag: CaffeinateFlags, label: String, hint: String) -> some View {
        Toggle(isOn: binding(for: flag)) {
            HStack(spacing: 6) {
                Text(label)
                Text(hint)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.checkbox)
    }

    private func binding(for flag: CaffeinateFlags) -> Binding<Bool> {
        Binding(
            get: { flags.contains(flag) },
            set: { isOn in
                if isOn { flags.insert(flag) } else { flags.remove(flag) }
            }
        )
    }
}
