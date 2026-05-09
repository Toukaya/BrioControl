//
//  BoolCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Observation
import UVC

@MainActor
@Observable
final class BoolCaptureDeviceProperty {
    @ObservationIgnored private let control: UVCBoolControl

    let isCapable: Bool

    var isEnabled: Bool {
        get {
            access(keyPath: \.isEnabled)
            return control.isEnabled
        }
        set {
            if newValue != control.isEnabled {
                _ = withMutation(keyPath: \.isEnabled) {
                    Task {
                        control.isEnabled = newValue
                    }
                }
            }
        }
    }

    init(_ control: UVCBoolControl) {
        self.control = control
        isCapable = control.isCapable
        isEnabled = control.isEnabled
    }

    func reset() {
        control.isEnabled = control.defaultValue
    }

    func write() {
        isEnabled = control.isEnabled
    }
}
