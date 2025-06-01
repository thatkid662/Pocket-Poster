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
    @State var selectedTendies: [URL]? = nil
    
    @State var showErrorAlert = false
    @State var showSuccessAlert = false
    @State var lastError: String?
    
    @State var downloadURL: String? = nil
    @State var showDownloadAlert = false
    
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
                        showTendiesImporter.toggle()
                    }) {
                        Text("Select Tendies")
                    }
                    .buttonStyle(TintedButton(color: .green, fullwidth: true))
                    
                    if let selectedTendies = selectedTendies {
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
                    }
                }
                
                Section {
                    if selectedTendies != nil {
                        if pbHash == "" {
                            Text("Enter your PosterBoard app hash in Settings.")
                        } else {
                            Button(action: {
                                do {
                                    try PosterBoardManager.applyTendies(selectedTendies!, appHash: pbHash)
                                    selectedTendies = nil
                                    lastError = "The PosterBoard app will now open. Please close it from the app switcher."
                                    showSuccessAlert.toggle()
                                } catch {
                                    lastError = error.localizedDescription
                                    showErrorAlert.toggle()
                                }
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
                if selectedTendies == nil {
                    selectedTendies = url
                } else {
                    selectedTendies?.append(contentsOf: url)
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
        .alert("Download Tendies File", isPresented: $showDownloadAlert) {
            Button("OK") {
                downloadWallpaper()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Would you like to download the file \(downloadURL ?? "UNKNOWN")?")
        }
        .onOpenURL(perform: { url in
            if url.absoluteString.starts(with: "pocketposter://download") {
                downloadURL = url.absoluteString.replacingOccurrences(of: "pocketposter://download?url=", with: "")
            }
            else if url.pathExtension == "tendies" {
                if selectedTendies == nil {
                    selectedTendies = []
                }
                selectedTendies?.append(url)
            }
        })
    }
    
    func delete(at offsets: IndexSet) {
        if selectedTendies != nil {
            selectedTendies?.remove(atOffsets: offsets)
        }
    }
    
    func downloadWallpaper() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        UIApplication.shared.alert(title: NSLocalizedString("Downloading", comment: "") + " \(DownloadManager.getWallpaperNameFromURL(string: downloadURL ?? "/Unknown"))...", body: NSLocalizedString("Please wait", comment: ""), animated: false, withButton: false)
        
        Task {
            do {
                let newURL = try await DownloadManager.downloadFromURL(string: downloadURL!)
                if selectedTendies == nil {
                    selectedTendies = []
                }
                selectedTendies?.append(newURL)
                Haptic.shared.notify(.success)
                UIApplication.shared.dismissAlert(animated: true)
            } catch {
                Haptic.shared.notify(.error)
                UIApplication.shared.dismissAlert(animated: true)
                UIApplication.shared.alert(title: NSLocalizedString("Could not download wallpaper!", comment: ""), body: error.localizedDescription)
            }
        }
    }
    
    init() {
        // Fix file picker
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
    }
}

#Preview {
    ContentView()
}
