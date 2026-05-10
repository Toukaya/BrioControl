//
//  PreviewSession.swift
//  CameraController
//
//  Owns the AVCaptureSession lifecycle for the menu-bar preview.
//
//  Before TASK-09 the AVCaptureSession was created inside the preview
//  NSView, and start/stop was driven from a transitional reference-type
//  bridge plus view-lifecycle callbacks. That made it impossible to
//  coordinate device-switch / quality-change / scenePhase transitions
//  atomically and leaked sessions when the user switched devices
//  rapidly.
//
//  After TASK-09 the AVCaptureSession is owned by this single
//  @MainActor @Observable type. Views drive it declaratively via
//  `.task(id:)` and `.onChange(of:)`. CameraPreview is a thin renderer
//  that just hosts `previewLayer` in an NSView.
//

import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
final class PreviewSession {
    // The single AVCaptureSession instance that backs the preview. The
    // verification grep `rg 'AVCaptureSession\(\)' CameraController/`
    // must match this one and only this one.
    //
    // `nonisolated(unsafe)` is the narrowest escape hatch that lets the
    // session reference be captured in the `nonisolated` start/stop
    // helpers below. AVCaptureSession is documented as safe to call
    // startRunning / stopRunning from a background queue, and the
    // `ioQueue` serializes those calls so they can never race with each
    // other; configuration mutations (beginConfiguration / addInput /
    // commitConfiguration) all happen on the main actor.
    @ObservationIgnored
    nonisolated(unsafe) private let session = AVCaptureSession()

    // The AVCaptureVideoPreviewLayer is created once, bound to `session`,
    // and handed to CameraPreview as a prop. Because CALayer is mutable
    // reference type and never reassigned after creation, observers see
    // a stable identity for the lifetime of this PreviewSession.
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    // The currently attached device, exposed for diagnostics / future
    // tests. Mutated only on the main actor as part of attach / detach.
    private(set) var currentDevice: AVCaptureDevice?

    // The quality the session was last configured for. nil until the
    // first attach. Exposed so TASK-01's quality picker (and any future
    // diagnostics view) can show "currently rendering at ..." without
    // re-deriving the answer from UserSettings.
    private(set) var currentQuality: PreviewQualitySettings?

    // The currently installed input. Tracked so detach() and a
    // device-switch attach can call removeInput() before adding the new
    // one, instead of leaving stale inputs on the session.
    @ObservationIgnored private var currentInput: AVCaptureInput?

    // Serial queue used to host the blocking AVFoundation calls
    // (startRunning / stopRunning can each block the calling thread for
    // up to ~5 seconds on cold cameras). Keeping them off the main
    // actor avoids stalling the UI; serializing them avoids the
    // out-of-order start/stop interleavings that the old NSView-based
    // pipeline could produce when the user toggled scenes / devices
    // rapidly.
    @ObservationIgnored
    private let ioQueue = DispatchQueue(label: "com.itaysoft.CameraController.PreviewSession.io",
                                        qos: .userInitiated)

    init() {
        // Bridge the legacy UserSettings.cameraPreviewQuality didSet
        // notification (kept for backwards compatibility while TASK-01
        // is still pending). Once TASK-01 lands, the picker UI will
        // call change(quality:) directly and this observer can be
        // removed in the same commit that introduces the picker.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(qualityNotification),
                                               name: .cameraPreviewQualityChanged,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API

    // Attach the given device at the given quality. Safe to call when a
    // different device is already attached: the previous input is
    // removed and the session is reconfigured atomically inside a
    // single beginConfiguration / commitConfiguration pair before the
    // potentially-blocking startRunning is dispatched off-main.
    //
    // Quality .disabled keeps the session stopped and hides the
    // preview layer; this matches the legacy behavior so users who
    // previously selected "Disabled" continue to see no preview.
    func attach(device: AVCaptureDevice, quality: PreviewQualitySettings) async {
        ensurePreviewLayer()

        // Stop first; on a fresh PreviewSession this is a no-op and
        // returns immediately. On a device switch this is the cheap
        // teardown of the prior pipeline before reconfiguration.
        await stopSessionOffMain()

        currentDevice = device
        currentQuality = quality

        configureInput(for: device)

        if quality == .disabled {
            previewLayer?.isHidden = true
            return
        }

        previewLayer?.isHidden = false
        applyFormat(on: device, quality: quality)
        await startSessionOffMain()
    }

    // Tear down the active pipeline. After detach(), previewLayer is
    // hidden and the session is stopped, but the layer itself is kept
    // alive so a subsequent attach(device:quality:) can resume cheaply
    // without flicker from re-allocating an AVCaptureVideoPreviewLayer.
    func detach() async {
        await stopSessionOffMain()
        if let input = currentInput {
            session.beginConfiguration()
            session.removeInput(input)
            session.commitConfiguration()
            currentInput = nil
        }
        previewLayer?.isHidden = true
        currentDevice = nil
    }

    // Re-configure the active session for a different preview quality.
    // No-op when no device is attached (the next attach() will pick up
    // the new quality). When a device is attached, swaps activeFormat
    // while the session is briefly stopped so AVFoundation does not
    // raise the "cannot change activeFormat while running" exception.
    //
    // TASK-01's quality picker is expected to call this from a
    // .onChange(of: settings.cameraPreviewQuality) modifier in
    // ContentView.
    func change(quality: PreviewQualitySettings) async {
        currentQuality = quality
        guard let device = currentDevice else {
            return
        }

        await stopSessionOffMain()

        if quality == .disabled {
            previewLayer?.isHidden = true
            return
        }

        previewLayer?.isHidden = false
        applyFormat(on: device, quality: quality)
        await startSessionOffMain()
    }

    // Suspend the running session without dropping the configured
    // device. Used when the SwiftUI scenePhase leaves .active so the
    // camera LED turns off while the menu-bar popover is hidden.
    func suspend() async {
        await stopSessionOffMain()
    }

    // Resume the previously-configured session. No-op when no device
    // is attached, or when the user selected the .disabled quality.
    func resume() async {
        guard currentDevice != nil else {
            return
        }
        guard currentQuality != nil && currentQuality != .disabled else {
            return
        }
        await startSessionOffMain()
    }

    // MARK: - Notification bridge (transitional, removed by TASK-01)

    @objc
    private func qualityNotification() {
        // The notification is posted from UserSettings.cameraPreviewQuality
        // didSet on the main actor; hop explicitly to satisfy Swift 6
        // concurrency checks and to read UserSettings.shared safely.
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.change(quality: UserSettings.shared.cameraPreviewQuality)
        }
    }

