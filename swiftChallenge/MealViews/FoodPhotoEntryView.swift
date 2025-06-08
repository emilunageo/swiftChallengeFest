////
////  FoodPhotoEntryView.swift
////  swiftChallenge
////
////  Created by Victoria Marin on 07/06/25.
////
//
//import SwiftUI
//import Vision
//import UIKit
//import AVFoundation
//import CoreML
//import HealthKit
//
//// MARK: - HealthKit Manager for Glucose Data
//class HealthKitManager: ObservableObject {
//    private let healthStore = HKHealthStore()
//    @Published var recentGlucoseReading: Double?
//    @Published var averageGlucose: Double?
//    
//    func requestHealthKitPermissions() {
//        guard HKHealthStore.isHealthDataAvailable() else { return }
//        
//        let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
//        let readTypes: Set<HKObjectType> = [glucoseType]
//        
//        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
//            if success {
//                self.fetchRecentGlucoseData()
//            }
//        }
//    }
//    
//    private func fetchRecentGlucoseData() {
//        let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
//        let query = HKSampleQuery(sampleType: glucoseType, predicate: nil, limit: 10, sortDescriptors: [sortDescriptor]) { _, samples, _ in
//            
//            DispatchQueue.main.async {
//                if let glucoseSamples = samples as? [HKQuantitySample], !glucoseSamples.isEmpty {
//                    // Most recent reading
//                    let recentValue = glucoseSamples.first!.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
//                    self.recentGlucoseReading = recentValue
//                    
//                    // Average of recent readings
//                    let values = glucoseSamples.map { $0.quantity.doubleValue(for: HKUnit(from: "mg/dL")) }
//                    self.averageGlucose = values.reduce(0, +) / Double(values.count)
//                }
//            }
//        }
//        
//        healthStore.execute(query)
//    }
//}
//
//// MARK: - Glucose Estimation Model
//struct GlucoseEstimation {
//    let estimatedIncrease: Double
//    let estimatedPeak: Double
//    let riskLevel: GlucoseRiskLevel
//    let timeToPeak: String
//    let recommendations: [String]
//}
//
//enum GlucoseRiskLevel {
//    case low, moderate, high
//    
//    var color: Color {
//        switch self {
//        case .low: return .green
//        case .moderate: return .orange
//        case .high: return .red
//        }
//    }
//    
//    var icon: String {
//        switch self {
//        case .low: return "checkmark.circle.fill"
//        case .moderate: return "exclamationmark.triangle.fill"
//        case .high: return "xmark.octagon.fill"
//        }
//    }
//    
//    var title: String {
//        switch self {
//        case .low: return "Low Impact"
//        case .moderate: return "Moderate Impact"
//        case .high: return "High Impact"
//        }
//    }
//}
//
//extension GlucoseEstimation {
//    static func estimate(for foodItems: [String], baselineGlucose: Double = 100) -> GlucoseEstimation {
//        let foodText = foodItems.joined(separator: " ").lowercased()
//        
//        // Simplified carb estimation based on common foods
//        var carbEstimate = 0.0
//        var glycemicLoad = 0.0
//        
//        // High carb foods
//        if foodText.contains("rice") { carbEstimate += 45; glycemicLoad += 40 }
//        if foodText.contains("bread") { carbEstimate += 25; glycemicLoad += 15 }
//        if foodText.contains("pasta") { carbEstimate += 40; glycemicLoad += 18 }
//        if foodText.contains("potato") { carbEstimate += 35; glycemicLoad += 22 }
//        if foodText.contains("pizza") { carbEstimate += 50; glycemicLoad += 25 }
//        if foodText.contains("bagel") { carbEstimate += 55; glycemicLoad += 30 }
//        if foodText.contains("cereal") { carbEstimate += 30; glycemicLoad += 20 }
//        if foodText.contains("oats") { carbEstimate += 25; glycemicLoad += 12 }
//        if foodText.contains("banana") { carbEstimate += 25; glycemicLoad += 15 }
//        if foodText.contains("apple") { carbEstimate += 20; glycemicLoad += 8 }
//        if foodText.contains("orange") { carbEstimate += 15; glycemicLoad += 7 }
//        
//        // Processed/sugary foods
//        if foodText.contains("soda") { carbEstimate += 40; glycemicLoad += 35 }
//        if foodText.contains("candy") { carbEstimate += 30; glycemicLoad += 28 }
//        if foodText.contains("cake") { carbEstimate += 45; glycemicLoad += 32 }
//        if foodText.contains("cookie") { carbEstimate += 20; glycemicLoad += 15 }
//        
//        // Protein foods (minimal impact)
//        if foodText.contains("chicken") || foodText.contains("fish") || foodText.contains("meat") || foodText.contains("beef") {
//            carbEstimate += 0; glycemicLoad += 0
//        }
//        
//        // Calculate estimated glucose impact
//        // Rule of 500: 1g carb raises glucose by ~4-5 mg/dL for average person
//        let estimatedIncrease = carbEstimate * 2
//        let estimatedPeak = baselineGlucose + estimatedIncrease
//        
//        // Determine risk level
//        let riskLevel: GlucoseRiskLevel
//        if estimatedIncrease <= 2.5 {
//            riskLevel = .low
//        } else if estimatedIncrease <= 3 {
//            riskLevel = .moderate
//        } else {
//            riskLevel = .high
//        }
//        
//        // Time to peak (simplified)
//        let timeToPeak = carbEstimate > 30 ? "60-90 min" : "30-60 min"
//        
//        // Generate recommendations
//        var recommendations: [String] = []
//        if riskLevel == .high {
//            recommendations.append("Consider taking a walk after eating")
//            recommendations.append("Drink water to help with glucose clearance")
//        }
//        if riskLevel != .low {
//            recommendations.append("Monitor glucose levels after eating")
//        }
//        if carbEstimate > 40 {
//            recommendations.append("Consider pairing with protein or fiber")
//        }
//        
//        return GlucoseEstimation(
//            estimatedIncrease: estimatedIncrease,
//            estimatedPeak: estimatedPeak,
//            riskLevel: riskLevel,
//            timeToPeak: timeToPeak,
//            recommendations: recommendations
//        )
//    }
//}
//
//// MARK: - Eating Recommendations Model
//struct EatingRecommendation {
//    let title: String
//    let description: String
//    let icon: String
//    let color: Color
//}
//
//struct MealRecommendations {
//    let eatingOrder: [String]
//    let generalTips: [EatingRecommendation]
//    
//    static func generateRecommendations(for foodItems: [String]) -> MealRecommendations {
//        let eatingOrder = generateEatingOrder(for: foodItems)
//        let generalTips = generateGeneralTips(for: foodItems)
//        return MealRecommendations(eatingOrder: eatingOrder, generalTips: generalTips)
//    }
//    
//    private static func generateEatingOrder(for items: [String]) -> [String] {
//        var order: [String] = []
//        let itemsLower = items.map { $0.lowercased() }
//        
//        // Vegetables and fiber first
//        let vegetables = itemsLower.filter { item in
//            ["salad", "vegetables", "greens", "broccoli", "spinach", "kale", "lettuce", "cucumber", "tomato", "carrot", "pepper"].contains { item.contains($0) }
//        }
//        
//        // Proteins second
//        let proteins = itemsLower.filter { item in
//            ["chicken", "fish", "meat", "beef", "pork", "egg", "tofu", "beans", "lentils", "quinoa", "salmon", "tuna"].contains { item.contains($0) }
//        }
//        
//        // Carbs last
//        let carbs = itemsLower.filter { item in
//            ["rice", "bread", "pasta", "potato", "noodles", "toast", "bagel", "cereal", "oats"].contains { item.contains($0) }
//        }
//        
//        if !vegetables.isEmpty {
//            order.append("🥬 Start with vegetables/fiber (helps with satiety)")
//        }
//        if !proteins.isEmpty {
//            order.append("🍗 Eat your proteins (promotes fullness)")
//        }
//        if !carbs.isEmpty {
//            order.append("🍚 Finish with carbohydrates (better blood sugar control)")
//        }
//        
//        if order.isEmpty {
//            order = ["🍽️ Eat mindfully, chewing each bite thoroughly"]
//        }
//        
//        return order
//    }
//    
//    private static func generateGeneralTips(for items: [String]) -> [EatingRecommendation] {
//        var tips: [EatingRecommendation] = []
//        let itemsText = items.joined(separator: " ").lowercased()
//        
//        // Base recommendations everyone gets
//        tips.append(EatingRecommendation(
//            title: "Chew Mindfully",
//            description: "Chew each bite 20-30 times to aid digestion and increase satiety",
//            icon: "mouth",
//            color: .blue
//        ))
//        
//        tips.append(EatingRecommendation(
//            title: "Eat Slowly",
//            description: "Take 15-20 minutes to finish your meal to allow fullness signals",
//            icon: "clock",
//            color: .green
//        ))
//        
//        // Conditional recommendations based on food content
//        let hasVeggies = ["salad", "vegetables", "greens", "broccoli", "spinach", "kale"].contains { itemsText.contains($0) }
//        let hasProcessed = ["pizza", "hamburger", "fries", "chips", "soda", "candy"].contains { itemsText.contains($0) }
//        let hasCarbs = ["rice", "bread", "pasta", "potato"].contains { itemsText.contains($0) }
//        
//        if !hasVeggies {
//            tips.append(EatingRecommendation(
//                title: "Add More Greens",
//                description: "Consider adding leafy greens or vegetables to boost nutrition",
//                icon: "leaf.fill",
//                color: .green
//            ))
//        }
//        
//        if hasProcessed {
//            tips.append(EatingRecommendation(
//                title: "Balance Your Plate",
//                description: "Try to include whole foods and reduce processed items next time",
//                icon: "scale.3d",
//                color: .orange
//            ))
//        }
//        
//        if hasCarbs {
//            tips.append(EatingRecommendation(
//                title: "Portion Control",
//                description: "Keep carb portions to about 1/4 of your plate",
//                icon: "hand.raised.fill",
//                color: .purple
//            ))
//        }
//        
//        tips.append(EatingRecommendation(
//            title: "Stay Hydrated",
//            description: "Drink water before and after eating, but limit during meals",
//            icon: "drop.fill",
//            color: .cyan
//        ))
//        
//        return Array(tips.prefix(4)) // Limit to 4 tips to avoid overwhelming
//    }
//}
//
//// MARK: - Recommendations Bottom Sheet
//struct RecommendationsBottomSheet: View {
//    let recommendations: MealRecommendations
//    let mealType: String
//    let foodItems: [String]
//    @Binding var isPresented: Bool
//    let onDismiss: () -> Void
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                Color(.systemGroupedBackground)
//                    .ignoresSafeArea()
//                
//                ScrollView {
//                    VStack(spacing: 24) {
//                        // Header
//                        VStack(spacing: 12) {
//                            ZStack {
//                                Circle()
//                                    .fill(Color.green.opacity(0.2))
//                                    .frame(width: 80, height: 80)
//                                
//                                Image(systemName: "brain.head.profile")
//                                    .font(.system(size: 32))
//                                    .foregroundColor(.green)
//                            }
//                            
//                            Text("Smart Eating Tips")
//                                .font(.title2)
//                                .fontWeight(.bold)
//                            
//                            Text("Personalized recommendations for your \(mealType.lowercased())")
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                                .multilineTextAlignment(.center)
//                        }
//                        .padding(.top, 20)
//                        
//                        // Eating Order Section
//                        if !recommendations.eatingOrder.isEmpty {
//                            VStack(alignment: .leading, spacing: 16) {
//                                HStack {
//                                    Image(systemName: "list.number")
//                                        .foregroundColor(.blue)
//                                        .font(.title2)
//                                    
//                                    Text("Recommended Eating Order")
//                                        .font(.headline)
//                                        .fontWeight(.semibold)
//                                }
//                                
//                                VStack(spacing: 12) {
//                                    ForEach(Array(recommendations.eatingOrder.enumerated()), id: \.offset) { index, order in
//                                        HStack(spacing: 12) {
//                                            ZStack {
//                                                Circle()
//                                                    .fill(Color.blue.opacity(0.2))
//                                                    .frame(width: 32, height: 32)
//                                                
//                                                Text("\(index + 1)")
//                                                    .font(.system(size: 14, weight: .bold))
//                                                    .foregroundColor(.blue)
//                                            }
//                                            
//                                            Text(order)
//                                                .font(.system(size: 15))
//                                                .foregroundColor(.primary)
//                                            
//                                            Spacer()
//                                        }
//                                        .padding(.vertical, 8)
//                                        .padding(.horizontal, 16)
//                                        .background(
//                                            RoundedRectangle(cornerRadius: 12)
//                                                .fill(Color(.systemBackground))
//                                        )
//                                    }
//                                }
//                            }
//                            .padding(20)
//                            .background(
//                                RoundedRectangle(cornerRadius: 16)
//                                    .fill(Color(.systemBackground))
//                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
//                            )
//                        }
//                        
//                        // General Tips Section
//                        VStack(alignment: .leading, spacing: 16) {
//                            HStack {
//                                Image(systemName: "lightbulb.fill")
//                                    .foregroundColor(.orange)
//                                    .font(.title2)
//                                
//                                Text("Health Tips")
//                                    .font(.headline)
//                                    .fontWeight(.semibold)
//                            }
//                            
//                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
//                                ForEach(Array(recommendations.generalTips.enumerated()), id: \.offset) { _, tip in
//                                    VStack(alignment: .leading, spacing: 12) {
//                                        HStack {
//                                            Image(systemName: tip.icon)
//                                                .foregroundColor(tip.color)
//                                                .font(.title3)
//                                            
//                                            Text(tip.title)
//                                                .font(.system(size: 14, weight: .semibold))
//                                                .foregroundColor(.primary)
//                                            
//                                            Spacer()
//                                        }
//                                        
//                                        Text(tip.description)
//                                            .font(.system(size: 12))
//                                            .foregroundColor(.secondary)
//                                            .lineLimit(3)
//                                            .multilineTextAlignment(.leading)
//                                    }
//                                    .padding(16)
//                                    .background(
//                                        RoundedRectangle(cornerRadius: 12)
//                                            .fill(tip.color.opacity(0.1))
//                                    )
//                                }
//                            }
//                        }
//                        .padding(20)
//                        .background(
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(Color(.systemBackground))
//                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
//                        )
//                        
//                        // Action Button
//                        Button(action: {
//                            onDismiss()
//                        }) {
//                            HStack(spacing: 12) {
//                                Image(systemName: "checkmark.circle.fill")
//                                    .font(.system(size: 18))
//                                
//                                Text("Got It!")
//                                    .fontWeight(.semibold)
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding(.vertical, 16)
//                            .background(
//                                LinearGradient(
//                                    colors: [Color.green, Color.blue],
//                                    startPoint: .leading,
//                                    endPoint: .trailing
//                                )
//                            )
//                            .foregroundColor(.white)
//                            .cornerRadius(16)
//                            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
//                        }
//                        
//                        Spacer(minLength: 20)
//                    }
//                    .padding(.horizontal, 20)
//                }
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationTitle("")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        onDismiss()
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Food Photo Entry View (CoreML)
//struct FoodPhotoEntryView: View {
//    @State private var foodEntry = FoodEntry()
//    @State private var showingCamera = false
//    @State private var showingImagePicker = false
//    @State private var selectedImage: UIImage?
//    @State private var isProcessing = false
//    @State private var showingAlert = false
//    @State private var alertMessage = ""
//    @State private var predictedFood = ""
//    @State private var confidence: Double = 0.0
//    @State private var showingRecommendations = false
//    @StateObject private var healthKitManager = HealthKitManager()
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        ZStack {
//            LinearGradient(
//                colors: [Color.lightGray, Color.white],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .ignoresSafeArea()
//            
//            ScrollView {
//                VStack(spacing: 24) {
//                    // Camera Section
//                    cameraSection
//                    
//                    // Meal Type Selection
//                    mealTypeCard
//                    
//                    // Predicted Food Display
//                    if !predictedFood.isEmpty {
//                        predictedFoodCard
//                    }
//                    
//                    // Manual adjustment if needed
//                    foodItemsCard
//                    
//                    // Glucose Estimation
//                    if !foodEntry.items.allSatisfy { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } {
//                        glucoseEstimationCard
//                    }
//                    
//                    // Save Button
//                    saveButton
//                    
//                    Spacer(minLength: 20)
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 10)
//            }
//        }
//        .navigationTitle("Food Photo")
//        .navigationBarBackButtonHidden(false)
//        .sheet(isPresented: $showingCamera) {
//            CameraView(onImageCaptured: { image in
//                selectedImage = image
//                predictFood(from: image)
//            })
//        }
//        .sheet(isPresented: $showingImagePicker) {
//            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
//        }
//        .sheet(isPresented: $showingRecommendations) {
//            RecommendationsBottomSheet(
//                recommendations: MealRecommendations.generateRecommendations(
//                    for: foodEntry.items.compactMap { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0.name }
//                ),
//                mealType: foodEntry.mealType.rawValue,
//                foodItems: foodEntry.items.compactMap { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0.name },
//                isPresented: $showingRecommendations
//            ) {
//                showingRecommendations = false
//                dismiss()
//            }
//        }
//        .alert("", isPresented: $showingAlert) {
//            Button("OK") {
//                if alertMessage.contains("successfully") {
//                    // Don't dismiss here, let the recommendations sheet handle it
//                }
//            }
//        } message: {
//            Text(alertMessage)
//        }
//        .onChange(of: selectedImage) { image in
//            if let image = image {
//                predictFood(from: image)
//            }
//        }
//        .onAppear {
//            healthKitManager.requestHealthKitPermissions()
//        }
//    }
//    
//    private var cameraSection: some View {
//        VStack(spacing: 20) {
//            if let selectedImage = selectedImage {
//                ZStack {
//                    RoundedRectangle(cornerRadius: 20)
//                        .fill(Color.cardBackground)
//                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
//                    
//                    VStack(spacing: 12) {
//                        Image(uiImage: selectedImage)
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .frame(height: 200)
//                            .clipped()
//                            .cornerRadius(16)
//                        
//                        if isProcessing {
//                            AppleLoadingView()
//                                .padding(.bottom, 8)
//                        }
//                    }
//                    .padding(16)
//                }
//            } else {
//                ZStack {
//                    RoundedRectangle(cornerRadius: 20)
//                        .fill(
//                            LinearGradient(
//                                colors: [Color.appleGreen.opacity(0.1), Color.green.opacity(0.05)],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 20)
//                                .stroke(
//                                    LinearGradient(
//                                        colors: [Color.appleGreen.opacity(0.3), Color.green.opacity(0.2)],
//                                        startPoint: .topLeading,
//                                        endPoint: .bottomTrailing
//                                    ),
//                                    lineWidth: 2
//                                )
//                        )
//                        .frame(height: 220)
//                    
//                    VStack(spacing: 16) {
//                        ZStack {
//                            Circle()
//                                .fill(Color.appleGreen.opacity(0.2))
//                                .frame(width: 80, height: 80)
//                            
//                            Image(systemName: "camera.viewfinder")
//                                .font(.system(size: 32))
//                                .foregroundColor(.appleGreen)
//                        }
//                        
//                        VStack(spacing: 4) {
//                            Text("Capture food photo")
//                                .font(.headline)
//                                .fontWeight(.semibold)
//                                .foregroundColor(.primary)
//                            
//                            Text("AI will identify the food automatically")
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                                .multilineTextAlignment(.center)
//                        }
//                    }
//                }
//            }
//            
//            HStack(spacing: 16) {
//                Button(action: { showingCamera = true }) {
//                    HStack(spacing: 8) {
//                        Image(systemName: "camera")
//                            .font(.system(size: 18, weight: .semibold))
//                        Text("Camera")
//                            .fontWeight(.semibold)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 16)
//                    .background(
//                        LinearGradient(
//                            colors: [Color.appleGreen, Color.green],
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                    )
//                    .foregroundColor(.white)
//                    .cornerRadius(16)
//                    .shadow(color: Color.appleGreen.opacity(0.3), radius: 8, x: 0, y: 4)
//                }
//                
//                Button(action: { showingImagePicker = true }) {
//                    HStack(spacing: 8) {
//                        Image(systemName: "photo")
//                            .font(.system(size: 18, weight: .semibold))
//                        Text("Gallery")
//                            .fontWeight(.semibold)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 16)
//                    .background(
//                        LinearGradient(
//                            colors: [Color.orange, Color.red],
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                    )
//                    .foregroundColor(.white)
//                    .cornerRadius(16)
//                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
//                }
//            }
//        }
//    }
//    
//    private var predictedFoodCard: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            HStack {
//                Image(systemName: "brain.head.profile")
//                    .foregroundColor(.purple)
//                    .font(.title2)
//                
//                Text("AI Prediction")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
//            }
//            
//            HStack(spacing: 12) {
//                Circle()
//                    .fill(Color.purple.opacity(0.2))
//                    .frame(width: 50, height: 50)
//                    .overlay(
//                        Image(systemName: "sparkles")
//                            .foregroundColor(.purple)
//                            .font(.title3)
//                    )
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Detected Food:")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    Text(predictedFood)
//                        .font(.headline)
//                        .fontWeight(.semibold)
//                        .foregroundColor(.primary)
//                    
//                    Text("Confidence: \(String(format: "%.1f", confidence))%")
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                }
//                
//                Spacer()
//                
//                Button("Use This") {
//                    foodEntry.items = [FoodItem(name: predictedFood)]
//                }
//                .padding(.horizontal, 16)
//                .padding(.vertical, 8)
//                .background(Color.purple.opacity(0.1))
//                .foregroundColor(.purple)
//                .cornerRadius(8)
//            }
//        }
//        .padding(20)
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.cardBackground)
//                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
//        )
//    }
//    
//    // Include similar meal type and food items cards as manual entry
//    private var mealTypeCard: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            HStack {
//                Image(systemName: "clock.fill")
//                    .foregroundColor(.appleGreen)
//                    .font(.title2)
//                
//                Text("Meal Type")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
//            }
//            
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
//                ForEach(MealType.allCases, id: \.self) { meal in
//                    Button(action: { foodEntry.mealType = meal }) {
//                        HStack(spacing: 12) {
//                            Image(systemName: meal.icon)
//                                .font(.title2)
//                                .foregroundColor(foodEntry.mealType == meal ? .white : meal.color)
//                            
//                            Text(meal.rawValue)
//                                .font(.system(size: 16, weight: .semibold))
//                                .foregroundColor(foodEntry.mealType == meal ? .white : .primary)
//                            
//                            Spacer()
//                        }
//                        .padding(16)
//                        .background(
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(
//                                    foodEntry.mealType == meal ?
//                                    LinearGradient(colors: [meal.color, meal.color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
//                                        LinearGradient(colors: [Color.cardBackground, Color.cardBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
//                                )
//                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
//                        )
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//            }
//        }
//        .padding(20)
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.cardBackground)
//                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
//        )
//    }
//    
//    
//    private var foodItemsCard: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            HStack {
//                Image(systemName: "fork.knife")
//                    .foregroundColor(.orange)
//                    .font(.title2)
//                
//                Text("Food Items")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
//                
//                Spacer()
//                
//                Button(action: addFoodItem) {
//                    HStack(spacing: 6) {
//                        Image(systemName: "plus.circle.fill")
//                            .font(.title3)
//                        Text("Add")
//                            .fontWeight(.semibold)
//                    }
//                    .foregroundColor(.appleGreen)
//                }
//            }
//            
//            VStack(spacing: 12) {
//                ForEach(Array(foodEntry.items.enumerated()), id: \.element.id) { index, item in
//                    HStack(spacing: 12) {
//                        Circle()
//                            .fill(Color.orange.opacity(0.2))
//                            .frame(width: 40, height: 40)
//                            .overlay(
//                                Image(systemName: "leaf.fill")
//                                    .foregroundColor(.orange)
//                                    .font(.system(size: 18))
//                            )
//                        
//                        TextField("e.g., Avocado toast, Coffee", text: Binding(
//                            get: { foodEntry.items[index].name },
//                            set: { foodEntry.items[index].name = $0 }
//                        ))
//                        .font(.system(size: 16))
//                        .padding(.horizontal, 16)
//                        .padding(.vertical, 12)
//                        .background(
//                            RoundedRectangle(cornerRadius: 12)
//                                .fill(Color.lightGray.opacity(0.5))
//                        )
//                        .onSubmit {
//                            // Dismiss keyboard when user taps return
//                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                        }
//                        
//                        if foodEntry.items.count > 1 {
//                            Button(action: { removeFoodItem(at: index) }) {
//                                Image(systemName: "minus.circle.fill")
//                                    .foregroundColor(.red)
//                                    .font(.title2)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        .padding(20)
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.cardBackground)
//                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
//        )
//    }
//    
//    private var saveButton: some View {
//        Button(action: saveFoodEntry) {
//            HStack(spacing: 12) {
//                Image(systemName: "checkmark.seal.fill")
//                    .font(.system(size: 18, weight: .semibold))
//                
//                Text("Save Meal")
//                    .fontWeight(.bold)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 18)
//            .background(
//                LinearGradient(
//                    colors: [Color.appleGreen, Color.green],
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//            )
//            .foregroundColor(.white)
//            .cornerRadius(16)
//            .shadow(color: Color.appleGreen.opacity(0.4), radius: 12, x: 0, y: 6)
//            .scaleEffect(foodEntry.items.allSatisfy { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ? 0.95 : 1.0)
//            .opacity(foodEntry.items.allSatisfy { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ? 0.6 : 1.0)
//            .animation(.easeInOut(duration: 0.2), value: foodEntry.items.map { $0.name })
//        }
//        .disabled(foodEntry.items.allSatisfy { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
//    }
//    
//    private func addFoodItem() {
//        withAnimation(.spring()) {
//            foodEntry.items.append(FoodItem())
//        }
//    }
//    
//    private func removeFoodItem(at index: Int) {
//        withAnimation(.spring()) {
//            foodEntry.items.remove(at: index)
//        }
//    }
//    
//    private func predictFood(from image: UIImage) {
//        isProcessing = true
//        
//        // Using your SeeFood model
//        let model = SeeFood()
//        
//        guard let resizedBuffer = pixelBuffer(from: image, size: CGSize(width: 299, height: 299)) else {
//            DispatchQueue.main.async {
//                self.isProcessing = false
//                self.alertMessage = "Failed to process image"
//                self.showingAlert = true
//            }
//            return
//        }
//        
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                let result = try model.prediction(image: resizedBuffer)
//                
//                DispatchQueue.main.async {
//                    self.isProcessing = false
//                    self.predictedFood = result.classLabel
//                    self.confidence = result.foodConfidence[result.classLabel]! * 100.0
//                    
//                    self.alertMessage = "🤖 AI detected: \(result.classLabel) with \(String(format: "%.1f", self.confidence))% confidence!"
//                    self.showingAlert = true
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.isProcessing = false
//                    self.alertMessage = "Prediction failed: \(error.localizedDescription)"
//                    self.showingAlert = true
//                }
//            }
//        }
//    }
//    
//    private func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
//        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
//             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
//        
//        var pixelBuffer: CVPixelBuffer?
//        let status = CVPixelBufferCreate(kCFAllocatorDefault,
//                                         Int(size.width),
//                                         Int(size.height),
//                                         kCVPixelFormatType_32ARGB,
//                                         attrs,
//                                         &pixelBuffer)
//        
//        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
//            return nil
//        }
//        
//        CVPixelBufferLockBaseAddress(buffer, [])
//        let pixelData = CVPixelBufferGetBaseAddress(buffer)
//        
//        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//        guard let context = CGContext(data: pixelData,
//                                      width: Int(size.width),
//                                      height: Int(size.height),
//                                      bitsPerComponent: 8,
//                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
//                                      space: rgbColorSpace,
//                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
//        else {
//            return nil
//        }
//        
//        UIGraphicsPushContext(context)
//        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
//        UIGraphicsPopContext()
//        
//        CVPixelBufferUnlockBaseAddress(buffer, [])
//        
//        return buffer
//    }
//    private var glucoseEstimationCard: some View {
//        let foodNames = foodEntry.items.compactMap {
//            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0.name
//        }
//        let baselineGlucose = healthKitManager.recentGlucoseReading ?? 100.0
//        let estimation = GlucoseEstimation.estimate(for: foodNames, baselineGlucose: baselineGlucose)
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            HStack {
//                Image(systemName: "waveform.path.ecg")
//                    .foregroundColor(.red)
//                    .font(.title2)
//                
//                Text("Glucose Impact")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
//                
//                Spacer()
//                
//                // HealthKit indicator
//                if let recentReading = healthKitManager.recentGlucoseReading {
//                    VStack(alignment: .trailing, spacing: 2) {
//                        Text("Current")
//                            .font(.caption2)
//                            .foregroundColor(.secondary)
//                        Text("\(Int(recentReading)) mg/dL")
//                            .font(.caption)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.blue)
//                    }
//                }
//            }
//            
//            // Risk Level Indicator
//            HStack(spacing: 12) {
//                ZStack {
//                    Circle()
//                        .fill(estimation.riskLevel.color.opacity(0.2))
//                        .frame(width: 50, height: 50)
//                    
//                    Image(systemName: estimation.riskLevel.icon)
//                        .foregroundColor(estimation.riskLevel.color)
//                        .font(.title3)
//                }
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(estimation.riskLevel.title)
//                        .font(.headline)
//                        .fontWeight(.semibold)
//                        .foregroundColor(estimation.riskLevel.color)
//                    
//                    Text("Estimated peak: \(Int(estimation.estimatedPeak)) mg/dL")
//                        .font(.subheadline)
//                        .foregroundColor(.primary)
//                    
//                    Text("Time to peak: \(estimation.timeToPeak)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                
//                Spacer()
//            }
//            .padding(16)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(estimation.riskLevel.color.opacity(0.1))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 12)
//                            .stroke(estimation.riskLevel.color.opacity(0.3), lineWidth: 1)
//                    )
//            )
//            
//            // Detailed Information
//            VStack(alignment: .leading, spacing: 12) {
//                HStack {
//                    Text("Expected increase:")
//                        .font(.system(size: 14))
//                        .foregroundColor(.secondary)
//                    Spacer()
//                    Text("+\(Int(estimation.estimatedIncrease)) mg/dL")
//                        .font(.system(size: 14, weight: .semibold))
//                        .foregroundColor(.primary)
//                }
//                
//                if let avgGlucose = healthKitManager.averageGlucose {
//                    HStack {
//                        Text("Recent average:")
//                            .font(.system(size: 14))
//                            .foregroundColor(.secondary)
//                        Spacer()
//                        Text("\(Int(avgGlucose)) mg/dL")
//                            .font(.system(size: 14, weight: .semibold))
//                            .foregroundColor(.blue)
//                    }
//                }
//            }
//            .padding(.horizontal, 4)
//            
//            // Recommendations
//            if !estimation.recommendations.isEmpty {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Recommendations:")
//                        .font(.system(size: 14, weight: .semibold))
//                        .foregroundColor(.primary)
//                    
//                    ForEach(Array(estimation.recommendations.enumerated()), id: \.offset) { index, recommendation in
//                        HStack(alignment: .top, spacing: 8) {
//                            Image(systemName: "checkmark.circle.fill")
//                                .foregroundColor(.appleGreen)
//                                .font(.system(size: 12))
//                                .padding(.top, 2)
//                            
//                            Text(recommendation)
//                                .font(.system(size: 13))
//                                .foregroundColor(.primary)
//                                .multilineTextAlignment(.leading)
//                        }
//                    }
//                }
//                .padding(12)
//                .background(
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(Color.appleGreen.opacity(0.1))
//                )
//            }
//            
//            // Disclaimer
//            Text("⚠️ This is an estimate based on general food data. Individual responses may vary. Consult your healthcare provider for personalized advice.")
//                .font(.caption2)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.leading)
//                .padding(.top, 8)
//        }
//        .padding(20)
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.cardBackground)
//                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
//        )
//    }
//    
//    private func saveFoodEntry() {
//        let validItems = foodEntry.items.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
//        
//        if validItems.isEmpty {
//            alertMessage = "Please add at least one food item before saving."
//            showingAlert = true
//            return
//        }
//        
//        // Dismiss keyboard first to avoid RTI errors
//        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//        
//        // Add small delay to let keyboard dismiss, then show recommendations
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            self.showingRecommendations = true
//        }
//    }
//}

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
import HealthKit

