//
//  MetronomeSettingsTests.swift
//  PulseTests
//
//  Created by Tylor Schafer on 12/1/25.
//

import Foundation
import Testing
@testable import Pulse

struct MetronomeSettingsTests {

    // MARK: - Initialization Tests

    @Test("MetronomeSettings initializes with default values")
    func testDefaultInitialization() {
        let settings = MetronomeSettings()
        #expect(settings.tempo == 120)
        #expect(settings.timeSignature == .fourFour)
        #expect(settings.soundEnabled == true)
        #expect(settings.hapticEnabled == true)
        #expect(settings.accentFirstBeat == true)
    }

    @Test("MetronomeSettings initializes with custom values")
    func testCustomInitialization() {
        let settings = MetronomeSettings(
            tempo: 140,
            timeSignature: .threeFour,
            soundEnabled: false,
            hapticEnabled: false,
            accentFirstBeat: false
        )
        #expect(settings.tempo == 140)
        #expect(settings.timeSignature == .threeFour)
        #expect(settings.soundEnabled == false)
        #expect(settings.hapticEnabled == false)
        #expect(settings.accentFirstBeat == false)
    }

    // MARK: - Tempo Validation Tests

    @Test("Tempo clamps to minimum value")
    func testTempoMinimumClamping() {
        var settings = MetronomeSettings(tempo: 10)
        #expect(settings.tempo == 30, "Tempo below minimum should be clamped to 30")

        settings.tempo = 20
        #expect(settings.tempo == 30, "Setting tempo below minimum should clamp to 30")
    }

    @Test("Tempo clamps to maximum value")
    func testTempoMaximumClamping() {
        var settings = MetronomeSettings(tempo: 500)
        #expect(settings.tempo == 150, "Tempo above maximum should be clamped to 150")

        settings.tempo = 400
        #expect(settings.tempo == 150, "Setting tempo above maximum should clamp to 150")
    }

    @Test("Valid tempo values are not clamped")
    func testValidTempoValues() {
        let validTempos = [30, 60, 120, 150]

        for tempo in validTempos {
            let settings = MetronomeSettings(tempo: tempo)
            #expect(settings.tempo == tempo, "Valid tempo \(tempo) should not be clamped")
        }
    }

    @Test("Tempo mutation is properly clamped")
    func testTempoMutationClamping() {
        var settings = MetronomeSettings()

        settings.tempo = 100
        #expect(settings.tempo == 100)

        settings.tempo = 25
        #expect(settings.tempo == 30)

        settings.tempo = 350
        #expect(settings.tempo == 150)
    }

    // MARK: - Beat Interval Tests

    @Test("Beat interval calculates correctly for 60 BPM")
    func testBeatIntervalAt60BPM() {
        let settings = MetronomeSettings(tempo: 60)
        #expect(settings.beatInterval == 1.0, "60 BPM should have 1 second interval")
    }

    @Test("Beat interval calculates correctly for 120 BPM")
    func testBeatIntervalAt120BPM() {
        let settings = MetronomeSettings(tempo: 120)
        #expect(settings.beatInterval == 0.5, "120 BPM should have 0.5 second interval")
    }

    @Test("Beat interval calculates correctly for 150 BPM")
    func testBeatIntervalAt150BPM() {
        let settings = MetronomeSettings(tempo: 150)
        let expectedInterval = 60.0 / 150.0
        #expect(abs(settings.beatInterval - expectedInterval) < 0.0001, "150 BPM should have correct interval")
    }

    @Test("Beat interval updates when tempo changes")
    func testBeatIntervalUpdatesWithTempo() {
        var settings = MetronomeSettings(tempo: 60)
        #expect(settings.beatInterval == 1.0)

        settings.tempo = 120
        #expect(settings.beatInterval == 0.5)

        settings.tempo = 90
        let expectedInterval = 60.0 / 90.0
        #expect(abs(settings.beatInterval - expectedInterval) < 0.0001)
    }

    // MARK: - Validation Tests

    @Test("Valid settings return true")
    func testValidSettings() {
        let settings = MetronomeSettings(tempo: 120, timeSignature: .fourFour)
        #expect(settings.isValid)
    }

    @Test("Settings with invalid time signature return false")
    func testInvalidTimeSignature() {
        let invalidTimeSignature = TimeSignature(beatsPerMeasure: 0, noteValue: 4)
        let settings = MetronomeSettings(
            tempo: 120,
            timeSignature: invalidTimeSignature
        )
        #expect(!settings.isValid)
    }

    // MARK: - Equatable Tests

    @Test("Equal settings are equal")
    func testEquality() {
        let settings1 = MetronomeSettings(tempo: 120)
        let settings2 = MetronomeSettings(tempo: 120)
        #expect(settings1 == settings2)
    }

    @Test("Different settings are not equal")
    func testInequality() {
        let settings1 = MetronomeSettings(tempo: 120)
        let settings2 = MetronomeSettings(tempo: 140)
        #expect(settings1 != settings2)
    }

    // MARK: - Codable Tests

    @Test("MetronomeSettings encodes and decodes correctly")
    func testCodable() throws {
        let original = MetronomeSettings(
            tempo: 140,
            timeSignature: .threeFour,
            soundEnabled: false,
            hapticEnabled: true,
            accentFirstBeat: false
        )
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MetronomeSettings.self, from: data)

        #expect(decoded == original)
    }

    @Test("MetronomeSettings decodes with clamped tempo")
    func testDecodingWithInvalidTempo() throws {
        // Create JSON with invalid tempo
        let json = """
        {
            "tempo": 500,
            "timeSignature": {"beatsPerMeasure": 4, "noteValue": 4},
            "soundEnabled": true,
            "hapticEnabled": true,
            "accentFirstBeat": true
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let decoded = try decoder.decode(MetronomeSettings.self, from: data)
        #expect(decoded.tempo == 150, "Decoded tempo should be clamped to maximum")
    }

    // MARK: - Constants Tests

    @Test("Tempo constants have correct values")
    func testTempoConstants() {
        #expect(MetronomeSettings.minTempo == 30)
        #expect(MetronomeSettings.maxTempo == 150)
        #expect(MetronomeSettings.defaultTempo == 120)
    }
}
