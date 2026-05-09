//
//  CameraPreview.swift
//  CameraController
//
//  Thin NSViewRepresentable that hosts the AVCaptureVideoPreviewLayer
//  produced by PreviewSession. Owns no AVFoundation state itself: the
//  AVCaptureSession, format selection, and start/stop lifecycle all
//  live in PreviewSession (CameraController/Devices/PreviewSession.swift).
//
//  This view only:
//   - mounts the provided layer as the NSView's backing CALayer sublayer,
//   - keeps the layer frame in sync with the NSView bounds during layout,
//   - forwards mouse events so the menu-bar popover can be dragged and
//     the cursor changes to .contextualMenu while hovering the preview.
//

import SwiftUI
import AVFoundation

struct CameraPreview: NSViewRepresentable {
    // The preview layer to display. Sourced from
    // PreviewSession.previewLayer in ContentView. nil while no device
    // is attached or before the first attach() completes.
    let layer: AVCaptureVideoPreviewLayer?

    func makeNSView(context: Context) -> CameraPreviewHostingView {
        let view = CameraPreviewHostingView(frame: .zero)
        view.mount(previewLayer: layer)
        return view
    }

    func updateNSView(_ nsView: CameraPreviewHostingView,
                      context: NSViewRepresentableContext<CameraPreview>) {
        nsView.mount(previewLayer: layer)
    }
}
