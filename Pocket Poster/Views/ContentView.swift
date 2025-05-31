//
//  ContentView.swift
//  Pocket Poster
//
//  Created by lemin on 5/31/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // Prefs
    @AppStorage("pbHash") var pbHash: String = ""
    
    @State var showTendiesImporter: Bool = false
    @State var selectedTendies: [URL]? = nil
    
    @State var showErrorAlert = false
    @State var showSuccessAlert = false
    @State var lastError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Section {
                    HStack {
                        Text("App Hash:")
                            .bold()
                        Spacer()
                    }
                    TextField("App Hash", text: $pbHash)
                }
                .padding(.bottom, 5)
                
                Section {
                    Button(action: {
                        showTendiesImporter.toggle()
                    }) {
                        Text("Select Tendies")
                    }
                    .buttonStyle(TintedButton(color: .green, fullwidth: true))
                    
                    if let selectedTendies = selectedTendies {
                        HStack {
                            Text("Selected Tendies:")
                                .bold()
                            Spacer()
                        }
                        ForEach(selectedTendies, id: \.self) { tendie in
                            HStack {
                                Text("- \(tendie.deletingPathExtension().lastPathComponent)")
                                Spacer()
                            }
                        }
                    }
                }
                
                Section {
                    if let selectedTendies = selectedTendies, pbHash != "" {
                        Button(action: {
                            do {
                                try PosterBoardManager.applyTendies(selectedTendies, appHash: pbHash)
                                lastError = "Please open PosterBoard in the Shortcuts app and then close it from the app switcher."
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
            .padding()
            .navigationTitle("Pocket Poster")
        }
        .fileImporter(isPresented: $showTendiesImporter, allowedContentTypes: [UTType(filenameExtension: "tendies", conformingTo: .data)!], allowsMultipleSelection: true, onCompletion: { result in
            switch result {
            case .success(let url):
                selectedTendies = url
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
            Button("OK") {}
        } message: {
            Text(lastError ?? "???")
        }
    }
}

#Preview {
    ContentView()
}
