//
//  BitmapCaptureDeviceProperty.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright (c) 2020 Itaysoft. All rights reserved.
//
//  View-model wrapper for a UVCBitmapControl. See NumberCaptureDeviceProperty
//  for the design rationale.
//

import Foundation
import Observation
import UVC

@MainActor
@Observable
final class BitmapCaptureDeviceProperty {
    @ObservationIgnored private let actor: UVCDeviceActor
    @ObservationIgnored private let controlID: UVCControlID
    @ObservationIgnored private let defaultValueRaw: Int

    let isCapable: Bool

    var selected: UVCBitmapControl.BitmapValue {
        didSet {
            let raw = selected.rawValue
            let id = controlID
            let actor = self.actor
            Task { await actor.setBitmapRaw(id, raw) }
        }
    }

    init(actor: UVCDeviceActor, id: UVCControlID, snapshot: UVCBitmapControlSnapshot) {
        self.actor = actor
        self.controlID = id
        self.isCapable = snapshot.isCapable
        self.defaultValueRaw = snapshot.defaultValueRaw
        self.selected = UVCBitmapControl.BitmapValue(rawValue: snapshot.currentRaw) ?? .auto
    }

    func reset() {
        selected = UVCBitmapControl.BitmapValue(rawValue: defaultValueRaw) ?? .auto
    }

    /// Force-write the cached value back to the device (timer-driven).
    func write() {
        let raw = selected.rawValue
        let id = controlID
        let actor = self.actor
        Task { await actor.setBitmapRaw(id, raw) }
    }
}
