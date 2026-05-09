//
//  LogitechView.swift
//  CameraController
//
//  Vendor-specific settings tab for Logitech devices. Each section is
//  conditionally visible based on whether the corresponding XU is present
//  on the connected device AND its underlying UVCControl reports isCapable.
//

import SwiftUI
import UVC

struct LogitechView: View {
    @ObservedObject var controller: DeviceController

    init(controller: DeviceController) {
        self.controller = controller
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Constants.Style.controlsSpacing) {
                if let fov = controller.logitechFieldOfView, fov.isCapable {
                    fieldOfViewSection(fov)
                }

                if let led = controller.logitechLed, led.isCapable {
                    indicatorLedSection(led)
                }

                if let rightLight = controller.logitechRightLight, rightLight.isCapable {
                    rightLightSection(rightLight)
                }

                diagnosticsSection()
            }
            .padding(.top, 2)
            .padding(.bottom, Constants.Style.topSpacing)
        }
        .frame(maxHeight: 300)
    }

    @ViewBuilder
    private func fieldOfViewSection(_ fov: NumberCaptureDeviceProperty) -> some View {
        SectionView {
            SectionTitle(title: "Field of View",
                         image: Image(systemName: "viewfinder"))

            Picker(selection: fovBinding(fov), label: EmptyView()) {
                Text("90").frame(width: 100).tag(0 as Float)
                Text("78").frame(width: 100).tag(1 as Float)
                Text("65").frame(width: 100).tag(2 as Float)
            }
            .disabled(!fov.isCapable)
            .pickerStyle(.segmented)
        }
    }

    private func fovBinding(_ fov: NumberCaptureDeviceProperty) -> Binding<Float> {
        Binding(get: {
            // Clamp to known FoV preset range so an out-of-range device value
            // does not crash the segmented picker.
            let raw = fov.sliderValue
            if raw < 0 { return 0 }
            if raw > 2 { return 2 }
            return raw
        }, set: { newValue in
            fov.sliderValue = newValue
        })
    }

    @ViewBuilder
    private func indicatorLedSection(_ led: NumberCaptureDeviceProperty) -> some View {
        SectionView {
            SectionTitle(title: "Indicator LED",
                         image: Image(systemName: "lightbulb")) {
                Toggle(isOn: ledOnOffBinding(led))
            }

            Picker(selection: ledModeBinding(led), label: EmptyView()) {
                Text("Off").frame(width: 75).tag(0 as Float)
                Text("On").frame(width: 75).tag(1 as Float)
                Text("Blink").frame(width: 75).tag(2 as Float)
                Text("Auto").frame(width: 75).tag(3 as Float)
            }
            .disabled(!led.isCapable)
            .pickerStyle(.segmented)
        }
    }

    private func ledOnOffBinding(_ led: NumberCaptureDeviceProperty) -> Binding<Bool> {
        Binding(get: {
            // Mode is in byte[0] of the 3-byte payload. UVCIntControl with
            // size=3 packs Int 1 as little-endian bytes [01, 00, 00], which
            // matches mode=on.
            return Int(led.sliderValue) == 1
        }, set: { newValue in
            led.sliderValue = newValue ? 1 : 0
        })
    }

    private func ledModeBinding(_ led: NumberCaptureDeviceProperty) -> Binding<Float> {
        Binding(get: {
            let raw = Int(led.sliderValue)
            if raw < 0 || raw > 3 { return 0 }
            return Float(raw)
        }, set: { newValue in
            led.sliderValue = newValue
        })
    }

    @ViewBuilder
    private func rightLightSection(_ rightLight: NumberCaptureDeviceProperty) -> some View {
        RightLightSection(rightLight: rightLight)
    }

    @ViewBuilder
    private func diagnosticsSection() -> some View {
        if let logitechBrio = controller.logitechBrio {
            SectionView {
                SectionTitle(title: "Diagnostics",
                             image: Image(systemName: "doc.text.magnifyingglass"))

                if logitechBrio.allExtensionUnits.isEmpty {
                    Text("No Extension Units found on this device.")
                        .font(.system(.caption, design: .monospaced))
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(logitechBrio.allExtensionUnits.indices, id: \.self) { index in
                            extensionUnitRow(logitechBrio.allExtensionUnits[index])
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func extensionUnitRow(_ unit: ExtensionUnit) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Unit \(unit.unitID): \(LogitechView.label(for: unit.guid))")
                .font(.system(.caption, design: .default))
                .fontWeight(.semibold)
            Text(unit.guid.uuidString)
                .font(.system(.caption2, design: .monospaced))
            Text("bmControls: \(LogitechView.formatHexBytes(unit.bmControls))")
                .font(.system(.caption2, design: .monospaced))
        }
    }

    private static func label(for guid: UUID) -> String {
        if guid == LogitechXUGuids.brioFoV {
            return "BRIO Video Pipe V3 (FoV / RightLight)"
        }
        if guid == LogitechXUGuids.userHwV1 {
            return "Legacy LED v1"
        }
        if guid == LogitechXUGuids.unknownGuid82066163 {
            return "Logitech Video Pipe V3 (FY11)"
        }
        return "Unknown"
    }

    private static func formatHexBytes(_ bytes: [UInt8]) -> String {
        if bytes.isEmpty {
            return "(empty)"
        }
        return bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

/*
 * RightLight Mode is treated as an opaque integer in [minimum...maximum]
 * because the value semantics are device-defined and labels are not yet
 * confirmed. A discrete slider with the device's own GET_RES step is the
 * most honest representation until the user reports value-to-label mapping.
 */
private struct RightLightSection: View {
    @ObservedObject var rightLight: NumberCaptureDeviceProperty

    var body: some View {
        let lower = min(rightLight.minimum, rightLight.maximum)
        let upper = max(rightLight.minimum, rightLight.maximum)
        let step = rightLight.resolution > 0 ? rightLight.resolution : 1
        GenericControl(value: $rightLight.sliderValue,
                       step: step,
                       range: lower...upper,
                       title: "RightLight Mode",
                       imageName: "sun.max",
                       auto: nil)
    }
}
