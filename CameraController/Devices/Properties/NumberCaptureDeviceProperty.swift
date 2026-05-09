//
//  IntCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Combine
import UVC

protocol SliderCapableProperty {
    var sliderValue: Float { get set }
    var isCapable: Bool { get }
    var minimum: Float { get }
    var maximum: Float { get }
    var resolution: Float { get }
    var defaultValue: Float { get }
}

final class NumberCaptureDeviceProperty: SliderCapableProperty, ObservableObject {
    private let control: UVCIntControl

    var sliderValue: Float {
        get {
            return Float(control.current)
        }
        set {
            if sliderValue != newValue {
                // Defer the change notification so SwiftUI does not see a
                // publish during a view-update cycle.
                DispatchQueue.main.async { [weak self] in
                    self?.objectWillChange.send()
                }
                Task {
                    control.current = Int(newValue)
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
