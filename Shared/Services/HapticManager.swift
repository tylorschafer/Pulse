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
/// - Haptics limited to downbeats only to avoid overload
/// - Maximum 3-4 haptics per second
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

    /// Play haptic feedback for a downbeat
    ///
    /// This method is designed to be called from audio buffer completion callbacks
    /// and is thread-safe for use from any context.
    ///
    /// - Parameter isDownbeat: If true, plays a stronger haptic for the downbeat.
    ///                        Only downbeats should trigger haptics to avoid overload.
    func playBeat(isDownbeat: Bool) {
        guard isDownbeat else { return } // Only play haptics on downbeats

        let enabled = stateLock.withLock { $0.isEnabled }
        guard enabled else { return }

        #if os(iOS)
        playiOSHaptic()
        #elseif os(watchOS)
        playwatchOSHaptic()
        #endif
    }

    // MARK: - Platform-Specific Implementations

    #if os(iOS)
    private func playiOSHaptic() {
        let isRunning = stateLock.withLock { $0.isEngineRunning }
        guard isRunning else {
            startEngine()
            return
        }

        engineLock.withLock { engine in
            guard let engine = engine else { return }

            do {
                // Create a strong, sharp haptic for downbeat
                let intensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: 1.0 // Maximum intensity for downbeat
                )

                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: 1.0 // Sharp, percussive feel
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
    private func playwatchOSHaptic() {
        // Use .start for a strong, distinct downbeat haptic
        WKInterfaceDevice.current().play(.start)
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
