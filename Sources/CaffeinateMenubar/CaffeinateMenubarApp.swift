import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Best-effort stop of any running caffeinate. The controller is
        // @MainActor-isolated, so reach it through the shared instance held by
        // the SwiftUI scene; if it has already torn down, the OS will reap the
        // child process when our PID exits.
        SharedServices.shared.controller.stop()
    }
}

@MainActor
final class SharedServices {
    static let shared = SharedServices()
    let controller = CaffeinateController()
    let runningApps = RunningAppsService()
    let launchAtLogin = LaunchAtLoginService()
    private init() {}
}

@main
struct CaffeinateMenubarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = SharedServices.shared.controller
    @StateObject private var runningApps = SharedServices.shared.runningApps
    @StateObject private var launchAtLogin = SharedServices.shared.launchAtLogin

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView()
                .environmentObject(controller)
                .environmentObject(runningApps)
                .environmentObject(launchAtLogin)
        } label: {
            Image(systemName: controller.state.isRunning
                  ? "cup.and.saucer.fill"
                  : "cup.and.saucer")
        }
        .menuBarExtraStyle(.window)
    }
}
