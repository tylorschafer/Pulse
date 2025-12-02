//
//  TimeSignature.swift
//  Pulse
//
//  Created by Tylor Schafer on 12/1/25.
//

import Foundation

/// Represents a musical time signature with common presets
struct TimeSignature: Codable, Equatable, Hashable, Sendable {
    /// Number of beats per measure
    let beatsPerMeasure: Int

    /// Note value that gets one beat (e.g., 4 for quarter note, 8 for eighth note)
    let noteValue: Int

    // MARK: - Common Presets

    /// 4/4 time signature (common time)
    static let fourFour = TimeSignature(beatsPerMeasure: 4, noteValue: 4)

    /// 3/4 time signature (waltz time)
    static let threeFour = TimeSignature(beatsPerMeasure: 3, noteValue: 4)

    /// 6/8 time signature
    static let sixEight = TimeSignature(beatsPerMeasure: 6, noteValue: 8)

    /// 2/4 time signature
    static let twoFour = TimeSignature(beatsPerMeasure: 2, noteValue: 4)

    /// 5/4 time signature
    static let fiveFour = TimeSignature(beatsPerMeasure: 5, noteValue: 4)

    /// 7/8 time signature
    static let sevenEight = TimeSignature(beatsPerMeasure: 7, noteValue: 8)

    // MARK: - String Representation

    /// Returns a string representation like "4/4"
    var displayString: String {
        "\(beatsPerMeasure)/\(noteValue)"
    }

    // MARK: - Validation

    /// Validates that the time signature has reasonable values
    var isValid: Bool {
        beatsPerMeasure > 0 && beatsPerMeasure <= 16 &&
        [1, 2, 4, 8, 16].contains(noteValue)
    }
}
