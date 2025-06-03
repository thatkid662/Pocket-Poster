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
    
    @State var checkingForHash: Bool = false
    @State var hashCheckTask: Task<Void, any Error>? = nil
    
    @State var showErrorAlert = false
    @State var errorAlertTitle: String?
    @State var errorAlertDescr: String?
    
    var body: some View {
        ScrollView {
            Section {
                HStack {
                    // Add button to run task to check until file exists from Nugget pc over AFC
                    Text("App Hash:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: {
                        UIApplication.shared.confirmAlert(title: "Waiting for app hash...", body: "Connect your device to Nugget and click the \"Pocket Poster Helper\" button.", confirmTitle: "Cancel", onOK: {
                            cancelWaitForHash()
                        }, noCancel: true)
                        startWaitForHash()
                    }) {
                        Text("Detect")
                    }
                    .buttonStyle(TintedButton(color: .green, fullwidth: false))
                    .onChange(of: checkingForHash) {
                        if !checkingForHash {
                            // hide ui
                            UIApplication.shared.dismissAlert(animated: true)
                        }
                    }
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
            
            // MARK: Links
            Section {
                if let scURL = URL(string: PosterBoardManager.ShortcutURL) {
                    Link(destination: scURL) {
                        Text("Download Shortcut")
                    }
                    .buttonStyle(TintedButton(color: .blue, fullwidth: true))
                }
                if let fbURL = URL(string: "shortcuts://run-shortcut?name=PosterBoard&input=text&text=troubleshoot") {
                    Link(destination: fbURL) {
                        Text("Create Fallback Method")
                    }
                    .buttonStyle(TintedButton(color: .blue, fullwidth: true))
                }
                if let wpURL = URL(string: PosterBoardManager.WallpapersURL) {
                    Link(destination: wpURL) {
                        Text("Find Wallpapers")
                    }
                    .buttonStyle(TintedButton(color: .blue, fullwidth: true))
                }
            } header: {
                Text("Links")
            }
            
            // TODO: Credits
        }
        .padding()
        .alert(errorAlertTitle ?? "Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorAlertDescr ?? "???")
        }
    }
    
    func startWaitForHash() {
        checkingForHash = true
        hashCheckTask = Task {
            let filePath = SymHandler.getDocumentsDirectory().appendingPathComponent("NuggetAppHash")
            while !FileManager.default.fileExists(atPath: filePath.path()) {
                try? await Task.sleep(nanoseconds: 500_000_000) // Sleep 0.5s
                try Task.checkCancellation()
            }
            
            do {
                let contents = try String(contentsOf: filePath)
                try? FileManager.default.removeItem(at: filePath)
                await MainActor.run {
                    pbHash = contents
                }
            } catch {
                print(error.localizedDescription)
            }

            await MainActor.run {
                checkingForHash = false
                hashCheckTask = nil
            }
        }
    }
    
    func cancelWaitForHash() {
        hashCheckTask?.cancel()
        hashCheckTask = nil
        checkingForHash = false
    }
}
