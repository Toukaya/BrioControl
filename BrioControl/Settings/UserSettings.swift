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
            // Migrate from the macOS-13-deprecated SMLoginItemSetEnabled to
            // SMAppService.loginItem. The Helper bundle identifier is the
            // same; the new API surface returns void / throws and is the
            // sanctioned path on every supported deployment target
            // (MACOSX_DEPLOYMENT_TARGET = 26.0).
            let helperService = SMAppService.loginItem(
                identifier: "com.toukaya.BrioControl.Helper"
            )
            let registerSucceeded: Bool
            if openAtLogin {
                do {
                    try helperService.register()
                    registerSucceeded = true
                } catch {
                    registerSucceeded = false
                }
            } else {
                do {
                    try helperService.unregister()
                    registerSucceeded = true
                } catch {
                    registerSucceeded = false
                }
            }
            if registerSucceeded {
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
