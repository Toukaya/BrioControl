//
//  ExposureView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI
import UVC

struct ExposureView: View {
    @Bindable var exposureMode: BitmapCaptureDeviceProperty
    @Bindable var exposureTime: NumberCaptureDeviceProperty
    @Bindable var gain: NumberCaptureDeviceProperty

    // Bridges the BitmapCaptureDeviceProperty's exposureMode (UVC bitmap
    // selector with .aperturePriority / .manual) to a Bool for the SwiftUI
    // Toggle. Preserved verbatim from the previous implementation -- TASK-06
    // reviewer flagged this derivation as load-bearing.
    var auto: Binding<Bool> {
        Binding(get: {
            exposureMode.selected == .aperturePriority
        }, set: { auto in
            withAnimation {
                exposureMode.selected = auto ? .aperturePriority : .manual
            }
        })
    }

    init(controller: DeviceController) {
        self.exposureTime = controller.exposureTime
        self.exposureMode = controller.exposureMode
        self.gain = controller.gain
    }

    var body: some View {
        LabeledContent {
            Toggle("Auto", isOn: auto)
                .toggleStyle(.switch)
        } label: {
            Label("Exposure", systemImage: "clock.fill")
                .symbolRenderingMode(.hierarchical)
        }

        if !auto.wrappedValue {
            LabeledContent {
                Slider(value: $exposureTime.sliderValue,
                       in: exposureTime.minimum...exposureTime.maximum,
                       step: exposureTime.tickStep)
            } label: {
                Label("Time", systemImage: "timer")
                    .symbolRenderingMode(.hierarchical)
            }

            LabeledContent {
                Slider(value: $gain.sliderValue,
                       in: gain.minimum...gain.maximum,
                       step: gain.tickStep)
            } label: {
                Label("Gain", systemImage: "dial.medium.fill")
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }
}
