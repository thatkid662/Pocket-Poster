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
    
    @State var showErrorAlert = false
    @State var errorAlertTitle: String?
    @State var errorAlertDescr: String?
    
    var body: some View {
        ScrollView {
            Section {
                HStack {
                    Text("App Hash:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                TextField("Enter App Hash", text: $pbHash)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
            }
            .padding(.bottom, 5)
            
            Section {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    UserDefaults.standard.set(false, forKey: "finishedTutorial")
                }) {
                    Text("Replay Tutorial")
                }
                .buttonStyle(TintedButton(color: .blue, fullwidth: true))
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    do {
                        try PosterBoardManager.clearCache()
                        Haptic.shared.notify(.success)
                        errorAlertTitle = "App Cache Successfully Cleared!"
                        errorAlertDescr = ""
                        showErrorAlert = true
                    } catch {
                        Haptic.shared.notify(.error)
                        errorAlertTitle = "Error"
                        errorAlertDescr = error.localizedDescription
                        showErrorAlert = true
                    }
                }) {
                    Text("Clear App Cache")
                }
                .buttonStyle(TintedButton(color: .red, fullwidth: true))
            }
        }
        .padding()
        .alert(errorAlertTitle ?? "Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorAlertDescr ?? "???")
        }
    }
}
