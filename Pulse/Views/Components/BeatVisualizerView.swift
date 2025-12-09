//
//  BeatVisualizerView.swift
//  Pulse
//
//  Created by Tylor Schafer on 12/8/25.
//

import SwiftUI

struct BeatVisualizerView: View {
    let currentBeat: Int
    let totalBeats: Int
    let isPlaying: Bool
    let tempo: Int

    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 30) {
            // Large circular beat indicator
            ZStack {
                // Outer rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.1),
                                    .white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 250 + CGFloat(ring * 30), height: 250 + CGFloat(ring * 30))
                        .opacity(pulseAnimation && isPlaying ? 0.2 : 0.6)
                        .scaleEffect(pulseAnimation && isPlaying ? 1.1 : 1.0)
                        .animation(
                            .easeOut(duration: 60.0 / Double(tempo))
                            .repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }

                // Main circle with glass effect
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 250, height: 250)
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
                                lineWidth: 3
                            )
                    }
                    .shadow(color: .white.opacity(isPlaying ? 0.3 : 0.1), radius: 20)
                    .scaleEffect(pulseAnimation && isPlaying ? 1.05 : 1.0)

                // Beat counter
                VStack(spacing: 8) {
                    Text("\(currentBeat)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())

                    Text(isPlaying ? "of \(totalBeats)" : "Ready")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
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

            // Beat indicator dots
            HStack(spacing: 16) {
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
                        .frame(width: 12, height: 12)
                        .overlay {
                            if currentBeat == beat && isPlaying {
                                Circle()
                                    .stroke(.white.opacity(0.5), lineWidth: 2)
                                    .scaleEffect(1.5)
                            }
                        }
                        .scaleEffect(currentBeat == beat && isPlaying ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentBeat)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: Capsule())
        }
    }
}
