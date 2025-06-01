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
                
                Button(action: {
                    do {
                        try PosterBoardManager.clearCache()
                        errorAlertTitle = "App Cache Successfully Cleared!"
                        errorAlertDescr = ""
                        showErrorAlert = true
                    } catch {
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