    // MARK: - Internals

    private func ensurePreviewLayer() {
        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspect
            previewLayer = layer
        }
    }

    private func configureInput(for device: AVCaptureDevice) {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if let existing = currentInput {
            session.removeInput(existing)
            currentInput = nil
        }

        let newInput: AVCaptureDeviceInput
        do {
            newInput = try AVCaptureDeviceInput(device: device)
        } catch {
            // The device is unusable as an input (in use by another
            // process, removed mid-attach, etc). Leave the session
            // empty; the next attach() will retry.
            return
        }

        if session.canAddInput(newInput) {
            session.addInput(newInput)
            currentInput = newInput
        }
    }

    // Pick the AVCaptureDeviceFormat that best matches the requested
    // resolution and apply it under a lockForConfiguration block. Same
    // selection policy as the pre-TASK-09 CameraPreviewInternal: prefer
    // an exact match, otherwise the largest format whose width and
    // height are both within the requested bounds.
    private func applyFormat(on device: AVCaptureDevice,
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

        do {
            try device.lockForConfiguration()
        } catch {
            // Locking can fail if another process holds the device.
            // In that case fall back to whatever format the device
            // exposes by default; startRunning will still happen and
            // produce some preview rather than none.
            return
        }

        device.activeFormat = chosen

        // Use the device-reported AVFrameRateRange.minFrameDuration
        // directly. Constructing CMTime(value: 1, timescale: fps)
        // ourselves drifts off the supported ranges some webcams
        // (Logitech BRIO included) advertise (e.g. 60.00024 fps), and
        // setting that drifted value raises NSInvalidArgumentException
        // which Swift cannot catch.
        if let range = pickFrameRateRange(in: chosen, preferredFps: preferredFps) {
            device.activeVideoMinFrameDuration = range.minFrameDuration
            device.activeVideoMaxFrameDuration = range.minFrameDuration
        }

        device.unlockForConfiguration()
    }

    private func pickFrameRateRange(in format: AVCaptureDevice.Format,
                                    preferredFps: Double) -> AVFrameRateRange? {
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

    // MARK: - Off-main lifecycle helpers

    // startRunning / stopRunning each block the calling thread for up
    // to ~5 seconds on cold cameras. Dispatching them onto the
    // dedicated serial ioQueue keeps the main actor responsive and
    // serializes start/stop pairs so they can never interleave out of
    // order even when attach() / detach() / change() are called in
    // rapid succession.
    nonisolated private func startSessionOffMain() async {
        let captured = SessionBox(session: session)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ioQueue.async {
                if !captured.session.isRunning {
                    captured.session.startRunning()
                }
                continuation.resume()
            }
        }
    }

    nonisolated private func stopSessionOffMain() async {
        let captured = SessionBox(session: session)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ioQueue.async {
                if captured.session.isRunning {
                    captured.session.stopRunning()
                }
                continuation.resume()
            }
        }
    }
}

// Sendable box around the non-Sendable AVCaptureSession. The session
// instance itself is owned by exactly one PreviewSession and the boxes
// are short-lived — they exist only for the round trip into the
// ioQueue.async closure. AVCaptureSession's start/stop API is
// documented as safe to call from any thread, and the ioQueue
// serializes those calls per-PreviewSession; configuration writes stay
// on the main actor. The `@unchecked Sendable` here is therefore
// asserting "this reference is safe to ferry across an isolation hop
// because no one else will touch it concurrently".
private struct SessionBox: @unchecked Sendable {
    let session: AVCaptureSession
}
