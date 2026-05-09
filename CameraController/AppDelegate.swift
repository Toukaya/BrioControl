//
//  AppDelegate.swift
//  CameraController
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//
//  Thin NSApplicationDelegate adopted via @NSApplicationDelegateAdaptor on
//  CameraControllerApp. Owns Sparkle, LetsMove, the AVCaptureDevice video
//  permission prompt, and the applicationShouldTerminateAfterLastWindowClosed
//  override. The menu-bar item and popover-style window are now provided by
//  SwiftUI's MenuBarExtra scene and no longer live here.
//

import Cocoa
import SwiftUI
import AVFoundation
import Sparkle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        LetsMove.shared.moveToApplicationsFolderIfNecessary()

        // Request camera access at launch instead of lazily at first capture.
        // The permission prompt ('CameraController would like to access the
        // camera') appears immediately, before the user clicks the menu-bar
        // icon, so the first popover open already has access granted.
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        }

        if UserSettings.shared.checkForUpdatesOnStartup {
            checkForUpdates()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - Check For Updates
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
