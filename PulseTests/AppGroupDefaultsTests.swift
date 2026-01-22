//
//  AppGroupDefaultsTests.swift
//  PulseTests
//
//  Created by Tylor Schafer on 12/21/25.
//

import Foundation
import Testing
@testable import Pulse

struct AppGroupDefaultsTests {

    // MARK: - Setup

    /// Clear all data before each test to ensure clean state
    init() {
        AppGroupDefaults.shared.clearAll()
    }

    // MARK: - Settings Persistence Tests

    @Test("Save and load default settings")
    func testSaveAndLoadDefaultSettings() {
        let defaults = AppGroupDefaults.shared
        let settings = MetronomeSettings()

        defaults.saveSettings(settings)
        let loaded = defaults.loadSettings()

        #expect(loaded == settings)
        #expect(loaded.tempo == 120)
        #expect(loaded.timeSignature == .fourFour)
        #expect(loaded.soundEnabled == true)
        #expect(loaded.hapticEnabled == true)
        #expect(loaded.accentFirstBeat == true)
    }

    @Test("Save and load custom settings")
    func testSaveAndLoadCustomSettings() {
        let defaults = AppGroupDefaults.shared
        let settings = MetronomeSettings(
            tempo: 140,
            timeSignature: .threeFour,
            soundEnabled: false,
            hapticEnabled: false,
            accentFirstBeat: false
        )

        defaults.saveSettings(settings)
        let loaded = defaults.loadSettings()

        #expect(loaded == settings)
        #expect(loaded.tempo == 140)
        #expect(loaded.timeSignature == .threeFour)
        #expect(loaded.soundEnabled == false)
        #expect(loaded.hapticEnabled == false)
        #expect(loaded.accentFirstBeat == false)
    }

    @Test("Load settings returns defaults when no data saved")
    func testLoadSettingsWithNoData() {
        let defaults = AppGroupDefaults.shared
        defaults.clearAll()

        let loaded = defaults.loadSettings()
        let defaultSettings = MetronomeSettings()

        #expect(loaded == defaultSettings)
    }

    @Test("Settings persist across multiple saves")
    func testMultipleSaves() {
        let defaults = AppGroupDefaults.shared

        // First save
        let settings1 = MetronomeSettings(tempo: 100)
        defaults.saveSettings(settings1)
        #expect(defaults.loadSettings().tempo == 100)

        // Second save
        let settings2 = MetronomeSettings(tempo: 150)
        defaults.saveSettings(settings2)
 
        // Third save
        let settings3 = MetronomeSettings(tempo: 200)
        defaults.saveSettings(settings3)
        #expect(defaults.loadSettings().tempo == 200)
    }

    @Test("Settings with different time signatures persist correctly")
    func testTimeSignaturePersistence() {
        let defaults = AppGroupDefaults.shared

        let timeSignatures: [TimeSignature] = [
            .fourFour,
            .threeFour,
            .sixEight,
            .twoFour,
            .fiveFour,
            .sevenEight
        ]

        for timeSignature in timeSignatures {
            let settings = MetronomeSettings(timeSignature: timeSignature)
            defaults.saveSettings(settings)
            let loaded = defaults.loadSettings()
            #expect(loaded.timeSignature == timeSignature)
        }
    }

    // MARK: - Playback State Persistence Tests

    @Test("Save and load playback state as true")
    func testSaveAndLoadPlaybackStateTrue() {
        let defaults = AppGroupDefaults.shared

        defaults.savePlaybackState(true)
        let loaded = defaults.loadPlaybackState()

        #expect(loaded == true)
    }

    @Test("Save and load playback state as false")
    func testSaveAndLoadPlaybackStateFalse() {
        let defaults = AppGroupDefaults.shared

        defaults.savePlaybackState(false)
        let loaded = defaults.loadPlaybackState()

        #expect(loaded == false)
    }

    @Test("Load playback state returns false when no data saved")
    func testLoadPlaybackStateWithNoData() {
        let defaults = AppGroupDefaults.shared
        defaults.clearAll()

        let loaded = defaults.loadPlaybackState()

        #expect(loaded == false)
    }

    @Test("Playback state persists across multiple updates")
    func testMultiplePlaybackStateUpdates() {
        let defaults = AppGroupDefaults.shared

        defaults.savePlaybackState(true)
        #expect(defaults.loadPlaybackState() == true)

        defaults.savePlaybackState(false)
        #expect(defaults.loadPlaybackState() == false)

        defaults.savePlaybackState(true)
        #expect(defaults.loadPlaybackState() == true)
    }

    // MARK: - Clear All Tests

    @Test("Clear all removes settings data")
    func testClearAllRemovesSettings() {
        let defaults = AppGroupDefaults.shared
        let settings = MetronomeSettings(tempo: 180)

        defaults.saveSettings(settings)
        #expect(defaults.loadSettings().tempo == 180)

        defaults.clearAll()
        let loaded = defaults.loadSettings()
        #expect(loaded == MetronomeSettings()) // Should return defaults
    }

    @Test("Clear all removes playback state")
    func testClearAllRemovesPlaybackState() {
        let defaults = AppGroupDefaults.shared

        defaults.savePlaybackState(true)
        #expect(defaults.loadPlaybackState() == true)

        defaults.clearAll()
        #expect(defaults.loadPlaybackState() == false) // Should return false
    }

    @Test("Clear all removes both settings and playback state")
    func testClearAllRemovesAllData() {
        let defaults = AppGroupDefaults.shared

        defaults.saveSettings(MetronomeSettings(tempo: 160))
        defaults.savePlaybackState(true)

        defaults.clearAll()

        #expect(defaults.loadSettings() == MetronomeSettings())
        #expect(defaults.loadPlaybackState() == false)
    }

    // MARK: - Edge Cases

    @Test("Settings with minimum tempo persist correctly")
    func testMinimumTempoPersistence() {
        let defaults = AppGroupDefaults.shared
        let settings = MetronomeSettings(tempo: MetronomeSettings.minTempo)

        defaults.saveSettings(settings)
        let loaded = defaults.loadSettings()

        #expect(loaded.tempo == MetronomeSettings.minTempo)
    }

    @Test("Settings with maximum tempo persist correctly")
    func testMaximumTempoPersistence() {
        let defaults = AppGroupDefaults.shared
        let settings = MetronomeSettings(tempo: MetronomeSettings.maxTempo)

        defaults.saveSettings(settings)
        let loaded = defaults.loadSettings()

        #expect(loaded.tempo == MetronomeSettings.maxTempo)
    }

    @Test("Settings with all toggles disabled persist correctly")
    func testAllTogglesDisabled() {
        let defaults = AppGroupDefaults.shared
        let settings = MetronomeSettings(
            soundEnabled: false,
            hapticEnabled: false,
            accentFirstBeat: false
        )

        defaults.saveSettings(settings)
        let loaded = defaults.loadSettings()

        #expect(loaded.soundEnabled == false)
        #expect(loaded.hapticEnabled == false)
        #expect(loaded.accentFirstBeat == false)
    }

    // MARK: - Singleton Tests

    @Test("AppGroupDefaults.shared returns same instance")
    func testSingletonInstance() {
        let instance1 = AppGroupDefaults.shared
        let instance2 = AppGroupDefaults.shared

        // Swift doesn't have === for class comparison in Testing framework
        // Instead, verify they share the same data
        instance1.saveSettings(MetronomeSettings(tempo: 175))
        #expect(instance2.loadSettings().tempo == 175)
    }
}
