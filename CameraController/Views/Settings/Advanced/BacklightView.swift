//
//  BacklightView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/25/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct BacklightView: View {
    @Bindable var backlightCompensation: NumberCaptureDeviceProperty

    init(controller: DeviceController) {
        self.backlightCompensation = controller.backlightCompensation
    }

    // Bridges the integer backlight-compensation control to a Bool for the
    // SwiftUI Toggle. Preserved verbatim from the previous implementation
    // -- TASK-06 reviewer flagged this derivation as load-bearing.
    var backightEnabled: Binding<Bool> {
        Binding(get: {
            backlightCompensation.sliderValue > 0
        }, set: {
            backlightCompensation.sliderValue = $0 ? backlightCompensation.maximum : 0
        })
    }

    var body: some View {
        LabeledContent {
            SwiftUI.Toggle("Backlight Compensation", isOn: backightEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        } label: {
            Label("Backlight Compensation", systemImage: "light.beacon.max")
                .symbolRenderingMode(.hierarchical)
        }
    }
}
