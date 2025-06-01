//
//  SettingsView.swift
//  Pocket Poster
//
//  Created by lemin on 6/1/25.
//

import SwiftUI

struct SettingsView: View {
    // Prefs
    @AppStorage("pbHash") var pbHash: String = ""
    
    var body: some View {
        ScrollView {
            Section {
                HStack {
                    Text("App Hash:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                TextField("App Hash", text: $pbHash)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
            }
            .padding(.bottom, 5)
            
            Section {
                Button(action: {
                    UserDefaults.standard.set(false, forKey: "finishedTutorial")
                }) {
                    Text("Replay Tutorial")
                }
                .buttonStyle(TintedButton(color: .blue, fullwidth: true))
            }
        }
        .padding()
    }
}
