//
//  CameraControllerApp.swift
//  CameraController
//
//  SwiftUI App lifecycle entry point. Hosts the menu-bar item via a
//  MenuBarExtra scene and the standard preferences window via a
//  Settings scene.
//

import SwiftUI
import AVFoundation

@main
struct CameraControllerApp: App {
    // The AppDelegate adaptor still owns Sparkle, LetsMove, and the
    // applicationShouldTerminateAfterLastWindowClosed override.
    // Everything menu-bar-window related is handled by SwiftUI.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // Request camera access at app construction time, before any
        // PreviewSession.attach() can run. The permission prompt
        // ('CameraController would like to access the camera') appears
        // as soon as the process is launched, so by the time the user
        // clicks the menu-bar icon for the first popover open, access
        // has already been granted (or denied) and the preview can
        // start without a re-prompt midway through attach.
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        }
    }

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
