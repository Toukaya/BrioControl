//
//  LogitechBrioDeviceProperties.swift
//  UVC
//
//  Vendor-specific control wrapper for Logitech BRIO-family webcams. For each
//  supported control the constructor:
//    1. Looks up the matching ExtensionUnit on the device by canonical GUID.
//    2. Constructs a typed UVCControl bound to that XU's unitID and the
//       device's video-control interface.
//    3. Calls updateIsCapable() (already invoked inside the typed control's
//       configure step).
//
//  Controls whose XU is not present on this device are left nil. Views must
//  check both `nil` and `isCapable` before showing a setting.
//

import Foundation

public final class LogitechBrioDeviceProperties {
    /*
     * Field of View preset. Backed by the BRIO FoV XU (GUID
     * 49E40215-F434-47FE-B158-0E885023E51B). 1-byte payload, values
     * 0x00=90 / 0x01=78 / 0x02=65.
     */
    public let fieldOfView: UVCIntControl?

    /*
     * Indicator LED. Backed by the legacy v1 USER_HW_CONTROL XU (GUID
     * 63610682-5070-49AB-B8CC-B3855E8D221F). 3-byte payload; byte[0] holds
     * the mode (0=off, 1=on, 2=blink, 3=auto). Writing an Int via
     * UVCIntControl with size=3 produces little-endian bytes [mode,0,0],
     * which matches the documented layout for the simple on/off/blink/auto
     * case (frequency byte left at zero).
     */
    public let indicatorLed: UVCIntControl?

    /*
     * HDR. Placeholder until selectors are confirmed via USB capture.
     */
    public let hdr: UVCIntControl?

    /*
     * RightLight. Placeholder until selectors are confirmed via USB capture
     * (or the feature is determined to be a relabel of a standard PU/CT
     * control, in which case it lives on UVCDeviceProperties instead).
     */
    public let rightLight: UVCIntControl?

    /*
     * All XU descriptors found on this device. Populated regardless of
     * whether any of the controls above were matched. Surfaced for the
     * Logitech diagnostics view.
     */
    public let allExtensionUnits: [ExtensionUnit]

    init(_ device: USBDevice) {
        let interface = device.interface
        let interfaceID = device.descriptor.interfaceID
        let extensionUnits = device.descriptor.extensionUnits
        allExtensionUnits = extensionUnits

        // FoV
        if let fovUnit = LogitechBrioDeviceProperties.findExtensionUnit(
            extensionUnits, withGuid: LogitechXUGuids.brioFoV) {
            fieldOfView = UVCIntControl(interface, 1, LogitechFoVXU.fov,
                                        fovUnit.unitID, interfaceID)
        } else {
            fieldOfView = nil
        }

        // LED (legacy v1 USER_HW_CONTROL XU)
        if let ledUnit = LogitechBrioDeviceProperties.findExtensionUnit(
            extensionUnits, withGuid: LogitechXUGuids.userHwV1) {
            indicatorLed = UVCIntControl(interface, 3, LogitechLedV1XU.led,
                                         ledUnit.unitID, interfaceID)
        } else {
            indicatorLed = nil
        }

        // HDR / RightLight: placeholders. Both XU GUIDs are TBD; nothing to
        // wire up until a USB capture supplies the selector.
        hdr = nil
        rightLight = nil
    }

    private static func findExtensionUnit(_ units: [ExtensionUnit],
                                          withGuid guid: UUID) -> ExtensionUnit? {
        for unit in units where unit.guid == guid {
            return unit
        }
        return nil
    }
}
