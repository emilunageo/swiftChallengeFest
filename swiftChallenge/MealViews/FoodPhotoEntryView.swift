//
//  FoodPhotoEntryView.swift
//  swiftChallenge
//
//  Created by Victoria Marin on 07/06/25.
//

import SwiftUI
import Vision
import UIKit
import AVFoundation
import CoreML

// MARK: - Food Photo Entry View (CoreML)
struct FoodPhotoEntryView: View {
    @State private var foodEntry = FoodEntry()
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var predictedFood = ""
    @State private var confidence: Double = 0.0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.lightGray, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Camera Section
                    cameraSection
                    
                    // Meal Type Selection
                    mealTypeCard
                    
                    // Predicted Food Display
                    if !predictedFood.isEmpty {
                        predictedFoodCard
                    }
                    
                    // Manual adjustment if needed
                    foodItemsCard
                    
                    // Save Button
                    saveButton
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .navigationTitle("Food Photo")
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showingCamera) {
            CameraView(onImageCaptured: { image in
                selectedImage = image
                predictFood(from: image)
            })
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .alert("", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                predictFood(from: image)
            }
        }
    }
    
    private var cameraSection: some View {
        VStack(spacing: 20) {
            if let selectedImage = selectedImage {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 12) {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(16)
                        
                        if isProcessing {
                            AppleLoadingView()
                                .padding(.bottom, 8)
                        }
                    }
                    .padding(16)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.appleGreen.opacity(0.1), Color.green.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.appleGreen.opacity(0.3), Color.green.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .frame(height: 220)
                    
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.appleGreen.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 32))
                                .foregroundColor(.appleGreen)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Capture food photo")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("AI will identify the food automatically")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            
            HStack(spacing: 16) {
                Button(action: { showingCamera = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Camera")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.appleGreen, Color.green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.appleGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Button(action: { showingImagePicker = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Gallery")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
    
    private var predictedFoodCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("AI Prediction")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.title3)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detected Food:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(predictedFood)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Confidence: \(String(format: "%.1f", confidence))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Use This") {
                    foodEntry.items = [FoodItem(name: predictedFood)]
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.purple.opacity(0.1))
                .foregroundColor(.purple)
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // Include similar meal type and food items cards as manual entry
    private var mealTypeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.appleGreen)
                    .font(.title2)
                
                Text("Meal Type")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    Button(action: { foodEntry.mealType = meal }) {
                        HStack(spacing: 12) {
                            Image(systemName: meal.icon)
                                .font(.title2)
                                .foregroundColor(foodEntry.mealType == meal ? .white : meal.color)
                            
                            Text(meal.rawValue)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(foodEntry.mealType == meal ? .white : .primary)
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    foodEntry.mealType == meal ?
                                    LinearGradient(colors: [meal.color, meal.color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color.cardBackground, Color.cardBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var foodItemsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Food Items")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: addFoodItem) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.appleGreen)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(Array(foodEntry.items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "leaf.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 18))
                            )
                        
                        TextField("e.g., Avocado toast, Coffee", text: Binding(
                            get: { foodEntry.items[index].name },
                            set: { foodEntry.items[index].name = $0 }
                        ))
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.lightGray.opacity(0.5))
                        )
                        
                        if foodEntry.items.count > 1 {
                            Button(action: { removeFoodItem(at: index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var saveButton: some View {
        Button(action: saveFoodEntry) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Save Meal")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color.appleGreen, Color.green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.appleGreen.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(foodEntry.items.allSatisfy { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ? 0.95 : 1.0)
            .opacity(foodEntry.items.allSatisfy { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: foodEntry.items.map { $0.name })
        }
        .disabled(foodEntry.items.allSatisfy { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
    }
    
    private func addFoodItem() {
        withAnimation(.spring()) {
            foodEntry.items.append(FoodItem())
        }
    }
    
    private func removeFoodItem(at index: Int) {
        withAnimation(.spring()) {
            foodEntry.items.remove(at: index)
        }
    }
    
    private func predictFood(from image: UIImage) {
        isProcessing = true
        
        // Using your SeeFood model
        let model = SeeFood()
        
        guard let resizedBuffer = pixelBuffer(from: image, size: CGSize(width: 299, height: 299)) else {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.alertMessage = "Failed to process image"
                self.showingAlert = true
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try model.prediction(image: resizedBuffer)
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.predictedFood = result.classLabel
                    self.confidence = result.foodConfidence[result.classLabel]! * 100.0
                    
                    self.alertMessage = "🤖 AI detected: \(result.classLabel) with \(String(format: "%.1f", self.confidence))% confidence!"
                    self.showingAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.alertMessage = "Prediction failed: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        else {
            return nil
        }
        
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
    
    private func saveFoodEntry() {
        let validItems = foodEntry.items.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        if validItems.isEmpty {
            alertMessage = "Please add at least one food item before saving."
            showingAlert = true
            return
        }
        
        alertMessage = "🎉 Meal saved successfully!\n\n📋 Type: \(foodEntry.mealType.rawValue)\n🍽️ Items: \(validItems.map { $0.name }.joined(separator: ", "))"
        showingAlert = true
    }
}
