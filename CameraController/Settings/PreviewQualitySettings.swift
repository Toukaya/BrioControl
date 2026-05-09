//
//  PreviewQualitySettings.swift
//  CameraController
//
//  Created on 10/5/26.
//  Copyright © 2026 Itaysoft. All rights reserved.
//

import Foundation

enum PreviewQualitySettings: Int, CaseIterable, Identifiable {
    case disabled = 0
    case hd720 = 720
    case fhd1080 = 1080
    case qhd1440 = 1440
    case uhd2160 = 2160

    var id: Int { rawValue }

    var width: Int {
        switch self {
        case .disabled: return 0
        case .hd720:    return 1280
        case .fhd1080:  return 1920
        case .qhd1440:  return 2560
        case .uhd2160:  return 3840
        }
    }

    var height: Int {
        switch self {
        case .disabled: return 0
        case .hd720:    return 720
        case .fhd1080:  return 1080
        case .qhd1440:  return 1440
        case .uhd2160:  return 2160
        }
    }

    // Preferred frame rate for this preview quality. 60 fps for the lower
    // resolutions where most webcams (including Logitech BRIO) support it,
    // 30 fps at 4K.
    var preferredFrameRate: Int {
        switch self {
        case .disabled: return 0
        case .hd720:    return 60
        case .fhd1080:  return 60
        case .qhd1440:  return 30
        case .uhd2160:  return 30
        }
    }

    var displayName: String {
        switch self {
        case .disabled: return "Disabled"
        case .hd720:    return "720p (HD) 1280x720"
        case .fhd1080:  return "1080p (FHD) 1920x1080"
        case .qhd1440:  return "2K (QHD) 2560x1440"
        case .uhd2160:  return "4K (UHD) 3840x2160"
        }
    }
}
