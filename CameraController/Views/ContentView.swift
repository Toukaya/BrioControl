//
//  ContentView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @Environment(DevicesManager.self) private var manager
    @Environment(UserSettings.self) private var settings

    // Drives camera-preview start/stop. SwiftUI's scenePhase transitions
    // when the MenuBarExtra window becomes key / loses key, which is the
    // lifecycle signal we use to suspend the AVCaptureSession while the
    // popover is hidden.
    @Environment(\.scenePhase) private var scenePhase
    @State private var previewController = CameraPreviewController()

    var body: some View {
        // Local @Bindable shadow so we can hand out bindings ($manager.foo)
        // to subviews. @Environment alone does not expose Bindings; this is
        // the canonical Observation-framework idiom.
        @Bindable var manager = manager
        let selectedDeviceBinding = $manager.selectedDevice

        VStack(spacing: 0) {
            cameraPreview(selectedDevice: selectedDeviceBinding)
                .animation(nil, value: settings.hideCameraPreview)

            SettingsView(captureDevice: selectedDeviceBinding)
        }
        .onAppear {
            DevicesManager.shared.startMonitoring()
        }
        .onDisappear {
            DevicesManager.shared.stopMonitoring()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                previewController.startSession()
            case .inactive, .background:
                previewController.stopSession()
            @unknown default:
                break
            }
        }
        .frame(width: settings.cameraPreviewSize.getWidth())
        .fixedSize(horizontal: true, vertical: false)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func cameraPreview(selectedDevice: Binding<CaptureDevice?>) -> some View {
        if settings.hideCameraPreview {
            EmptyView()
        } else if selectedDevice.wrappedValue != nil {
            CameraPreview(captureDevice: selectedDevice,
                          controller: previewController)
                .frame(
                    width: settings.cameraPreviewSize.getWidth(),
                    height: settings.cameraPreviewSize.getHeight()
                )
                .scaleEffect(CGSize(width: settings.mirrorPreview ? -1 : 1, height: 1))
        } else {
            Image("video.slash")
                .frame(
                    width: settings.cameraPreviewSize.getWidth(),
                    height: settings.cameraPreviewSize.getHeight()
                )
                .background(Color.gray)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(DevicesManager.shared)
            .environment(UserSettings.shared)
            .environment(ProfileManager.shared)
    }
}
#endif
