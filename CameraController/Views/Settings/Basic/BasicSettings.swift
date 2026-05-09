//
//  BasicSettings.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct BasicSettings: View {
    @Bindable var controller: DeviceController

    var body: some View {
        Form {
            Section("Image") {
                if controller.exposureTime.isCapable {
                    ExposureView(controller: controller)
                }

                if controller.brightness.isCapable {
                    BrightnessView(controller: controller)
                }

                if controller.contrast.isCapable {
                    ContrastView(controller: controller)
                }

                if controller.saturation.isCapable {
                    SaturationView(controller: controller)
                }

                if controller.sharpness.isCapable {
                    SharpnessView(controller: controller)
                }

                if controller.hue.isCapable && controller.hue.maximum > 0 {
                    HueView(controller: controller)
                }

                if controller.whiteBalance.isCapable {
                    WhiteBalanceView(controller: controller)
                }
            }

            if let rightLight = controller.logitechRightLight, rightLight.isCapable {
                Section("Logitech BRIO") {
                    RightLightView(rightLight: rightLight)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxHeight: 360)
    }
}
