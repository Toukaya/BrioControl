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

    // PreviewSession is owned by AppDelegate (NSStatusItem +
    // NSPopover lifetime) and injected via .environment(_:) on the
    // NSHostingController root view. Reading it via @Environment here
    // — instead of @State — keeps the AVCaptureSession instance
    // stable across popover open/close cycles. AppDelegate's
    // popoverWillShow / popoverDidClose hooks drive resume() /
    // suspend(), so ContentView no longer watches scenePhase.
    @Environment(PreviewSession.self) private var preview

    var body: some View {
        // Camera preview at the top of the popover, settings tabs
        // below. NSPopover sizes to the content's intrinsic size, so
        // each child carries its own .frame and the popover grows
        // to fit the sum of preview + tab content.
        VStack(spacing: 0) {
            cameraPreview()
                .animation(nil, value: settings.hideCameraPreview)

            SettingsView()
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
        .frame(width: settings.cameraPreviewSize.getWidth())
        .fixedSize(horizontal: true, vertical: false)
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
                .padding(8)
        } else {
            Image("video.slash")
                .frame(
                    width: settings.cameraPreviewSize.getWidth(),
                    height: settings.cameraPreviewSize.getHeight()
                )
                .background(Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .environment(PreviewSession())
    }
}
#endif
