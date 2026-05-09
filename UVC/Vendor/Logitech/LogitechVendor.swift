//
//  LogitechVendor.swift
//  UVC
//
//  Vendor identification helpers for Logitech webcams. Used to decide whether
//  to attempt to construct a Logitech-specific properties wrapper from a UVC
//  device. Per-XU control availability is still gated by GUID matching and
//  isCapable probing inside LogitechBrioDeviceProperties.
//

import Foundation

public struct LogitechVendor {
    public static let vendorID: UInt16 = 0x046D

    /*
     * Known BRIO-family product IDs sourced from cameractrls.py
     * (https://github.com/soyersoyer/cameractrls). Brio 100 / Brio 300 PIDs
     * are not publicly documented, so they are intentionally absent. A device
     * with vendor 0x046D and an unknown PID will still be probed; per-control
     * availability is gated on XU GUID match plus runtime GET_INFO.
     */
    public static let knownBrioPIDs: Set<UInt16> = [
        0x085E, // Brio 4K Pro
        0x086B, // Brio 4K Stream Edition
        0x0943, // Brio 500
        0x0946, // Brio 501
        0x0919, // Brio 505
        0x0944  // MX Brio
    ]

    public static func isLogitech(vendorID: UInt16) -> Bool {
        return vendorID == LogitechVendor.vendorID
    }

    public static func isBrio(vendorID: UInt16, productID: UInt16) -> Bool {
        return isLogitech(vendorID: vendorID) && knownBrioPIDs.contains(productID)
    }
}
