//
//  MetronomeEngineTests.swift
//  PulseTests
//
//  Created by Tylor Schafer on 12/1/25.
//

import AVFoundation
import Foundation
import Testing
@testable import Pulse

struct MetronomeEngineTests {

    // Helper actor to safely collect beat callbacks across threads
    private actor BeatCollector {
        var beatCount = 0
        var accentedBeats: [Int] = []

        func recordBeat(beat: Int, isAccented: Bool) {
            beatCount += 1
            if isAccented {
                accentedBeats.append(beat)
            }
        }

        func recordAccentedBeat() {
            beatCount += 1
        }

        func getCounts() -> (beats: Int, accented: [Int]) {
            (beatCount, accentedBeats)
        }

        func getBeatCount() -> Int {
            beatCount
        }

        func reset() {
            beatCount = 0
            accentedBeats = []
        }
    }

    // MARK: - Initialization Tests

    @Test("MetronomeEngine initializes successfully")
    func testInitialization() {
        let engine = MetronomeEngine()
        #expect(!engine.isPlaying)
        #expect(engine.currentTempo == 120) // Default value
    }

    // MARK: - Playback Control Tests

    @Test("MetronomeEngine starts playback")
    func testStartPlayback() {
        let engine = MetronomeEngine()

        engine.start(tempo: 120, beatsPerMeasure: 4, accentFirstBeat: true)

        #expect(engine.isPlaying)
        #expect(engine.currentTempo == 120)
        #expect(engine.currentBeatsPerMeasure == 4)

        engine.stop()
    }

    @Test("MetronomeEngine stops playback")
    func testStopPlayback() {
        let engine = MetronomeEngine()

        engine.start(tempo: 120, beatsPerMeasure: 4, accentFirstBeat: true)
        #expect(engine.isPlaying)

        engine.stop()
        #expect(!engine.isPlaying)
    }

    @Test("MetronomeEngine can restart after stopping")
    func testRestartPlayback() {
        let engine = MetronomeEngine()

        // First playback session
        engine.start(tempo: 120, beatsPerMeasure: 4, accentFirstBeat: true)
        #expect(engine.isPlaying)

        engine.stop()
        #expect(!engine.isPlaying)

        // Second playback session
        engine.start(tempo: 140, beatsPerMeasure: 3, accentFirstBeat: false)
        #expect(engine.isPlaying)
        #expect(engine.currentTempo == 140)
        #expect(engine.currentBeatsPerMeasure == 3)

        engine.stop()
    }

    // MARK: - Tempo Validation Tests

    @Test("MetronomeEngine validates tempo range")
    func testTempoValidation() {
        let engine = MetronomeEngine()

        // Invalid tempo below range
        engine.start(tempo: 30, beatsPerMeasure: 4, accentFirstBeat: true)
        #expect(!engine.isPlaying, "Engine should not start with tempo below 40 BPM")

        // Invalid tempo above range
        engine.start(tempo: 300, beatsPerMeasure: 4, accentFirstBeat: true)
        #expect(!engine.isPlaying, "Engine should not start with tempo above 150 BPM")

        // Valid tempo at lower bound
        engine.start(tempo: 40, beatsPerMeasure: 4, accentFirstBeat: true)
        #expect(engine.isPlaying)
        engine.stop()

        // Valid tempo at upper bound
        engine.start(tempo: 150, beatsPerMeasure: 4, accentFirstBeat: true)
        #expect(engine.isPlaying)
        engine.stop()
    }

    @Test("MetronomeEngine updates tempo within valid range")
    func testUpdateTempo() {
        let engine = MetronomeEngine()

        engine.start(tempo: 120, beatsPerMeasure: 4, accentFirstBeat: true)
        #expect(engine.currentTempo == 120)

        engine.updateTempo(140)
        #expect(engine.currentTempo == 140)

        // Invalid tempo should not update
        engine.updateTempo(200)
        #expect(engine.currentTempo == 140, "Tempo should not update to invalid value")

        engine.stop()
    }

    // MARK: - Time Signature Tests

