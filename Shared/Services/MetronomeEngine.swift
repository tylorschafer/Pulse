//
//  MetronomeEngine.swift
//  Pulse
//
//  Created by Tylor Schafer on 12/1/25.
//

import AVFoundation
import Foundation
import os

/// Core audio engine for metronome with sample-accurate timing
/// Uses AVAudioEngine and AVAudioPlayerNode for sub-millisecond precision
/// Thread-safe for Swift 6 concurrency
final class MetronomeEngine: Sendable {
    // MARK: - Constants

    private static let sampleRate: Double = 44100.0
    private static let beatsToScheduleAhead = 3

    // MARK: - Audio Components (thread-safe per AVFoundation docs)

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    // Sound buffers (immutable after init)
    private let clickBuffer: AVAudioPCMBuffer
    private let accentBuffer: AVAudioPCMBuffer

    // MARK: - Haptic Feedback

    private let hapticManager: HapticManager

    // MARK: - Synchronized State

    private struct State {
        var isPlaying = false
        var currentBeat = 0
        var beatsScheduled = 0
        var startTime: AVAudioTime?
        var tempo: Int = 120
        var beatsPerMeasure: Int = 4
        var accentFirstBeat: Bool = true
        var volume: Float = 1.0
    }

    private let stateLock = OSAllocatedUnfairLock(initialState: State())

    // MARK: - Callbacks

    // Callback is invoked on audio completion handler thread (background thread)
    // Caller should dispatch to MainActor if UI updates are needed
    private let callbackLock = OSAllocatedUnfairLock<(@Sendable (Int, Bool) -> Void)?>(initialState: nil)

    var onBeat: (@Sendable (Int, Bool) -> Void)? {
        get { callbackLock.withLock { $0 } }
        set { callbackLock.withLock { $0 = newValue } }
    }

    // MARK: - Interruption Handling

    // Store observer token for cleanup (nonisolated var safe with nonisolated(unsafe))
    nonisolated(unsafe) private var interruptionObserver: NSObjectProtocol?

    // MARK: - Initialization

    init() {
        let format = AVAudioFormat(
            standardFormatWithSampleRate: Self.sampleRate,
            channels: 1
        )!

        // Generate sound buffers (must be done before Sendable conformance enforced)
        self.clickBuffer = Self.generateClickSound(
            frequency: 1000.0,
            duration: 0.05,
            format: format,
            amplitude: 0.5
        )

        self.accentBuffer = Self.generateClickSound(
            frequency: 1200.0,
            duration: 0.05,
            format: format,
            amplitude: 0.8
        )

        // Initialize haptic manager
        self.hapticManager = HapticManager()

        setupAudio(format: format)
        setupInterruptionHandling()
    }

    deinit {
        // Remove interruption observer
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // Safe to call - not main actor isolated anymore
        playerNode.stop()
        engine.stop()
    }

    // MARK: - Audio Setup

