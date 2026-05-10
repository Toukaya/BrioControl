//
//  PreferencesView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/25/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    var body: some View {
        Form {
            ApplicationSection()
            CameraSection()
            PreviewSection()
            ReadWriteSection()
            // UpdatesSection hidden by user request; the section file
            // and all of its Sparkle plumbing remain so it can be
            // re-added with a single line later.
            // UpdatesSection()
            QuitButton()
        }
        .formStyle(.grouped)
        .frame(maxHeight: 360)
    }
}

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environment(UserSettings.shared)
            .environment(DevicesManager.shared)
            .environment(ProfileManager.shared)
    }
}
#endif