// MARK: - HealthKit Manager for Glucose Data
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var recentGlucoseReading: Double?
    @Published var averageGlucose: Double?
    
    func requestHealthKitPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
        let readTypes: Set<HKObjectType> = [glucoseType]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            if success {
                self.fetchRecentGlucoseData()
            }
        }
    }
    
    private func fetchRecentGlucoseData() {
        let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: glucoseType, predicate: nil, limit: 10, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            
            DispatchQueue.main.async {
                if let glucoseSamples = samples as? [HKQuantitySample], !glucoseSamples.isEmpty {
                    // Most recent reading
                    let recentValue = glucoseSamples.first!.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
                    self.recentGlucoseReading = recentValue
                    
                    // Average of recent readings
                    let values = glucoseSamples.map { $0.quantity.doubleValue(for: HKUnit(from: "mg/dL")) }
                    self.averageGlucose = values.reduce(0, +) / Double(values.count)
                }
            }
        }
        
        healthStore.execute(query)
    }
}

// MARK: - Glucose Estimation Model
struct GlucoseEstimation {
    let estimatedIncrease: Double
    let estimatedPeak: Double
    let riskLevel: GlucoseRiskLevel
    let timeToPeak: String
    let recommendations: [String]
}

enum GlucoseRiskLevel {
    case low, moderate, high
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "xmark.octagon.fill"
        }
    }
    
    var title: String {
        switch self {
        case .low: return "Low Impact"
        case .moderate: return "Moderate Impact"
        case .high: return "High Impact"
        }
    }
}

