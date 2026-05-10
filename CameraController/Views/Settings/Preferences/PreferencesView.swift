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
            UpdatesSection()
            QuitButton()
        }
        .formStyle(.columns)
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
