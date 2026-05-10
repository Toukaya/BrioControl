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
import IOKit
import IOKit.usb

public final class LogitechHDRControl: UVCControl {
    public private(set) var defaultPayload: Int = 0
    public private(set) var currentPayload: Int = 0

    public var defaultValue: Bool {
        return LogitechHDRControl.payloadEnabled(defaultPayload)
    }

    public var isEnabled: Bool {
        get {
            return LogitechHDRControl.payloadEnabled(currentPayload)
        }
        set {
            _ = setEnabled(newValue)
        }
    }

    override init(_ interface: USBInterfacePointer, _ uvcSize: Int,
                  _ uvcSelector: Selector, _ uvcUnit: Int, _ uvcInterface: Int) {
        super.init(interface, uvcSize, uvcSelector, uvcUnit, uvcInterface)
        configure()
    }

    public func getCurrentPayload() -> Int {
        let payload = getDataFor(type: .getCurrent, length: uvcSize)
        currentPayload = payload
        return payload
    }

    @discardableResult
    public func setPayload(_ payload: Int) -> Int {
        if setData(value: payload, length: uvcSize) {
            currentPayload = payload
        }
        return currentPayload
    }

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> Bool {
        let payload = getCurrentPayload()
        let updated = LogitechHDRControl.replacingEnabledBit(in: payload, enabled: enabled)
        return LogitechHDRControl.payloadEnabled(setPayload(updated))
    }

    private func configure() {
        updateIsCapable()

        if isCapable {
            defaultPayload = getDataFor(type: .getDefault, length: uvcSize)
            currentPayload = getCurrentPayload()
        }
    }

    private static func payloadEnabled(_ payload: Int) -> Bool {
        return (payload & 0xFF) == 0x01
    }

    private static func replacingEnabledBit(in payload: Int, enabled: Bool) -> Int {
        let lowByte = enabled ? 0x01 : 0x00
        return (payload & ~0xFF) | lowByte
    }
}

