//
//  OnBoardingPage.swift
//  Pocket Poster
//
//  Created by lemin on 5/31/25.
//

import SwiftUICore

struct OnBoardingPage: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var image: String
    var link: URL?
    var linkName: String?
    var gradientColors: [Color]
    
    init(title: String, description: String, image: String, link: URL? = nil, linkName: String? = nil, gradientColors: [Color] = [Color("WelcomeLight"), Color("WelcomeDark")]) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.image = image
        self.link = link
        self.linkName = linkName
        self.gradientColors = gradientColors
    }
}

let onBoardingCards: [OnBoardingPage] = [
    .init(
        title: "Welcome to Pocket Poster!",
        description: "Here is a tutorial to help you get started with the app.",
        image: "Logo"
    ),
    .init(
        title: "Install the Shortcut",
        description: "To apply, you will need a shortcut that opens PosterBoard.",
        image: "Shortcuts",
        link: URL(string: PosterBoardManager.ShortcutURL),
        linkName: "Get Shortcut"
    ),
    .init(
        title: "Install Nugget",
        description: "To get the app bundle id, Nugget is required.\n\nOn your computer, download Nugget from the GitHub.",
        image: "Nugget",
        link: URL(string: "https://github.com/leminlimez/Nugget/releases/latest"),
        linkName: "Open GitHub"
    ),
    .init(
        title: "Enjoy!",
        description: "You can find wallpapers on the official Cowabun.ga website.",
        image: "Cowabunga",
        link: URL(string: PosterBoardManager.WallpapersURL),
        linkName: "Find Wallpapers"
    )
]
