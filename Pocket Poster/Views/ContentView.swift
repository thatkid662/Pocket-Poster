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
    @State var showSuccessAlert = false
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
                                    //                                UIApplication.shared.alert(title: NSLocalizedString("Applying Tendies...", comment: ""), body: NSLocalizedString("Please wait", comment: ""), animated: false, withButton: false)
                                    
                                    //                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    do {
                                        try PosterBoardManager.applyTendies(selectedTendies.wrappedValue, appHash: pbHash)
                                        selectedTendies.wrappedValue.removeAll()
                                        try? FileManager.default.removeItem(at: PosterBoardManager.getTendiesStoreURL())
                                        Haptic.shared.notify(.success)
                                        //                                        UIApplication.shared.dismissAlert(animated: true)
                                        lastError = "The PosterBoard app will now open. Please close it from the app switcher."
                                        showSuccessAlert.toggle()
                                    } catch {
                                        Haptic.shared.notify(.error)
                                        //                                        UIApplication.shared.dismissAlert(animated: true)
                                        lastError = error.localizedDescription
                                        showErrorAlert.toggle()
                                    }
                                    //                                }
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
                selectedTendies.wrappedValue.append(contentsOf: url)
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
        .alert("Success!", isPresented: $showSuccessAlert) {
            Button("OK") {
                PosterBoardManager.runShortcut(named: "PosterBoard")
            }
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