extension LogitechHDRControl: @unchecked Sendable {}

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
     * HDR candidate. Backed by Unit 21 (GUID
     * 5A6D654C-7E35-4D4E-810D-069D15E0F79B), selector 0x01.
     * 6-byte payload; byte[0] toggles HDR while bytes[1...5] are preserved.
     */
    public lazy var hdr: LogitechHDRControl? = {
        guard let unit = hdrUnit else { return nil }
        return LogitechHDRControl(interface, 6, LogitechHdrXU.hdr,
                                  unit.unitID, interfaceID)
    }()

    private let interface: USBInterfacePointer
    private let interfaceID: Int
    private let videoPipeV3Unit: ExtensionUnit?
    private let hdrUnit: ExtensionUnit?

    init(_ device: USBDevice) {
        let extensionUnits = device.descriptor.extensionUnits
        self.allExtensionUnits = extensionUnits
        self.interface = device.interface
        self.interfaceID = device.descriptor.interfaceID
        self.videoPipeV3Unit = LogitechBrioDeviceProperties.findExtensionUnit(
            extensionUnits, withGuid: LogitechXUGuids.brioFoV)
        self.hdrUnit = LogitechBrioDeviceProperties.findExtensionUnit(
            extensionUnits, withGuid: LogitechXUGuids.brioHdr)
    }

    private static func findExtensionUnit(_ units: [ExtensionUnit],
                                          withGuid guid: UUID) -> ExtensionUnit? {
        for unit in units where unit.guid == guid {
            return unit
        }
        return nil
    }

    #if DEBUG
    /*
     * Diagnostic: dump every selector bit advertised in every Extension Unit's
     * bmControls. For each selector that responds to GET_INFO, query GET_LEN
     * and then read MIN/MAX/RES/DEF/CUR with that length. Output goes to the
     * Xcode console with one line per selector.
     *
     * Use:
     * 1. Run the app; once it has connected to BRIO, the probe runs after a
     *    1.5s delay on a background queue.
     * 2. To probe HDR: in Logi Tune (or any other vendor tool) toggle HDR on,
     *    capture the console output, toggle HDR off, capture again, diff CUR
     *    columns to find which (unitID, selector) corresponds to HDR.
     * 3. Encode the result in LogitechXUSelector.swift and reconstruct the
     *    LogitechBrioDeviceProperties.hdr field accordingly.
     */
    public func probeAllSelectorsInBackground() {
        let unitsCopy = self.allExtensionUnits
        let interfaceCopy = self.interface
        let interfaceIDCopy = self.interfaceID
        Task.detached(priority: .utility) {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            LogitechBrioDeviceProperties.runProbe(units: unitsCopy,
                                                  interface: interfaceCopy,
                                                  interfaceID: interfaceIDCopy)
        }
    }

    private static func runProbe(units: [ExtensionUnit],
                                 interface: USBInterfacePointer,
                                 interfaceID: Int) {
        let context = ProbeContext(interface: interface, interfaceID: interfaceID)
        print("[XU PROBE] ===== begin =====")
        print("[XU PROBE] columns: sel  INFO  LEN  MIN  MAX  RES  DEF  CUR")
        for unit in units {
            let bmHex = unit.bmControls
                .map { String(format: "%02X", $0) }
                .joined(separator: " ")
            print("[XU PROBE] -- Unit \(unit.unitID) GUID=\(unit.guid.uuidString) "
                  + "bmControls=[\(bmHex)]")

            let totalSelectors = unit.bmControls.count * 8
            for selectorIndex in 1...totalSelectors {
                let byteIndex = (selectorIndex - 1) / 8
                let bitIndex = (selectorIndex - 1) % 8
                if (unit.bmControls[byteIndex] >> bitIndex) & 1 == 0 {
                    continue
                }
                probeSelector(selector: selectorIndex,
                              unitID: unit.unitID,
                              context: context)
            }
        }
        print("[XU PROBE] ===== end =====")
    }

    private static func probeSelector(selector: Int,
                                      unitID: Int,
                                      context: ProbeContext) {
        let info = readSelector(request: .getInfo, length: 1,
                                selector: selector, unitID: unitID,
                                context: context)
        guard let infoBytes = info, !infoBytes.isEmpty else {
            print(String(format: "[XU PROBE]   sel=0x%02X  INFO=---", selector))
            return
        }
        let infoByte = infoBytes[0]
        let supportsGet = (infoByte & 0x01) != 0
        let supportsSet = (infoByte & 0x02) != 0

        guard supportsGet else {
            print(String(format: "[XU PROBE]   sel=0x%02X  INFO=0x%02X (set-only)",
                         selector, infoByte))
            return
        }

        let lenBytes = readSelector(request: .getLength, length: 2,
                                    selector: selector, unitID: unitID,
                                    context: context)
        let payloadLen: Int
        if let lenResult = lenBytes, lenResult.count >= 2 {
            payloadLen = Int(lenResult[0]) | (Int(lenResult[1]) << 8)
        } else {
            payloadLen = 1
        }
        guard payloadLen > 0 && payloadLen <= 64 else {
            print(String(format: "[XU PROBE]   sel=0x%02X  INFO=0x%02X  LEN=%d (skipped)",
                         selector, infoByte, payloadLen))
            return
        }

        let minBytes = readSelector(request: .getMinimum, length: payloadLen,
                                    selector: selector, unitID: unitID,
                                    context: context)
        let maxBytes = readSelector(request: .getMaximum, length: payloadLen,
                                    selector: selector, unitID: unitID,
                                    context: context)
        let resBytes = readSelector(request: .getRessolution, length: payloadLen,
                                    selector: selector, unitID: unitID,
                                    context: context)
        let defBytes = readSelector(request: .getDefault, length: payloadLen,
                                    selector: selector, unitID: unitID,
                                    context: context)
        let curBytes = readSelector(request: .getCurrent, length: payloadLen,
                                    selector: selector, unitID: unitID,
                                    context: context)

        let info2 = String(format: "0x%02X", infoByte)
            + (supportsSet ? "(GET+SET)" : "(GET)")
        print(String(format: "[XU PROBE]   sel=0x%02X  INFO=%@  LEN=%d  MIN=%@  MAX=%@  RES=%@  DEF=%@  CUR=%@",
                     selector, info2, payloadLen,
                     hex(minBytes), hex(maxBytes), hex(resBytes),
                     hex(defBytes), hex(curBytes)))
    }

    private static func hex(_ bytes: [UInt8]?) -> String {
        guard let raw = bytes else { return "----" }
        return raw.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    private struct ProbeContext {
        let interface: USBInterfacePointer
        let interfaceID: Int
    }

    /*
     * Issue a single UVC class IN control transfer (CLASS, INTERFACE) to
     * (unitID << 8 | interfaceID), selector << 8, with the given length.
     * Returns the raw bytes on success, nil on failure.
     */
    private static func readSelector(request: UVCRequestCodes,
                                     length: Int,
                                     selector: Int,
                                     unitID: Int,
                                     context: ProbeContext) -> [UInt8]? {
        var buffer = [UInt8](repeating: 0, count: max(length, 1))
        let direction: UInt8 = UInt8(kUSBIn) << UInt8(kUSBRqDirnShift)
        let type: UInt8 = UInt8(kUSBClass) << UInt8(kUSBRqTypeShift)
        let recipient: UInt8 = UInt8(kUSBInterface)
        let bmRequestType: UInt8 = direction | type | recipient

        let success = buffer.withUnsafeMutableBufferPointer { ptr -> Bool in
            guard let baseAddress = ptr.baseAddress else { return false }
            var dev = IOUSBDevRequest(bmRequestType: bmRequestType,
                                      bRequest: request.rawValue,
                                      wValue: UInt16(selector << 8),
                                      wIndex: UInt16((unitID << 8) | context.interfaceID),
                                      wLength: UInt16(length),
                                      pData: UnsafeMutableRawPointer(baseAddress),
                                      wLenDone: 0)
            return context.interface.pointee.pointee
                .ControlRequest(context.interface, 0, &dev) == kIOReturnSuccess
        }
        return success ? buffer : nil
    }
    #endif
}

// Invariant: same as UVCDeviceProperties. Container is single-owner and,
// post-handoff, lives only inside UVCDeviceActor. The lazy `fieldOfView`
// / `rightLight` builders mutate state but are read exactly once from
// the actor's init before any concurrent access becomes possible.
extension LogitechBrioDeviceProperties: @unchecked Sendable {}
