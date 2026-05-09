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
        GenericControl(value: $rightLight.sliderValue,
                       step: step,
                       range: lower...upper,
                       title: "RightLight",
                       imageName: "sun.max",
                       auto: nil)
    }
}
