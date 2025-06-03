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
    var selectedTendies: Binding<[URL]?>
    
    @State var showErrorAlert = false
    @State var showSuccessAlert = false
    @State var lastError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                HStack {
                    Label("Version \(Bundle.main.releaseVersionNumber ?? "UNKNOWN") (\(Int(buildNumber) != 0 ? "Beta \(buildNumber)" : NSLocalizedString("Release", comment:"")))", systemImage: "info.circle.fill")
                    Spacer()
                }
                    .font(.caption)
                    .padding(.bottom, 10)
                
                Section {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        showTendiesImporter.toggle()
                    }) {
                        Text("Select Tendies")
                    }
                    .buttonStyle(TintedButton(color: .green, fullwidth: true))
                    .padding(10)
                    
                    if let selectedTendies = selectedTendies.wrappedValue, !selectedTendies.isEmpty {
                        HStack {
                            Text("Selected Tendies")
                                .font(.headline)
                            Spacer()
                        }
                        List {
                            ForEach(selectedTendies, id: \.self) { tendie in
                                Text(tendie.deletingPathExtension().lastPathComponent)
                            }
                            .onDelete(perform: delete)
                        }
                        .frame(height: CGFloat((selectedTendies.count * 65) + (selectedTendies.count < 3 ? 100 : 0)), alignment: .top)
                    }
                }
                
                Section {
                    if selectedTendies.wrappedValue != nil && !selectedTendies.wrappedValue!.isEmpty {
                        if pbHash == "" {
                            Text("Enter your PosterBoard app hash in Settings.")
                        } else {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
//                                UIApplication.shared.alert(title: NSLocalizedString("Applying Tendies...", comment: ""), body: NSLocalizedString("Please wait", comment: ""), animated: false, withButton: false)
                                
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    do {
                                        try PosterBoardManager.applyTendies(selectedTendies.wrappedValue!, appHash: pbHash)
                                        selectedTendies.wrappedValue = nil
                                        try? FileManager.default.removeItem(at: PosterBoardManager.getTendiesStoreURL())
                                        Haptic.shared.notify(.success)
//                                        UIApplication.shared.dismissAlert(animated: true)
                                        // TODO: Clear downloaded tendies
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
                    }
                }
            }
            .padding()
            .navigationTitle("Pocket Poster")
            .toolbar {
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
                if selectedTendies.wrappedValue == nil {
                    selectedTendies.wrappedValue = url
                } else {
                    selectedTendies.wrappedValue?.append(contentsOf: url)
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
        .alert("Success!", isPresented: $showSuccessAlert) {
            Button("OK") {
                PosterBoardManager.runShortcut(named: "PosterBoard")
            }
        } message: {
            Text(lastError ?? "???")
        }
    }
    
    func delete(at offsets: IndexSet) {
        if selectedTendies.wrappedValue != nil {
            selectedTendies.wrappedValue?.remove(atOffsets: offsets)
        }
    }
    
    init(selectedTendies: Binding<[URL]?>) {
        self.selectedTendies = selectedTendies
        // Fix file picker
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
    }
}