extension GlucoseEstimation {
    static func estimate(for foodItems: [String], baselineGlucose: Double = 100) -> GlucoseEstimation {
        let foodText = foodItems.joined(separator: " ").lowercased()
        
        // Simplified carb estimation based on common foods
        var carbEstimate = 0.0
        var glycemicLoad = 0.0
        
        // High carb foods
        if foodText.contains("rice") { carbEstimate += 45; glycemicLoad += 40 }
        if foodText.contains("bread") { carbEstimate += 25; glycemicLoad += 15 }
        if foodText.contains("pasta") { carbEstimate += 40; glycemicLoad += 18 }
        if foodText.contains("potato") { carbEstimate += 35; glycemicLoad += 22 }
        if foodText.contains("pizza") { carbEstimate += 50; glycemicLoad += 25 }
        if foodText.contains("bagel") { carbEstimate += 55; glycemicLoad += 30 }
        if foodText.contains("cereal") { carbEstimate += 30; glycemicLoad += 20 }
        if foodText.contains("oats") { carbEstimate += 25; glycemicLoad += 12 }
        if foodText.contains("banana") { carbEstimate += 25; glycemicLoad += 15 }
        if foodText.contains("apple") { carbEstimate += 20; glycemicLoad += 8 }
        if foodText.contains("orange") { carbEstimate += 15; glycemicLoad += 7 }
        
        // Processed/sugary foods
        if foodText.contains("soda") { carbEstimate += 40; glycemicLoad += 35 }
        if foodText.contains("candy") { carbEstimate += 30; glycemicLoad += 28 }
        if foodText.contains("cake") { carbEstimate += 45; glycemicLoad += 32 }
        if foodText.contains("cookie") { carbEstimate += 20; glycemicLoad += 15 }
        
        // Protein foods (minimal impact)
        if foodText.contains("chicken") || foodText.contains("fish") || foodText.contains("meat") || foodText.contains("beef") {
            carbEstimate += 0; glycemicLoad += 0
        }
        
        // Calculate estimated glucose impact
        // Rule of 500: 1g carb raises glucose by ~4-5 mg/dL for average person
        let estimatedIncrease = carbEstimate * 2
        let estimatedPeak = baselineGlucose + estimatedIncrease
        
        // Determine risk level
        let riskLevel: GlucoseRiskLevel
        if estimatedIncrease <= 2.5 {
            riskLevel = .low
        } else if estimatedIncrease <= 3 {
            riskLevel = .moderate
        } else {
            riskLevel = .high
        }
        
        // Time to peak (simplified)
        let timeToPeak = carbEstimate > 30 ? "60-90 min" : "30-60 min"
        
        // Generate recommendations
        var recommendations: [String] = []
        if riskLevel == .high {
            recommendations.append("Consider taking a walk after eating")
            recommendations.append("Drink water to help with glucose clearance")
        }
        if riskLevel != .low {
            recommendations.append("Monitor glucose levels after eating")
        }
        if carbEstimate > 40 {
            recommendations.append("Consider pairing with protein or fiber")
        }
        
        return GlucoseEstimation(
            estimatedIncrease: estimatedIncrease,
            estimatedPeak: estimatedPeak,
            riskLevel: riskLevel,
            timeToPeak: timeToPeak,
            recommendations: recommendations
        )
    }
}

