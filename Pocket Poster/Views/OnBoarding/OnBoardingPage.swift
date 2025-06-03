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

let resetCollectionsInfo: [OnBoardingPage] = [
    .init(
        title: "How to Reset Collections",
        description: "Due to the way this exploit works, it cannot delete files.\n\nHere is a guide on how to do it manually.",
        image: "CustomCollection"
    ),
    .init(
        title: "Open the Language Settings",
        description: "Inside the Settings app, navigate to General > Language & Region",
        image: "Language"
    ),
    .init(
        title: "Set the Primary Language",
        description: "It doesn't matter what you set it to.\n\nAfterwards set it back to your native language.",
        image: "SetPrimary"
    ),
    .init(
        title: "Verify That It Worked",
        description: "Everything on PosterBoard should refresh. Check the Collections to see if they reset.",
        image: "OriginalCollection"
    )
]
