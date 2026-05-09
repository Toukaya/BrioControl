//
//  AppDelegate.swift
//  Helper
//
//  Created by Itay Brenner on 7/25/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Cocoa
import SwiftUI

enum HelperConstants {
    static let BundleIdentifier = "com.itaysoft.CameraController"
}

@main
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    static func main() {
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        NSApplication.shared.run()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains {
            $0.bundleIdentifier == HelperConstants.BundleIdentifier
        }

        if !isRunning {
            var path = Bundle.main.bundlePath as NSString
            for _ in 1...4 {
                path = path.deletingLastPathComponent as NSString
            }
            // openApplication(at:configuration:completionHandler:) is the
            // post-macOS-11 replacement for launchApplication. Pass an
            // empty configuration since we want the same default launch
            // behavior the legacy call provided.
            let url = URL(fileURLWithPath: path as String)
            NSWorkspace.shared.openApplication(at: url,
                                               configuration: NSWorkspace.OpenConfiguration(),
                                               completionHandler: nil)
        }
    }
}
