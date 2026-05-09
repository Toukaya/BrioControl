//
//  UVCBoolControl.swift
//  CameraController
//
//  Created by Itay Brenner on 7/21/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation

public final class UVCBoolControl: UVCControl {
    public var defaultValue: Bool = false

    public var isEnabled: Bool {
        get {
            return _isEnabled
        }
        set {
            let value = newValue ? 1 : 0
            if setData(value: value, length: uvcSize) {
                _isEnabled = newValue
            }
        }
    }

    private var _isEnabled = false

    override init(_ interface: USBInterfacePointer, _ uvcSize: Int,
                  _ uvcSelector: Selector, _ uvcUnit: Int, _ uvcInterface: Int) {
        super.init(interface, uvcSize, uvcSelector, uvcUnit, uvcInterface)
        configure()
    }

    private func configure() {
        updateIsCapable()

        if isCapable {
            updateEnabled()
            updateDefault()
        }
    }

    func updateEnabled() {
        _isEnabled = getDataFor(type: .getCurrent, length: uvcSize) != 0
    }

    func updateDefault() {
        defaultValue = getDataFor(type: .getDefault, length: uvcSize) != 0
    }
}

// Invariant: see UVCIntControl. Reads and writes are funneled through
// UVCDeviceActor; the C interface pointer never crosses task boundaries.
extension UVCBoolControl: @unchecked Sendable {}
