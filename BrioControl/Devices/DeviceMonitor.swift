//
//  DeviceMonitor.swift
//  CameraController
//
//  Created by Itay Brenner on 8/1/20.
//  Copyright © 2020 Itaysoft. All rights reserved.
//

import Foundation
import Observation

@MainActor
final class DeviceMonitor {
    private var readTimer: Timer?
    private var writeTimer: Timer?
    private var readInterval: Double = 0
    private var writeInterval: Double = 0
    private var lastDevice: CaptureDevice?

    init() {
        // Seed initial intervals from UserSettings and re-arm an Observation
        // tracker so that whenever readRate / writeRate change we recompute
        // the timers. withObservationTracking fires once per change, so we
        // call observeRates() recursively from inside the onChange block.
        observeRates()
    }

    private func observeRates() {
        withObservationTracking {
            self.readInterval = UserSettings.shared.readRate.rawValue
            self.writeInterval = UserSettings.shared.writeRate.rawValue
        } onChange: { [weak self] in
            // The onChange callback runs on the thread that mutated the
            // observed value (here always the main actor, since UserSettings
            // is configured from views). Hop explicitly to be safe.
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.observeRates()
                self.recreateTimers()
            }
        }
        recreateTimers()
    }

    private func recreateTimers() {
        readTimer?.invalidate()
        writeTimer?.invalidate()

        if readInterval > 0 {
            readTimer = Timer.scheduledTimer(timeInterval: readInterval,
                                             target: self,
                                             selector: #selector(readFromDevice),
                                             userInfo: nil,
                                             repeats: true)
        }

        if writeInterval > 0 {
            writeTimer = Timer.scheduledTimer(timeInterval: writeInterval,
                                             target: self,
                                             selector: #selector(writeToDevice),
                                             userInfo: nil,
                                             repeats: true)
        }
    }

    func updateDevice(_ captureDevice: CaptureDevice?) {
        lastDevice = captureDevice
        recreateTimers()
    }

    @objc
    private func readFromDevice() {
        lastDevice?.readValuesFromDevice()
    }

    @objc
    private func writeToDevice() {
        lastDevice?.writeValuesToDevice()
    }
}
