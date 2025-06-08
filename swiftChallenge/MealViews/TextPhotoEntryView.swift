//
//  TextPhotoEntryView.swift
//  swiftChallenge
//
//  Created by Victoria Marin on 07/06/25.
//

import SwiftUI
import Vision
import UIKit
import AVFoundation
import CoreML

// MARK: - Text Photo Entry View (OCR)
struct TextPhotoEntryView: View {
    @State private var foodEntry = FoodEntry()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var extractedText = ""
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
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
                    // Image Capture Card
                    imageCaptureCard
                    
                    // Meal Type Selection Card
                    mealTypeCard
                    
                    // Food Items Card
                    foodItemsCard
                    
                    // Save Button
                    saveButton
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .navigationTitle("Text Scanner")
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
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
                processImage(image)
            }
        }
    }
    
    // Same implementation as the original OCR view
    private var imageCaptureCard: some View {
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
                            AppleOCRLoadingView()
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
                                colors: [Color.orange.opacity(0.1), Color.red.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
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
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Scan menu text")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Extract text from menus or food lists")
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
    
    // Include similar implementations for meal type card, food items card, and save button
    // (Same as previous implementations)
    
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
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    self.alertMessage = "Error processing image: \(error.localizedDescription)"
                    self.showingAlert = true
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.alertMessage = "No text found in the image"
                    self.showingAlert = true
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                self.extractedText = recognizedText
                
                if recognizedText.isEmpty {
                    self.alertMessage = "No text detected in the image"
                    self.showingAlert = true
                } else {
                    self.mapExtractedTextToFields()
                    
                    let foodKeywords = self.extractFoodKeywords(from: recognizedText)
                    if !foodKeywords.isEmpty {
                        self.alertMessage = "✅ Perfect! Found \(foodKeywords.count) food items and auto-filled them for you."
                    } else {
                        self.alertMessage = "✅ Text extracted but no food items detected. You can manually add them below."
                    }
                    self.showingAlert = true
                }
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["es", "en"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.alertMessage = "Error processing image: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func mapExtractedTextToFields() {
        let foodKeywords = extractFoodKeywords(from: extractedText)
        
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                if !foodKeywords.isEmpty {
                    self.foodEntry.items = foodKeywords.map { FoodItem(name: $0) }
                    if self.foodEntry.items.isEmpty {
                        self.foodEntry.items = [FoodItem()]
                    }
                }
            }
        }
    }
    
    private func extractFoodKeywords(from text: String) -> [String] {
        let commonFoodWords = [
            "pancakes", "huevos", "eggs", "pan", "bread", "leche", "milk", "café", "coffee",
            "fruta", "fruit", "manzana", "apple", "plátano", "banana", "arroz", "rice",
            "pollo", "chicken", "carne", "meat", "pescado", "fish", "ensalada", "salad",
            "sopa", "soup", "pasta", "pizza", "hamburguesa", "burger", "sandwich",
            "yogurt", "cereal", "avena", "oatmeal", "tostada", "toast", "jugo", "juice",
            "aguacate", "avocado", "tomate", "tomato", "lechuga", "lettuce"
        ]
        
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
        
        let foundFoods = words.filter { word in
            commonFoodWords.contains { $0.contains(word) || word.contains($0) }
        }
        
        return Array(Set(foundFoods)).prefix(5).map { $0.capitalized }
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
