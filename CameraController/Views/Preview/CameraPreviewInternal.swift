//
//  CameraPrreviewInternal.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation
import CoreMedia

final class CameraPreviewInternal: NSView {
    var captureDevice: AVCaptureDevice?
    private var captureSession: AVCaptureSession
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureInput: AVCaptureInput?

    init(frame frameRect: NSRect, device: AVCaptureDevice?) {
        captureDevice = device
        captureSession = AVCaptureSession()

        super.init(frame: frameRect)

        setupPreviewLayer(captureSession)

        Task {
            applyConfiguration(for: device)
        }

        // Show / hide of the MenuBarExtra window is observed by the
        // SwiftUI wrapper (CameraPreview), which drives
        // startSession() / stopRunning() through CameraPreviewController.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(qualityChanged),
                                               name: .cameraPreviewQualityChanged,
                                               object: nil)
    }

    private func setupPreviewLayer(_ captureSession: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: UserSettings.shared.cameraPreviewSize.getWidth(),
            height: UserSettings.shared.cameraPreviewSize.getHeight()
        )
        previewLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layout() {
        super.layout()
        previewLayer.frame = bounds
        if previewLayer.superlayer == nil {
            layer?.addSublayer(previewLayer)
        }
        previewLayer.isHidden = (UserSettings.shared.cameraPreviewQuality == .disabled)
    }

    func stopRunning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    func updateCamera(_ cam: AVCaptureDevice?) {
        if captureDevice != cam {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }

            Task {
                applyConfiguration(for: cam)
            }
        }
    }

    // Apply the input device, the preview-quality format, and start the
    // session. If the user selected Disabled, the session is left stopped
    // and the preview layer is hidden. Format selection happens BEFORE
    // startRunning while the device is locked, so activeFormat changes
    // do not race with running session state.
    private func applyConfiguration(for aDevice: AVCaptureDevice?) {
        let quality = UserSettings.shared.cameraPreviewQuality

        configureDevice(aDevice)

        if quality == .disabled {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
            DispatchQueue.main.async { [weak self] in
                self?.previewLayer?.isHidden = true
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.isHidden = false
        }

        guard let device = captureDevice else {
            return
        }

        do {
            try device.lockForConfiguration()
            applyPreviewFormat(on: device, quality: quality)
            captureSession.startRunning()
            device.unlockForConfiguration()
        } catch {
            // Locking can fail if another process holds the device. In that
            // case, fall back to whatever format the device exposes by
            // default and still start the session.
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }

    // Pick the AVCaptureDeviceFormat that best matches the requested
    // resolution. If no exact match exists, choose the largest supported
    // format whose width and height are both <= the requested resolution
    // (graceful downgrade). Then set the min/max frame duration to the
    // highest fps that the chosen format and the user's preferred fps
    // both support.
    private func applyPreviewFormat(on device: AVCaptureDevice,
                                    quality: PreviewQualitySettings) {
        let targetWidth = Int32(quality.width)
        let targetHeight = Int32(quality.height)
        let preferredFps = Double(quality.preferredFrameRate)

        var exactMatch: AVCaptureDevice.Format?
        var fallback: AVCaptureDevice.Format?
        var fallbackArea: Int32 = 0

        for format in device.formats {
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if dims.width == targetWidth && dims.height == targetHeight {
                if exactMatch == nil ||
                    bestFps(in: format) > bestFps(in: exactMatch!) {
                    exactMatch = format
                }
            } else if dims.width <= targetWidth && dims.height <= targetHeight {
                let area = dims.width * dims.height
                if area > fallbackArea {
                    fallbackArea = area
                    fallback = format
                }
            }
        }

        guard let chosen = exactMatch ?? fallback else {
            return
        }

        device.activeFormat = chosen

        // Use the device-reported AVFrameRateRange.minFrameDuration directly,
        // never construct CMTime(value: 1, timescale: fps) ourselves: many
        // devices (BRIO included) report supported ranges as e.g.
        // 1000000/60000240 (60.00024 fps), and a strict 1/60 CMTime is
        // outside that range, causing AVFoundation to throw an
        // NSInvalidArgumentException that Swift cannot catch.
        if let range = pickFrameRateRange(in: chosen, preferredFps: preferredFps) {
            device.activeVideoMinFrameDuration = range.minFrameDuration
            device.activeVideoMaxFrameDuration = range.minFrameDuration
        }
    }

    private func pickFrameRateRange(in format: AVCaptureDevice.Format,
                                    preferredFps: Double) -> AVFrameRateRange? {
        // Prefer the highest range that does not exceed `preferredFps`.
        // If none qualifies, fall back to the lowest available range.
        var bestUnderPreferred: AVFrameRateRange?
        var lowestOverall: AVFrameRateRange?
        for range in format.videoSupportedFrameRateRanges {
            if range.maxFrameRate <= preferredFps + 0.5 {
                if bestUnderPreferred == nil
                    || range.maxFrameRate > bestUnderPreferred!.maxFrameRate {
                    bestUnderPreferred = range
                }
            }
            if lowestOverall == nil
                || range.maxFrameRate < lowestOverall!.maxFrameRate {
                lowestOverall = range
            }
        }
        return bestUnderPreferred ?? lowestOverall
    }

    private func bestFps(in format: AVCaptureDevice.Format) -> Double {
        var maxFps: Double = 0
        for range in format.videoSupportedFrameRateRanges where range.maxFrameRate > maxFps {
            maxFps = range.maxFrameRate
        }
        return maxFps
    }

    private func configureDevice(_ aDevice: AVCaptureDevice?) {
        guard let device = aDevice else {
            captureDevice = aDevice
            return
        }

        if let input = captureInput {
            captureSession.removeInput(input)
        }

        do {
            captureInput = try AVCaptureDeviceInput(device: device)
        } catch {
            return
        }

        if let input = captureInput,
            captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            return
        }
        captureDevice = device
    }

    // Re-entry point used by the SwiftUI wrapper when the MenuBarExtra
    // window becomes visible again. No-op when the user disabled the
    // preview, or when the session is already running.
    func startSession() {
        if UserSettings.shared.cameraPreviewQuality == .disabled {
            return
        }
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    @objc
    func qualityChanged() {
        Task {
            applyConfiguration(for: captureDevice)
        }
    }
}

extension CameraPreviewInternal {
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
