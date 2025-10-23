//
//  spill.swift
//  spill
//
//  Created by faraaz on 2/14/25.
//

import SwiftUI
import Sparkle

@main
struct spillApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("colorScheme") private var colorSchemeString: String = "light"

    private let updaterController: SPUStandardUpdaterController

    init() {
        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorSchemeString == "dark" ? .dark : .light)
        }
        .defaultSize(width: 1100, height: 600)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}

// Add AppDelegate to handle window configuration
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            // Ensure all window controls are available
            window.styleMask.insert(.miniaturizable)
            window.styleMask.insert(.resizable)
            window.styleMask.insert(.closable)
            
            // Center the window on the screen
            window.center()
        }
    }
}
