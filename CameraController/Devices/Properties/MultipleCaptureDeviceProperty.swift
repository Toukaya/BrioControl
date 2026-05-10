//
//  MultipleCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/25/20.
//  Copyright (c) 2020 Itaysoft. All rights reserved.
//
//  View-model wrapper for a UVCMultipleIntControl (pan/tilt). See
//  NumberCaptureDeviceProperty for the design rationale.
//

import Foundation
import Observation
import SwiftUI
import UVC

@MainActor
@Observable
final class MultipleCaptureDeviceProperty {
    @ObservationIgnored private let actor: UVCDeviceActor
    @ObservationIgnored private let controlID: UVCControlID
    @ObservationIgnored private let defaultValue1Int: Int
    @ObservationIgnored private let defaultValue2Int: Int

    var sliderValue1: Float {
        didSet {
            let value = Int(sliderValue1)
            let id = controlID
            let actor = self.actor
            Task { await actor.setMultipleInt1(id, value) }
        }
    }

    var sliderValue2: Float {
        didSet {
            let value = Int(sliderValue2)
            let id = controlID
            let actor = self.actor
            Task { await actor.setMultipleInt2(id, value) }
        }
    }

    let isCapable: Bool
    let minimum1: Float
    let minimum2: Float
    let maximum1: Float
    let maximum2: Float
    let resolution1: Float
    let resolution2: Float
    var tickStep1: Float {
        Self.tickStep(minimum: minimum1, maximum: maximum1, resolution: resolution1)
    }
    var tickStep2: Float {
        Self.tickStep(minimum: minimum2, maximum: maximum2, resolution: resolution2)
    }
    let defaultValue1: Float
    let defaultValue2: Float

    init(actor: UVCDeviceActor, id: UVCControlID, snapshot: UVCMultipleIntControlSnapshot) {
        self.actor = actor
        self.controlID = id
        self.isCapable = snapshot.isCapable
        self.minimum1 = Float(snapshot.minimum1)
        self.minimum2 = Float(snapshot.minimum2)
        self.maximum1 = Float(snapshot.maximum1)
        self.maximum2 = Float(snapshot.maximum2)
        self.resolution1 = Float(snapshot.resolution1)
        self.resolution2 = Float(snapshot.resolution2)
        self.defaultValue1 = Float(snapshot.defaultValue1)
        self.defaultValue2 = Float(snapshot.defaultValue2)
        self.defaultValue1Int = snapshot.defaultValue1
        self.defaultValue2Int = snapshot.defaultValue2
        self.sliderValue1 = Float(snapshot.current1)
        self.sliderValue2 = Float(snapshot.current2)
    }

    func reset() {
        sliderValue1 = defaultValue1
        sliderValue2 = defaultValue2
    }

    func update() {
        let id = controlID
        let actor = self.actor
        Task { @MainActor [weak self] in
            let (newValue1, newValue2) = await actor.getMultipleInt(id)
            guard let self = self else { return }

            if Int(self.sliderValue1) != newValue1 {
                self.sliderValue1 = Float(newValue1)
            }
            if Int(self.sliderValue2) != newValue2 {
                self.sliderValue2 = Float(newValue2)
            }
        }
    }

    /// Force-write the cached values back to the device (timer-driven).
    func write() {
        let value1 = Int(sliderValue1)
        let value2 = Int(sliderValue2)
        let id = controlID
        let actor = self.actor
        Task {
            await actor.setMultipleInt1(id, value1)
            await actor.setMultipleInt2(id, value2)
        }
    }

    private static func tickStep(minimum: Float, maximum: Float, resolution: Float) -> Float {
        let resolvedResolution = max(abs(resolution), 1)
        let span = abs(maximum - minimum)
        let tenth = span / 10
        guard tenth > 0 else { return resolvedResolution }
        return max(tenth, resolvedResolution)
    }

}
