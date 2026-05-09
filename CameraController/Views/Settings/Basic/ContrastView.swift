//
//  ContrastView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct ContrastView: View {
    @Bindable var contrast: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.contrast = controller.contrast
    }

    var body: some View {
        LabeledContent {
            SwiftUI.Slider(value: $contrast.sliderValue,
                           in: contrast.minimum...contrast.maximum,
                           step: contrast.resolution)
        } label: {
            Label("Contrast", systemImage: "circle.lefthalf.filled")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
