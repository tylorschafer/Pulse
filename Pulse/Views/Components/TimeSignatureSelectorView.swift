//
//  TimeSignatureSelectorView.swift
//  Pulse
//
//  Created by Tylor Schafer on 12/8/25.
//

import SwiftUI

struct TimeSignatureSelectorView: View {
    @Binding var timeSignature: TimeSignature
    let isPlaying: Bool

    let signatures: [TimeSignature] = [
        .fourFour, .threeFour, .sixEight, .twoFour, .fiveFour, .sevenEight
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Signature")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(signatures, id: \.self) { sig in
                        TimeSignatureButton(
                            timeSignature: sig,
                            isSelected: timeSignature == sig,
                            isDisabled: isPlaying
                        ) {
                            if !isPlaying {
                                withAnimation(.spring(response: 0.3)) {
                                    timeSignature = sig
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
    }
}

struct TimeSignatureButton: View {
    let timeSignature: TimeSignature
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(timeSignature.beatsPerMeasure)")
                    .font(.title2)
                    .fontWeight(.bold)

                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(.white.opacity(0.3))

                Text("\(timeSignature.noteValue)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
            .frame(width: 60, height: 70)
            .background(
                isSelected ?
                    AnyShapeStyle(.thinMaterial) :
                    AnyShapeStyle(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: isSelected ? [
                                .white.opacity(0.4),
                                .white.opacity(0.2)
                            ] : [
                                .white.opacity(0.1),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .shadow(color: isSelected ? .white.opacity(0.3) : .clear, radius: 10)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}
