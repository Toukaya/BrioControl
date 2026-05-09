//
//  UVCDescriptor.swift
//  CameraController
//
//  Created by Itay Brenner on 7/20/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

public struct ExtensionUnit {
    public let unitID: Int
    public let guid: UUID
    public let bmControls: [UInt8]

    public init(unitID: Int, guid: UUID, bmControls: [UInt8]) {
        self.unitID = unitID
        self.guid = guid
        self.bmControls = bmControls
    }
}

struct UVCDescriptor {
    let processingUnitID: Int
    let cameraTerminalID: Int
    let interfaceID: Int
    let extensionUnits: [ExtensionUnit]
}
