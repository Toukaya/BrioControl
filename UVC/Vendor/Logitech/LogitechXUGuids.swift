//
//  LogitechXUGuids.swift
//  UVC
//
//  Canonical Microsoft GUID strings for Logitech Extension Units. These are
//  matched byte-for-byte against the GUIDs surfaced by IOUSBConfiguration-
//  DescriptorPtr.proccessDescriptor() (which already converts the on-wire
//  Microsoft byte order to canonical Foundation.UUID form).
//

import Foundation

public struct LogitechXUGuids {
    /*
     * BRIO-specific XU. Hosts the Field of View preset selector. Sourced
     * from cameractrls.py line 1364.
     */
    public static let brioFoV = UUID(uuidString: "49E40215-F434-47FE-B158-0E885023E51B")!

    /*
     * Legacy v1 USER_HW_CONTROL XU. On older Logitech cameras this hosts the
     * indicator LED control. cameractrls applies it opportunistically to
     * BRIO; presence on BRIO firmware is unconfirmed (gate behind isCapable).
     */
    public static let userHwV1 = UUID(uuidString: "63610682-5070-49AB-B8CC-B3855E8D221F")!

    /*
     * BRIO HDR candidate XU. Derived from USB captures while toggling HDR in
     * Logi Tune: Unit 21 / selector 0x01 / 6-byte payload where byte[0]
     * flips between 0x00 and 0x01 while the trailing bytes stay constant.
     */
    public static let brioHdr = UUID(uuidString: "5A6D654C-7E35-4D4E-810D-069D15E0F79B")!

    /*
     * Placeholder retained for future vendor controls whose GUIDs are still
     * pending confirmation from USB captures.
     */
    public static let brioRightLightTbd: UUID? = nil

    /*
     * GUID supplied to the manager out-of-band but NOT located in any public
     * source (cameractrls, libwebcam, kernel uvc_ctrl.c, joelpurra/uvcc).
     * Retained here purely so the diagnostics view can label the XU if it
     * happens to appear on real hardware.
     */
    public static let unknownGuid82066163 = UUID(uuidString: "82066163-7050-AB49-B8CC-B3855E412522")!
}
