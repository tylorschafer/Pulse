//
//  TempoControlView.swift
//  Pulse
//
//  Created by Tylor Schafer on 12/8/25.
//

import SwiftUI

struct TempoControlView: View {
    @Binding var tempo: Int
    let isPlaying: Bool

    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 16) {
            // Tempo display
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(tempo)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())

                Text("BPM")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.5))
                    .offset(y: -5)
            }

            // Slider with glass effect
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(tempo) },
                        set: { tempo = Int($0) }
                    ),
                    in: 40...240,
                    step: 1
                )
                .tint(
                    LinearGradient(
                        colors: [.white.opacity(0.9), .white.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                HStack {
                    Text("40")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text("240")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
    }
}
