//
//  FocusView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/25/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct FocusView: View {
    @Bindable var focusAuto: BoolCaptureDeviceProperty
    @Bindable var focusAbsolute: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.focusAuto = controller.focusAuto
        self.focusAbsolute = controller.focusAbsolute
    }

    var body: some View {
        LabeledContent {
            HStack {
                Slider(value: $focusAbsolute.sliderValue,
                       in: focusAbsolute.minimum...focusAbsolute.maximum,
                       step: focusAbsolute.resolution)
                    .disabled(focusAuto.isEnabled)
                Toggle("Auto", isOn: $focusAuto.isEnabled.animation())
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        } label: {
            Label("Focus", systemImage: "camera.aperture")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
