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
 * BRIO HDR candidate XU (GUID 5A6D654C-7E35-4D4E-810D-069D15E0F79B).
 * Derived from USB capture while toggling HDR in Logi Tune.
 *   HDR selector: 0x01, length 6 bytes.
 *   Payload layout: byte[0] = HDR enable bit (0=off, 1=on), bytes[1...5]
 *   are companion vendor data that must be preserved on write.
 */
enum LogitechHdrXU: Int, Selector {
    case hdr = 0x01

    func raw() -> Int {
        return self.rawValue
    }
}

/*
 * RightLight XU selectors. RightLight Mode lives on the SAME XU as FoV
 * (BRIO Video Pipe V3, GUID 49E40215-F434-47FE-B158-0E885023E51B),
 * confirmed by Researcher #2 against llmike/v4l2-tools and mpls/libwebcam
 * logitech.xml.
 *   RightLight Mode selector: 0x04, length 1 byte.
 *   Supports SET_CUR/GET_CUR/GET_MIN/GET_MAX/GET_RES/GET_DEF.
 *   Value semantics are device-defined; treat as opaque integers and
 *   surface the GET_MIN/GET_MAX/GET_RES range in the UI.
 */
enum LogitechRightLightXU: Int, Selector {
    case rightLight = 0x04

    func raw() -> Int {
        return self.rawValue
    }
}
