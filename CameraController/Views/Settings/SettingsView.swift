//
//  SettingsView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Binding var captureDevice: CaptureDevice?

    var body: some View {
        TabView {
            Tab("Basic", systemImage: "video") {
                if let controller = captureDevice?.controller {
                    BasicSettings(controller: controller)
                } else {
                    UnsupportedView()
                }
            }
            Tab("Advanced", systemImage: "camera.filters") {
                if let controller = captureDevice?.controller {
                    AdvancedView(controller: controller)
                } else {
                    UnsupportedView()
                }
            }
            Tab("Profiles", systemImage: "bookmark") {
                ProfilesView()
            }
            Tab("Settings", systemImage: "gearshape") {
                PreferencesView()
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(captureDevice: .constant(nil))
            .environment(UserSettings.shared)
            .environment(DevicesManager.shared)
            .environment(ProfileManager.shared)
    }
}
#endif
