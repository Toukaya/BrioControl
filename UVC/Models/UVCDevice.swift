//
//  UCDevice.swift
//  CameraController
//
//  Created by Itay Brenner on 7/19/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import AVFoundation

typealias USBInterfacePointer = UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface190>>

public final class UVCDevice {
    let interface: USBInterfacePointer
    let processingUnitID: Int
    let cameraTerminalID: Int
    public let vendorID: UInt16
    public let productID: UInt16
    public let extensionUnits: [ExtensionUnit]
    public let properties: UVCDeviceProperties

    public init(device: AVCaptureDevice) throws {
        let deviceInfo = try device.usbDevice()

        interface = deviceInfo.interface
        processingUnitID = deviceInfo.descriptor.processingUnitID
        cameraTerminalID = deviceInfo.descriptor.cameraTerminalID
        vendorID = deviceInfo.vendorID
        productID = deviceInfo.productID
        extensionUnits = deviceInfo.descriptor.extensionUnits
        properties = UVCDeviceProperties(deviceInfo)
    }

    deinit { _ = interface.pointee.pointee.Release(interface) }
}
