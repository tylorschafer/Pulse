//
//  HapticManager.swift
//  Pulse
//
//  Created on 2025-12-04.
//

#if os(iOS)
import CoreHaptics
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

import Foundation
import os

/// Manages haptic feedback synchronized with metronome beats.
///
/// **Critical limitations:**
/// - Taptic Engine cannot play overlapping haptics
/// - Max tempo capped at 150 BPM (2.5 beats/sec) to support haptics on all beats
/// - Maximum safe rate: 2-3 haptics per second
/// - iPads typically lack haptic support
///
/// **Thread safety:**
/// - All methods are thread-safe and can be called from any context
/// - Uses OSAllocatedUnfairLock for state synchronization
final class HapticManager: Sendable {

    // MARK: - State Management

    private struct State {
        var isEnabled: Bool = true
        var isEngineRunning: Bool = false
    }

    private let stateLock = OSAllocatedUnfairLock(initialState: State())

    // MARK: - iOS Core Haptics

    #if os(iOS)
    private let engineLock: OSAllocatedUnfairLock<CHHapticEngine?>

    /// Check if the device supports haptic feedback
    var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    #endif

    // MARK: - Initialization

    init() {
        #if os(iOS)
        let engine = Self.createHapticEngine()
        self.engineLock = OSAllocatedUnfairLock(initialState: engine)

        if engine != nil {
            setupEngineHandlers()
            startEngine()
        }
        #endif
    }

    #if os(iOS)
    private static func createHapticEngine() -> CHHapticEngine? {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return nil
        }

        do {
            return try CHHapticEngine()
        } catch {
            print("HapticManager: Failed to create haptic engine: \(error.localizedDescription)")
            return nil
        }
    }

    private func setupEngineHandlers() {
        engineLock.withLock { engine in
            guard let engine = engine else { return }

            // Handle engine stop
            engine.stoppedHandler = { [weak self] reason in
                print("HapticManager: Engine stopped - \(reason.rawValue)")
                self?.stateLock.withLock { $0.isEngineRunning = false }

                // Attempt to restart
                self?.startEngine()
            }

            // Handle engine reset
            engine.resetHandler = { [weak self] in
                print("HapticManager: Engine reset")
                self?.stateLock.withLock { $0.isEngineRunning = false }

                // Attempt to restart
                self?.startEngine()
            }
        }
    }

    private func startEngine() {
        engineLock.withLock { engine in
            guard let engine = engine else { return }

            do {
                try engine.start()
                stateLock.withLock { $0.isEngineRunning = true }
            } catch {
                print("HapticManager: Failed to start engine: \(error.localizedDescription)")
                stateLock.withLock { $0.isEngineRunning = false }
            }
        }
    }
    #endif

    // MARK: - Public Interface

    /// Enable or disable haptic feedback
    var isEnabled: Bool {
        get {
            stateLock.withLock { $0.isEnabled }
        }
        set {
            stateLock.withLock { $0.isEnabled = newValue }
        }
    }

    /// Play haptic feedback for a beat
    ///
    /// This method is designed to be called from audio buffer completion callbacks
    /// and is thread-safe for use from any context.
    ///
    /// - Parameter isDownbeat: If true, plays a stronger haptic for the downbeat.
    ///                        Otherwise plays a standard haptic for regular beats.
    func playBeat(isDownbeat: Bool) {
        let enabled = stateLock.withLock { $0.isEnabled }
        guard enabled else { return }

        #if os(iOS)
        playiOSHaptic(isDownbeat: isDownbeat)
        #elseif os(watchOS)
        playwatchOSHaptic(isDownbeat: isDownbeat)
        #endif
    }

    // MARK: - Platform-Specific Implementations

    #if os(iOS)
    private func playiOSHaptic(isDownbeat: Bool) {
        let isRunning = stateLock.withLock { $0.isEngineRunning }
        guard isRunning else {
            startEngine()
            return
        }

        engineLock.withLock { engine in
            guard let engine = engine else { return }

            do {
                // Vary intensity and sharpness based on beat type
                let intensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: isDownbeat ? 1.0 : 0.6  // Stronger for downbeats
                )

                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: isDownbeat ? 1.0 : 0.8  // Sharper for downbeats
                )

                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: 0
                )

                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
            } catch {
                print("HapticManager: Failed to play haptic: \(error.localizedDescription)")
            }
        }
    }
    #endif

    #if os(watchOS)
    private func playwatchOSHaptic(isDownbeat: Bool) {
        // Use different haptic types for downbeats vs regular beats
        let hapticType: WKHapticType = isDownbeat ? .start : .click
        WKInterfaceDevice.current().play(hapticType)
    }
    #endif

    // MARK: - Cleanup

    deinit {
        #if os(iOS)
        engineLock.withLock { engine in
            engine?.stop()
        }
        #endif
    }
}
