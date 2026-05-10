//
//  SettingsView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    // The selected device is read straight from the @Environment-injected
    // DevicesManager instead of being threaded through as a Binding.
    // SettingsView never mutates the selection — it only branches on
    // selectedDevice?.controller — so a binding here was unnecessary
    // ceremony and forced ContentView to construct $manager.selectedDevice
    // just to hand the binding straight back into a child that ignored
    // its writability.
    @Environment(DevicesManager.self) private var manager

    var body: some View {
        TabView {
            Tab("Basic", systemImage: "video") {
                if let controller = manager.selectedDevice?.controller {
                    BasicSettings(controller: controller)
                } else {
                    UnsupportedView()
                }
            }
            Tab("Advanced", systemImage: "camera.filters") {
                if let controller = manager.selectedDevice?.controller {
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
        // The new macOS 26 TabView { Tab(...) } API has no intrinsic
        // vertical size when its container uses .fixedSize(vertical:
        // false) — the tab bar renders but the content area collapses
        // to 0 because each Form inside only sets a maxHeight. Pin a
        // fixed height here so the popover stays stable across tab
        // switches and matches the Forms' maxHeight: 360.
        .frame(height: 360)
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(UserSettings.shared)
            .environment(DevicesManager.shared)
            .environment(ProfileManager.shared)
    }
}
#endif
