//
//  CaptureDevice.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import AVFoundation
import Combine
import UVC

@MainActor
final class CaptureDevice: Hashable, ObservableObject {
    nonisolated let name: String
    nonisolated(unsafe) let avDevice: AVCaptureDevice?
    let uvcDevice: UVCDevice?
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
