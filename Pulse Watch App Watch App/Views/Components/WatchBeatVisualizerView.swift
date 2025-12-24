//
//  WatchBeatVisualizerView.swift
//  Pulse Watch App
//
//  Created by Tylor Schafer on 12/8/25.
//

import SwiftUI

struct WatchBeatVisualizerView: View {
    let currentBeat: Int
    let totalBeats: Int
    let isPlaying: Bool
    let tempo: Int
    let onTap: () -> Void
    @Binding var volume: Float

    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            // Top: BPM and Volume display
            HStack(spacing: 12) {
                Text("\(tempo) BPM")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))

                // Volume indicator
                HStack(spacing: 2) {
                    Image(systemName: volumeIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(Int(volume * 100))%")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 20)

            Spacer()

            // Center: Main tappable circle
            Button(action: onTap) {
                ZStack {
                    // Main circle with glass effect
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 140, height: 140)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.3),
                                            .white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        }
                        .shadow(color: .white.opacity(isPlaying ? 0.3 : 0.1), radius: 10)
                        .scaleEffect(pulseAnimation && isPlaying ? 1.08 : 1.0)

                    // Beat counter or play icon
                    VStack(spacing: 4) {
                        if isPlaying {
                            Text("\(currentBeat)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .contentTransition(.numericText())

                            Text("of \(totalBeats)")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Text("Tap to Start")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onChange(of: currentBeat) { oldValue, newValue in
                if isPlaying {
                    pulseAnimation = false
                    withAnimation(.easeOut(duration: 0.1)) {
                        pulseAnimation = true
                    }
                }
            }
            .onChange(of: isPlaying) { oldValue, newValue in
                if !newValue {
                    pulseAnimation = false
                }
            }

            Spacer()

            // Bottom: Beat indicator dots
            HStack(spacing: 8) {
                ForEach(1...totalBeats, id: \.self) { beat in
                    Circle()
                        .fill(
                            currentBeat == beat && isPlaying ?
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ) :
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .frame(width: 7, height: 7)
                        .scaleEffect(currentBeat == beat && isPlaying ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentBeat)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .padding(.bottom, 20)
        }
    }

    // MARK: - Computed Properties

    private var volumeIcon: String {
        if volume < 0.01 {
            return "speaker.slash.fill"
        } else if volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
}
