//
//  MetronomeViewModelTests.swift
//  PulseTests
//
//  Created on 2025-12-06.
//

import Foundation
import Testing
@testable import Pulse

@MainActor
struct MetronomeViewModelTests {

    // MARK: - Setup

    /// Clear all persisted data before each test to ensure clean state
    init() {
        AppGroupDefaults.shared.clearAll()
    }

    // MARK: - Initialization Tests

    @Test("MetronomeViewModel initializes with default values")
    func testDefaultInitialization() {
        AppGroupDefaults.shared.clearAll() // Ensure clean state
        let viewModel = MetronomeViewModel()

        #expect(viewModel.isPlaying == false)
        #expect(viewModel.currentBeat == 1)
        #expect(viewModel.settings.tempo == 120)
        #expect(viewModel.settings.timeSignature == .fourFour)
    }

    @Test("MetronomeViewModel initializes with custom settings")
    func testCustomInitialization() {
        let customSettings = MetronomeSettings(
            tempo: 140,
            timeSignature: .threeFour,
            soundEnabled: false,
            hapticEnabled: false,
            accentFirstBeat: false
        )
        let viewModel = MetronomeViewModel(settings: customSettings)

        #expect(viewModel.isPlaying == false)
        #expect(viewModel.currentBeat == 1)
        #expect(viewModel.settings.tempo == 140)
        #expect(viewModel.settings.timeSignature == .threeFour)
        #expect(viewModel.settings.soundEnabled == false)
        #expect(viewModel.settings.hapticEnabled == false)
        #expect(viewModel.settings.accentFirstBeat == false)
    }

    // MARK: - Playback Control Tests

    @Test("Start changes isPlaying to true")
    func testStart() {
        let viewModel = MetronomeViewModel()

        viewModel.start()

        #expect(viewModel.isPlaying == true)
        #expect(viewModel.currentBeat == 1)
    }

    @Test("Stop changes isPlaying to false")
    func testStop() {
        let viewModel = MetronomeViewModel()

        viewModel.start()
        #expect(viewModel.isPlaying == true)

        viewModel.stop()
        #expect(viewModel.isPlaying == false)
        #expect(viewModel.currentBeat == 1)
    }

    @Test("Toggle playback changes state correctly")
    func testTogglePlayback() {
        let viewModel = MetronomeViewModel()

        // First toggle: start
        viewModel.togglePlayback()
        #expect(viewModel.isPlaying == true)

        // Second toggle: stop
        viewModel.togglePlayback()
        #expect(viewModel.isPlaying == false)
        #expect(viewModel.currentBeat == 1)
    }

    @Test("Multiple start calls are safe")
    func testMultipleStarts() {
        let viewModel = MetronomeViewModel()

        viewModel.start()
        viewModel.start()
        viewModel.start()

        #expect(viewModel.isPlaying == true)
        #expect(viewModel.currentBeat == 1)
    }

    @Test("Multiple stop calls are safe")
    func testMultipleStops() {
        let viewModel = MetronomeViewModel()

        viewModel.start()
        viewModel.stop()
        viewModel.stop()
        viewModel.stop()

        #expect(viewModel.isPlaying == false)
        #expect(viewModel.currentBeat == 1)
    }

    // MARK: - Tempo Update Tests

    @Test("Update tempo while not playing")
    func testUpdateTempoWhileStopped() {
        let viewModel = MetronomeViewModel()

        viewModel.updateTempo(140)

        #expect(viewModel.settings.tempo == 140)
        #expect(viewModel.isPlaying == false)
    }

    @Test("Update tempo while playing restarts metronome")
    func testUpdateTempoWhilePlaying() {
        let viewModel = MetronomeViewModel()

        viewModel.start()
        #expect(viewModel.isPlaying == true)

        viewModel.updateTempo(160)

        #expect(viewModel.settings.tempo == 160)
        #expect(viewModel.isPlaying == true)
        #expect(viewModel.currentBeat == 1) // Should reset to beat 1
    }

