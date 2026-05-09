//
//  CameraControllerApp.swift
//  CameraController
//
//  SwiftUI App lifecycle entry point. Hosts the menu-bar item via a
//  MenuBarExtra scene and the standard preferences window via a
//  Settings scene.
//

import SwiftUI

@main
struct CameraControllerApp: App {
    // The AppDelegate adaptor still owns Sparkle, LetsMove, AVCapture
    // permission, and the applicationShouldTerminateAfterLastWindowClosed
    // override. Everything menu-bar-window related is handled by SwiftUI.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Camera Controller", systemImage: "camera.fill") {
            // ContentView already calls .fixedSize() to size to its
            // contents (camera preview + tabs + active settings panel),
            // so MenuBarExtra's window sizes to fit.
            ContentView()
                .environment(DevicesManager.shared)
                .environment(UserSettings.shared)
                .environment(ProfileManager.shared)
        }
        .menuBarExtraStyle(.window)

        // Standard macOS Preferences window (⌘,). Independent of the
        // MenuBarExtra window. Hosts the same PreferencesView used by
        // the in-popover "Settings" tab so users have parity with the
        // legacy popover behavior.
        Settings {
            PreferencesView()
                .frame(width: UserSettings.shared.cameraPreviewSize.getWidth())
                .padding(.horizontal, Constants.Style.padding)
                .environment(DevicesManager.shared)
                .environment(UserSettings.shared)
                .environment(ProfileManager.shared)
        }
    }
}
