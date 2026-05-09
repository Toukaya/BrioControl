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

    // SwiftUI's scenePhase transitions when the MenuBarExtra window
    // becomes key / loses key. We use those transitions to suspend the
    // AVCaptureSession (and turn the camera LED off) while the popover
    // is hidden, then resume on re-show.
    @Environment(\.scenePhase) private var scenePhase

    // The single source of truth for the AVCaptureSession lifecycle.
    // Created once per ContentView instance and driven declaratively
    // via .task(id:) and .onChange(of:) modifiers below. See
    // CameraController/Devices/PreviewSession.swift for the lifecycle
    // contract.
    @State private var preview = PreviewSession()

    var body: some View {
        // Local @Bindable shadow so we can hand out bindings ($manager.foo)
        // to subviews. @Environment alone does not expose Bindings; this is
        // the canonical Observation-framework idiom.
        @Bindable var manager = manager
        let selectedDeviceBinding = $manager.selectedDevice

        // GlassEffectContainer batches the Liquid Glass passes for every
        // descendant that calls .glassEffect(_:in:), so the camera-preview
        // frame and any future glass surfaces share a single render pass.
        GlassEffectContainer(spacing: 0) {
            VStack(spacing: 0) {
                cameraPreview()
                    .animation(nil, value: settings.hideCameraPreview)

                SettingsView(captureDevice: selectedDeviceBinding)
            }
            .onAppear {
                DevicesManager.shared.startMonitoring()
            }
            .onDisappear {
                DevicesManager.shared.stopMonitoring()
            }
            // Drive PreviewSession from the selected-device identity. A
            // change to selectedDevice cancels the previous task body and
            // runs this one, so a rapid sequence of switches collapses
            // to "detach prior, attach latest" with the intermediate
            // attaches superseded.
            .task(id: manager.selectedDevice?.avDevice?.uniqueID) {
                if let device = manager.selectedDevice?.avDevice {
                    await preview.attach(device: device,
                                         quality: settings.cameraPreviewQuality)
                } else {
                    await preview.detach()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    Task { await preview.resume() }
                case .inactive, .background:
                    Task { await preview.suspend() }
                @unknown default:
                    break
                }
            }
            .frame(width: settings.cameraPreviewSize.getWidth())
            .fixedSize(horizontal: true, vertical: false)
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func cameraPreview() -> some View {
        if settings.hideCameraPreview {
            EmptyView()
        } else if manager.selectedDevice != nil {
            CameraPreview(layer: preview.previewLayer)
                .frame(
                    width: settings.cameraPreviewSize.getWidth(),
                    height: settings.cameraPreviewSize.getHeight()
                )
                .scaleEffect(CGSize(width: settings.mirrorPreview ? -1 : 1, height: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                .padding(8)
        } else {
            Image("video.slash")
                .frame(
                    width: settings.cameraPreviewSize.getWidth(),
                    height: settings.cameraPreviewSize.getHeight()
                )
                .background(Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
                .padding(8)
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
