//
//  ContentView.swift
//  Pulse
//
//  Created by Tylor Schafer on 11/3/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = MetronomeViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground(isPlaying: viewModel.isPlaying)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with glass morphism
                HeaderView(showSettings: $showSettings)
                    .padding(.top, 20)

                Spacer()

                // Main beat visualizer
                BeatVisualizerView(
                    currentBeat: viewModel.currentBeat,
                    totalBeats: viewModel.settings.timeSignature.beatsPerMeasure,
                    isPlaying: viewModel.isPlaying,
                    tempo: viewModel.settings.tempo
                )
                .padding(.horizontal, 40)

                Spacer()

                // Tempo display and controls
                TempoControlView(
                    tempo: Binding(
                        get: { viewModel.settings.tempo },
                        set: { viewModel.updateTempo($0) }
                    ),
                    isPlaying: viewModel.isPlaying
                )
                .padding(.horizontal, 30)

                Spacer()

                // Time signature selector
                TimeSignatureSelectorView(
                    timeSignature: Binding(
                        get: { viewModel.settings.timeSignature },
                        set: { viewModel.updateTimeSignature($0) }
                    ),
                    isPlaying: viewModel.isPlaying
                )
                .padding(.horizontal, 30)

                Spacer()

                // Play/Stop button
                PlaybackButtonView(
                    isPlaying: viewModel.isPlaying,
                    action: viewModel.togglePlayback
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
}
