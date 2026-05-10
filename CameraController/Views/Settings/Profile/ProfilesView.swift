//
//  ProfilesView.swift
//  CameraController
//
//  Created by Itay Brenner on 26/6/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct ProfilesView: View {
    @Environment(ProfileManager.self) private var profileManager

    @State private var isAddingProfile = false
    @State private var profileName = ""

    private let profileListHeight: CGFloat = 176

    var body: some View {
        Form {
            Section("Profiles") {
                List {
                    ProfileRow(name: "Camera Default", profile: .defaultProfile)

                    if !profileManager.profiles.isEmpty {
                        Section("Saved Profiles") {
                            ForEach(profileManager.profiles, id: \.self) { profile in
                                ProfileRow(name: profile.name, profile: .custom(profile))
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .frame(minHeight: profileListHeight, maxHeight: profileListHeight)
            }

            Section {
                HStack {
                    Spacer()
                    Button("Save Current Profile") {
                        isAddingProfile.toggle()
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            }
        }
        .formStyle(.columns)
        .alert("Save Profile", isPresented: $isAddingProfile) {
            TextField("Name", text: $profileName)
            Button("Save", action: {
                addNewProfile()
                isAddingProfile = false
            })
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enter the name for your profile")
        }
    }

    private func addNewProfile() {
        guard let device = DevicesManager.shared.selectedDevice,
            let controller = device.controller else {
            return
        }

        withAnimation {
            profileManager.saveProfile(profileName, controller.getSettings())
            profileName = ""
        }
    }
}

#if DEBUG
struct ProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilesView()
            .environment(ProfileManager.shared)
            .environment(DevicesManager.shared)
    }
}
#endif
