//
//  UVCDeviceActor.swift
//  UVC
//
//  Owner-actor for one physical USB Video Class device. All IOKit
//  control transfers (UVCControl.setData / getDataFor) are funneled
//  through this actor so that:
//
//   - C function-pointer calls happen serially per device, removing
//     the lost-update race that exists when SwiftUI bindings fire
//     `Task { control.current = newValue }` from concurrent slider
//     drags.
//   - The non-Sendable UVCControl reference graph (UnsafeMutablePointer
//     interfaces, IOKit C structs) never crosses task boundaries:
//     callers exchange plain Sendable values (Int, Bool, BitmapValue)
//     keyed by UVCControlID.
//   - The view-model layer (NumberCaptureDeviceProperty etc.) can stay
//     on @MainActor with a @Bindable @Observable cache, while the
//     hardware writes hop to this actor via `Task { await ... }`.
//
//  Lifetime: one UVCDeviceActor instance per UVCDevice / DeviceController.
//  Created from CaptureDevice.init synchronously after UVCDeviceProperties
//  has finished its blocking GET_INFO/GET_MIN/.../GET_CUR probe sequence,
//  so that the synchronous snapshot fields (min/max/default/resolution/
//  isCapable) are already populated by the time the actor is spun up.
//
//  After hand-off no one outside the actor is allowed to read or mutate
//  the wrapped UVCControl instances. The control types are marked
//  @unchecked Sendable in their respective files with a comment pointing
//  at this invariant.
//

import Foundation

/// Stable identifier for a control owned by a UVCDeviceActor. The raw
/// values are arbitrary; the only requirement is that each value maps to
/// exactly one control instance per device.
public enum UVCControlID: Hashable, Sendable {
    // Standard UVC camera-terminal / processing-unit controls. Names
    // mirror UVCDeviceProperties field names so cross-referencing is
    // mechanical.
    case scanningMode
    case exposureMode
    case exposurePriority
    case exposureTime
    case focusAbsolute
    case focusAuto
    case irisAbsolute
    case zoomAbsolute
    case panTiltAbsolute
    case rollAbsolute

    case backlightCompensation
    case brightness
    case contrast
    case contrastAuto
    case gain
    case powerLineFrequency
    case hue
    case hueAuto
    case saturation
    case sharpness
    case gamma
    case whiteBalance
    case whiteBalanceAuto

    // Vendor (Logitech) XU controls.
    case logitechFieldOfView
    case logitechHDR
    case logitechRightLight
    case logitechIndicatorLed
}

/// Sendable snapshot of a UVCIntControl's discoverable, immutable-after-
/// configure() fields plus the current value at snapshot time. Property
/// view models seed their `let` fields and `var sliderValue` cache from
/// this struct synchronously during init.
public struct UVCIntControlSnapshot: Sendable {
    public let isCapable: Bool
    public let minimum: Int
    public let maximum: Int
    public let defaultValue: Int
    public let resolution: Int
    public let current: Int

    /// Nonisolated factory used by call-sites that own the control
    /// pre-handoff (e.g. DeviceController.init builds all snapshots
    /// before constructing UVCDeviceActor and surrendering ownership).
    public init(_ control: UVCIntControl) {
        self.isCapable = control.isCapable
        self.minimum = control.minimum
        self.maximum = control.maximum
        self.defaultValue = control.defaultValue
        self.resolution = control.resolution
        self.current = control.getCurrent()
    }
}

/// Sendable snapshot of a UVCBoolControl.
public struct UVCBoolControlSnapshot: Sendable {
    public let isCapable: Bool
    public let defaultValue: Bool
    public let isEnabled: Bool

    public init(_ control: UVCBoolControl) {
        self.isCapable = control.isCapable
        self.defaultValue = control.defaultValue
        self.isEnabled = control.isEnabled
    }

    public init(isCapable: Bool, defaultValue: Bool, isEnabled: Bool) {
        self.isCapable = isCapable
        self.defaultValue = defaultValue
        self.isEnabled = isEnabled
    }
}

/// Sendable snapshot of a UVCBitmapControl. We use the raw Int form so
/// the snapshot stays Sendable without the actor needing to know about
/// the consumer's enum mapping.
public struct UVCBitmapControlSnapshot: Sendable {
    public let isCapable: Bool
    public let defaultValueRaw: Int
    public let currentRaw: Int

    public init(_ control: UVCBitmapControl) {
        self.isCapable = control.isCapable
        self.defaultValueRaw = control.defaultValue.rawValue
        self.currentRaw = control.current.rawValue
    }
}

