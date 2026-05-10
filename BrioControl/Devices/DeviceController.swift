//
//  DeviceController.swift
//  CameraController
//
//  Created by Itay Brenner on 7/23/20.
//  Copyright (c) 2020 Itaysoft. All rights reserved.
//
//  Per-device view-model bundle. Owns one UVCDeviceActor (which in turn
//  owns every UVCControl on this physical USB device) and a set of
//  @MainActor @Observable property wrappers that SwiftUI binds against.
//
//  Hand-off invariant: this file constructs every snapshot synchronously
//  from the freshly-configured UVCDeviceProperties and then transfers
//  ownership of the property containers (and the controls inside them)
//  into the actor. After UVCDeviceActor's init returns, no other code
//  reads or writes any UVCControl directly.
//

import Foundation
import Observation
import UVC

@MainActor
@Observable
final class DeviceController {
    // The lazy sub-properties are stored references to objects that are
    // themselves @Observable. SwiftUI views observe each property's own
    // state directly (via @Bindable), so DeviceController does not need
    // to participate in observation tracking for these handles -- and
    // @ObservationIgnored is required because the @Observable macro is
    // incompatible with `lazy`.

    // Exposure
    let exposureMode: BitmapCaptureDeviceProperty
    let exposureTime: NumberCaptureDeviceProperty
    let gain: NumberCaptureDeviceProperty

    // Image
    let brightness: NumberCaptureDeviceProperty
    let contrast: NumberCaptureDeviceProperty
    let saturation: NumberCaptureDeviceProperty
    let sharpness: NumberCaptureDeviceProperty
    let hue: NumberCaptureDeviceProperty
    let hueAuto: BoolCaptureDeviceProperty

    // WhiteBalance
    let whiteBalanceAuto: BoolCaptureDeviceProperty
    let whiteBalance: NumberCaptureDeviceProperty

    // PowerLine
    let powerLineFrequency: NumberCaptureDeviceProperty

    // Backlight Compensation
    let backlightCompensation: NumberCaptureDeviceProperty

    // Orientation
    let zoomAbsolute: NumberCaptureDeviceProperty
    let panTiltAbsolute: MultipleCaptureDeviceProperty
    let rollAbsolute: NumberCaptureDeviceProperty

    // Focus
    let focusAuto: BoolCaptureDeviceProperty
    let focusAbsolute: NumberCaptureDeviceProperty

    // Vendor-specific (currently Logitech only)
    let logitechFieldOfView: NumberCaptureDeviceProperty?
    let logitechHDR: BoolCaptureDeviceProperty?
    let logitechLed: NumberCaptureDeviceProperty?
    let logitechRightLight: NumberCaptureDeviceProperty?

    /// Strong reference to the per-device actor. Keeps every UVCControl
    /// on this physical device alive for as long as the controller (and
    /// thus the parent CaptureDevice) is alive.
    @ObservationIgnored let uvcActor: UVCDeviceActor

    init?(properties: UVCDeviceProperties?, logitechBrio: LogitechBrioDeviceProperties?) {
        guard let properties = properties else {
            return nil
        }

        // All snapshots are constructed BEFORE the actor takes
        // ownership of the property graph. See Snapshots below for the
        // per-control build steps; the lazy vendor probes in
        // LogitechBrioDeviceProperties are also forced inside that init.
        let snap = Snapshots(properties: properties, brio: logitechBrio)

        let actor = UVCDeviceActor(properties: properties, logitechBrio: logitechBrio)
        self.uvcActor = actor

        self.exposureMode = Self.makeBitmap(actor, .exposureMode, snap.exposureMode)
        self.exposureTime = Self.makeNumber(actor, .exposureTime, snap.exposureTime)
        self.gain = Self.makeNumber(actor, .gain, snap.gain)
        self.brightness = Self.makeNumber(actor, .brightness, snap.brightness)
        self.contrast = Self.makeNumber(actor, .contrast, snap.contrast)
        self.saturation = Self.makeNumber(actor, .saturation, snap.saturation)
        self.sharpness = Self.makeNumber(actor, .sharpness, snap.sharpness)
        self.hue = Self.makeNumber(actor, .hue, snap.hue)
        self.hueAuto = Self.makeBool(actor, .hueAuto, snap.hueAuto)
        self.whiteBalanceAuto = Self.makeBool(actor, .whiteBalanceAuto, snap.whiteBalanceAuto)
        self.whiteBalance = Self.makeNumber(actor, .whiteBalance, snap.whiteBalance)
        self.powerLineFrequency = Self.makeNumber(actor, .powerLineFrequency, snap.powerLine)
        self.backlightCompensation = Self.makeNumber(actor, .backlightCompensation, snap.backlight)
        self.zoomAbsolute = Self.makeNumber(actor, .zoomAbsolute, snap.zoom)
        self.panTiltAbsolute = Self.makeMultiple(actor, .panTiltAbsolute, snap.panTilt)
        self.rollAbsolute = Self.makeNumber(actor, .rollAbsolute, snap.roll)
        self.focusAuto = Self.makeBool(actor, .focusAuto, snap.focusAuto)
        self.focusAbsolute = Self.makeNumber(actor, .focusAbsolute, snap.focusAbsolute)

        self.logitechFieldOfView = snap.fov.map { Self.makeNumber(actor, .logitechFieldOfView, $0) }
        self.logitechHDR = snap.hdr.map { Self.makeBool(actor, .logitechHDR, $0) }
        self.logitechRightLight = snap.rightLight.map { Self.makeNumber(actor, .logitechRightLight, $0) }
        self.logitechLed = snap.led.map { Self.makeNumber(actor, .logitechIndicatorLed, $0) }
    }

