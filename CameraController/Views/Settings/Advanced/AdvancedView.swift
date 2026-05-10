//
//  AdvancedView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct AdvancedView: View {
    @Bindable var controller: DeviceController

    var body: some View {
        Form {
            Section("Camera") {
                if controller.powerLineFrequency.isCapable {
                    PowerLineView(controller: controller)
                }

                if controller.backlightCompensation.isCapable {
                    BacklightView(controller: controller)
                }
            }

            if controller.zoomAbsolute.isCapable
                || controller.panTiltAbsolute.isCapable
                || controller.rollAbsolute.isCapable {
                Section("Orientation") {
                    if controller.zoomAbsolute.isCapable {
                        ZoomView(controller: controller)
                    }

                    if controller.panTiltAbsolute.isCapable {
                        PanTiltView(controller: controller)
                    }

                    if controller.rollAbsolute.isCapable {
                        RollView(controller: controller)
                    }
                }
            }

            if controller.focusAbsolute.isCapable {
                Section("Focus") {
                    FocusView(controller: controller)
                }
            }

            if (controller.logitechFieldOfView?.isCapable == true)
                || (controller.logitechHDR?.isCapable == true) {
                Section("Logitech BRIO") {
                    if let fov = controller.logitechFieldOfView, fov.isCapable {
                        FieldOfViewView(fieldOfView: fov)
                    }

                    if let hdr = controller.logitechHDR, hdr.isCapable {
                        Toggle("HDR", isOn: Binding(
                            get: { hdr.isEnabled },
                            set: { hdr.isEnabled = $0 }
                        ))
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxHeight: 360)
    }
}
