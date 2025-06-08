////
////  Animation.swift
////  swiftChallenge
////
////  Created by Victoria Marin on 07/06/25.
////
//
import SwiftUI
import Vision
import UIKit
import AVFoundation
import CoreML
//
//
//// MARK: - Loading Animation Views
//struct AppleLoadingView: View {
//    @State private var rotationAngle: Double = 0
//    @State private var scale: CGFloat = 1.0
//    
//    var body: some View {
//        HStack(spacing: 8) {
//            Image("apple")
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(width: 20, height: 20)
//                .rotationEffect(.degrees(rotationAngle))
//                .scaleEffect(scale)
//                .onAppear {
//                    withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
//                        rotationAngle = 360
//                    }
//                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
//                        scale = 1.2
//                    }
//                }
//            
//            Text("Analyzing food...")
//                .font(.subheadline)
//                .foregroundColor(.appleGreen)
//        }
//    }
//}

struct AppleOCRLoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 8) {
            Image("apple")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(rotationAngle))
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        scale = 1.2
                    }
                }
            
            Text("Analyzing image...")
                .font(.subheadline)
                .foregroundColor(.appleGreen)
        }
    }
}
