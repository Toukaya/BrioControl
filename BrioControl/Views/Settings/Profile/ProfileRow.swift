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

    var body: some View {
        LabeledContent {
            Menu {
                Button {
                    applyProfile()
                } label: {
                    Label("Apply", systemImage: "checkmark")
                }

                if case .custom = profile {
                    Divider()
                    Button {
                        deleteProfile()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        } label: {
            Text(name)
                .fontWeight(.bold)
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
