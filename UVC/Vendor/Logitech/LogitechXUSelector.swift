//
//  LogitechXUSelector.swift
//  UVC
//
//  Control selector enums for Logitech XUs. Selectors are bUnitID-relative
//  and are placed in the high byte of wValue when issuing class control
//  transfers (see UVCControl.performRequest).
//

import Foundation

/*
 * BRIO Field of View XU (GUID 49E40215-F434-47FE-B158-0E885023E51B).
 * Source: cameractrls.py lines 1375-1381.
 *   FoV selector: 0x05, length 1 byte.
 *   Values:
 *     0x00 = 90 degrees
 *     0x01 = 78 degrees
 *     0x02 = 65 degrees
 */
enum LogitechFoVXU: Int, Selector {
    case fov = 0x05

    func raw() -> Int {
        return self.rawValue
    }
}

/*
 * Legacy USER_HW_CONTROL v1 XU (GUID 63610682-5070-49AB-B8CC-B3855E8D221F).
 * Source: cameractrls.py lines 1336-1347.
 *   LED1 selector: 0x01, length 3 bytes.
 *   Byte layout: byte[0] = mode (0=off,1=on,2=blink,3=auto)
 *                byte[1] = reserved
 *                byte[2] = blink frequency in 0.05 Hz units
 */
enum LogitechLedV1XU: Int, Selector {
    case led = 0x01

    func raw() -> Int {
        return self.rawValue
    }
}

/*
 * HDR XU selectors. TBD - selector value not publicly documented for BRIO.
 * Will be populated from a USB capture of Logi Tune toggling HDR. Until
 * then this enum has no cases and HDR stays hidden in the UI.
 */
enum LogitechHdrXU: Int, Selector {
    // TBD: no confirmed selectors for BRIO HDR.
    case unused = -1

    func raw() -> Int {
        return self.rawValue
    }
}

/*
 * RightLight XU selectors. TBD - selector value not publicly documented for
 * BRIO. May ultimately be a relabel of standard UVC PU/CT controls rather
 * than an XU at all (see research notes).
 */
enum LogitechRightLightXU: Int, Selector {
    // TBD: no confirmed selectors for BRIO RightLight.
    case unused = -1

    func raw() -> Int {
        return self.rawValue
    }
}
