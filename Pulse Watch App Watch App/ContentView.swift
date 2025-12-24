//
//  ContentView.swift
//  Pulse Watch App Watch App
//
//  Created by Tylor Schafer on 12/1/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = MetronomeViewModel()
    @State private var volume: Float = 1.0

    // Inverted binding for Digital Crown (so clockwise = increase volume)
    private var invertedVolume: Binding<Double> {
        Binding(
            get: { 1.0 - Double(volume) },
            set: { volume = Float(1.0 - $0) }
        )
    }

    var body: some View {
        TabView {
            // Page 1: Beat Visualizer (tap to play/stop)
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground(isPlaying: viewModel.isPlaying)
                    .ignoresSafeArea()

                WatchBeatVisualizerView(
                    currentBeat: viewModel.currentBeat,
                    totalBeats: viewModel.settings.timeSignature.beatsPerMeasure,
                    isPlaying: viewModel.isPlaying,
                    tempo: viewModel.settings.tempo,
                    onTap: viewModel.togglePlayback,
                    volume: $volume
                )
            }
            .focusable(true)
            .digitalCrownRotation(
                invertedVolume,
                from: 0.0,
                through: 1.0,
                by: 0.01,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: volume) { oldValue, newValue in
                viewModel.updateVolume(newValue)
            }
            .onAppear {
                volume = viewModel.settings.volume
            }

            // Page 2: Controls
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground(isPlaying: viewModel.isPlaying)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Tempo display with Digital Crown control
                    WatchTempoControlView(
                        tempo: Binding(
                            get: { viewModel.settings.tempo },
                            set: { viewModel.updateTempo($0) }
                        )
                    )

                    // Time signature selector
                    WatchTimeSignaturePickerView(
                        timeSignature: Binding(
                            get: { viewModel.settings.timeSignature },
                            set: { viewModel.updateTimeSignature($0) }
                        ),
                        isPlaying: viewModel.isPlaying
                    )
                }
                .padding(.horizontal, 8)
            }
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    ContentView()
}