    @Test("Update tempo clamps to minimum (40 BPM)")
    func testUpdateTempoMinimumClamping() {
        let viewModel = MetronomeViewModel()

        viewModel.updateTempo(20)

        #expect(viewModel.settings.tempo == 40, "Tempo below 40 should be clamped to 40")
    }

    @Test("Update tempo clamps to maximum (150 BPM)")
    func testUpdateTempoMaximumClamping() {
        let viewModel = MetronomeViewModel()

        viewModel.updateTempo(300)

        #expect(viewModel.settings.tempo == 150, "Tempo above 150 should be clamped to 150")
    }

    @Test("Valid tempo values are not clamped")
    func testValidTempoValues() {
        let viewModel = MetronomeViewModel()
        let validTempos = [40, 60, 100, 120, 150]

        for tempo in validTempos {
            viewModel.updateTempo(tempo)
            #expect(viewModel.settings.tempo == tempo, "Valid tempo \(tempo) should not be clamped")
        }
    }

    @Test("Start with out-of-range tempo clamps to valid range")
    func testStartWithInvalidTempo() {
        let viewModel = MetronomeViewModel()

        // Set tempo directly to out-of-range value (MetronomeSettings allows 30-300)
        viewModel.settings.tempo = 30

        viewModel.start()

        #expect(viewModel.settings.tempo == 40, "Tempo should be clamped to 40 on start")
        #expect(viewModel.isPlaying == true)
    }

    // MARK: - Time Signature Update Tests

    @Test("Update time signature while not playing")
    func testUpdateTimeSignatureWhileStopped() {
        let viewModel = MetronomeViewModel()

        viewModel.updateTimeSignature(.threeFour)

        #expect(viewModel.settings.timeSignature == .threeFour)
        #expect(viewModel.isPlaying == false)
    }

    @Test("Update time signature while playing restarts metronome")
    func testUpdateTimeSignatureWhilePlaying() {
        let viewModel = MetronomeViewModel()

        viewModel.start()
        #expect(viewModel.isPlaying == true)

        viewModel.updateTimeSignature(.sixEight)

        #expect(viewModel.settings.timeSignature == .sixEight)
        #expect(viewModel.isPlaying == true)
        #expect(viewModel.currentBeat == 1) // Should reset to beat 1
    }

    @Test("Time signature updates correctly for all presets")
    func testAllTimeSignaturePresets() {
        let viewModel = MetronomeViewModel()
        let signatures: [TimeSignature] = [.fourFour, .threeFour, .sixEight, .twoFour, .fiveFour, .sevenEight]

        for signature in signatures {
            viewModel.updateTimeSignature(signature)
            #expect(viewModel.settings.timeSignature == signature)
        }
    }

    // MARK: - Accent First Beat Tests

    @Test("Update accent first beat while not playing")
    func testUpdateAccentFirstBeatWhileStopped() {
        let viewModel = MetronomeViewModel()

        viewModel.updateAccentFirstBeat(false)

        #expect(viewModel.settings.accentFirstBeat == false)
        #expect(viewModel.isPlaying == false)
    }

    @Test("Update accent first beat while playing restarts metronome")
    func testUpdateAccentFirstBeatWhilePlaying() {
        let viewModel = MetronomeViewModel()

        viewModel.start()
        #expect(viewModel.isPlaying == true)

        viewModel.updateAccentFirstBeat(false)

        #expect(viewModel.settings.accentFirstBeat == false)
        #expect(viewModel.isPlaying == true)
        #expect(viewModel.currentBeat == 1) // Should reset to beat 1
    }

    @Test("Accent first beat toggles correctly")
    func testAccentFirstBeatToggle() {
        let viewModel = MetronomeViewModel()

        #expect(viewModel.settings.accentFirstBeat == true) // Default

        viewModel.updateAccentFirstBeat(false)
        #expect(viewModel.settings.accentFirstBeat == false)

        viewModel.updateAccentFirstBeat(true)
        #expect(viewModel.settings.accentFirstBeat == true)
    }

    // MARK: - Haptic Enabled Tests

