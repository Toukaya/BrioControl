//
//  WhiteBalanceView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/24/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct WhiteBalanceView: View {
    @Bindable var whiteBalanceAuto: BoolCaptureDeviceProperty
    @Bindable var whiteBalance: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.whiteBalanceAuto = controller.whiteBalanceAuto
        self.whiteBalance = controller.whiteBalance
    }

    var body: some View {
        LabeledContent {
            HStack {
                Slider(value: $whiteBalance.sliderValue,
                       in: whiteBalance.minimum...whiteBalance.maximum,
                       step: whiteBalance.tickStep)
                    .disabled(whiteBalanceAuto.isEnabled)
                Toggle("Auto", isOn: $whiteBalanceAuto.isEnabled.animation())
                    .toggleStyle(.button)
                    .controlSize(.small)
            }
        } label: {
            Label("White Balance", systemImage: "thermometer.sun.fill")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
