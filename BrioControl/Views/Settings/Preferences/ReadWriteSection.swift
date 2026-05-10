//
//  ReadWriteSection.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct ReadWriteSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section("Read / Write settings from device") {
            LabeledContent {
                Picker("Read", selection: $settings.readRate) {
                    Text("Disabled").tag(RefreshSettingsRate.disabled)
                    Text("Every 0.5 Seconds").tag(RefreshSettingsRate.halfSecond)
                    Text("Every 1 Second").tag(RefreshSettingsRate.oneSecond)
                    Text("Every 2 Second").tag(RefreshSettingsRate.twoSeconds)
                }
                .labelsHidden()
            } label: {
                Label("Read", systemImage: "arrow.down.circle")
                    .symbolRenderingMode(.hierarchical)
                    .help("BrioControl will read the configuration from the camera every X amount of time.")
            }

            LabeledContent {
                Picker("Write", selection: $settings.writeRate) {
                    Text("Disabled").tag(RefreshSettingsRate.disabled)
                    Text("Every 0.5 Seconds").tag(RefreshSettingsRate.halfSecond)
                    Text("Every 1 Second").tag(RefreshSettingsRate.oneSecond)
                    Text("Every 2 Second").tag(RefreshSettingsRate.twoSeconds)
                }
                .labelsHidden()
            } label: {
                Label("Write", systemImage: "arrow.up.circle")
                    .symbolRenderingMode(.hierarchical)
                    .help("BrioControl will write the configuration to the camera every X amount of time.")
            }
        }
    }
}

#if DEBUG
struct ReadWriteSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            ReadWriteSection()
        }
        .formStyle(.grouped)
        .environment(UserSettings.shared)
    }
}
#endif
