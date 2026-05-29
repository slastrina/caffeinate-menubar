import SwiftUI

struct AppPickerView: View {
    @ObservedObject var service: RunningAppsService
    @Binding var selection: RunningApp?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stay awake while app runs")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("", selection: $selection) {
                Text("None").tag(RunningApp?.none)
                ForEach(service.apps) { app in
                    Text(app.name).tag(RunningApp?.some(app))
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .onAppear { service.refresh() }
        }
    }
}
