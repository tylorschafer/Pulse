//
//  MetronomeViewModel.swift
//  Pulse
//
//  Created on 2025-12-06.
//

import Foundation
import Observation

/// Main view model for the metronome using the Observation framework
///
/// Manages metronome state and business logic, coordinating between the UI,
/// audio engine, and haptic feedback systems.
///
/// **Thread safety:**
/// - Observable properties are updated on @MainActor
/// - Audio engine callbacks dispatch to @MainActor for UI updates
@Observable
@MainActor
final class MetronomeViewModel {
    // MARK: - Observable Properties

    /// Whether the metronome is currently playing
    var isPlaying: Bool = false

    /// Current beat position in the measure (1-based for UI display)
    /// Range: 1 to timeSignature.beatsPerMeasure
    var currentBeat: Int = 1

    /// Current metronome settings
    var settings: MetronomeSettings

    // MARK: - Non-Observable Properties

    /// Audio engine for metronome playback
    /// Marked @ObservationIgnored as it doesn't need to trigger view updates
    @ObservationIgnored
    private var engine: MetronomeEngine?

    // MARK: - Initialization

    init(settings: MetronomeSettings = MetronomeSettings()) {
        self.settings = settings
        self.engine = MetronomeEngine()
        setupEngine()
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        // Configure initial haptic state
        engine?.hapticsEnabled = settings.hapticEnabled

        // Setup beat callback to update UI
        // Note: Callback fires on background audio thread, so we dispatch to MainActor
        engine?.onBeat = { [weak self] beatInMeasure, isAccented in
            Task { @MainActor in
                // Convert 0-based engine beat to 1-based UI beat
                self?.currentBeat = beatInMeasure + 1
            }
        }
    }

    // MARK: - Playback Control

    /// Toggle playback state (start/stop)
    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    /// Start the metronome
    func start() {
        // Validate tempo is within engine's supported range (40-240 BPM)
        let clampedTempo = min(max(settings.tempo, 40), 240)
        if clampedTempo != settings.tempo {
            settings.tempo = clampedTempo
        }

        engine?.start(
            tempo: settings.tempo,
            beatsPerMeasure: settings.timeSignature.beatsPerMeasure,
            accentFirstBeat: settings.accentFirstBeat
        )

        isPlaying = true
        currentBeat = 1
    }

    /// Stop the metronome
    func stop() {
        engine?.stop()
        isPlaying = false
        currentBeat = 1
    }

    // MARK: - Settings Updates

    /// Update tempo and restart if playing
    ///
    /// - Parameter newTempo: The new tempo in BPM (will be clamped to 40-240 range)
    func updateTempo(_ newTempo: Int) {
        // Clamp to engine's supported range
        let clampedTempo = min(max(newTempo, 40), 240)
        settings.tempo = clampedTempo

        if isPlaying {
            // Restart to apply new tempo
            start()
        }
    }

    /// Update time signature and restart if playing
    ///
    /// - Parameter newTimeSignature: The new time signature
    func updateTimeSignature(_ newTimeSignature: TimeSignature) {
        settings.timeSignature = newTimeSignature

        if isPlaying {
            // Restart to apply new time signature
            start()
        }
    }

    /// Update whether the first beat of each measure should be accented
    ///
    /// - Parameter enabled: Whether to accent the first beat
    func updateAccentFirstBeat(_ enabled: Bool) {
        settings.accentFirstBeat = enabled

        if isPlaying {
            // Restart to apply new accent setting
            start()
        }
    }

    /// Update whether haptic feedback is enabled
    ///
    /// - Parameter enabled: Whether haptic feedback should be enabled
    func updateHapticEnabled(_ enabled: Bool) {
        settings.hapticEnabled = enabled
        engine?.hapticsEnabled = enabled
    }

    /// Update whether sound/audio feedback is enabled
    ///
    /// - Parameter enabled: Whether sound should be enabled
    /// - Note: Currently the engine always plays audio. This setting is for future use.
    func updateSoundEnabled(_ enabled: Bool) {
        settings.soundEnabled = enabled
        // TODO: Implement audio muting in engine when needed
    }
}
