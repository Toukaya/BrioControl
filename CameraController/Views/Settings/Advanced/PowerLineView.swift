//
//  PowerLineView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct PowerLineView: View {
    @Bindable var powerLineFrequency: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.powerLineFrequency = controller.powerLineFrequency
    }

    var body: some View {
        LabeledContent {
            Picker("Power Line", selection: $powerLineFrequency.sliderValue) {
                Text("Disabled").tag(0 as Float)
                Text("50 Hz").tag(1 as Float)
                Text("60 Hz").tag(2 as Float)
                Text("Auto").tag(3 as Float)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .disabled(!powerLineFrequency.isCapable)
        } label: {
            Label("Power Line", systemImage: "bolt")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
