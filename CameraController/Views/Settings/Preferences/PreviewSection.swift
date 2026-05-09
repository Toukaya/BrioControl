//
//  PreviewSection.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI
import AVFoundation
import CoreMedia

struct PreviewSection: View {
    @ObservedObject var settings = UserSettings.shared
    @ObservedObject var devices = DevicesManager.shared

    var body: some View {
        SectionView {
            SectionTitle(title: "Preview",
                         image: Image(systemName: "photo"))

            HStack {
                Text("Preview Size")
                Spacer()
                Picker(selection: $settings.cameraPreviewSize, label: Text("")) {
                    Text("Disabled").tag(PreviewSizeSettings.disabled)
                    Text("Small").tag(PreviewSizeSettings.small)
                    Text("Medium").tag(PreviewSizeSettings.medium)
                    Text("Large").tag(PreviewSizeSettings.large)
                    Text("Extra Large").tag(PreviewSizeSettings.extraLarge)
                }
                .frame(width: 200)
            }

            HStack {
                Text("Preview video quality")
                Spacer()
                Picker(selection: $settings.cameraPreviewQuality, label: Text("")) {
                    ForEach(availableQualities, id: \.self) { quality in
                        Text(quality.displayName).tag(quality)
                    }
                }
                .frame(width: 240)
            }

            HStack {
                Text("Mirror Preview")
                Spacer()
                Toggle(isOn: $settings.mirrorPreview)
            }
        }
    }

    // List of preview-quality options offered to the user. Always includes
    // Disabled. The remaining entries are filtered against the currently
    // selected device's supported formats so that a 720p-only webcam does
    // not show 4K/2K/1080p choices that would silently fall back.
    private var availableQualities: [PreviewQualitySettings] {
        var result: [PreviewQualitySettings] = [.disabled]

        let supported = supportedNonDisabledQualities()
        if supported.isEmpty {
            // No device available right now. Show all options so the user
            // can still configure the setting; CameraPreviewInternal will
            // gracefully downgrade if the actual device cannot match.
            result.append(contentsOf: PreviewQualitySettings.allCases.filter { $0 != .disabled })
        } else {
            result.append(contentsOf: supported)
        }

        // Make sure the currently persisted selection is always present so
        // SwiftUI's Picker has a valid tag. If the persisted quality is no
        // longer supported by the active device, keep it visible so the
        // user can change it explicitly.
        if !result.contains(settings.cameraPreviewQuality) {
            result.append(settings.cameraPreviewQuality)
        }

        return result
    }

    private func supportedNonDisabledQualities() -> [PreviewQualitySettings] {
        guard let device = devices.selectedDevice?.avDevice else {
            return []
        }

        var supportedSet = Set<PreviewQualitySettings>()
        for format in device.formats {
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            for quality in PreviewQualitySettings.allCases where quality != .disabled {
                if Int(dims.width) == quality.width && Int(dims.height) == quality.height {
                    supportedSet.insert(quality)
                }
            }
        }

        // Sort ascending by resolution so the Picker reads
        // 720p, 1080p, 2K, 4K.
        return supportedSet.sorted { $0.rawValue < $1.rawValue }
    }
}
