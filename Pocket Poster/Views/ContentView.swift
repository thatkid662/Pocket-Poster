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
    @State var selectedTendie: URL? = nil
    
    @State var showErrorAlert = false
    @State var lastError: String?
    
    var body: some View {
        VStack {
            TextField("App Hash", text: $pbHash)
            
            Button(action: {
                showTendiesImporter.toggle()
            }) {
                Text("Select Tendie")
            }
            
            if let selectedTendie = selectedTendie {
                Text("Selected Tendie: \(selectedTendie)")
                if pbHash != "" {
                    Button(action: {
                        do {
                            try PosterBoardManager.applyTendie(selectedTendie, appHash: pbHash)
                            lastError = "Success. Delete in files app."
                            showErrorAlert.toggle()
                        } catch {
                            lastError = error.localizedDescription
                            showErrorAlert.toggle()
                        }
                    }) {
                        Text("Apply")
                    }
                }
            }
        }
        .padding()
        .fileImporter(isPresented: $showTendiesImporter, allowedContentTypes: [UTType(filenameExtension: "tendies", conformingTo: .data)!], onCompletion: { result in
                switch result {
                case .success(let url):
                    selectedTendie = url
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
    }
}

#Preview {
    ContentView()
}
