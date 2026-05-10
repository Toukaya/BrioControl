//
//  AppDelegate.swift
//  CameraController
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//
//  Owns the menu-bar status item and the NSPopover that hosts the
//  SwiftUI ContentView. macOS 26 SwiftUI ships only `.menu` and
//  `.window` menu-bar scene styles, neither of which renders the
//  popover arrow tail. AppKit's NSPopover does, and on macOS 26 it
//  automatically composes the Liquid Glass arrow tail with the popover
//  surface — so we route the entire menu-bar UI through NSStatusItem +
//  NSPopover here instead of through a SwiftUI scene.
//
//  Also owns Sparkle, LetsMove, the AVCaptureDevice video permission
//  prompt, and the long-lived PreviewSession that backs the camera
//  preview. PreviewSession is owned by AppDelegate (rather than being
//  a @State on ContentView) so that its lifetime spans repeated
//  popover open/close cycles instead of being torn down and
//  recreated on every show.
//

import Cocoa
import SwiftUI
import AVFoundation
import Sparkle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    // The single PreviewSession used by ContentView. Owned here so its
    // AVCaptureSession survives popover open/close cycles. Injected
    // into the SwiftUI hierarchy via .environment(_:) on the
    // NSHostingController root view below.
    private let previewSession = PreviewSession()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        LetsMove.shared.moveToApplicationsFolderIfNecessary()

        // Request camera access at app launch, before any
        // PreviewSession.attach() can run. The permission prompt
        // ('CameraController would like to access the camera') appears
        // as soon as the process is launched, so by the time the user
        // clicks the menu-bar icon for the first popover open, access
        // has already been granted (or denied) and the preview can
        // start without a re-prompt midway through attach.
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        }

        // Device hot-plug monitoring runs for the lifetime of the app
        // (not just while the popover is open) so a USB camera plugged
        // in while the popover is hidden is picked up immediately on
        // the next open instead of being missed.
        DevicesManager.shared.startMonitoring()

        installStatusItem()
        installPopover()

        if UserSettings.shared.checkForUpdatesOnStartup {
            checkForUpdates()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        DevicesManager.shared.stopMonitoring()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - Status item / popover

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "camera.fill",
                                   accessibilityDescription: "Camera Controller")
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        statusItem = item
    }

    private func installPopover() {
        let pop = NSPopover()
        pop.behavior = .transient
        pop.delegate = self
        pop.contentViewController = NSHostingController(rootView:
            ContentView()
                .environment(DevicesManager.shared)
                .environment(UserSettings.shared)
                .environment(ProfileManager.shared)
                .environment(previewSession)
        )
        popover = pop
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        guard let item = statusItem,
              let button = item.button,
              let pop = popover else {
            return
        }
        if pop.isShown {
            pop.performClose(sender)
        } else {
            pop.show(relativeTo: button.bounds,
                     of: button,
                     preferredEdge: .minY)
            // Make the hosting window key so SwiftUI controls receive
            // keyboard events (sliders, arrow-key adjustments, etc.).
            pop.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - NSPopoverDelegate

    // Allow the user to drag the popover off into a free-floating
    // window. The detached window keeps the same ContentView and so
    // keeps rendering the live camera preview.
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }

    // Drive PreviewSession suspend/resume from popover visibility so
    // the camera LED turns off while the popover is hidden. The
    // detached free-floating window keeps the popover "shown" from
    // AppKit's point of view, so the session also keeps running there.
    func popoverWillShow(_ notification: Notification) {
        Task { @MainActor [previewSession] in
            await previewSession.resume()
        }
    }

    func popoverDidClose(_ notification: Notification) {
        Task { @MainActor [previewSession] in
            await previewSession.suspend()
        }
    }

    // MARK: - Check For Updates
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
