//
//  CameraPreview.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI
import AVFoundation

// External controller used by ContentView to drive
// startSession() / stopRunning() in response to SwiftUI lifecycle
// transitions (scenePhase active <-> inactive).
@MainActor
final class CameraPreviewController {
    fileprivate weak var view: CameraPreviewInternal?

    func startSession() {
        view?.startSession()
    }

    func stopSession() {
        view?.stopRunning()
    }
}

struct CameraPreview: NSViewRepresentable {
    @Binding var captureDevice: CaptureDevice?
    let controller: CameraPreviewController

    func makeNSView(context: Context) -> CameraPreviewInternal {
        let view = CameraPreviewInternal(frame: .zero, device: captureDevice?.avDevice)
        controller.view = view
        return view
    }

    func updateNSView(_ nsView: CameraPreviewInternal, context: NSViewRepresentableContext<CameraPreview>) {
        nsView.updateCamera(captureDevice?.avDevice)
        controller.view = nsView
    }

    static func dismantleNSView(_ nsView: CameraPreviewInternal, coordinator: ()) {
        nsView.stopRunning()
    }
}