// MARK: - Eating Recommendations Model
struct EatingRecommendation {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct MealRecommendations {
    let eatingOrder: [String]
    let generalTips: [EatingRecommendation]
    
    static func generateRecommendations(for foodItems: [String]) -> MealRecommendations {
        let eatingOrder = generateEatingOrder(for: foodItems)
        let generalTips = generateGeneralTips(for: foodItems)
        return MealRecommendations(eatingOrder: eatingOrder, generalTips: generalTips)
    }
    
    private static func generateEatingOrder(for items: [String]) -> [String] {
        var order: [String] = []
        let itemsLower = items.map { $0.lowercased() }
        
        // Vegetables and fiber first
        let vegetables = itemsLower.filter { item in
            ["salad", "vegetables", "greens", "broccoli", "spinach", "kale", "lettuce", "cucumber", "tomato", "carrot", "pepper"].contains { item.contains($0) }
        }
        
        // Proteins second
        let proteins = itemsLower.filter { item in
            ["chicken", "fish", "meat", "beef", "pork", "egg", "tofu", "beans", "lentils", "quinoa", "salmon", "tuna"].contains { item.contains($0) }
        }
        
        // Carbs last
        let carbs = itemsLower.filter { item in
            ["rice", "bread", "pasta", "potato", "noodles", "toast", "bagel", "cereal", "oats"].contains { item.contains($0) }
        }
        
        if !vegetables.isEmpty {
            order.append("🥬 Start with vegetables/fiber (helps with satiety)")
        }
        if !proteins.isEmpty {
            order.append("🍗 Eat your proteins (promotes fullness)")
        }
        if !carbs.isEmpty {
            order.append("🍚 Finish with carbohydrates (better blood sugar control)")
        }
        
        if order.isEmpty {
            order = ["🍽️ Eat mindfully, chewing each bite thoroughly"]
        }
        
        return order
    }
    
