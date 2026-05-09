//
//  UVCConstants.swift
//  UVC
//
//  Created by Itay Brenner on 22/6/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import Foundation

// CFUUID is a CoreFoundation reference type and is not formally
// Sendable, so Swift 6 strict-concurrency rejects module-level `let`
// CFUUID values without a concurrency annotation. The instances below
// are read-only IOKit type identifiers that CFUUIDGetConstantUUIDWithBytes
// vends from a per-process cache; the underlying memory is immutable
// for the lifetime of the process and is the standard pattern for
// IOKit GUID lookups. `nonisolated(unsafe)` is the narrowest escape
// hatch that does not require relocating these constants into an actor
// or wrapping each one in a Sendable holder.

nonisolated(unsafe) let kIOUSBDeviceUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(
    kCFAllocatorDefault,
    0x9d, 0xc7, 0xb7, 0x80,
    0x9e, 0xc0, 0x11, 0xD4,
    0xa5, 0x4f, 0x00, 0x0a,
    0x27, 0x05, 0x28, 0x61
)!

nonisolated(unsafe) let kIOUSBDeviceInterfaceID = CFUUIDGetConstantUUIDWithBytes(
    kCFAllocatorDefault,
    0x5c, 0x81, 0x87, 0xd0,
    0x9e, 0xf3, 0x11, 0xD4,
    0x8b, 0x45, 0x00, 0x0a,
    0x27, 0x05, 0x28, 0x61
)!

nonisolated(unsafe) let kIOUSBInterfaceInterfaceID = CFUUIDGetConstantUUIDWithBytes(
    kCFAllocatorDefault,
    0x73, 0xc9, 0x7a, 0xe8,
    0x9e, 0xf3, 0x11, 0xD4,
    0xb1, 0xd0, 0x00, 0x0a,
    0x27, 0x05, 0x28, 0x61
)!

nonisolated(unsafe) let kIOCFPlugInInterfaceID = CFUUIDGetConstantUUIDWithBytes(
    kCFAllocatorDefault,
    0xC2, 0x44, 0xE8, 0x58,
    0x10, 0x9C, 0x11, 0xD4,
    0x91, 0xD4, 0x00, 0x50,
    0xE4, 0xC6, 0x42, 0x6F
)!

nonisolated(unsafe) let kIOUSBInterfaceUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(
    kCFAllocatorDefault,
    0x2d, 0x97, 0x86, 0xc6,
    0x9e, 0xf3, 0x11, 0xD4,
    0xad, 0x51, 0x00, 0x0a,
    0x27, 0x05, 0x28, 0x61
)!
