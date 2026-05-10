//
//  SettingsView.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Environment(DevicesManager.self) private var manager
    @State private var section: Section = .basic

    private let bodyHeight: CGFloat = 360

    enum Section: String, CaseIterable, Identifiable, Hashable {
        case basic, advanced, profiles, settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .basic: return "Basic"
            case .advanced: return "Advanced"
            case .profiles: return "Profiles"
            case .settings: return "Settings"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top segmented Picker is the native macOS pattern for
            // popover-internal navigation. SwiftUI's TabView pulls in
            // either default segmented chrome (visually similar but
            // bottom-anchored) or window-frame chrome (.tabBarOnly),
            // neither of which sits cleanly inside an NSPopover. Driving
            // the body off a @State Section enum gives us full control
            // over spacing, ordering and conditional content.
            Picker("Section", selection: $section) {
                ForEach(Section.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 8)

            sectionBody()
                .frame(height: bodyHeight)
        }
    }

    @ViewBuilder
    private func sectionBody() -> some View {
        switch section {
        case .basic:
            if let controller = manager.selectedDevice?.controller {
                BasicSettings(controller: controller)
            } else {
                UnsupportedView()
            }
        case .advanced:
            if let controller = manager.selectedDevice?.controller {
                AdvancedView(controller: controller)
            } else {
                UnsupportedView()
            }
        case .profiles:
            ProfilesView()
        case .settings:
            PreferencesView()
        }
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
