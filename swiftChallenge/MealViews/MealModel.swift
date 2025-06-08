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
