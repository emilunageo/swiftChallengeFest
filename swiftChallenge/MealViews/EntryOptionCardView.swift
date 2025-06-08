//
//  EntryOptionCardView.swift
//  swiftChallenge
//
//  Created by Victoria Marin on 07/06/25.
//


import SwiftUI
import Vision
import UIKit
import AVFoundation
import CoreML

// MARK: - Entry Option Card
struct EntryOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
