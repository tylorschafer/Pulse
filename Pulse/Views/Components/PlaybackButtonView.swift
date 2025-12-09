//
//  PlaybackButtonView.swift
//  Pulse
//
//  Created by Tylor Schafer on 12/8/25.
//

import SwiftUI

struct PlaybackButtonView: View {
    let isPlaying: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2)
                    .contentTransition(.symbolEffect(.replace))

                Text(isPlaying ? "Stop" : "Start")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                ZStack {
                    if isPlaying {
                        LinearGradient(
                            colors: [
                                Color.red.opacity(0.8),
                                Color.red.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: isPlaying ? .red.opacity(0.5) : .blue.opacity(0.5), radius: 20)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}
