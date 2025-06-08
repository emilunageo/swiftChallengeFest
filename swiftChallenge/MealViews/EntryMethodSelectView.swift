//
//  EntryMethodSelectView.swift
//  swiftChallenge
//
//  Created by Victoria Marin on 07/06/25.
//

import SwiftUI
import Vision
import UIKit
import AVFoundation
import CoreML

struct EntryMethodSelectionView: View {
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.lightGray, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // Entry Options
                    entryOptionsSection
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Food Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Choose how to log your meal")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appleGreen, Color.green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    private var entryOptionsSection: some View {
        VStack(spacing: 20) {
            // Manual Entry
            EntryOptionCard(
                title: "Manual Entry",
                subtitle: "Type your food items manually",
                icon: "pencil.and.list.clipboard",
                gradientColors: [Color.blue, Color.blue.opacity(0.7)],
                action: { navigationPath.append(EntryMethod.manual) }
            )
            
            // Food Photo
            EntryOptionCard(
                title: "Food Photo",
                subtitle: "AI identifies food from photos",
                icon: "camera.viewfinder",
                gradientColors: [Color.appleGreen, Color.green],
                action: { navigationPath.append(EntryMethod.foodPhoto) }
            )
            
            // Text Photo
            EntryOptionCard(
                title: "Text Scanner",
                subtitle: "Extract text from menu photos",
                icon: "doc.text.viewfinder",
                gradientColors: [Color.orange, Color.red],
                action: { navigationPath.append(EntryMethod.textPhoto) }
            )
        }
    }
}
