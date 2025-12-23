//
//  AppGroupDefaults.swift
//  Pulse
//
//  Created by Tylor Schafer on 12/21/25.
//

import Foundation

/// UserDefaults wrapper using App Groups for sharing data between iPhone and Watch
final class AppGroupDefaults: Sendable {
    // MARK: - Constants

    /// App Group identifier for shared data between iPhone and Watch
    private static let appGroupIdentifier = "group.com.tylorschafer.pulse"

    /// Keys for UserDefaults storage
    private enum Keys {
        static let settings = "metronome_settings"
        static let isPlaying = "is_playing"
    }

    // MARK: - Singleton

    static let shared = AppGroupDefaults()

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    private init() {
        guard let userDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            fatalError("Failed to initialize UserDefaults with App Group: \(Self.appGroupIdentifier)")
        }
        self.userDefaults = userDefaults
    }

    // MARK: - Settings Persistence

    /// Save metronome settings to App Group UserDefaults
    /// - Parameter settings: The settings to persist
    func saveSettings(_ settings: MetronomeSettings) {
        do {
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: Keys.settings)
        } catch {
            print("Failed to encode MetronomeSettings: \(error)")
        }
    }

    /// Load metronome settings from App Group UserDefaults
    /// - Returns: Saved settings, or default settings if none exist
    func loadSettings() -> MetronomeSettings {
        guard let data = userDefaults.data(forKey: Keys.settings) else {
            return MetronomeSettings() // Return default settings
        }

        do {
            return try decoder.decode(MetronomeSettings.self, from: data)
        } catch {
            print("Failed to decode MetronomeSettings: \(error)")
            return MetronomeSettings() // Return default settings on error
        }
    }

    // MARK: - Playback State Persistence

    /// Save playback state to App Group UserDefaults
    /// - Parameter isPlaying: Whether the metronome is currently playing
    func savePlaybackState(_ isPlaying: Bool) {
        userDefaults.set(isPlaying, forKey: Keys.isPlaying)
    }

    /// Load playback state from App Group UserDefaults
    /// - Returns: Saved playback state, or false if none exists
    func loadPlaybackState() -> Bool {
        userDefaults.bool(forKey: Keys.isPlaying)
    }

    // MARK: - Utilities

    /// Clear all persisted data (useful for testing or reset)
    func clearAll() {
        userDefaults.removeObject(forKey: Keys.settings)
        userDefaults.removeObject(forKey: Keys.isPlaying)
    }
}