/// Sendable snapshot of a UVCMultipleIntControl (pan/tilt).
public struct UVCMultipleIntControlSnapshot: Sendable {
    public let isCapable: Bool
    public let minimum1: Int
    public let minimum2: Int
    public let maximum1: Int
    public let maximum2: Int
    public let defaultValue1: Int
    public let defaultValue2: Int
    public let resolution1: Int
    public let resolution2: Int
    public let current1: Int
    public let current2: Int

    public init(_ control: UVCMultipleIntControl) {
        self.isCapable = control.isCapable
        self.minimum1 = control.minimum1
        self.minimum2 = control.minimum2
        self.maximum1 = control.maximum1
        self.maximum2 = control.maximum2
        self.defaultValue1 = control.defaultValue1
        self.defaultValue2 = control.defaultValue2
        self.resolution1 = control.resolution1
        self.resolution2 = control.resolution2
        self.current1 = control.current1
        self.current2 = control.current2
    }
}

public actor UVCDeviceActor {
    private var intControls: [UVCControlID: UVCIntControl] = [:]
    private var boolControls: [UVCControlID: UVCBoolControl] = [:]
    private var bitmapControls: [UVCControlID: UVCBitmapControl] = [:]
    private var multipleIntControls: [UVCControlID: UVCMultipleIntControl] = [:]
    private var hdrControls: [UVCControlID: LogitechHDRControl] = [:]

    /// Strong references to the property containers solely to keep the
    /// underlying UVCControl objects alive for the actor's lifetime. The
    /// property containers are @unchecked Sendable for the same
    /// invariant: post-handoff they live only inside this actor.
    private let properties: UVCDeviceProperties
    private let logitechBrio: LogitechBrioDeviceProperties?

    /// Construct an actor that takes ownership of every control on this
    /// device. Must be called *after* the synchronous configure() probe
    /// pass run by UVCDeviceProperties.init has completed, so that the
    /// initial snapshots are valid.
    public init(properties: UVCDeviceProperties,
                logitechBrio: LogitechBrioDeviceProperties?) {
        self.properties = properties
        self.logitechBrio = logitechBrio

        // Standard UVC controls.
        intControls[.exposurePriority] = properties.exposurePriority
        intControls[.exposureTime] = properties.exposureTime
        intControls[.focusAbsolute] = properties.focusAbsolute
        intControls[.irisAbsolute] = properties.irisAbsolute
        intControls[.zoomAbsolute] = properties.zoomAbsolute
        intControls[.rollAbsolute] = properties.rollAbsolute
        intControls[.backlightCompensation] = properties.backlightCompensation
        intControls[.brightness] = properties.brightness
        intControls[.contrast] = properties.contrast
        intControls[.gain] = properties.gain
        intControls[.powerLineFrequency] = properties.powerLineFrequency
        intControls[.hue] = properties.hue
        intControls[.saturation] = properties.saturation
        intControls[.sharpness] = properties.sharpness
        intControls[.gamma] = properties.gamma
        intControls[.whiteBalance] = properties.whiteBalance

        boolControls[.scanningMode] = properties.scanningMode
        boolControls[.focusAuto] = properties.focusAuto
        boolControls[.contrastAuto] = properties.contrastAuto
        boolControls[.hueAuto] = properties.hueAuto
        boolControls[.whiteBalanceAuto] = properties.whiteBalanceAuto

        bitmapControls[.exposureMode] = properties.exposureMode

        multipleIntControls[.panTiltAbsolute] = properties.panTiltAbsolute

        // Vendor (Logitech) XU controls. The lazy XU-builder closures on
        // LogitechBrioDeviceProperties issue blocking USB control
        // transfers, so touching them here drives the same probe cost
        // that the legacy lazy access in DeviceController used to incur.
        if let brio = logitechBrio {
            if let fov = brio.fieldOfView {
                intControls[.logitechFieldOfView] = fov
            }
            if let rightLight = brio.rightLight {
                intControls[.logitechRightLight] = rightLight
            }
            if let hdr = brio.hdr {
                hdrControls[.logitechHDR] = hdr
            }
            if let led = brio.indicatorLed {
                intControls[.logitechIndicatorLed] = led
            }
        }
    }

    // MARK: - Snapshots

    public func snapshotInt(_ id: UVCControlID) -> UVCIntControlSnapshot? {
        guard let ctl = intControls[id] else { return nil }
        return UVCIntControlSnapshot(ctl)
    }

    public func snapshotBool(_ id: UVCControlID) -> UVCBoolControlSnapshot? {
        if let ctl = hdrControls[id] {
            return UVCBoolControlSnapshot(isCapable: ctl.isCapable,
                                          defaultValue: ctl.defaultValue,
                                          isEnabled: ctl.isEnabled)
        }
        guard let ctl = boolControls[id] else { return nil }
        return UVCBoolControlSnapshot(ctl)
    }

    public func snapshotBitmap(_ id: UVCControlID) -> UVCBitmapControlSnapshot? {
        guard let ctl = bitmapControls[id] else { return nil }
        return UVCBitmapControlSnapshot(ctl)
    }

    public func snapshotMultipleInt(_ id: UVCControlID) -> UVCMultipleIntControlSnapshot? {
        guard let ctl = multipleIntControls[id] else { return nil }
        return UVCMultipleIntControlSnapshot(ctl)
    }

    // MARK: - Setters

    @discardableResult
    public func setInt(_ id: UVCControlID, _ value: Int) -> Int {
        guard let ctl = intControls[id] else { return 0 }
        ctl.current = value
        return ctl.current
    }

    @discardableResult
    public func setBool(_ id: UVCControlID, _ value: Bool) -> Bool {
        if let ctl = hdrControls[id] {
            return ctl.setEnabled(value)
        }
        guard let ctl = boolControls[id] else { return false }
        ctl.isEnabled = value
        return ctl.isEnabled
    }

    @discardableResult
    public func setBitmapRaw(_ id: UVCControlID, _ rawValue: Int) -> Int {
        guard let ctl = bitmapControls[id] else { return 0 }
        guard let parsed = UVCBitmapControl.BitmapValue(rawValue: rawValue) else {
            return ctl.current.rawValue
        }
        ctl.current = parsed
        return ctl.current.rawValue
    }

    @discardableResult
    public func setMultipleInt1(_ id: UVCControlID, _ value: Int) -> Int {
        guard let ctl = multipleIntControls[id] else { return 0 }
        ctl.current1 = value
        return ctl.current1
    }

    @discardableResult
    public func setMultipleInt2(_ id: UVCControlID, _ value: Int) -> Int {
        guard let ctl = multipleIntControls[id] else { return 0 }
        ctl.current2 = value
        return ctl.current2
    }

    // MARK: - Getters / refresh

    public func getInt(_ id: UVCControlID) -> Int {
        guard let ctl = intControls[id] else { return 0 }
        return ctl.getCurrent()
    }

    public func getBool(_ id: UVCControlID) -> Bool {
        if let ctl = hdrControls[id] {
            return ctl.isEnabled
        }
        guard let ctl = boolControls[id] else { return false }
        ctl.updateEnabled()
        return ctl.isEnabled
    }

    public func getHDRPayload(_ id: UVCControlID) -> Int {
        guard let ctl = hdrControls[id] else { return 0 }
        return ctl.getCurrentPayload()
    }

    @discardableResult
    public func setHDRPayload(_ id: UVCControlID, _ payload: Int) -> Int {
        guard let ctl = hdrControls[id] else { return 0 }
        return ctl.setPayload(payload)
    }

    public func getBitmapRaw(_ id: UVCControlID) -> Int {
        guard let ctl = bitmapControls[id] else { return 0 }
        ctl.updateCurrent()
        return ctl.current.rawValue
    }

    public func getMultipleInt(_ id: UVCControlID) -> (Int, Int) {
        guard let ctl = multipleIntControls[id] else { return (0, 0) }
        ctl.updateCurrent()
        return (ctl.current1, ctl.current2)
    }

    // MARK: - Reset

    /// Reset to default for an Int control. Returns the new current.
    @discardableResult
    public func resetInt(_ id: UVCControlID) -> Int {
        guard let ctl = intControls[id] else { return 0 }
        ctl.current = ctl.defaultValue
        return ctl.current
    }

    @discardableResult
    public func resetBool(_ id: UVCControlID) -> Bool {
        if let ctl = hdrControls[id] {
            return ctl.setEnabled(ctl.defaultValue)
        }
        guard let ctl = boolControls[id] else { return false }
        ctl.isEnabled = ctl.defaultValue
        return ctl.isEnabled
    }

    @discardableResult
    public func resetBitmap(_ id: UVCControlID) -> Int {
        guard let ctl = bitmapControls[id] else { return 0 }
        ctl.current = ctl.defaultValue
        return ctl.current.rawValue
    }

    @discardableResult
    public func resetMultipleInt(_ id: UVCControlID) -> (Int, Int) {
        guard let ctl = multipleIntControls[id] else { return (0, 0) }
        ctl.current1 = ctl.defaultValue1
        ctl.current2 = ctl.defaultValue2
        return (ctl.current1, ctl.current2)
    }
}
