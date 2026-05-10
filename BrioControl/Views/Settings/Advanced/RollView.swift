//
//  RollView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct RollView: View {
    @Bindable var rollAbsolute: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.rollAbsolute = controller.rollAbsolute
    }

    var body: some View {
        LabeledContent {
            Slider(value: $rollAbsolute.sliderValue,
                   in: rollAbsolute.minimum...rollAbsolute.maximum,
                   step: rollAbsolute.tickStep)
        } label: {
            Label("Roll", systemImage: "arrow.counterclockwise")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