    private static func generateGeneralTips(for items: [String]) -> [EatingRecommendation] {
        var tips: [EatingRecommendation] = []
        let itemsText = items.joined(separator: " ").lowercased()
        
        // Base recommendations everyone gets
        tips.append(EatingRecommendation(
            title: "Chew Mindfully",
            description: "Chew each bite 20-30 times to aid digestion and increase satiety",
            icon: "mouth",
            color: .blue
        ))
        
        tips.append(EatingRecommendation(
            title: "Eat Slowly",
            description: "Take 15-20 minutes to finish your meal to allow fullness signals",
            icon: "clock",
            color: .green
        ))
        
        // Conditional recommendations based on food content
        let hasVeggies = ["salad", "vegetables", "greens", "broccoli", "spinach", "kale"].contains { itemsText.contains($0) }
        let hasProcessed = ["pizza", "hamburger", "fries", "chips", "soda", "candy"].contains { itemsText.contains($0) }
        let hasCarbs = ["rice", "bread", "pasta", "potato"].contains { itemsText.contains($0) }
        
        if !hasVeggies {
            tips.append(EatingRecommendation(
                title: "Add More Greens",
                description: "Consider adding leafy greens or vegetables to boost nutrition",
                icon: "leaf.fill",
                color: .green
            ))
        }
        
        if hasProcessed {
            tips.append(EatingRecommendation(
                title: "Balance Your Plate",
                description: "Try to include whole foods and reduce processed items next time",
                icon: "scale.3d",
                color: .orange
            ))
        }
        
        if hasCarbs {
            tips.append(EatingRecommendation(
                title: "Portion Control",
                description: "Keep carb portions to about 1/4 of your plate",
                icon: "hand.raised.fill",
                color: .purple
            ))
        }
        
        tips.append(EatingRecommendation(
            title: "Stay Hydrated",
            description: "Drink water before and after eating, but limit during meals",
            icon: "drop.fill",
            color: .cyan
        ))
        
        return Array(tips.prefix(4)) // Limit to 4 tips to avoid overwhelming
    }
}

// MARK: - Recommendations Bottom Sheet
struct RecommendationsBottomSheet: View {
    let recommendations: MealRecommendations
    let mealType: String
    let foodItems: [String]
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                            }
                            
