//
//  IOUSBConfigurationDescriptorPtr+UVC.swift
//  CameraController
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import IOKit

extension IOUSBConfigurationDescriptorPtr {
    func proccessDescriptor() -> UVCDescriptor {
        var processingUnitID = -1
        var cameraTerminalID = -1
        var interfaceID = -1

        let remaining = self.pointee.wTotalLength - UInt16(self.pointee.bLength)
        var pointer = UnsafeMutablePointer<UInt8>(OpaquePointer(self))
        pointer = pointer.advanced(by: Int(self.pointee.bLength))

        browseDescriptor(remaining, pointer, &processingUnitID, &cameraTerminalID, &interfaceID)

        // Extension units are collected by an independent second pass so that
        // any safety bug in EU parsing cannot affect the standard UVC values
        // (PU/CT/interface) that the rest of the app depends on.
        let extensionUnits = collectExtensionUnits(remaining, pointer)

        return UVCDescriptor(processingUnitID: processingUnitID,
                             cameraTerminalID: cameraTerminalID,
                             interfaceID: interfaceID,
                             extensionUnits: extensionUnits)
    }

    private func browseDescriptor(_ memory: UInt16, _ pointer: UnsafeMutablePointer<UInt8>,
                                  _ processingUnitID: inout Int,
                                  _ cameraTerminalID: inout Int,
                                  _ interfaceID: inout Int) {
        var remaining = memory
        var currentPointer = pointer

        while remaining > 0 {
            var descriptorPointer = InterfaceDescriptorPointer(OpaquePointer(currentPointer))

            if descriptorPointer.pointee.bDescriptorType == kUSBInterfaceDesc {
                let intDesc = UnsafeMutablePointer<IOUSBInterfaceDescriptor>(OpaquePointer(descriptorPointer))
                if !(intDesc.pointee.bInterfaceClass == UVCConstants.classVideo
                    && intDesc.pointee.bInterfaceSubClass == UVCConstants.subclassVideoControl) {

                    currentPointer = currentPointer.advanced(by: Int(intDesc.pointee.bLength))
                    continue
                }

                currentPointer = currentPointer.advanced(by: Int(intDesc.pointee.bLength))
                descriptorPointer = InterfaceDescriptorPointer(OpaquePointer(currentPointer))

                if descriptorPointer.pointee.bDescriptorType != UVCConstants.descriptorTypeInterface {
                    break
                }

                let internalDescriptor = UnsafeMutablePointer<UVC_VCHeaderDescriptor>(OpaquePointer(descriptorPointer))
                if internalDescriptor.pointee.bDescriptorSubType == UVCConstants.subclassVideoControl {
                    let littleEndian = Int(internalDescriptor.pointee.wTotalLength).littleEndian
                    internalDescriptor.pointee.wTotalLength = UInt16(littleEndian)

                    remaining -= internalDescriptor.pointee.wTotalLength
                    currentPointer = currentPointer.advanced(by: Int(internalDescriptor.pointee.bLength))
                    var remainingMemory = internalDescriptor.pointee.wTotalLength
                        - UInt16(internalDescriptor.pointee.bLength)

                    while remainingMemory > 0 {
                        descriptorPointer = InterfaceDescriptorPointer(OpaquePointer(currentPointer))
                        if descriptorPointer.pointee.bDescriptorType != UVCConstants.descriptorTypeInterface {
                            break
                        }

                        getDeviceId(descriptorPointer, currentPointer, &processingUnitID, &cameraTerminalID)
                        interfaceID = Int(intDesc.pointee.bInterfaceNumber)

                        if interfaceID != -1 && processingUnitID != -1 && cameraTerminalID != -1 {
                            // Found all necessary data, exit
                            // Fix for WB7022 Camera
                            return
                        }

                        remainingMemory -= UInt16(descriptorPointer.pointee.bLength)
                        currentPointer = currentPointer.advanced(by: Int(descriptorPointer.pointee.bLength))
                    }
                } else {
                    remaining -= UInt16(descriptorPointer.pointee.bLength)
                    currentPointer = currentPointer.advanced(by: Int(descriptorPointer.pointee.bLength))
                }
                break
            } else {
                remaining -= UInt16(descriptorPointer.pointee.bLength)
                currentPointer = currentPointer.advanced(by: Int(descriptorPointer.pointee.bLength))
            }
        }
    }

    private func getDeviceId(_ descriptorPointer: InterfaceDescriptorPointer,
                             _ currentPointer: UnsafeMutablePointer<UInt8>,
                             _ processingUnitID: inout Int,
                             _ cameraTerminalID: inout Int) {
        let unitType = UVCConstants.DescriptorSubtype(rawValue: descriptorPointer.pointee.bDescriptorSubType)
        switch unitType {
        case .processingUnit:
            let puPointer = ProcessingUnitDescriptorPointer(OpaquePointer(currentPointer))
            processingUnitID = Int(puPointer.pointee.bUnitID)
        case .inputTerminal:
            let ctPointer = CameraTerminalDescriptorPointer(OpaquePointer(currentPointer))
            cameraTerminalID = Int(ctPointer.pointee.bTerminalID)
        case .none:
            break
        case .selectorUnit:
            break
        case .extensionUnit:
            break
        }
    }

