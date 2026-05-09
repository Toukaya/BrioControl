//
//  DeviceController.swift
//  CameraController
//
//  Created by Itay Brenner on 7/23/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
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
    @ObservationIgnored lazy var exposureMode = BitmapCaptureDeviceProperty(properties.exposureMode)
    @ObservationIgnored lazy var exposureTime = NumberCaptureDeviceProperty(properties.exposureTime)
    @ObservationIgnored lazy var gain = NumberCaptureDeviceProperty(properties.gain)

    // Image
    @ObservationIgnored lazy var brightness = NumberCaptureDeviceProperty(properties.brightness)
    @ObservationIgnored lazy var contrast = NumberCaptureDeviceProperty(properties.contrast)
    @ObservationIgnored lazy var saturation = NumberCaptureDeviceProperty(properties.saturation)
    @ObservationIgnored lazy var sharpness = NumberCaptureDeviceProperty(properties.sharpness)
    @ObservationIgnored lazy var hue = NumberCaptureDeviceProperty(properties.hue)
    @ObservationIgnored lazy var hueAuto = BoolCaptureDeviceProperty(properties.hueAuto)

    // WhiteBalance
    @ObservationIgnored lazy var whiteBalanceAuto = BoolCaptureDeviceProperty(properties.whiteBalanceAuto)
    @ObservationIgnored lazy var whiteBalance = NumberCaptureDeviceProperty(properties.whiteBalance)

    // PowerLine
    @ObservationIgnored lazy var powerLineFrequency = NumberCaptureDeviceProperty(properties.powerLineFrequency)

    // Backlight Compensation
    @ObservationIgnored lazy var backlightCompensation = NumberCaptureDeviceProperty(properties.backlightCompensation)

    // Orientation
    @ObservationIgnored lazy var zoomAbsolute = NumberCaptureDeviceProperty(properties.zoomAbsolute)
    @ObservationIgnored lazy var panTiltAbsolute = MultipleCaptureDeviceProperty(properties.panTiltAbsolute)
    @ObservationIgnored lazy var rollAbsolute = NumberCaptureDeviceProperty(properties.rollAbsolute)

    // Focus
    @ObservationIgnored lazy var focusAuto = BoolCaptureDeviceProperty(properties.focusAuto)
    @ObservationIgnored lazy var focusAbsolute = NumberCaptureDeviceProperty(properties.focusAbsolute)

    // Vendor-specific (currently Logitech only)
    @ObservationIgnored let logitechBrio: LogitechBrioDeviceProperties?
    @ObservationIgnored lazy var logitechFieldOfView: NumberCaptureDeviceProperty? = {
        guard let control = logitechBrio?.fieldOfView else { return nil }
        return NumberCaptureDeviceProperty(control)
    }()
    @ObservationIgnored lazy var logitechLed: NumberCaptureDeviceProperty? = {
        guard let control = logitechBrio?.indicatorLed else { return nil }
        return NumberCaptureDeviceProperty(control)
    }()
    @ObservationIgnored lazy var logitechRightLight: NumberCaptureDeviceProperty? = {
        guard let control = logitechBrio?.rightLight else { return nil }
        return NumberCaptureDeviceProperty(control)
    }()

    @ObservationIgnored private let properties: UVCDeviceProperties

    init?(properties: UVCDeviceProperties?, logitechBrio: LogitechBrioDeviceProperties?) {
        guard let properties = properties else {
            return nil
        }
        self.properties = properties
        self.logitechBrio = logitechBrio
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
        self.panTiltAbsolute.reset()
        self.focusAuto.reset()
        self.focusAbsolute.reset()
    }
}
