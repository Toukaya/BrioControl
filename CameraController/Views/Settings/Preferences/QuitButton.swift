//
//  QuitButton.swift
//  CameraController
//
//  Created by Itay Brenner on 9/7/23.
//  Copyright © 2023 Itaysoft. All rights reserved.
//

import SwiftUI

struct QuitButton: View {
    var body: some View {
        Section {
            HStack {
                Spacer()
                Button("Quit", role: .destructive) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                Spacer()
            }
        }
    }
}

#if DEBUG
struct QuitButton_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            QuitButton()
        }
        .formStyle(.columns)
    }
}
#endif