    @Test("Update haptic enabled changes settings")
    func testUpdateHapticEnabled() {
        let viewModel = MetronomeViewModel()

        #expect(viewModel.settings.hapticEnabled == true) // Default

        viewModel.updateHapticEnabled(false)
        #expect(viewModel.settings.hapticEnabled == false)

        viewModel.updateHapticEnabled(true)
        #expect(viewModel.settings.hapticEnabled == true)
    }

    @Test("Update haptic enabled does not restart playback")
    func testUpdateHapticEnabledWhilePlaying() {
        let viewModel = MetronomeViewModel()

        viewModel.start()
        let initialBeat = viewModel.currentBeat

        viewModel.updateHapticEnabled(false)

        #expect(viewModel.settings.hapticEnabled == false)
        #expect(viewModel.isPlaying == true)
        // Current beat should not reset (no restart)
        #expect(viewModel.currentBeat == initialBeat)
    }

    // MARK: - Sound Enabled Tests

    @Test("Update sound enabled changes settings")
    func testUpdateSoundEnabled() {
        let viewModel = MetronomeViewModel()

        #expect(viewModel.settings.soundEnabled == true) // Default

        viewModel.updateSoundEnabled(false)
        #expect(viewModel.settings.soundEnabled == false)

        viewModel.updateSoundEnabled(true)
        #expect(viewModel.settings.soundEnabled == true)
    }

    @Test("Update sound enabled does not restart playback")
    func testUpdateSoundEnabledWhilePlaying() {
        let viewModel = MetronomeViewModel()

        viewModel.start()
        let initialBeat = viewModel.currentBeat

        viewModel.updateSoundEnabled(false)

        #expect(viewModel.settings.soundEnabled == false)
        #expect(viewModel.isPlaying == true)
        // Current beat should not reset (no restart)
        #expect(viewModel.currentBeat == initialBeat)
    }

    // MARK: - Integration Tests

    @Test("Complex workflow: start, update tempo, update time signature, stop")
    func testComplexWorkflow() {
        let viewModel = MetronomeViewModel()

        // Start with defaults
        viewModel.start()
        #expect(viewModel.isPlaying == true)
        #expect(viewModel.settings.tempo == 120)
        #expect(viewModel.settings.timeSignature == .fourFour)

        // Update tempo while playing
        viewModel.updateTempo(140)
        #expect(viewModel.isPlaying == true)
        #expect(viewModel.settings.tempo == 140)

        // Update time signature while playing
        viewModel.updateTimeSignature(.threeFour)
        #expect(viewModel.isPlaying == true)
        #expect(viewModel.settings.timeSignature == .threeFour)

        // Stop
        viewModel.stop()
        #expect(viewModel.isPlaying == false)
        #expect(viewModel.currentBeat == 1)

        // Settings should persist after stopping
        #expect(viewModel.settings.tempo == 140)
        #expect(viewModel.settings.timeSignature == .threeFour)
    }

    @Test("Multiple rapid tempo changes")
    func testRapidTempoChanges() {
        let viewModel = MetronomeViewModel()

        viewModel.start()

        // Rapidly change tempo
        for tempo in stride(from: 60, through: 140, by: 20) {
            viewModel.updateTempo(tempo)
            #expect(viewModel.settings.tempo == tempo)
            #expect(viewModel.isPlaying == true)
        }

        viewModel.stop()
        #expect(viewModel.isPlaying == false)
    }

    @Test("Settings updates while stopped don't start playback")
    func testSettingsUpdatesDontStartPlayback() {
        let viewModel = MetronomeViewModel()

        #expect(viewModel.isPlaying == false)

        viewModel.updateTempo(140)
        viewModel.updateTimeSignature(.threeFour)
        viewModel.updateAccentFirstBeat(false)
        viewModel.updateHapticEnabled(false)
        viewModel.updateSoundEnabled(false)

        #expect(viewModel.isPlaying == false, "Settings updates should not start playback")
        #expect(viewModel.settings.tempo == 140)
        #expect(viewModel.settings.timeSignature == .threeFour)
        #expect(viewModel.settings.accentFirstBeat == false)
        #expect(viewModel.settings.hapticEnabled == false)
        #expect(viewModel.settings.soundEnabled == false)
    }
}
