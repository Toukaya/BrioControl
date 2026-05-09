//
//  ZoomView.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct ZoomView: View {
    @Bindable var zoomAbsolute: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.zoomAbsolute = controller.zoomAbsolute
    }

    var body: some View {
        LabeledContent {
            Slider(value: $zoomAbsolute.sliderValue,
                   in: zoomAbsolute.minimum...zoomAbsolute.maximum,
                   step: zoomAbsolute.resolution)
        } label: {
            Label("Zoom", systemImage: "plus.magnifyingglass")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
