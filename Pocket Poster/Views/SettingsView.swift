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
        List {
            Section {
                VStack {
                    TextField("Enter App Hash", text: $pbHash)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                    HStack {
                        Spacer()
                        // Run task to check until file exists from Nugget pc over AFC
                        Button(action: {
                            UIApplication.shared.confirmAlert(title: "Waiting for app hash...", body: "Connect your device to Nugget and click the \"Pocket Poster Helper\" button.", confirmTitle: "Cancel", onOK: {
                                cancelWaitForHash()
                            }, noCancel: true)
                            startWaitForHash()
                        }) {
                            Text("Detect")
                        }
                        .foregroundStyle(.green)
                        .onChange(of: checkingForHash) {
                            if !checkingForHash {
                                // hide ui alert
                                UIApplication.shared.dismissAlert(animated: true)
                            }
                        }
                    }
                }
            } header: {
                Label("App Hash", systemImage: "lock.app.dashed")
            }
            
            Section {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    UserDefaults.standard.set(false, forKey: "finishedTutorial")
                }) {
                    Text("Replay Tutorial")
                }
                
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
                .foregroundStyle(.red)
            } header: {
                Label("Actions", systemImage: "gear")
            }
            
            // MARK: Links
            Section {
                if let scURL = URL(string: PosterBoardManager.ShortcutURL) {
                    Link(destination: scURL) {
                        Label("Download Shortcut", systemImage: "arrow.down.circle")
                    }
                }
                if let fbURL = URL(string: "shortcuts://run-shortcut?name=PosterBoard&input=text&text=troubleshoot") {
                    Link(destination: fbURL) {
                        Label("Create Fallback Method", systemImage: "appclip")
                    }
                }
                if let wpURL = URL(string: PosterBoardManager.WallpapersURL) {
                    Link(destination: wpURL) {
                        Label("Find Wallpapers", systemImage: "safari")
                    }
                }
            } header: {
                Label("Links", systemImage: "link")
            }
            
            // MARK: Socials
            Section {
                Link(destination: URL(string: "https://github.com/leminlimez/Pocket-Poster")!) {
                    Label("View on GitHub", image: "github.fill")
                }
                Link(destination: URL(string: "https://discord.gg/MN8JgqSAqT")!) {
                    Label("Join the Discord", image: "discord.fill")
                }
                Link(destination: URL(string: "https://ko-fi.com/leminlimez")!) {
                    Label("Support on Ko-Fi", image: "ko-fi")
                }
            } header: {
                Label("Socials", systemImage: "globe")
            }
            
            // MARK: Credits
            Section {
                LinkCell(imageName: "leminlimez", url: "https://github.com/leminlimez", title: "LeminLimez", contribution: NSLocalizedString("Main Developer", comment: "leminlimez's contribution"), circle: true)
                LinkCell(imageName: "sky", url: "https://bsky.app/profile/did:plc:xykfeb7ieeo335g3aly6vev4", title: "dootskyre", contribution: "Shortcut Creator", circle: true)
                LinkCell(imageName: "Nathan", url: "https://github.com/verygenericname", title: "Nathan", contribution: "Exploit", circle: true)
                LinkCell(imageName: "duy", url: "https://github.com/khanhduytran0", title: "DuyKhanhTran", contribution: "Exploit", circle: true)
            } header: {
                Label("Credits", systemImage: "wrench.and.screwdriver")
            }
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
