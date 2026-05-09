//
//  ProfileRow.swift
//  CameraController
//
//  Created by Itay Brenner on 12/8/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

enum ProfileType {
    case defaultProfile
    case custom(Profile)
}

struct ProfileRow: View {
    @Environment(DevicesManager.self) private var devicesManager
    @Environment(ProfileManager.self) private var profileManager

    var name: String
    var profile: ProfileType
    @State private var showIcons = false

    var body: some View {
        LabeledContent {
            HStack {
                if showIcons {
                    Button {
                        applyProfile()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderless)

                    if case .custom = profile {
                        Button {
                            deleteProfile()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        } label: {
            Text(name)
                .fontWeight(.bold)
        }
        .contentShape(Rectangle())
        .onHover { isHovering in
            showIcons = isHovering
        }
    }

    private func applyProfile() {
        guard let device = devicesManager.selectedDevice else {
            return
        }

        switch profile {
        case .defaultProfile:
            device.controller?.resetDefault()
        case .custom(let profile):
            device.controller?.set(profile.settings!)
        }
    }

    private func deleteProfile() {
        guard case let .custom(profile) = profile else {
            return
        }
        withAnimation {
            profileManager.deleteProfile(profile)
        }
    }
}
