import SwiftUI

enum DurationOption: String, Hashable, CaseIterable, Identifiable {
    case indefinite    = "indefinite"
    case thirtyMinutes = "thirtyMinutes"
    case oneHour       = "oneHour"
    case twoHours      = "twoHours"
    case custom        = "custom"

    var id: Self { self }

    var label: String {
        switch self {
        case .indefinite:    return "Indefinite"
        case .thirtyMinutes: return "30 minutes"
        case .oneHour:       return "1 hour"
        case .twoHours:      return "2 hours"
        case .custom:        return "Custom…"
        }
    }

    var presetSeconds: Int? {
        switch self {
        case .indefinite, .custom: return nil
        case .thirtyMinutes:       return 30 * 60
        case .oneHour:             return 60 * 60
        case .twoHours:            return 2 * 60 * 60
        }
    }
}

struct DurationPickerView: View {
    @Binding var option: DurationOption
    @Binding var customMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Duration")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("", selection: $option) {
                ForEach(DurationOption.allCases) { opt in
                    Text(opt.label).tag(opt)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            if option == .custom {
                HStack(spacing: 6) {
                    TextField("Minutes", value: $customMinutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("minutes")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

extension DurationOption {
    static func resolveSeconds(option: DurationOption, customMinutes: Int) -> Int? {
        switch option {
        case .indefinite:
            return nil
        case .custom:
            return customMinutes > 0 ? customMinutes * 60 : nil
        default:
            return option.presetSeconds
        }
    }
}
