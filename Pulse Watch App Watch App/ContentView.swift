//
//  ContentView.swift
//  Pulse Watch App Watch App
//
//  Created by Tylor Schafer on 12/1/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = MetronomeViewModel()

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
                    onTap: viewModel.togglePlayback
                )
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
