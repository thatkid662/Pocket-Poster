//
//  OnBoardingView.swift
//  Pocket Poster
//
//  Created by lemin on 5/31/25.
//

import SwiftUI

struct OnBoardingView: View {
    @State var currentIndex: Int = 0
    
    var body: some View {
        VStack {
            OnBoardingCardView(info: onBoardingCards[currentIndex], pageCount: onBoardingCards.count, idx: $currentIndex)
        }
    }
}
