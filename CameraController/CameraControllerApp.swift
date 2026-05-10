//
//  CameraControllerApp.swift
//  CameraController
//
//  SwiftUI App lifecycle entry point. The menu-bar status item and
//  popover are owned by AppDelegate (NSStatusItem + NSPopover) so the
//  popover renders the macOS 26 Liquid Glass arrow tail — SwiftUI's
//  menu-bar scene styles do not. This Scene only hosts the standard
//  Preferences window (⌘,).
//

import SwiftUI

@main
struct CameraControllerApp: App {
    // The AppDelegate adaptor owns the NSStatusItem, NSPopover, and
    // the long-lived PreviewSession that backs the camera preview, in
    // addition to Sparkle / LetsMove / the AVCaptureDevice video
    // permission prompt and the
    // applicationShouldTerminateAfterLastWindowClosed override.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Standard macOS Preferences window (⌘,). Independent of the
        // menu-bar popover. Hosts the same PreferencesView used by the
        // in-popover "Settings" tab so users have parity with the
        // in-popover behavior.
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
