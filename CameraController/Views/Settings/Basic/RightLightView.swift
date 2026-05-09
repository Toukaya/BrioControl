//
//  RightLightView.swift
//  CameraController
//
//  Created by Itay Brenner on 5/10/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import SwiftUI

struct RightLightView: View {
    @Bindable var rightLight: NumberCaptureDeviceProperty

    init(rightLight: NumberCaptureDeviceProperty) {
        self.rightLight = rightLight
    }

    var body: some View {
        let lower = min(rightLight.minimum, rightLight.maximum)
        let upper = max(rightLight.minimum, rightLight.maximum)
        let step = rightLight.resolution > 0 ? rightLight.resolution : 1
        LabeledContent {
            SwiftUI.Slider(value: $rightLight.sliderValue,
                           in: lower...upper,
                           step: step)
        } label: {
            Label("RightLight", systemImage: "sun.max")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