    /*
     * Independent second pass that walks the same configuration descriptor
     * looking only for VC Extension Unit descriptors. This is intentionally
     * separate from `browseDescriptor`: any defect here cannot cause the
     * standard UVC PU/CT/interface IDs to be lost, and conversely the
     * original walker is left bit-for-bit identical to its long-shipped form.
     */
    private func collectExtensionUnits(_ memory: UInt16,
                                       _ pointer: UnsafeMutablePointer<UInt8>) -> [ExtensionUnit] {
        var result: [ExtensionUnit] = []
        var remaining = memory
        var currentPointer = pointer

        while remaining > 0 {
            let descriptorPointer = InterfaceDescriptorPointer(OpaquePointer(currentPointer))
            let bLength = UInt16(descriptorPointer.pointee.bLength)

            // Defensive: a zero-length descriptor would never advance the
            // pointer and would spin forever on a single address.
            if bLength == 0 || bLength > remaining {
                break
            }

            // Only class-specific VC Interface descriptors (type 0x24) carry
            // an Extension Unit. Anything else is skipped without further
            // interpretation.
            if descriptorPointer.pointee.bDescriptorType == UVCConstants.descriptorTypeInterface {
                let subType = UVCConstants.DescriptorSubtype(
                    rawValue: descriptorPointer.pointee.bDescriptorSubType)
                if subType == .extensionUnit {
                    if let unit = parseExtensionUnit(currentPointer) {
                        result.append(unit)
                        #if DEBUG
                        let bmHex = unit.bmControls
                            .map { String(format: "%02X", $0) }
                            .joined(separator: " ")
                        print("[UVC] Extension Unit: unitID=\(unit.unitID) "
                              + "guid=\(unit.guid.uuidString) "
                              + "bmControls=[\(bmHex)]")
                        #endif
                    }
                }
            }

            remaining -= bLength
            currentPointer = currentPointer.advanced(by: Int(bLength))
        }

        return result
    }

    private func parseExtensionUnit(_ currentPointer: UnsafeMutablePointer<UInt8>) -> ExtensionUnit? {
        let euPointer = ExtensionUnitDescriptorPointer(OpaquePointer(currentPointer))
        let bLength = Int(euPointer.pointee.bLength)
        // Fixed-prefix size: bLength(1) + bDescriptorType(1) + bDescriptorSubType(1)
        // + bUnitID(1) + guidExtensionCode(16) + bNumControls(1) + bNrInPins(1) = 22
        let fixedPrefixSize = 22
        if bLength < fixedPrefixSize {
            return nil
        }

        let unitID = Int(euPointer.pointee.bUnitID)

        // Copy 16 GUID bytes from the descriptor.
        var guidBytes = [UInt8](repeating: 0, count: 16)
        withUnsafePointer(to: &euPointer.pointee.guidExtensionCode) { tuplePtr in
            tuplePtr.withMemoryRebound(to: UInt8.self, capacity: 16) { bytePtr in
                for index in 0..<16 {
                    guidBytes[index] = bytePtr[index]
                }
            }
        }
        let guid = uuidFromMicrosoftBytes(guidBytes)

        let nrInPins = Int(euPointer.pointee.bNrInPins)
        // After the fixed prefix, the descriptor lays out:
        //   baSourceID[bNrInPins], bControlSize, bmControls[bControlSize], bIExtension
        let baseOffset = fixedPrefixSize + nrInPins
        if bLength <= baseOffset {
            return ExtensionUnit(unitID: unitID, guid: guid, bmControls: [])
        }
        let controlSize = Int(currentPointer[baseOffset])
        let bmStart = baseOffset + 1
        var bmControls: [UInt8] = []
        if controlSize > 0 && bmStart + controlSize <= bLength {
            bmControls.reserveCapacity(controlSize)
            for index in 0..<controlSize {
                bmControls.append(currentPointer[bmStart + index])
            }
        }
        return ExtensionUnit(unitID: unitID, guid: guid, bmControls: bmControls)
    }

    /*
     * In the VC_EXTENSION_UNIT descriptor, guidExtensionCode is laid out in
     * Microsoft GUID byte order: fields 1-3 (4, 2, 2 bytes) are little-endian,
     * fields 4-5 (2 then 6 bytes) are stored in network/canonical order.
     */
    private func uuidFromMicrosoftBytes(_ bytes: [UInt8]) -> UUID {
        precondition(bytes.count == 16)
        let canonical: [UInt8] = [
            bytes[3], bytes[2], bytes[1], bytes[0],
            bytes[5], bytes[4],
            bytes[7], bytes[6],
            bytes[8], bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ]
        let uuidTuple: uuid_t = (
            canonical[0], canonical[1], canonical[2], canonical[3],
            canonical[4], canonical[5], canonical[6], canonical[7],
            canonical[8], canonical[9], canonical[10], canonical[11],
            canonical[12], canonical[13], canonical[14], canonical[15]
        )
        return UUID(uuid: uuidTuple)
    }
}
