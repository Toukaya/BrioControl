//
//  SaturationView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct SaturationView: View {
    @Bindable var saturation: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.saturation = controller.saturation
    }

    var body: some View {
        LabeledContent {
            SwiftUI.Slider(value: $saturation.sliderValue,
                           in: saturation.minimum...saturation.maximum,
                           step: saturation.resolution)
        } label: {
            Label("Saturation", systemImage: "drop.fill")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
