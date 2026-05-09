//
//  FieldOfViewView.swift
//  CameraController
//
//  Created by Itay Brenner on 5/10/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import SwiftUI

struct FieldOfViewView: View {
    @Bindable var fieldOfView: NumberCaptureDeviceProperty

    init(fieldOfView: NumberCaptureDeviceProperty) {
        self.fieldOfView = fieldOfView
    }

    private var selection: Binding<Float> {
        Binding(get: {
            let raw = fieldOfView.sliderValue
            if raw < 0 { return 0 }
            if raw > 2 { return 2 }
            return raw
        }, set: { newValue in
            fieldOfView.sliderValue = newValue
        })
    }

    var body: some View {
        SectionView {
            SectionTitle(title: "Field of View",
                         image: Image(systemName: "viewfinder"))

            Picker(selection: selection, label: EmptyView()) {
                Text("90°").frame(width: 100).tag(0 as Float)
                Text("78°").frame(width: 100).tag(1 as Float)
                Text("65°").frame(width: 100).tag(2 as Float)
            }
            .disabled(!fieldOfView.isCapable)
            .pickerStyle(.segmented)
        }
    }
}
