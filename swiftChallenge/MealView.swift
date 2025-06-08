//
//  MealView.swift
//  swiftChallenge
//
//  Created by Fatima Alonso on 6/7/25.
//

import SwiftUI
import Vision
import UIKit
import AVFoundation
import CoreML

// MARK: - Color Extensions
extension Color {
    static let appleGreen = Color(red: 0.2, green: 0.8, blue: 0.2)
    static let lightGray = Color(red: 0.97, green: 0.97, blue: 0.97)
    static let cardBackground = Color.white
    static let warmRed = Color(red: 221/255, green: 104/255, blue: 90/255)
}

// MARK: - Main Navigation View
struct MealView: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {

        Text("Meal")

        NavigationStack(path: $navigationPath) {
            EntryMethodSelectionView(navigationPath: $navigationPath)
                .navigationDestination(for: EntryMethod.self) { method in
                    switch method {
                    case .manual:
                        ManualEntryView()
                    case .foodPhoto:
                        FoodPhotoEntryView()
                    case .textPhoto:
                        TextPhotoEntryView()
                    }
                }
        }

    }
}
