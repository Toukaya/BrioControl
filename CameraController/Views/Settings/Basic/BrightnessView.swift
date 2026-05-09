//
//  BrightnessView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct BrightnessView: View {
    @Bindable var brightness: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.brightness = controller.brightness
    }

    var body: some View {
        LabeledContent {
            Slider(value: $brightness.sliderValue,
                   in: brightness.minimum...brightness.maximum,
                   step: brightness.resolution)
        } label: {
            Label("Brightness", systemImage: "sun.max.fill")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
