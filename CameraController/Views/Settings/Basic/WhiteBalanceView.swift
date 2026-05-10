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
            Toggle("Auto", isOn: $whiteBalanceAuto.isEnabled.animation())
                .toggleStyle(.switch)
        } label: {
            Label("White Balance", systemImage: "thermometer.sun.fill")
                .symbolRenderingMode(.hierarchical)
        }

        if !whiteBalanceAuto.isEnabled {
            LabeledContent {
                Slider(value: $whiteBalance.sliderValue,
                       in: whiteBalance.minimum...whiteBalance.maximum,
                       step: whiteBalance.tickStep)
            } label: {
                Label("Temperature", systemImage: "drop.fill")
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }
}
