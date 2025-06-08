//
//  MealModel.swift
//  swiftChallenge
//
//  Created by Victoria Marin on 07/06/25.
//

import SwiftUI
import Vision
import UIKit
import AVFoundation
import CoreML

// MARK: - Models
struct FoodItem: Identifiable {
    let id = UUID()
    var name: String = ""
}

enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case snack = "Snack"
    case lunch = "Lunch"
    case dinner = "Dinner"
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .snack: return "leaf.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .snack: return .green
        case .lunch: return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .dinner: return Color(red: 0.3, green: 0.4, blue: 0.9)
        }
    }
}

struct FoodEntry {
    var mealType: MealType = .breakfast
    var items: [FoodItem] = [FoodItem()]
}

enum EntryMethod: String, CaseIterable {
    case manual = "Manual Entry"
    case foodPhoto = "Food Photo"
    case textPhoto = "Text Scanner"
    
    var icon: String {
        switch self {
        case .manual: return "pencil.and.list.clipboard"
        case .foodPhoto: return "camera.viewfinder"
        case .textPhoto: return "doc.text.viewfinder"
        }
    }
    
    var color: Color {
        switch self {
        case .manual: return .blue
        case .foodPhoto: return .green
        case .textPhoto: return .orange
        }
    }
    
    var description: String {
        switch self {
        case .manual: return "Type your food items manually"
        case .foodPhoto: return "AI identifies food from photos"
        case .textPhoto: return "Extract text from menu photos"
        }
    }
}

// MARK: - API Integration
class MealService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analysisId: String?
    
    private let baseURL = "https://apiswiftchallengefest-production.up.railway.app/api"
    private let carlosToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2ODQ1MzE5NDM2Yzc1ZjJhMWYwNjg5NDIiLCJpYXQiOjE3NDkzNjUyNTMsImV4cCI6MTc0OTk3MDA1MywiYXVkIjoiZGlhYmV0ZXMtYXBwIiwiaXNzIjoiZGlhYmV0ZXMtYXBpIn0._4KViwaTmYQM1cKmn90KoB1wrtHIYt44LktMn_yHQ1E"
    
    func registerMeal(foodEntry: FoodEntry) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        // Add this function to normalize food names
        func normalizeFoodName(_ name: String) -> String {
            // 1. Trim whitespace
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 2. Capitalize first letter of each word
            let capitalized = trimmed.capitalized
            
            // 3. Remove special characters if needed
            let normalized = capitalized.folding(options: .diacriticInsensitive, locale: .current)
            
            // 4. Handle common variations
            var result = normalized
            
            // Handle common food name variations
            let replacements = [
                "Manzana Verde": "Manzana",
                "Manzana Roja": "Manzana",
                "Arroz Blanco": "Arroz",
                "Arroz Integral": "Arroz Integral",
                "Pan Blanco": "Pan",
                "Pan Integral": "Pan Integral"
            ]
            
            for (variant, standard) in replacements {
                if normalized.contains(variant) {
                    result = standard
                    break
                }
            }
            
            print("🔄 Normalized food name: '\(name)' → '\(result)'")
            return result
        }

        // Use this function when preparing the request
        let normalizedItems = foodEntry.items.map { item in
            return FoodItem(name: normalizeFoodName(item.name))
        }

        // Prepare the request body
        let requestBody: [String: Any] = [
            "mealType": foodEntry.mealType.rawValue.lowercased(),
            "items": normalizedItems.map { ["name": $0.name] },
            "source": "manual_entry"
        ]
        
        // Añade este código temporalmente en la función registerMeal de MealService
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 ENVIANDO DATOS: \(jsonString)")
            }
        } catch {
            print("❌ Error al serializar datos: \(error.localizedDescription)")
        }
        
        guard let url = URL(string: "\(baseURL)/meals") else {
            errorMessage = "Invalid URL"
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                return false
            }
            
            if httpResponse.statusCode == 201 {
                // Successfully created meal entry
                if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = responseDict["data"] as? [String: Any],
                   let meal = dataDict["meal"] as? [String: Any],
                   let analysisId = meal["analysisId"] as? String {
                    self.analysisId = analysisId
                }
                return true
            } else {
                if let errorDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorDict["message"] as? String {
                    errorMessage = message
                } else {
                    errorMessage = "Failed to register meal. Status code: \(httpResponse.statusCode)"
                }
                return false
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            return false
        }
    }
    
    func fetchAnalysisResults(analysisId: String) async -> [String: Any]? {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/food-analysis/\(analysisId)") else {
            errorMessage = "Invalid URL"
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Failed to fetch analysis results"
                return nil
            }
            
            if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataDict = responseDict["data"] as? [String: Any],
               let analysis = dataDict["analysis"] as? [String: Any] {
                return analysis
            } else {
                errorMessage = "Invalid response format"
                return nil
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func getAuthToken() -> String {
        // Using Carlos's token directly
        return carlosToken
    }
    
    func fetchFoodSuggestions(query: String) async -> [String] {
        guard !query.isEmpty, query.count >= 2 else { return [] }
        
        print("🔍 Buscando sugerencias para: \(query)")
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/foods?search=\(encodedQuery)&limit=5") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return []
            }
            
            if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataDict = responseDict["data"] as? [String: Any],
               let foods = dataDict["foods"] as? [[String: Any]] {
                
                let suggestions = foods.compactMap { $0["nombre"] as? String }
                print("✅ Sugerencias encontradas: \(suggestions.joined(separator: ", "))")
                return suggestions
            }
        } catch {
            print("❌ Error al buscar sugerencias: \(error.localizedDescription)")
        }
        
        return []
    }
}

// MARK: - View Model
class MealViewModel: ObservableObject {
    @Published var foodEntry = FoodEntry()
    @Published var mealService = MealService()
    @Published var analysisResults: [String: Any]? = nil
    @Published var isSubmitting = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    func registerMeal() {
        guard !foodEntry.items.isEmpty, !foodEntry.items[0].name.isEmpty else {
            alertMessage = "Please add at least one food item"
            showAlert = true
            return
        }
        
        isSubmitting = true
        
        Task {
            let success = await mealService.registerMeal(foodEntry: foodEntry)
            
            DispatchQueue.main.async {
                self.isSubmitting = false
                
                if success {
                    self.alertMessage = "Meal registered successfully!"
                    if let analysisId = self.mealService.analysisId {
                        Task {
                            let results = await self.mealService.fetchAnalysisResults(analysisId: analysisId)
                            DispatchQueue.main.async {
                                self.analysisResults = results
                            }
                        }
                    }
                } else {
                    self.alertMessage = self.mealService.errorMessage ?? "Failed to register meal"
                }
                self.showAlert = true
            }
        }
    }
}
