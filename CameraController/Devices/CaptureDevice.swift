//
//  CaptureDevice.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import AVFoundation
import Observation
import UVC

@MainActor
@Observable
final class CaptureDevice: Hashable {
    nonisolated let name: String
    // AVCaptureDevice's `Sendable` conformance is not yet declared in
    // the AVFoundation overlay this project targets, but the instance
    // we hold is treated as opaque from Swift's side: we never mutate
    // it; we only forward to its `==`/`hashValue` for identity and
    // `uniqueID` for persistence. `nonisolated(unsafe)` is the
    // narrowest escape hatch that keeps the static `==` / `hash(into:)`
    // implementations accessible from Equatable/Hashable's nonisolated
    // requirements without lifting the entire CaptureDevice type off
    // @MainActor.
    @ObservationIgnored nonisolated(unsafe) let avDevice: AVCaptureDevice?
    @ObservationIgnored let uvcDevice: UVCDevice?
    var controller: DeviceController?

    init(avDevice: AVCaptureDevice) {
        self.avDevice = avDevice
        self.name = avDevice.localizedName
        self.uvcDevice = try? UVCDevice(device: avDevice)
        self.controller = DeviceController(properties: uvcDevice?.properties,
                                           logitechBrio: uvcDevice?.logitechBrio)
    }

    nonisolated static func == (lhs: CaptureDevice, rhs: CaptureDevice) -> Bool {
        return lhs.avDevice == rhs.avDevice
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(avDevice)
    }

    func isConfigurable() -> Bool {
        return uvcDevice != nil
    }

    func isDefaultDevice() -> Bool {
        return false
    }

    func readValuesFromDevice() {
        guard let controller = controller else {
            return
        }

        Task {
            controller.exposureTime.update()
            controller.whiteBalance.update()
            controller.focusAbsolute.update()
        }
    }

    func writeValuesToDevice() {
        guard let controller = controller else {
            return
        }

        Task {
            controller.writeValues()
        }
    }
}
