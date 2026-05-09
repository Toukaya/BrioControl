//
//  PanTiltView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct PanTiltView: View {
    @Bindable var panTiltAbsolute: MultipleCaptureDeviceProperty

    init(controller: DeviceController) {
        self.panTiltAbsolute = controller.panTiltAbsolute
    }

    // Render PanTilt as two separate LabeledContent rows ("Pan" and
    // "Tilt"). The two-axis pad alternative would require a custom
    // gesture-driven view; two sliders mirror the legacy layout, are
    // keyboard-navigable for free, and read naturally to VoiceOver.
    var body: some View {
        LabeledContent {
            SwiftUI.Slider(value: $panTiltAbsolute.sliderValue2,
                           in: panTiltAbsolute.minimum2...panTiltAbsolute.maximum2,
                           step: panTiltAbsolute.resolution2)
        } label: {
            Label("Pan", systemImage: "arrow.left.and.right")
                .symbolRenderingMode(.hierarchical)
        }

        LabeledContent {
            SwiftUI.Slider(value: $panTiltAbsolute.sliderValue1,
                           in: panTiltAbsolute.minimum1...panTiltAbsolute.maximum1,
                           step: panTiltAbsolute.resolution1)
        } label: {
            Label("Tilt", systemImage: "arrow.up.and.down")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
