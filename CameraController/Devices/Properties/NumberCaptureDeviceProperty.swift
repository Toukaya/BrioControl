//
//  IntCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright (c) 2020 Itaysoft. All rights reserved.
//
//  View-model wrapper for a UVCIntControl. The underlying UVCControl
//  lives inside UVCDeviceActor; this type holds a stable identifier
//  (UVCControlID), an actor reference, and a @Observable cache of the
//  control's current value so SwiftUI bindings stay synchronous.
//
//  Slider drags fire `Task { await actor.setInt(id, value) }`. Because
//  the actor serializes those requests, rapid drags no longer race on
//  the IOKit control transfer.
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
    @ObservationIgnored private let actor: UVCDeviceActor
    @ObservationIgnored private let controlID: UVCControlID
    @ObservationIgnored private let defaultValueInt: Int

    var sliderValue: Float {
        didSet {
            // Forward the new value to the actor. The actor serializes
            // calls per device, so concurrent slider drags can no longer
            // interleave their underlying USB control transfers.
            let newInt = Int(sliderValue)
            let id = controlID
            let actor = self.actor
            Task { await actor.setInt(id, newInt) }
        }
    }

    let isCapable: Bool
    let minimum: Float
    var maximum: Float
    let resolution: Float
    let defaultValue: Float

    init(actor: UVCDeviceActor, id: UVCControlID, snapshot: UVCIntControlSnapshot) {
        self.actor = actor
        self.controlID = id
        self.isCapable = snapshot.isCapable
        self.minimum = Float(snapshot.minimum)
        self.maximum = Float(snapshot.maximum)
        self.resolution = Float(snapshot.resolution)
        self.defaultValue = Float(snapshot.defaultValue)
        self.defaultValueInt = snapshot.defaultValue
        self.sliderValue = Float(snapshot.current)
    }

    func reset() {
        sliderValue = defaultValue
    }

    /// Re-read the current value from the device (timer-driven).
    func update() {
        let id = controlID
        let actor = self.actor
        Task { @MainActor [weak self] in
            let newValue = await actor.getInt(id)
            guard let self = self else { return }
            // Only mutate the @Observable cache if the value actually
            // changed; this avoids triggering didSet (and a redundant
            // hardware write) on every poll tick.
            if Int(self.sliderValue) != newValue {
                self.sliderValue = Float(newValue)
            }
        }
    }

    /// Force-write the cached value back to the device (timer-driven).
    /// Re-issues the slider value through the actor, providing a
    /// last-write-wins convergence path if a previous SET failed.
    func write() {
        let value = Int(sliderValue)
        let id = controlID
        let actor = self.actor
        Task { await actor.setInt(id, value) }
    }
}
