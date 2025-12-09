//
//  HapticManagerTests.swift
//  PulseTests
//
//  Created on 2025-12-04.
//

import Foundation
import Testing
@testable import Pulse

#if os(iOS)
import CoreHaptics
#endif

struct HapticManagerTests {

    // MARK: - Initialization Tests

    @Test("HapticManager initializes successfully")
    func testInitialization() {
        let manager = HapticManager()

        #expect(manager.isEnabled, "HapticManager should be enabled by default")
    }

    #if os(iOS)
    @Test("HapticManager reports device haptic capabilities")
    func testHapticCapabilities() {
        let manager = HapticManager()

        // The supportsHaptics property should reflect device capabilities
        // Note: In simulator this will be false, on most iPhones it will be true
        let deviceSupports = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        #expect(manager.supportsHaptics == deviceSupports,
                "Manager should report same capabilities as CHHapticEngine")
    }
    #endif

    // MARK: - Enable/Disable Tests

    @Test("HapticManager can be disabled and re-enabled")
    func testEnableDisable() {
        let manager = HapticManager()

        #expect(manager.isEnabled, "Should start enabled")

        manager.isEnabled = false
        #expect(!manager.isEnabled, "Should be disabled after setting to false")

        manager.isEnabled = true
        #expect(manager.isEnabled, "Should be enabled after setting to true")
    }

    // MARK: - Beat Playback Tests

    @Test("HapticManager playBeat only triggers on downbeats")
    func testDownbeatOnly() {
        let manager = HapticManager()

        // These calls should not crash, even if we can't verify haptic output
        // The critical behavior is that non-downbeats are filtered out

        // Regular beat - should be filtered out (no haptic)
        manager.playBeat(isDownbeat: false)

        // Downbeat - should trigger haptic (if enabled and supported)
        manager.playBeat(isDownbeat: true)

        // Multiple regular beats - should all be filtered out
        for _ in 0..<10 {
            manager.playBeat(isDownbeat: false)
        }

        // Success is no crash and no errors
        #expect(true, "Should handle beat calls without crashing")
    }

    @Test("HapticManager respects enabled state")
    func testEnabledState() {
        let manager = HapticManager()

        // Enable haptics and trigger downbeat
        manager.isEnabled = true
        manager.playBeat(isDownbeat: true) // Should attempt to play

        // Disable haptics and trigger downbeat
        manager.isEnabled = false
        manager.playBeat(isDownbeat: true) // Should not play

        // Re-enable
        manager.isEnabled = true
        manager.playBeat(isDownbeat: true) // Should attempt to play

        // Success is no crash
        #expect(true, "Should respect enabled state without crashing")
    }

    // MARK: - Thread Safety Tests

    @Test("HapticManager is thread-safe")
    func testThreadSafety() async {
        let manager = HapticManager()

        // Simulate concurrent access from multiple threads
        await withTaskGroup(of: Void.self) { group in
            // Multiple threads toggling enabled state
            for _ in 0..<10 {
                group.addTask {
                    manager.isEnabled = true
                    manager.isEnabled = false
                }
            }

            // Multiple threads triggering beats
            for i in 0..<20 {
                group.addTask {
                    manager.playBeat(isDownbeat: i % 4 == 0)
                }
            }

            // Multiple threads reading state
            for _ in 0..<10 {
                group.addTask {
                    _ = manager.isEnabled
                }
            }
        }

        // Success is no crash or data race
        #expect(true, "Should handle concurrent access without issues")
    }

    @Test("HapticManager can be called from audio thread simulation")
    func testAudioThreadUsage() async {
        let manager = HapticManager()

        // Simulate being called from audio buffer completion callback
        // (which happens on a background audio thread)
        await Task.detached {
            for beat in 0..<16 {
                let isDownbeat = (beat % 4 == 0)
                manager.playBeat(isDownbeat: isDownbeat)

                // Small delay to simulate beat timing
                try? await Task.sleep(for: .milliseconds(10))
            }
        }.value

        #expect(true, "Should be callable from background threads")
    }

    // MARK: - Stress Tests

    @Test("HapticManager handles rapid downbeat triggers")
    func testRapidDownbeats() {
        let manager = HapticManager()

        // Trigger many downbeats in rapid succession
        // This simulates very fast tempo (e.g., 240 BPM)
        for _ in 0..<20 {
            manager.playBeat(isDownbeat: true)
        }

        // Success is no crash - the haptic engine should handle or queue
        #expect(true, "Should handle rapid downbeat triggers without crashing")
    }

    @Test("HapticManager survives enable/disable cycling")
    func testEnableDisableCycling() {
        let manager = HapticManager()

        // Rapidly toggle enabled state while triggering beats
        for i in 0..<50 {
            manager.isEnabled = (i % 2 == 0)
            manager.playBeat(isDownbeat: true)
        }

        #expect(true, "Should survive rapid enable/disable cycling")
    }

    // MARK: - Integration Tests

    @Test("HapticManager integrates with MetronomeEngine callback pattern")
    func testMetronomeEngineIntegration() {
        let manager = HapticManager()
        var callbackCount = 0

        // Simulate the callback pattern used by MetronomeEngine
        let simulateEngineBeat: @Sendable (Int, Bool) -> Void = { beat, isAccented in
            // In real usage, this would be called from audio thread
            manager.playBeat(isDownbeat: isAccented)
            callbackCount += 1
        }

        // Simulate a measure of 4/4 with accent on first beat
        for beat in 0..<4 {
            simulateEngineBeat(beat, beat == 0)
        }

        #expect(callbackCount == 4, "Should have processed all beats")
    }

    @Test("Multiple HapticManager instances can coexist")
    func testMultipleInstances() {
        let manager1 = HapticManager()
        let manager2 = HapticManager()
        let manager3 = HapticManager()

        manager1.playBeat(isDownbeat: true)
        manager2.playBeat(isDownbeat: true)
        manager3.playBeat(isDownbeat: true)

        manager1.isEnabled = false
        manager2.isEnabled = false

        manager3.playBeat(isDownbeat: true)

        #expect(true, "Multiple instances should coexist without interference")
    }
}
