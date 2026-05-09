//
//  HueView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct HueView: View {
    @Bindable var hueAuto: BoolCaptureDeviceProperty
    @Bindable var hue: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.hueAuto = controller.hueAuto
        self.hue = controller.hue
    }

    var body: some View {
        GenericControl(value: $hue.sliderValue,
                       step: hue.resolution,
                       range: hue.minimum...hue.maximum,
                       title: "Hue",
                       imageName: "hue",
                       auto: $hueAuto.isEnabled)
    }
}
