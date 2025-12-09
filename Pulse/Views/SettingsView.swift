//
//  SettingsView.swift
//  Pulse
//
//  Created by Tylor Schafer on 12/8/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MetronomeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color(red: 0.1, green: 0.1, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                List {
                    Section {
                        Toggle("Sound", isOn: Binding(
                            get: { viewModel.settings.soundEnabled },
                            set: { viewModel.updateSoundEnabled($0) }
                        ))

                        Toggle("Haptic Feedback", isOn: Binding(
                            get: { viewModel.settings.hapticEnabled },
                            set: { viewModel.updateHapticEnabled($0) }
                        ))

                        Toggle("Accent First Beat", isOn: Binding(
                            get: { viewModel.settings.accentFirstBeat },
                            set: { viewModel.updateAccentFirstBeat($0) }
                        ))
                    } header: {
                        Text("Playback Options")
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}
