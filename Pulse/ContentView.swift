//
//  ContentView.swift
//  Pulse
//
//  Created by Tylor Schafer on 11/3/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "metronome")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            Text("Pulse")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Professional Metronome")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
