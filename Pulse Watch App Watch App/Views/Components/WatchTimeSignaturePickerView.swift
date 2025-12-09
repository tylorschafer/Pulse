//
//  WatchTimeSignaturePickerView.swift
//  Pulse Watch App
//
//  Created by Tylor Schafer on 12/8/25.
//

import SwiftUI

struct WatchTimeSignaturePickerView: View {
    @Binding var timeSignature: TimeSignature
    let isPlaying: Bool

    let signatures: [TimeSignature] = [
        .fourFour, .threeFour, .sixEight, .twoFour, .fiveFour, .sevenEight
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(signatures.prefix(4), id: \.self) { sig in
                Button(action: {
                    if !isPlaying {
                        withAnimation(.spring(response: 0.3)) {
                            timeSignature = sig
                        }
                    }
                }) {
                    VStack(spacing: 1) {
                        Text("\(sig.beatsPerMeasure)")
                            .font(.system(size: 12, weight: .bold))

                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.white.opacity(0.3))

                        Text("\(sig.noteValue)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(timeSignature == sig ? .white : .white.opacity(0.5))
                    .frame(width: 32, height: 36)
                    .background(
                        timeSignature == sig ?
                            AnyShapeStyle(.thinMaterial) :
                            AnyShapeStyle(.ultraThinMaterial)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: timeSignature == sig ? [
                                        .white.opacity(0.4),
                                        .white.opacity(0.2)
                                    ] : [
                                        .white.opacity(0.1),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: timeSignature == sig ? 1.5 : 0.5
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isPlaying)
                .opacity(isPlaying ? 0.5 : 1.0)
            }
        }
    }
}
