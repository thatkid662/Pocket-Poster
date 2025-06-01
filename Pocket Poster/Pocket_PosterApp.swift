//
//  Pocket_PosterApp.swift
//  Pocket Poster
//
//  Created by lemin on 5/31/25.
//

import SwiftUI

@main
struct Pocket_PosterApp: App {
    @AppStorage("finishedTutorial") var finishedTutorial: Bool = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if finishedTutorial {
                    ContentView()
                } else {
                    OnBoardingView()
                }
            }
            .transition(.opacity)
            .animation(.easeOut(duration: 0.5), value: finishedTutorial)
        }
    }
}