    // Bundles every per-control snapshot built during DeviceController
    // construction. Lives in its own struct so DeviceController.init
    // stays under the function_body_length lint, and to make the
    // snapshot-then-handoff invariant explicit: all snapshot reads are
    // performed in this struct's init, BEFORE the actor takes ownership.
    private struct Snapshots {
        let exposureMode: UVCBitmapControlSnapshot
        let exposureTime: UVCIntControlSnapshot
        let gain: UVCIntControlSnapshot
        let brightness: UVCIntControlSnapshot
        let contrast: UVCIntControlSnapshot
        let saturation: UVCIntControlSnapshot
        let sharpness: UVCIntControlSnapshot
        let hue: UVCIntControlSnapshot
        let hueAuto: UVCBoolControlSnapshot
        let whiteBalanceAuto: UVCBoolControlSnapshot
        let whiteBalance: UVCIntControlSnapshot
        let powerLine: UVCIntControlSnapshot
        let backlight: UVCIntControlSnapshot
        let zoom: UVCIntControlSnapshot
        let panTilt: UVCMultipleIntControlSnapshot
        let roll: UVCIntControlSnapshot
        let focusAuto: UVCBoolControlSnapshot
        let focusAbsolute: UVCIntControlSnapshot
        let fov: UVCIntControlSnapshot?
        let hdr: UVCBoolControlSnapshot?
        let rightLight: UVCIntControlSnapshot?
        let led: UVCIntControlSnapshot?

        init(properties: UVCDeviceProperties, brio: LogitechBrioDeviceProperties?) {
            self.exposureMode = UVCBitmapControlSnapshot(properties.exposureMode)
            self.exposureTime = UVCIntControlSnapshot(properties.exposureTime)
            self.gain = UVCIntControlSnapshot(properties.gain)
            self.brightness = UVCIntControlSnapshot(properties.brightness)
            self.contrast = UVCIntControlSnapshot(properties.contrast)
            self.saturation = UVCIntControlSnapshot(properties.saturation)
            self.sharpness = UVCIntControlSnapshot(properties.sharpness)
            self.hue = UVCIntControlSnapshot(properties.hue)
            self.hueAuto = UVCBoolControlSnapshot(properties.hueAuto)
            self.whiteBalanceAuto = UVCBoolControlSnapshot(properties.whiteBalanceAuto)
            self.whiteBalance = UVCIntControlSnapshot(properties.whiteBalance)
            self.powerLine = UVCIntControlSnapshot(properties.powerLineFrequency)
            self.backlight = UVCIntControlSnapshot(properties.backlightCompensation)
            self.zoom = UVCIntControlSnapshot(properties.zoomAbsolute)
            self.panTilt = UVCMultipleIntControlSnapshot(properties.panTiltAbsolute)
            self.roll = UVCIntControlSnapshot(properties.rollAbsolute)
            self.focusAuto = UVCBoolControlSnapshot(properties.focusAuto)
            self.focusAbsolute = UVCIntControlSnapshot(properties.focusAbsolute)
            self.fov = brio?.fieldOfView.map { UVCIntControlSnapshot($0) }
            self.hdr = brio?.hdr.map {
                UVCBoolControlSnapshot(isCapable: $0.isCapable,
                                       defaultValue: $0.defaultValue,
                                       isEnabled: $0.isEnabled)
            }
            self.rightLight = brio?.rightLight.map { UVCIntControlSnapshot($0) }
            self.led = brio?.indicatorLed.map { UVCIntControlSnapshot($0) }
        }
    }

    var isHDR: Bool {
        return logitechHDR?.isEnabled ?? false
    }

