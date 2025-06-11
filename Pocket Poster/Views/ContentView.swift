//
//  ContentView.swift
//  Pocket Poster
//
//  Created by lemin on 5/31/25.
//

import SwiftUI
import UniformTypeIdentifiers

extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}

struct ContentView: View {
    // Prefs
    @AppStorage("pbHash") var pbHash: String = ""
    
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    @State var showTendiesImporter: Bool = false
    var selectedTendies: Binding<[URL]>
    
    @State var showErrorAlert = false
    @State var lastError: String?
    @State var hideResetHelp: Bool = true
    
    var body: some View {
        NavigationStack {
            List {
                Section {} header: {
                    Label("Version \(Bundle.main.releaseVersionNumber ?? "UNKNOWN") (\(Int(buildNumber) != 0 ? "Beta \(buildNumber)" : NSLocalizedString("Release", comment:"")))", systemImage: "info.circle.fill")
                        .font(.caption)
                }
                
                Section {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        showTendiesImporter.toggle()
                    }) {
                        Text("Select Tendies")
                    }
                    .buttonStyle(TintedButton(color: .green, fullwidth: true))
                }
                Section {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        let trashURL = SymHandler.getCorruptedSymlink()
                        if FileManager.default.fileExists(atPath: trashURL.path, isDirectory: &isDir) {
                            if !isDir.boolValue {
                                // A file named .Trash exists, but it's not a folder – delete it
                                do {
                                    try FileManager.default.removeItem(at: trashURL)
                                    print(".Trash file removed successfully.")
                                } catch {
                                    print("Failed to remove .Trash file: \(error)")
                                }
                            }
                        }
                    }) {
                        Text("Delete .Trash File")
                    }
                    .buttonStyle(TintedButton(color: .purple, fullwidth: true))
                }
                .listRowInsets(EdgeInsets())
                .padding(7)
                
                if !selectedTendies.wrappedValue.isEmpty {
                    Section {
                        ForEach(selectedTendies.wrappedValue, id: \.self) { tendie in
                            Text(tendie.deletingPathExtension().lastPathComponent)
                        }
                        .onDelete(perform: delete)
                    } header: {
                        Label("Selected Tendies", systemImage: "document")
                    }
                }
                
                Section {
                    if pbHash == "" {
                        Text("Enter your PosterBoard app hash in Settings.")
                    } else {
                        VStack {
                            if !selectedTendies.wrappedValue.isEmpty {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    UIApplication.shared.alert(title: NSLocalizedString("Applying Tendies...", comment: ""), body: NSLocalizedString("Please wait", comment: ""), animated: false, withButton: false)

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        do {
                                            try PosterBoardManager.applyTendies(selectedTendies.wrappedValue, appHash: pbHash)
                                            selectedTendies.wrappedValue.removeAll()
                                            SymHandler.cleanup() // just to be extra sure
                                            try? FileManager.default.removeItem(at: PosterBoardManager.getTendiesStoreURL())
                                            Haptic.shared.notify(.success)
                                            UIApplication.shared.dismissAlert(animated: false)
                                            UIApplication.shared.confirmAlert(title: "Success!", body: "The PosterBoard app will now open. Please close it from the app switcher.", onOK: {
                                                if !PosterBoardManager.openPosterBoard() {
                                                    UIApplication.shared.confirmAlert(title: "Falling Back to Shortcut", body: "PosterBoard failed to open directly. The fallback shortcut will now be opened.", onOK: {
                                                        PosterBoardManager.runShortcut(named: "PosterBoard")
                                                    }, noCancel: true)
                                                }
                                            }, noCancel: true)
                                        } catch {
                                            Haptic.shared.notify(.error)
                                            SymHandler.cleanup()
                                            UIApplication.shared.dismissAlert(animated: false)
                                            UIApplication.shared.alert(body: error.localizedDescription)
                                        }
                                    }
                                }) {
                                    Text("Apply")
                                }
                                .buttonStyle(TintedButton(color: .blue, fullwidth: true))
                            }
                            Button(action: {
                                hideResetHelp = false
                            }) {
                                Text("Reset Collections")
                            }
                            .buttonStyle(TintedButton(color: .red, fullwidth: true))
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(7)
                    }
                } header: {
                    Label("Actions", systemImage: "hammer")
                }
            }
            .navigationTitle("Pocket Poster")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let wpURL = URL(string: PosterBoardManager.WallpapersURL) {
                        Link(destination: wpURL) {
                            Image(systemName: "safari")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing, content: {
                    NavigationLink(destination: {
                        SettingsView()
                    }, label: {
                        Image(systemName: "gear")
                    })
                })
            }
        }
        .fileImporter(isPresented: $showTendiesImporter, allowedContentTypes: [UTType(filenameExtension: "tendies", conformingTo: .data)!], allowsMultipleSelection: true, onCompletion: { result in
            switch result {
            case .success(let url):
                if selectedTendies.wrappedValue.count + url.count > PosterBoardManager.MaxTendies {
                    UIApplication.shared.alert(title: "Max Tendies Reached", body: "You can only apply \(PosterBoardManager.MaxTendies) descriptors.")
                } else {
                    selectedTendies.wrappedValue.append(contentsOf: url)
                }
            case .failure(let error):
                lastError = error.localizedDescription
                showErrorAlert.toggle()
            }
        })
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(lastError ?? "???")
        }
        .overlay {
            OnBoardingView(cards: resetCollectionsInfo, isFinished: $hideResetHelp)
                .opacity(hideResetHelp ? 0.0 : 1.0)
                .transition(.opacity)
                .animation(.easeOut(duration: 0.5), value: hideResetHelp)
        }
    }
    
    func delete(at offsets: IndexSet) {
        selectedTendies.wrappedValue.remove(atOffsets: offsets)
    }
    
    init(selectedTendies: Binding<[URL]>) {
        self.selectedTendies = selectedTendies
        // Fix file picker
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
    }
}