                            Text("Smart Eating Tips")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Personalized recommendations for your \(mealType.lowercased())")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Eating Order Section
                        if !recommendations.eatingOrder.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "list.number")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                    
                                    Text("Recommended Eating Order")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(Array(recommendations.eatingOrder.enumerated()), id: \.offset) { index, order in
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.blue.opacity(0.2))
                                                    .frame(width: 32, height: 32)
                                                
                                                Text("\(index + 1)")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.blue)
                                            }
                                            
                                            Text(order)
                                                .font(.system(size: 15))
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemBackground))
                                        )
                                    }
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                        }
                        
                        // General Tips Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                                
                                Text("Health Tips")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                                ForEach(Array(recommendations.generalTips.enumerated()), id: \.offset) { _, tip in
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: tip.icon)
                                                .foregroundColor(tip.color)
                                                .font(.title3)
                                            
                                            Text(tip.title)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                        }
                                        
                                        Text(tip.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(tip.color.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        
                        // Action Button
                        Button(action: {
                            onDismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                
                                Text("Got It!")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

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
    @State private var showingRecommendations = false
    @StateObject private var healthKitManager = HealthKitManager()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Int?
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.lightGray, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                focusedField = nil
            }
            
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
                    
                    // Glucose Estimation
                    if !foodEntry.items.allSatisfy { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } {
                        glucoseEstimationCard
                    }
                    
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
        .sheet(isPresented: $showingRecommendations) {
            RecommendationsBottomSheet(
                recommendations: MealRecommendations.generateRecommendations(
                    for: foodEntry.items.compactMap { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0.name }
                ),
                mealType: foodEntry.mealType.rawValue,
                foodItems: foodEntry.items.compactMap { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0.name },
                isPresented: $showingRecommendations
            ) {
                showingRecommendations = false
                dismiss()
            }
        }
        .alert("", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    // Don't dismiss here, let the recommendations sheet handle it
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
        .onAppear {
            healthKitManager.requestHealthKitPermissions()
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
                    Button(action: {
                        foodEntry.mealType = meal
                        focusedField = nil // Dismiss keyboard when selecting meal type
                    }) {
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
                        .focused($focusedField, equals: index)
                        .onSubmit {
                            // Move to next field or dismiss keyboard
                            if index < foodEntry.items.count - 1 {
                                focusedField = index + 1
                            } else {
                                focusedField = nil
                            }
                        }
                        .submitLabel(.next)
                        
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
            // Focus on the new item
            focusedField = foodEntry.items.count - 1
        }
    }
    
    private func removeFoodItem(at index: Int) {
        withAnimation(.spring()) {
            foodEntry.items.remove(at: index)
            // Adjust focus if necessary
            if let focused = focusedField, focused >= index {
                focusedField = focused > 0 ? focused - 1 : nil
            }
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
    private var glucoseEstimationCard: some View {
        let foodNames = foodEntry.items.compactMap {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0.name
        }
        let baselineGlucose = healthKitManager.recentGlucoseReading ?? 100.0
        let estimation = GlucoseEstimation.estimate(for: foodNames, baselineGlucose: baselineGlucose)
        
        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Glucose Impact")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // HealthKit indicator
                if let recentReading = healthKitManager.recentGlucoseReading {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Current")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(recentReading)) mg/dL")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Risk Level Indicator
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(estimation.riskLevel.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: estimation.riskLevel.icon)
                        .foregroundColor(estimation.riskLevel.color)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(estimation.riskLevel.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(estimation.riskLevel.color)
                    
                    Text("Estimated peak: \(Int(estimation.estimatedPeak)) mg/dL")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("Time to peak: \(estimation.timeToPeak)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(estimation.riskLevel.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(estimation.riskLevel.color.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Detailed Information
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Expected increase:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("+\(Int(estimation.estimatedIncrease)) mg/dL")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                if let avgGlucose = healthKitManager.averageGlucose {
                    HStack {
                        Text("Recent average:")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(avgGlucose)) mg/dL")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // Recommendations
            if !estimation.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(Array(estimation.recommendations.enumerated()), id: \.offset) { index, recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.appleGreen)
                                .font(.system(size: 12))
                                .padding(.top, 2)
                            
                            Text(recommendation)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appleGreen.opacity(0.1))
                )
            }
            
            // Disclaimer
            Text("⚠️ This is an estimate based on general food data. Individual responses may vary. Consult your healthcare provider for personalized advice.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onTapGesture {
            focusedField = nil // Dismiss keyboard when tapping on glucose card
        }
    }
    
    private func saveFoodEntry() {
        let validItems = foodEntry.items.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        if validItems.isEmpty {
            alertMessage = "Please add at least one food item before saving."
            showingAlert = true
            return
        }
        
        // Dismiss keyboard first
        focusedField = nil
        
        // Add small delay to let keyboard dismiss, then show recommendations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showingRecommendations = true
        }
    }
}
