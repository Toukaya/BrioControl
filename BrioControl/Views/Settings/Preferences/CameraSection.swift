//
//  CameraSection.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct CameraSection: View {
    @Environment(DevicesManager.self) private var manager

    var body: some View {
        @Bindable var manager = manager
        Section("Camera") {
            LabeledContent {
                Picker("Camera", selection: $manager.selectedDevice) {
                    Text("None").tag(nil as CaptureDevice?)
                    ForEach(manager.devices, id: \.self) { device in
                        Text(device.name).tag(device as CaptureDevice?)
                    }
                }
                .labelsHidden()
            } label: {
                Label("Camera", systemImage: "web.camera")
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }
}

#if DEBUG
struct CameraSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            CameraSection()
        }
        .formStyle(.grouped)
        .environment(DevicesManager.shared)
    }
}
#endif
