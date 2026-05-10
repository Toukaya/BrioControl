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
        LabeledContent {
            HStack {
                Slider(value: $hue.sliderValue,
                       in: hue.minimum...hue.maximum,
                       step: hue.tickStep)
                    .disabled(hueAuto.isEnabled)
                Toggle("Auto", isOn: $hueAuto.isEnabled.animation())
                    .toggleStyle(.button)
                    .controlSize(.small)
            }
        } label: {
            Label("Hue", systemImage: "paintpalette.fill")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