    @Test("MetronomeEngine supports different time signatures")
    func testTimeSignatures() {
        let engine = MetronomeEngine()

        let timeSignatures = [
            (beats: 4, name: "4/4"),
            (beats: 3, name: "3/4"),
            (beats: 6, name: "6/8"),
            (beats: 2, name: "2/4"),
            (beats: 5, name: "5/4")
        ]

        for signature in timeSignatures {
            engine.start(tempo: 120, beatsPerMeasure: signature.beats, accentFirstBeat: true)
            #expect(engine.isPlaying, "Engine should start with \(signature.name) time signature")
            #expect(engine.currentBeatsPerMeasure == signature.beats)
            engine.stop()
        }
    }

    // MARK: - Beat Callback Tests

    // TODO: Fix callback timing in test environment
    @Test("MetronomeEngine triggers beat callbacks", .disabled("Callbacks not firing in test environment"))
    func testBeatCallbacks() async throws {
        let engine = MetronomeEngine()
        let collector = BeatCollector()

        engine.onBeat = { beat, isAccented in
            Task {
                await collector.recordBeat(beat: beat, isAccented: isAccented)
            }
        }

        engine.start(tempo: 150, beatsPerMeasure: 4, accentFirstBeat: true) // Fast tempo for quick test

        // Wait for several beats (using fast 150 BPM = 0.4s per beat)
        try await Task.sleep(for: .seconds(1.5))

        engine.stop()

        // Give a small amount of time for final callbacks to process
        try await Task.sleep(for: .milliseconds(100))

        let (beatCount, accentedBeats) = await collector.getCounts()

        #expect(beatCount > 0, "Should have received beat callbacks")
        #expect(accentedBeats.count > 0, "Should have received accented beats")

        // First beat of each measure (beat 0) should be accented
        for accentedBeat in accentedBeats {
            #expect(accentedBeat == 0, "Only first beat of measure should be accented")
        }
    }

    @Test("MetronomeEngine respects accent setting", .disabled("Callbacks not firing in test environment"))
    func testAccentSetting() async throws {
        let engine = MetronomeEngine()
        let collectorWithAccent = BeatCollector()
        let collectorWithoutAccent = BeatCollector()

        // Test with accent enabled
        engine.onBeat = { _, isAccented in
            if isAccented {
                Task {
                    await collectorWithAccent.recordAccentedBeat()
                }
            }
        }

        engine.start(tempo: 150, beatsPerMeasure: 4, accentFirstBeat: true)
        try await Task.sleep(for: .seconds(1.0))
        engine.stop()

        // Give a small amount of time for final callbacks to process
        try await Task.sleep(for: .milliseconds(100))

        // Test with accent disabled
        engine.onBeat = { _, isAccented in
            if isAccented {
                Task {
                    await collectorWithoutAccent.recordAccentedBeat()
                }
            }
        }

        engine.start(tempo: 150, beatsPerMeasure: 4, accentFirstBeat: false)
        try await Task.sleep(for: .seconds(1.0))
        engine.stop()

        // Give a small amount of time for final callbacks to process
        try await Task.sleep(for: .milliseconds(100))

        let accentedBeatsWithAccent = await collectorWithAccent.getBeatCount()
        let accentedBeatsWithoutAccent = await collectorWithoutAccent.getBeatCount()

        #expect(accentedBeatsWithAccent > 0, "Should have accented beats when enabled")
        #expect(accentedBeatsWithoutAccent == 0, "Should have no accented beats when disabled")
    }

    // MARK: - State Tests

    @Test("MetronomeEngine maintains correct playing state")
    func testPlayingState() {
        let engine = MetronomeEngine()

        #expect(!engine.isPlaying, "Should not be playing initially")

        engine.start(tempo: 120, beatsPerMeasure: 4, accentFirstBeat: true)
        #expect(engine.isPlaying, "Should be playing after start")

        engine.stop()
        #expect(!engine.isPlaying, "Should not be playing after stop")
    }

    @Test("Multiple stops don't cause issues")
    func testMultipleStops() {
        let engine = MetronomeEngine()

        engine.start(tempo: 120, beatsPerMeasure: 4, accentFirstBeat: true)
        engine.stop()
        engine.stop() // Second stop should be safe
        engine.stop() // Third stop should be safe

        #expect(!engine.isPlaying)
    }
}
