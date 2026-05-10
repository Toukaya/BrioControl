//
//  UpdatesSection.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct UpdatesSection: View {
    @Environment(UserSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section("Updates") {
            LabeledContent {
                Toggle("Check For Updates On Startup", isOn: $settings.checkForUpdatesOnStartup)
                    .toggleStyle(.switch)
                    .labelsHidden()
            } label: {
                Label("Check For Updates On Startup", systemImage: "icloud")
                    .symbolRenderingMode(.hierarchical)
            }

            HStack {
                Spacer()
                Button("Check For Updates Now") {
                    guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
                        return
                    }
                    delegate.checkForUpdates()
                }
                .buttonStyle(.bordered)
                Spacer()
            }
        }
    }
}

#if DEBUG
struct UpdatesSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            UpdatesSection()
        }
        .formStyle(.columns)
        .environment(UserSettings.shared)
    }
}
#endif
