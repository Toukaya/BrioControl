//
//  SharpnessView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct SharpnessView: View {
    @Bindable var sharpness: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.sharpness = controller.sharpness
    }

    var body: some View {
        LabeledContent {
            Slider(value: $sharpness.sliderValue,
                   in: sharpness.minimum...sharpness.maximum,
                   step: sharpness.resolution)
        } label: {
            Label("Sharpness", systemImage: "triangle.fill")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
