//
//  WatchTempoControlView.swift
//  Pulse Watch App
//
//  Created by Tylor Schafer on 12/8/25.
//

import SwiftUI

struct WatchTempoControlView: View {
    @Binding var tempo: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(tempo)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())

                Text("BPM")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .focusable()
            .digitalCrownRotation(
                Binding(
                    get: { Double(tempo) },
                    set: { tempo = Int($0) }
                ),
                from: 40,
                through: 240,
                by: 1,
                sensitivity: .low,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )

            Text("Use Digital Crown")
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
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