    private func setupInterruptionHandling() {
        // Observe audio session interruptions (phone calls, Siri, etc.)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }

            switch type {
            case .began:
                // Interruption began (phone call, Siri, etc.)
                // Stop the metronome
                self.stop()

            case .ended:
                // Interruption ended
                // Check if we should resume playback
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                    return
                }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

                // For a metronome, we typically don't auto-resume after interruptions
                // The user should manually restart. Just log this for now.
                if options.contains(.shouldResume) {
                    print("Interruption ended - app can resume playback")
                }

            @unknown default:
                break
            }
        }
    }


    private func setupAudio(format: AVAudioFormat) {
        // Configure audio session category (but don't activate yet)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        // Attach and connect player node
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)

        // Set default volume (will be updated when playback starts)
        playerNode.volume = 1.0
        engine.mainMixerNode.volume = 1.0

        // Prepare engine (but don't start it yet - will start when session is activated)
        engine.prepare()
    }

    // MARK: - Sound Generation

    private func createBeatBuffer(isAccented: Bool, beatInterval: TimeInterval) -> AVAudioPCMBuffer {
        // Get the base click sound
        let clickSource = isAccented ? accentBuffer : clickBuffer

        // Calculate total frames needed for the beat interval
        let totalFrames = AVAudioFrameCount(beatInterval * Self.sampleRate)
        let clickFrames = clickSource.frameLength

        // Create a buffer that can hold the click + silence
        let format = AVAudioFormat(
            standardFormatWithSampleRate: Self.sampleRate,
            channels: 1
        )!

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: totalFrames
        ) else {
            fatalError("Failed to create beat buffer")
        }

        buffer.frameLength = totalFrames

        guard let bufferData = buffer.floatChannelData,
              let clickData = clickSource.floatChannelData else {
            fatalError("Failed to get channel data")
        }

        let bufferChannel = bufferData[0]
        let clickChannel = clickData[0]

        // Copy the click sound to the beginning
        for frame in 0..<Int(clickFrames) {
            bufferChannel[frame] = clickChannel[frame]
        }

        // Fill the rest with silence (zeros)
        for frame in Int(clickFrames)..<Int(totalFrames) {
            bufferChannel[frame] = 0.0
        }

        return buffer
    }

    private static func generateClickSound(
        frequency: Float,
        duration: TimeInterval,
        format: AVAudioFormat,
        amplitude: Float
    ) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(duration * format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else {
            fatalError("Failed to create audio buffer")
        }

        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData else {
            fatalError("Failed to get channel data")
        }

        let channel = channelData[0]
        let sampleRate = Float(format.sampleRate)

        // Generate a short click with exponential decay envelope
        for frame in 0..<Int(frameCount) {
            let time = Float(frame) / sampleRate
            let sineWave = sin(2.0 * .pi * frequency * time)

            // Exponential decay envelope for a sharp click sound
            let envelope = exp(-20.0 * time)

            channel[frame] = sineWave * envelope * amplitude
        }

        return buffer
    }

    // MARK: - Playback Control

    /// Start or restart the metronome with given settings
    func start(tempo: Int, beatsPerMeasure: Int, accentFirstBeat: Bool, volume: Float = 1.0) {
        // Validate tempo range (40-150 BPM to support haptics on all beats)
        guard (40...150).contains(tempo) else {
            print("Tempo \(tempo) out of valid range (40-150 BPM)")
            return
        }

        stop()

        // Activate audio session for background playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
            return
        }

        // Start the audio engine now that session is active
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
                return
            }
        }

        stateLock.withLock { state in
            state.tempo = tempo
            state.beatsPerMeasure = beatsPerMeasure
            state.accentFirstBeat = accentFirstBeat
            state.volume = min(max(volume, 0.0), 1.0) // Clamp to 0.0-1.0
            state.currentBeat = 0
            state.beatsScheduled = 0
        }

        // Set volume on player node
        playerNode.volume = min(max(volume, 0.0), 1.0)

        // Start the player node first
        playerNode.play()

        // Use immediate-mode scheduling (no specific timing, just intervals)
        // This is more reliable than sample-accurate timing for metronome use
        stateLock.withLock { state in
            state.startTime = nil // Not using sample-based timing
            state.isPlaying = true
        }

        // Trigger immediate callback for beat 0 (first beat)
        // This ensures the first downbeat gets haptic/UI feedback
        let isFirstBeatAccented = accentFirstBeat
        hapticManager.playBeat(isDownbeat: isFirstBeatAccented)
        let callback = callbackLock.withLock { $0 }
        callback?(0, isFirstBeatAccented)

        // Schedule initial beats without timing
        scheduleBeatsImmediate()
    }

    /// Stop the metronome
    func stop() {
        let wasPlaying = stateLock.withLock { state in
            let playing = state.isPlaying
            state.isPlaying = false
            state.currentBeat = 0
            state.beatsScheduled = 0
            state.startTime = nil
            return playing
        }

        guard wasPlaying else { return }

        // Only stop the player node, NOT the engine
        // Engine needs to keep running for accurate timing
        playerNode.stop()

        // Deactivate audio session and notify other apps they can resume
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    /// Update tempo on the fly (will apply to next scheduled beats)
    func updateTempo(_ newTempo: Int) {
        guard (40...150).contains(newTempo) else { return }
        stateLock.withLock { state in
            state.tempo = newTempo
        }
    }

    /// Update volume on the fly
    func updateVolume(_ newVolume: Float) {
        let clampedVolume = min(max(newVolume, 0.0), 1.0)
        stateLock.withLock { state in
            state.volume = clampedVolume
        }
        playerNode.volume = clampedVolume
    }

    // MARK: - Beat Scheduling

    private func scheduleBeats() {
        let isPlaying = stateLock.withLock { $0.isPlaying }
        guard isPlaying else { return }

        // Maintain a buffer of scheduled beats ahead
        while stateLock.withLock({ $0.beatsScheduled }) < Self.beatsToScheduleAhead {
            scheduleBeat()
        }
    }

    private func scheduleBeatsImmediate() {
        let isPlaying = stateLock.withLock { $0.isPlaying }
        guard isPlaying else { return }

        // Schedule beats without specific timing (play as soon as possible)
        while stateLock.withLock({ $0.beatsScheduled }) < Self.beatsToScheduleAhead {
            scheduleBeatImmediate()
        }
    }

    private func scheduleBeat() {
        let (startTime, beatsScheduled, tempo, beatsPerMeasure, accentFirstBeat) = stateLock.withLock { state in
            (state.startTime, state.beatsScheduled, state.tempo, state.beatsPerMeasure, state.accentFirstBeat)
        }

        guard let startTime = startTime else { return }

        // Calculate exact sample time for this beat
        let beatInterval = 60.0 / Double(tempo)
        let sampleTime = AVAudioFramePosition(
            Double(beatsScheduled) * beatInterval * Self.sampleRate
        )

        let beatTime = AVAudioTime(
            sampleTime: startTime.sampleTime + sampleTime,
            atRate: Self.sampleRate
        )

        // Determine if this is an accented beat (first beat of measure)
        let isAccented = accentFirstBeat && (beatsScheduled % beatsPerMeasure == 0)
        let buffer = isAccented ? accentBuffer : clickBuffer

        // Increment scheduled count
        stateLock.withLock { $0.beatsScheduled += 1 }

        // Schedule the buffer
        playerNode.scheduleBuffer(buffer, at: beatTime, options: []) { [weak self] in
            guard let self = self else { return }

            let (shouldContinue, beatInMeasure) = self.stateLock.withLock { state -> (Bool, Int) in
                guard state.isPlaying else { return (false, 0) }

                let beatInMeasure = state.currentBeat % state.beatsPerMeasure
                state.currentBeat += 1
                state.beatsScheduled -= 1

                return (true, beatInMeasure)
            }

            guard shouldContinue else { return }

            // Trigger haptic feedback on downbeats
            self.hapticManager.playBeat(isDownbeat: isAccented)

            // Invoke callback directly on completion handler thread
            // Caller is responsible for dispatching to MainActor if needed
            let callback = self.callbackLock.withLock { $0 }
            callback?(beatInMeasure, isAccented)

            // Schedule next beat to maintain buffer
            self.scheduleBeats()
        }
    }

    private func scheduleBeatImmediate() {
        let (beatsScheduled, tempo, beatsPerMeasure, accentFirstBeat, currentBeat) = stateLock.withLock { state in
            (state.beatsScheduled, state.tempo, state.beatsPerMeasure, state.accentFirstBeat, state.currentBeat)
        }

        print("📅 Scheduling beat: scheduled=\(beatsScheduled), current=\(currentBeat)")

        // Determine if this is an accented beat (first beat of measure)
        let isAccented = accentFirstBeat && (beatsScheduled % beatsPerMeasure == 0)

        // Create a buffer with the click sound + silence to match tempo
        let beatInterval = 60.0 / Double(tempo) // seconds per beat
        let buffer = createBeatBuffer(isAccented: isAccented, beatInterval: beatInterval)

        // Increment scheduled count
        stateLock.withLock { $0.beatsScheduled += 1 }

        print("🎵 Scheduled beat \(beatsScheduled), isAccented=\(isAccented)")

        // Schedule the buffer WITHOUT timing (plays immediately in sequence)
        // NOTE: The callback fires when the buffer has FINISHED playing, which means
        // the NEXT beat is already playing when this callback fires. So we increment
        // currentBeat first to sync haptics/UI with the currently playing beat.
        playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            guard let self = self else { return }

            print("🔔 Beat completion callback fired")

            let (shouldContinue, beatInMeasure, isAccentedForCallback) = self.stateLock.withLock { state -> (Bool, Int, Bool) in
                guard state.isPlaying else {
                    print("❌ Not playing, stopping callbacks")
                    return (false, 0, false)
                }

                // Increment FIRST because callback fires after the beat finishes
                // (the next beat is already playing when this callback fires)
                state.currentBeat += 1
                state.beatsScheduled -= 1

                // Now calculate which beat is CURRENTLY playing
                let beatInMeasure = state.currentBeat % state.beatsPerMeasure
                let isAccentedForCallback = state.accentFirstBeat && (beatInMeasure == 0)

                print("💫 Callback: beat \(state.currentBeat) (beatInMeasure=\(beatInMeasure)), scheduled=\(state.beatsScheduled)")

                return (true, beatInMeasure, isAccentedForCallback)
            }

            guard shouldContinue else { return }

            print("🎯 Triggering callback for beat \(beatInMeasure), isAccented=\(isAccentedForCallback)")

            // Trigger haptic feedback on downbeats
            self.hapticManager.playBeat(isDownbeat: isAccentedForCallback)

            // Invoke callback
            let callback = self.callbackLock.withLock { $0 }
            callback?(beatInMeasure, isAccentedForCallback)

            // Schedule next beat to maintain buffer
            self.scheduleBeatsImmediate()
        }
    }

    // MARK: - Computed Properties

    /// Current tempo in BPM
    var currentTempo: Int {
        stateLock.withLock { $0.tempo }
    }

    /// Current time signature
    var currentBeatsPerMeasure: Int {
        stateLock.withLock { $0.beatsPerMeasure }
    }

    /// Whether the metronome is currently playing
    var isPlaying: Bool {
        stateLock.withLock { $0.isPlaying }
    }

    /// Current volume level
    var currentVolume: Float {
        stateLock.withLock { $0.volume }
    }

    /// Enable or disable haptic feedback
    var hapticsEnabled: Bool {
        get { hapticManager.isEnabled }
        set { hapticManager.isEnabled = newValue }
    }
}
