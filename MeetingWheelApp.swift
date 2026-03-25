import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct MeetingWheelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("Meeting Wheel") {
            ContentView()
                .frame(width: 700, height: 700)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}
