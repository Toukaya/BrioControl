//
//  LogitechBrioDeviceProperties.swift
//  UVC
//
//  Vendor-specific control wrapper for Logitech BRIO-family webcams.
//
//  XU lookups are resolved eagerly at construction (cheap; descriptor data is
//  already in memory). The actual UVCControl objects are constructed lazily
//  on first access, because UVCControl.configure() issues several synchronous
//  USB control transfers (GET_INFO/GET_LEN/GET_MIN/GET_MAX/GET_RES/GET_DEF/
//  GET_CUR). Doing all of those at device-discovery time would freeze the
//  status-bar UI thread for several seconds per non-responsive selector.
//

import Foundation

public final class LogitechBrioDeviceProperties {
    /*
     * All XU descriptors found on this device. Populated at construction;
     * surfaced for the Logitech diagnostics view.
     */
    public let allExtensionUnits: [ExtensionUnit]

    /*
     * Field of View preset. Backed by the BRIO FoV XU (GUID
     * 49E40215-F434-47FE-B158-0E885023E51B). 1-byte payload, values
     * 0x00=90 / 0x01=78 / 0x02=65. Constructed on first access.
     */
    public lazy var fieldOfView: UVCIntControl? = {
        guard let unit = videoPipeV3Unit else { return nil }
        return UVCIntControl(interface, 1, LogitechFoVXU.fov,
                             unit.unitID, interfaceID)
    }()

    /*
     * RightLight Mode. Lives on the SAME XU as FoV (BRIO Video Pipe V3).
     * 1-byte payload, opaque integer treated as a discrete mode index;
     * range and step are reported via GET_MIN/GET_MAX/GET_RES at runtime.
     * Constructed on first access.
     */
    public lazy var rightLight: UVCIntControl? = {
        guard let unit = videoPipeV3Unit else { return nil }
        return UVCIntControl(interface, 1, LogitechRightLightXU.rightLight,
                             unit.unitID, interfaceID)
    }()

    /*
     * Indicator LED. Backed by the legacy v1 USER_HW_CONTROL XU (GUID
     * 63610682-5070-49AB-B8CC-B3855E8D221F). 3-byte payload; byte[0] holds
     * the mode (0=off, 1=on, 2=blink, 3=auto). BRIO support is unconfirmed
     * in any public source. Left nil until USB capture verifies BRIO
     * firmware actually responds to the configure() probe sequence; on
     * firmware that exposes the GUID but stalls control transfers, the
     * UVCIntControl init would block the calling thread for seconds.
     */
    public let indicatorLed: UVCIntControl? = nil

    /*
     * HDR. Placeholder until selectors are confirmed via USB capture.
     */
    public let hdr: UVCIntControl? = nil

    private let interface: USBInterfacePointer
    private let interfaceID: Int
    private let videoPipeV3Unit: ExtensionUnit?

    init(_ device: USBDevice) {
        let extensionUnits = device.descriptor.extensionUnits
        self.allExtensionUnits = extensionUnits
        self.interface = device.interface
        self.interfaceID = device.descriptor.interfaceID
        self.videoPipeV3Unit = LogitechBrioDeviceProperties.findExtensionUnit(
            extensionUnits, withGuid: LogitechXUGuids.brioFoV)
    }

    private static func findExtensionUnit(_ units: [ExtensionUnit],
                                          withGuid guid: UUID) -> ExtensionUnit? {
        for unit in units where unit.guid == guid {
            return unit
        }
        return nil
    }
}
