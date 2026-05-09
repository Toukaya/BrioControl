//
//  ContentView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI
import Combine
import AVFoundation

struct ContentView: View {
    @ObservedObject var manager = DevicesManager.shared
    @ObservedObject var settings = UserSettings.shared
    @State var currentSection: Int?

    // Drives camera-preview start/stop. SwiftUI's scenePhase transitions
    // when the MenuBarExtra window becomes key / loses key, which is the
    // lifecycle signal we use to suspend the AVCaptureSession while the
    // popover is hidden.
    @Environment(\.scenePhase) private var scenePhase
    @State private var previewController = CameraPreviewController()

    var body: some View {
        HStack {
            VStack(spacing: 0) {
                cameraPreview()
                    .animation(nil, value: settings.hideCameraPreview)

                TabSelectorView(selectedIndex: $currentSection)
                    .padding(.vertical, Constants.Style.padding)
                    .animation(nil, value: currentSection)

                settingsView()
            }.onAppear {
                DevicesManager.shared.startMonitoring()
            }.onDisappear {
                DevicesManager.shared.stopMonitoring()
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .active:
                    previewController.startSession()
                case .inactive, .background:
                    previewController.stopSession()
                @unknown default:
                    break
                }
            }
            .frame(width: settings.cameraPreviewSize.getWidth() - Constants.Style.padding * 2)
        }
        .fixedSize()
        .background(
            VisualEffectView(material: .hudWindow,
                             blendingMode: .behindWindow,
                             state: .active)
        )
    }

    @ViewBuilder
    func cameraPreview() -> some View {
        if settings.hideCameraPreview {
            EmptyView()
        } else if $manager.selectedDevice.wrappedValue != nil {
            CameraPreview(captureDevice: $manager.selectedDevice,
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

    @ViewBuilder
    func settingsView() -> some View {
        SettingsView(
            captureDevice: $manager.selectedDevice,
            currentSection: $currentSection
        )
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
