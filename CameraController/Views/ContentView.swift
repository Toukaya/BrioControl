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

    // Fixed popover content height. NSPopover sizes to its content's
    // intrinsic size, so without an explicit height the popover
    // resizes when switching between tabs whose Forms have
    // different intrinsic heights.
    private let popoverContentHeight: CGFloat = 480

    var body: some View {
        // Tabs live at the top of the popover (matches the macOS 26
        // System Settings convention). The camera preview sits below
        // the tab bar and the active tab's content fills the rest of
        // the popover.
        VStack(spacing: 0) {
            SettingsView()

            cameraPreview()
                .animation(nil, value: settings.hideCameraPreview)
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
        .frame(width: settings.cameraPreviewSize.getWidth(),
               height: popoverContentHeight)
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
