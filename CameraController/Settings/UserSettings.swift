//
//  UserSettings.swift
//  CameraController
//
//  Created by Itay Brenner on 7/25/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class UserSettings {
    static let shared = UserSettings()

    var openAtLogin: Bool {
        didSet {
            // SMLoginItemSetEnabled was deprecated in macOS 13 in favor of
            // SMAppService.loginItem(identifier:). Migrating to SMAppService
            // requires repackaging the helper into a `Contents/Library/
            // LoginItems` bundle path and shipping a separate launchd plist;
            // that's out of scope for the strict-concurrency migration, so
            // the legacy call is preserved verbatim. The single deprecation
            // warning emitted on the line below is intentional tech debt
            // tracked for a future task that will repackage the helper.
            let success = SMLoginItemSetEnabled("com.itaysoft.CameraController.Helper" as CFString, openAtLogin)
            if success {
                UserDefaults.standard.set(openAtLogin, forKey: "login")
            }
        }
    }

    var readRate: RefreshSettingsRate {
        didSet {
            UserDefaults.standard.set(readRate.rawValue, forKey: "readRate")
        }
    }

    var writeRate: RefreshSettingsRate {
        didSet {
            UserDefaults.standard.set(writeRate.rawValue, forKey: "writeRate")
        }
    }

    var lastSelectedDevice: String? {
        didSet {
            UserDefaults.standard.set(lastSelectedDevice, forKey: "lastDevice")
        }
    }

    var hideCameraPreview: Bool {
        cameraPreviewSize == .disabled
    }

    var cameraPreviewSize: PreviewSizeSettings {
        didSet {
            UserDefaults.standard.set(cameraPreviewSize.rawValue, forKey: "cameraPreviewSize")
        }
    }

    var cameraPreviewQuality: PreviewQualitySettings {
        didSet {
            UserDefaults.standard.set(cameraPreviewQuality.rawValue, forKey: "cameraPreviewQuality")
            NotificationCenter.default.post(name: .cameraPreviewQualityChanged, object: nil)
        }
    }

    var checkForUpdatesOnStartup: Bool {
        didSet {
            UserDefaults.standard.set(checkForUpdatesOnStartup, forKey: "checkForUpdatesOnStartup")
        }
    }

    var mirrorPreview: Bool {
        didSet {
            UserDefaults.standard.set(mirrorPreview, forKey: "mirrorPreview")
        }
    }

    private init() {
        openAtLogin = UserDefaults.standard.bool(forKey: "login")
        readRate = RefreshSettingsRate(rawValue: UserDefaults.standard.double(forKey: "readRate")) ?? .disabled
        writeRate = RefreshSettingsRate(rawValue: UserDefaults.standard.double(forKey: "writeRate")) ?? .disabled
        lastSelectedDevice = UserDefaults.standard.string(forKey: "lastDevice")
        cameraPreviewSize = PreviewSizeSettings(
            rawValue: UserDefaults.standard.double(forKey: "cameraPreviewSize")
        ) ?? .small
        let storedQuality = UserDefaults.standard.object(forKey: "cameraPreviewQuality") as? Int
        let qualityRaw = storedQuality ?? PreviewQualitySettings.fhd1080.rawValue
        cameraPreviewQuality = PreviewQualitySettings(rawValue: qualityRaw) ?? .fhd1080
        checkForUpdatesOnStartup = UserDefaults.standard.bool(forKey: "checkForUpdatesOnStartup")
        mirrorPreview = UserDefaults.standard.bool(forKey: "mirrorPreview")
    }
}
