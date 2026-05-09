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

        // Build snapshots BEFORE handing the property graph to the actor.
        // At this point we are the single owner of every UVCControl, so
        // reading the configured min/max/default/resolution/current
        // fields is safe and serial.
        let exposureModeSnap = UVCBitmapControlSnapshot(properties.exposureMode)
        let exposureTimeSnap = UVCIntControlSnapshot(properties.exposureTime)
        let gainSnap = UVCIntControlSnapshot(properties.gain)
        let brightnessSnap = UVCIntControlSnapshot(properties.brightness)
        let contrastSnap = UVCIntControlSnapshot(properties.contrast)
        let saturationSnap = UVCIntControlSnapshot(properties.saturation)
        let sharpnessSnap = UVCIntControlSnapshot(properties.sharpness)
        let hueSnap = UVCIntControlSnapshot(properties.hue)
        let hueAutoSnap = UVCBoolControlSnapshot(properties.hueAuto)
        let whiteBalanceAutoSnap = UVCBoolControlSnapshot(properties.whiteBalanceAuto)
        let whiteBalanceSnap = UVCIntControlSnapshot(properties.whiteBalance)
        let powerLineSnap = UVCIntControlSnapshot(properties.powerLineFrequency)
        let backlightSnap = UVCIntControlSnapshot(properties.backlightCompensation)
        let zoomSnap = UVCIntControlSnapshot(properties.zoomAbsolute)
        let panTiltSnap = UVCMultipleIntControlSnapshot(properties.panTiltAbsolute)
        let rollSnap = UVCIntControlSnapshot(properties.rollAbsolute)
        let focusAutoSnap = UVCBoolControlSnapshot(properties.focusAuto)
        let focusAbsoluteSnap = UVCIntControlSnapshot(properties.focusAbsolute)

        // Vendor controls. Touching `fieldOfView` / `rightLight` /
        // `indicatorLed` triggers the lazy probe described in
        // LogitechBrioDeviceProperties. Build the snapshots here so the
        // probe cost is paid once, on the same thread that built the
        // controls, before the actor takes ownership.
        let fovSnap: UVCIntControlSnapshot? = logitechBrio?.fieldOfView.map { UVCIntControlSnapshot($0) }
        let rightLightSnap: UVCIntControlSnapshot? = logitechBrio?.rightLight.map { UVCIntControlSnapshot($0) }
        let ledSnap: UVCIntControlSnapshot? = logitechBrio?.indicatorLed.map { UVCIntControlSnapshot($0) }

        // Hand off control ownership to the actor.
        let actor = UVCDeviceActor(properties: properties, logitechBrio: logitechBrio)
        self.uvcActor = actor

        self.exposureMode = Self.makeBitmap(actor, .exposureMode, exposureModeSnap)
        self.exposureTime = Self.makeNumber(actor, .exposureTime, exposureTimeSnap)
        self.gain = Self.makeNumber(actor, .gain, gainSnap)
        self.brightness = Self.makeNumber(actor, .brightness, brightnessSnap)
        self.contrast = Self.makeNumber(actor, .contrast, contrastSnap)
        self.saturation = Self.makeNumber(actor, .saturation, saturationSnap)
        self.sharpness = Self.makeNumber(actor, .sharpness, sharpnessSnap)
        self.hue = Self.makeNumber(actor, .hue, hueSnap)
        self.hueAuto = Self.makeBool(actor, .hueAuto, hueAutoSnap)
        self.whiteBalanceAuto = Self.makeBool(actor, .whiteBalanceAuto, whiteBalanceAutoSnap)
        self.whiteBalance = Self.makeNumber(actor, .whiteBalance, whiteBalanceSnap)
        self.powerLineFrequency = Self.makeNumber(actor, .powerLineFrequency, powerLineSnap)
        self.backlightCompensation = Self.makeNumber(actor, .backlightCompensation, backlightSnap)
        self.zoomAbsolute = Self.makeNumber(actor, .zoomAbsolute, zoomSnap)
        self.panTiltAbsolute = Self.makeMultiple(actor, .panTiltAbsolute, panTiltSnap)
        self.rollAbsolute = Self.makeNumber(actor, .rollAbsolute, rollSnap)
        self.focusAuto = Self.makeBool(actor, .focusAuto, focusAutoSnap)
        self.focusAbsolute = Self.makeNumber(actor, .focusAbsolute, focusAbsoluteSnap)

        self.logitechFieldOfView = fovSnap.map { Self.makeNumber(actor, .logitechFieldOfView, $0) }
        self.logitechRightLight = rightLightSnap.map { Self.makeNumber(actor, .logitechRightLight, $0) }
        self.logitechLed = ledSnap.map { Self.makeNumber(actor, .logitechIndicatorLed, $0) }
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
