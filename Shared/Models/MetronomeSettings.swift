//
//  MetronomeSettings.swift
//  Pulse
//
//  Created by Tylor Schafer on 12/1/25.
//

import Foundation

/// Settings for the metronome, shared between iOS and watchOS
struct MetronomeSettings: Equatable, Sendable {
    // MARK: - Constants

    static let minTempo = 30
    static let maxTempo = 150  // Capped at 150 BPM (2.5 beats/sec) to support haptics on all beats
    static let defaultTempo = 120

    // MARK: - Properties

    /// Tempo in beats per minute (BPM)
    /// Valid range: 30-150 BPM (capped to support haptics on all beats without overload)
    var tempo: Int {
        didSet {
            tempo = tempo.clamped(to: Self.minTempo...Self.maxTempo)
        }
    }

    /// Time signature for the metronome
    var timeSignature: TimeSignature

    /// Whether sound/audio feedback is enabled
    var soundEnabled: Bool

    /// Whether haptic feedback is enabled (iOS/watchOS only, all beats)
    var hapticEnabled: Bool

    /// Whether to accent the first beat of each measure
    var accentFirstBeat: Bool

    /// Volume level for audio playback (0.0 = silent, 1.0 = max)
    var volume: Float

    // MARK: - Initialization

    init(
        tempo: Int = defaultTempo,
        timeSignature: TimeSignature = .fourFour,
        soundEnabled: Bool = true,
        hapticEnabled: Bool = true,
        accentFirstBeat: Bool = true,
        volume: Float = 1.0
    ) {
        self.tempo = tempo.clamped(to: Self.minTempo...Self.maxTempo)
        self.timeSignature = timeSignature
        self.soundEnabled = soundEnabled
        self.hapticEnabled = hapticEnabled
        self.accentFirstBeat = accentFirstBeat
        self.volume = min(max(volume, 0.0), 1.0) // Clamp to 0.0-1.0
    }

    // MARK: - Computed Properties

    /// The interval between beats in seconds
    var beatInterval: TimeInterval {
        60.0 / Double(tempo)
    }

    /// Whether this settings configuration is valid
    var isValid: Bool {
        tempo >= Self.minTempo &&
        tempo <= Self.maxTempo &&
        timeSignature.isValid
    }
}

// MARK: - Codable

extension MetronomeSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case tempo
        case timeSignature
        case soundEnabled
        case hapticEnabled
        case accentFirstBeat
        case volume
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedTempo = try container.decode(Int.self, forKey: .tempo)
        let decodedVolume = try container.decodeIfPresent(Float.self, forKey: .volume) ?? 1.0

        // Initialize with clamped tempo
        self.tempo = decodedTempo.clamped(to: Self.minTempo...Self.maxTempo)
        self.timeSignature = try container.decode(TimeSignature.self, forKey: .timeSignature)
        self.soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
        self.hapticEnabled = try container.decode(Bool.self, forKey: .hapticEnabled)
        self.accentFirstBeat = try container.decode(Bool.self, forKey: .accentFirstBeat)
        self.volume = min(max(decodedVolume, 0.0), 1.0) // Clamp to 0.0-1.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tempo, forKey: .tempo)
        try container.encode(timeSignature, forKey: .timeSignature)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(hapticEnabled, forKey: .hapticEnabled)
        try container.encode(accentFirstBeat, forKey: .accentFirstBeat)
        try container.encode(volume, forKey: .volume)
    }
}

// MARK: - Comparable Extension

private extension Comparable {
    /// Clamps a value to a given range
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
