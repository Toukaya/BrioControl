//
//  IntCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Observation
import UVC

@MainActor
protocol SliderCapableProperty {
    var sliderValue: Float { get set }
    var isCapable: Bool { get }
    var minimum: Float { get }
    var maximum: Float { get }
    var resolution: Float { get }
    var defaultValue: Float { get }
}

@MainActor
@Observable
final class NumberCaptureDeviceProperty: SliderCapableProperty {
    @ObservationIgnored private let control: UVCIntControl

    var sliderValue: Float {
        get {
            access(keyPath: \.sliderValue)
            return Float(control.current)
        }
        set {
            if Float(control.current) != newValue {
                _ = withMutation(keyPath: \.sliderValue) {
                    Task {
                        control.current = Int(newValue)
                    }
                }
            }
        }
    }

    let isCapable: Bool
    let minimum: Float
    var maximum: Float
    let resolution: Float
    let defaultValue: Float

    init(_ control: UVCIntControl) {
        self.control = control
        isCapable = control.isCapable
        minimum = Float(control.minimum)
        maximum = Float(control.maximum)
        resolution = Float(control.resolution)
        defaultValue = Float(control.defaultValue)
        sliderValue = Float(control.current)
    }

    func reset() {
        control.current = control.defaultValue
    }

    func update() {
        let newValue = control.getCurrent()
        sliderValue = Float(newValue)
    }

    func write() {
        sliderValue = Float(control.current)
    }
}
