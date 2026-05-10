//
//  ApplicationSection.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct ApplicationSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section("Application") {
            LabeledContent {
                Toggle("Open at login", isOn: $settings.openAtLogin)
                    .toggleStyle(.switch)
                    .labelsHidden()
            } label: {
                Label("Open at login", systemImage: "flag")
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }
}

#if DEBUG
struct ApplicationSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            ApplicationSection()
        }
        .formStyle(.grouped)
        .environment(UserSettings.shared)
    }
}
#endif
