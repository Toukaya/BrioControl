//
//  BoolCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright (c) 2020 Itaysoft. All rights reserved.
//
//  View-model wrapper for a UVCBoolControl. See NumberCaptureDeviceProperty
//  for the design rationale -- the UVCControl lives inside UVCDeviceActor
//  and this type is the @MainActor / @Observable cache that SwiftUI binds
//  against.
//

import Foundation
import Observation
import UVC

@MainActor
@Observable
final class BoolCaptureDeviceProperty {
    @ObservationIgnored private let actor: UVCDeviceActor
    @ObservationIgnored private let controlID: UVCControlID
    @ObservationIgnored private let defaultValueBool: Bool

    let isCapable: Bool

    var isEnabled: Bool {
        didSet {
            let value = isEnabled
            let id = controlID
            let actor = self.actor
            Task { await actor.setBool(id, value) }
        }
    }

    init(actor: UVCDeviceActor, id: UVCControlID, snapshot: UVCBoolControlSnapshot) {
        self.actor = actor
        self.controlID = id
        self.isCapable = snapshot.isCapable
        self.defaultValueBool = snapshot.defaultValue
        self.isEnabled = snapshot.isEnabled
    }

    func reset() {
        isEnabled = defaultValueBool
    }

    /// Force-write the cached value back to the device (timer-driven).
    func write() {
        let value = isEnabled
        let id = controlID
        let actor = self.actor
        Task { await actor.setBool(id, value) }
    }
}
