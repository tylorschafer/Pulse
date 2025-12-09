//
//  MetronomeTestView.swift
//  Pulse
//
//  Created by Tylor Schafer on 12/4/25.
//

import SwiftUI

@MainActor
@Observable
final class MetronomeTestViewModel {
    private let engine = MetronomeEngine()

    var tempo: Double = 120.0
    var beatsPerMeasure: Int = 4
    var accentFirstBeat: Bool = true
    var hapticsEnabled: Bool = true {
        didSet {
            engine.hapticsEnabled = hapticsEnabled
        }
    }
    var isPlaying: Bool = false
    var currentBeat: Int = 0

    init() {
        engine.onBeat = { [weak self] beat, isAccented in
            Task { @MainActor in
                self?.currentBeat = beat
            }
        }

        // Initialize haptics state
        engine.hapticsEnabled = hapticsEnabled
    }

    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func start() {
        engine.start(
            tempo: Int(tempo),
            beatsPerMeasure: beatsPerMeasure,
            accentFirstBeat: accentFirstBeat
        )
        isPlaying = engine.isPlaying
    }

    func stop() {
        engine.stop()
        isPlaying = false
        currentBeat = 0
    }

    func updateTempo() {
        if isPlaying {
            engine.updateTempo(Int(tempo))
        }
    }
}

struct MetronomeTestView: View {
    @State private var viewModel = MetronomeTestViewModel()

    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "metronome")
                    .imageScale(.large)
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)

                Text("Pulse")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Audio Engine Test")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)

            Spacer()

            // Beat indicator
            VStack(spacing: 12) {
                Text(viewModel.isPlaying ? "Beat \(viewModel.currentBeat + 1)" : "Ready")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.isPlaying ? .primary : .secondary)

                // Visual beat indicator
                HStack(spacing: 12) {
                    ForEach(0..<viewModel.beatsPerMeasure, id: \.self) { beat in
                        Circle()
                            .fill(viewModel.isPlaying && viewModel.currentBeat == beat ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .scaleEffect(viewModel.isPlaying && viewModel.currentBeat == beat ? 1.3 : 1.0)
                            .animation(.spring(response: 0.2), value: viewModel.currentBeat)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )

            // Controls
            VStack(spacing: 24) {
                // Tempo
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Tempo")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(viewModel.tempo)) BPM")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $viewModel.tempo, in: 40...240, step: 1) {
                        Text("Tempo")
                    } minimumValueLabel: {
                        Text("40")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("240")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .onChange(of: viewModel.tempo) { _, _ in
                        viewModel.updateTempo()
                    }
                }

                // Time Signature
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Signature")
                        .font(.headline)

                    Picker("Beats per measure", selection: $viewModel.beatsPerMeasure) {
                        Text("2/4").tag(2)
                        Text("3/4").tag(3)
                        Text("4/4").tag(4)
                        Text("5/4").tag(5)
                        Text("6/8").tag(6)
                    }
                    .pickerStyle(.segmented)
                    .disabled(viewModel.isPlaying)
                }

                // Accent toggle
                Toggle("Accent First Beat", isOn: $viewModel.accentFirstBeat)
                    .font(.headline)
                    .disabled(viewModel.isPlaying)

                // Haptic toggle
                Toggle("Haptic Feedback", isOn: $viewModel.hapticsEnabled)
                    .font(.headline)
            }
            .padding(.horizontal)

            Spacer()

            // Play/Stop button
            Button(action: viewModel.togglePlayback) {
                HStack {
                    Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                    Text(viewModel.isPlaying ? "Stop" : "Start")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.isPlaying ? Color.red : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
    }
}

#Preview {
    MetronomeTestView()
}
