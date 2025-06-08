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

// MARK: - Manual Entry View
struct ManualEntryView: View {
    @State private var foodEntry = FoodEntry()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSubmitting = false
    @StateObject private var mealService = MealService()
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
        .alert("", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // Similar to previous implementation but simplified
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
        .disabled(foodEntry.items.allSatisfy { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } || isSubmitting)
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

        isSubmitting = true

        Task {
            let success = await mealService.registerMeal(foodEntry: foodEntry)

            DispatchQueue.main.async {
                self.isSubmitting = false

                if success {
                    self.alertMessage = "🎉 Meal registered successfully!\n\nFood items have been matched against our database for accurate nutritional analysis."
                } else {
                    self.alertMessage = self.mealService.errorMessage ?? "Failed to register meal"
                }
                self.showingAlert = true
            }
        }
    }
}
