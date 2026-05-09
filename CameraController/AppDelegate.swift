//
//  AppDelegate.swift
//  CameraController
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//
//  Thin NSApplicationDelegate adopted via @NSApplicationDelegateAdaptor on
//  CameraControllerApp. Owns Sparkle, LetsMove, and the
//  applicationShouldTerminateAfterLastWindowClosed override. The
//  AVCaptureDevice video permission prompt now fires from
//  CameraControllerApp.init so that the prompt appears before the first
//  PreviewSession.attach() runs. The menu-bar item and popover-style
//  window are provided by SwiftUI's MenuBarExtra scene.
//

import Cocoa
import SwiftUI
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
