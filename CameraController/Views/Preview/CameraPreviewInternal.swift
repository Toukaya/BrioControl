//
//  CameraPreviewInternal.swift
//  CameraController
//
//  Layer-hosting NSView used by CameraPreview. Before TASK-09 this type
//  also owned an AVCaptureSession and drove device configuration / start
//  / stop inline; that responsibility now lives in PreviewSession
//  (CameraController/Devices/PreviewSession.swift) and this file shrunk
//  to a thin host: it mounts an externally-supplied
//  AVCaptureVideoPreviewLayer and forwards mouse events so the menu-bar
//  popover can be dragged.
//

import Cocoa
import AVFoundation

final class CameraPreviewHostingView: NSView {
    // The preview layer mounted as a sublayer. Owned by PreviewSession;
    // we hold an unowned reference (via the standard CALayer parent
    // pointer) and never mutate it ourselves.
    private weak var mountedLayer: AVCaptureVideoPreviewLayer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Install the given layer as our sole sublayer. Idempotent: calling
    // mount() with the same layer is a no-op; calling it with a
    // different layer detaches the previous one before adding the new
    // one. nil hides any currently-mounted layer.
    func mount(previewLayer: AVCaptureVideoPreviewLayer?) {
        if mountedLayer === previewLayer {
            // Same layer; nothing to install. The layout pass will
            // still update the frame on the next layoutSubtreeIfNeeded.
            mountedLayer?.frame = bounds
            return
        }

        if let prior = mountedLayer, prior.superlayer === layer {
            prior.removeFromSuperlayer()
        }

        mountedLayer = previewLayer

        if let newLayer = previewLayer {
            newLayer.frame = bounds
            layer?.addSublayer(newLayer)
        }
    }

    override func layout() {
        super.layout()
        mountedLayer?.frame = bounds
    }
}

extension CameraPreviewHostingView {
    override public func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        window?.performDrag(with: event)
        NSCursor.contextualMenu.set()
    }

    override public func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)

        NSCursor.contextualMenu.set()
    }

    override public func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)

        NSCursor.arrow.set()
    }

    override func mouseMoved(with event: NSEvent) {
        NSCursor.contextualMenu.set()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .mouseMoved]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
}
