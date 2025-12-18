//
//  TimeSignatureTests.swift
//  PulseTests
//
//  Created by Tylor Schafer on 12/1/25.
//

@testable import Pulse
import Foundation
import Testing

struct TimeSignatureTests {

    // MARK: - Initialization Tests

    @Test("TimeSignature initializes with correct values")
    func testInitialization() {
        let signature = TimeSignature(beatsPerMeasure: 4, noteValue: 4)
        #expect(signature.beatsPerMeasure == 4)
        #expect(signature.noteValue == 4)
    }

    // MARK: - Preset Tests

    @Test("4/4 preset has correct values")
    func testFourFourPreset() {
        let signature = TimeSignature.fourFour
        #expect(signature.beatsPerMeasure == 4)
        #expect(signature.noteValue == 4)
        #expect(signature.displayString == "4/4")
    }

    @Test("3/4 preset has correct values")
    func testThreeFourPreset() {
        let signature = TimeSignature.threeFour
        #expect(signature.beatsPerMeasure == 3)
        #expect(signature.noteValue == 4)
        #expect(signature.displayString == "3/4")
    }

    @Test("6/8 preset has correct values")
    func testSixEightPreset() {
        let signature = TimeSignature.sixEight
        #expect(signature.beatsPerMeasure == 6)
        #expect(signature.noteValue == 8)
        #expect(signature.displayString == "6/8")
    }

    @Test("2/4 preset has correct values")
    func testTwoFourPreset() {
        let signature = TimeSignature.twoFour
        #expect(signature.beatsPerMeasure == 2)
        #expect(signature.noteValue == 4)
        #expect(signature.displayString == "2/4")
    }

    @Test("5/4 preset has correct values")
    func testFiveFourPreset() {
        let signature = TimeSignature.fiveFour
        #expect(signature.beatsPerMeasure == 5)
        #expect(signature.noteValue == 4)
        #expect(signature.displayString == "5/4")
    }

    @Test("7/8 preset has correct values")
    func testSevenEightPreset() {
        let signature = TimeSignature.sevenEight
        #expect(signature.beatsPerMeasure == 7)
        #expect(signature.noteValue == 8)
        #expect(signature.displayString == "7/8")
    }

    // MARK: - Display String Tests

    @Test("Display string formats correctly")
    func testDisplayString() {
        let signature = TimeSignature(beatsPerMeasure: 12, noteValue: 16)
        #expect(signature.displayString == "12/16")
    }

    // MARK: - Validation Tests

    @Test("Valid time signatures return true")
    func testValidSignatures() {
        let valid = [
            TimeSignature(beatsPerMeasure: 1, noteValue: 4),
            TimeSignature(beatsPerMeasure: 4, noteValue: 4),
            TimeSignature(beatsPerMeasure: 16, noteValue: 16),
            TimeSignature(beatsPerMeasure: 6, noteValue: 8)
        ]

        for signature in valid {
            #expect(signature.isValid, "Expected \(signature.displayString) to be valid")
        }
    }

    @Test("Invalid time signatures return false")
    func testInvalidSignatures() {
        let invalid = [
            TimeSignature(beatsPerMeasure: 0, noteValue: 4),
            TimeSignature(beatsPerMeasure: 17, noteValue: 4),
            TimeSignature(beatsPerMeasure: 4, noteValue: 3),
            TimeSignature(beatsPerMeasure: 4, noteValue: 7),
            TimeSignature(beatsPerMeasure: -1, noteValue: 4)
        ]

        for signature in invalid {
            #expect(!signature.isValid, "Expected \(signature.displayString) to be invalid")
        }
    }

    // MARK: - Equatable Tests

    @Test("Equal time signatures are equal")
    func testEquality() {
        let sig1 = TimeSignature(beatsPerMeasure: 4, noteValue: 4)
        let sig2 = TimeSignature(beatsPerMeasure: 4, noteValue: 4)
        #expect(sig1 == sig2)
    }

    @Test("Different time signatures are not equal")
    func testInequality() {
        let sig1 = TimeSignature(beatsPerMeasure: 4, noteValue: 4)
        let sig2 = TimeSignature(beatsPerMeasure: 3, noteValue: 4)
        #expect(sig1 != sig2)
    }

    // MARK: - Codable Tests

    @Test("TimeSignature encodes and decodes correctly")
    func testCodable() throws {
        let original = TimeSignature.fourFour
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(TimeSignature.self, from: data)

        #expect(decoded == original)
    }

    @Test("TimeSignature array encodes and decodes correctly")
    func testCodableArray() throws {
        let original = [
            TimeSignature.fourFour,
            TimeSignature.threeFour,
            TimeSignature.sixEight
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode([TimeSignature].self, from: data)

        #expect(decoded == original)
    }
}
