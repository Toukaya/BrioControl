//
//  BitmapCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Observation
import UVC

@MainActor
@Observable
final class BitmapCaptureDeviceProperty {
    @ObservationIgnored private let control: UVCBitmapControl

    let isCapable: Bool

    var selected: UVCBitmapControl.BitmapValue {
        get {
            access(keyPath: \.selected)
            return control.current
        }
        set {
            _ = withMutation(keyPath: \.selected) {
                Task {
                    control.current = newValue
                }
            }
        }
    }

    init(_ control: UVCBitmapControl) {
        self.control = control
        isCapable = control.isCapable
        selected = control.current
    }

    func reset() {
        control.current = control.defaultValue
    }

    func write() {
        selected = control.current
    }
}