    func setHDR(_ enabled: Bool) {
        logitechHDR?.isEnabled = enabled
    }

    func toggleHDR() {
        guard let hdr = logitechHDR else { return }
        hdr.isEnabled.toggle()
    }

    private static func makeNumber(_ actor: UVCDeviceActor,
                                   _ id: UVCControlID,
                                   _ snap: UVCIntControlSnapshot) -> NumberCaptureDeviceProperty {
        return NumberCaptureDeviceProperty(actor: actor, id: id, snapshot: snap)
    }

    private static func makeBool(_ actor: UVCDeviceActor,
                                 _ id: UVCControlID,
                                 _ snap: UVCBoolControlSnapshot) -> BoolCaptureDeviceProperty {
        return BoolCaptureDeviceProperty(actor: actor, id: id, snapshot: snap)
    }

    private static func makeBitmap(_ actor: UVCDeviceActor,
                                   _ id: UVCControlID,
                                   _ snap: UVCBitmapControlSnapshot) -> BitmapCaptureDeviceProperty {
        return BitmapCaptureDeviceProperty(actor: actor, id: id, snapshot: snap)
    }

    private static func makeMultiple(_ actor: UVCDeviceActor,
                                     _ id: UVCControlID,
                                     _ snap: UVCMultipleIntControlSnapshot) -> MultipleCaptureDeviceProperty {
        return MultipleCaptureDeviceProperty(actor: actor, id: id, snapshot: snap)
    }

    func writeValues() {
        exposureMode.write()
        exposureTime.write()
        gain.write()
        brightness.write()
        contrast.write()
        saturation.write()
        sharpness.write()
        whiteBalanceAuto.write()
        whiteBalance.write()
        powerLineFrequency.write()
        backlightCompensation.write()
        zoomAbsolute.write()
        panTiltAbsolute.write()
        focusAuto.write()
        focusAbsolute.write()
    }

    func getSettings() -> DeviceSettings {
        return DeviceSettings(exposureMode: self.exposureMode.selected.rawValue,
                              exposureTime: self.exposureTime.sliderValue,
                              gain: self.gain.sliderValue,
                              brightness: self.brightness.sliderValue,
                              contrast: self.contrast.sliderValue,
                              saturation: self.saturation.sliderValue,
                              sharpness: self.sharpness.sliderValue,
                              whiteBalanceAuto: self.whiteBalanceAuto.isEnabled,
                              whiteBalance: self.whiteBalance.sliderValue,
                              powerline: self.powerLineFrequency.sliderValue,
                              backlightCompensation: self.backlightCompensation.sliderValue,
                              zoom: self.zoomAbsolute.sliderValue,
                              pan: self.panTiltAbsolute.sliderValue1,
                              tilt: self.panTiltAbsolute.sliderValue2,
                              focusAuto: self.focusAuto.isEnabled,
                              focus: self.focusAbsolute.sliderValue)
    }

    func set(_ deviceSettings: DeviceSettings) {
        self.exposureMode.selected = UVCBitmapControl.BitmapValue(rawValue: deviceSettings.exposureMode) ?? .auto
        self.exposureTime.sliderValue = deviceSettings.exposureTime
        self.gain.sliderValue = deviceSettings.gain
        self.brightness.sliderValue = deviceSettings.brightness
        self.contrast.sliderValue = deviceSettings.contrast
        self.saturation.sliderValue = deviceSettings.saturation
        self.sharpness.sliderValue = deviceSettings.sharpness
        self.whiteBalanceAuto.isEnabled = deviceSettings.whiteBalanceAuto
        self.whiteBalance.sliderValue = deviceSettings.whiteBalance
        self.powerLineFrequency.sliderValue = deviceSettings.powerline
        self.backlightCompensation.sliderValue = deviceSettings.backlightCompensation
        self.zoomAbsolute.sliderValue = deviceSettings.zoom
        self.panTiltAbsolute.sliderValue1 = deviceSettings.pan
        self.panTiltAbsolute.sliderValue2 = deviceSettings.tilt
        self.focusAuto.isEnabled = deviceSettings.focusAuto
        self.focusAbsolute.sliderValue = deviceSettings.focus
    }

    func resetDefault() {
        self.exposureMode.reset()
        self.exposureTime.reset()
        self.gain.reset()
        self.brightness.reset()
        self.contrast.reset()
        self.saturation.reset()
        self.sharpness.reset()
        self.whiteBalanceAuto.reset()
        self.whiteBalance.reset()
        self.powerLineFrequency.reset()
        self.backlightCompensation.reset()
        self.zoomAbsolute.reset()
        self.panTiltAbsolute.reset()
        self.focusAuto.reset()
        self.focusAbsolute.reset()
    }
}
