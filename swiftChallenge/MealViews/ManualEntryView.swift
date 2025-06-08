//
//  ManualEntryView.swift
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

// MARK: - Manual Entry View (Enhanced)
struct ManualEntryView: View {
    @State private var foodEntry = FoodEntry()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingRecommendations = false
    @StateObject private var healthKitManager = HealthKitManager()
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
                    // Meal Type Selection
                    mealTypeCard
                    
                    // Food Items Card
                    foodItemsCard
                    
                    // Glucose Estimation (only show when there are food items)
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
        .navigationTitle("Manual Entry")
        .navigationBarBackButtonHidden(false)
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
                // Don't dismiss here, let the recommendations sheet handle it
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            healthKitManager.requestHealthKitPermissions()
        }
    }
    
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
                        .onSubmit {
                            // Dismiss keyboard when user taps return
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        
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
    
    private func saveFoodEntry() {
        let validItems = foodEntry.items.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        if validItems.isEmpty {
            alertMessage = "Please add at least one food item before saving."
            showingAlert = true
            return
        }
        
        // Dismiss keyboard first to avoid RTI errors
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Add small delay to let keyboard dismiss, then show recommendations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showingRecommendations = true
        }
    }
}
