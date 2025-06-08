////
////  HealthIntents.swift
////  health-app
////
////  Created by Victoria Marin on 08/06/25.
////
//
//import AppIntents
//import Foundation
//
//// MARK: - Entities
//
//struct MealTypeEntity: AppEntity {
//    var id: String
//    var mealType: String
//
//    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Meal Type"
//    var displayRepresentation: DisplayRepresentation {
//        DisplayRepresentation(stringLiteral: mealType)
//    }
//
//    static var defaultQuery = MealTypeEntityQuery()
//}
//
//struct MealTypeEntityQuery: EntityQuery {
//    func entities(for identifiers: [String]) async throws -> [MealTypeEntity] {
//        return identifiers.map { MealTypeEntity(id: $0, mealType: $0) }
//    }
//
//    func suggestedEntities() async throws -> [MealTypeEntity] {
//        return [
//            MealTypeEntity(id: "breakfast", mealType: "breakfast"),
//            MealTypeEntity(id: "lunch", mealType: "lunch"),
//            MealTypeEntity(id: "dinner", mealType: "dinner"),
//            MealTypeEntity(id: "snack", mealType: "snack")
//        ]
//    }
//}
//
//// MARK: - Helper Functions
//
//extension HealthIntents {
//    static func loadHealthData() -> HealthData {
//        let possibleSuiteNames = [
//            "group.com.victoria.health",
//            "group.com.tuApp.health-data",
//            nil
//        ]
//
//        for suiteName in possibleSuiteNames {
//            let userDefaults = suiteName != nil ? UserDefaults(suiteName: suiteName!) : UserDefaults.standard
//
//            if let data = userDefaults?.data(forKey: "healthData"),
//               let healthData = try? JSONDecoder().decode(HealthData.self, from: data) {
//                return healthData
//            }
//        }
//
//        return HealthData() // Return empty data if none found
//    }
//
//    static func analyzeGlucoseLevel(_ glucose: Double, fasting: Bool = false) -> (String, String) {
//        let level: String
//        let advice: String
//
//        if fasting {
//            switch glucose {
//            case 0..<70:
//                level = "LOW"
//                advice = "Consume 15g fast-acting carbs immediately. Recheck in 15 minutes."
//            case 70..<100:
//                level = "NORMAL"
//                advice = "Maintain current diet and exercise routine."
//            case 100..<126:
//                level = "PREDIABETIC"
//                advice = "Focus on low-carb meals and increase physical activity."
//            default:
//                level = "DIABETIC"
//                advice = "Monitor closely, follow medication schedule, avoid high-carb foods."
//            }
//        } else {
//            switch glucose {
//            case 0..<70:
//                level = "LOW"
//                advice = "Have small snack with carbs and protein. Avoid exercise until normalized."
//            case 70..<140:
//                level = "NORMAL"
//                advice = "Proceed with regular activities and meals."
//            case 140..<200:
//                level = "ELEVATED"
//                advice = "Consider light walking, avoid additional carbs, drink water."
//            default:
//                level = "HIGH"
//                advice = "Check ketones if possible, take medication, contact provider if no improvement."
//            }
//        }
//
//        return (level, advice)
//    }
//}
//
//// MARK: - Personalized Glucose Advice Intent
//
//struct PersonalizedGlucoseAdviceIntent: AppIntent {
//    static var title: LocalizedStringResource = "Analyze My Glucose Levels"
//    static var description = IntentDescription("Provides personalized advice based on your current glucose readings")
//
//    @Parameter(title: "Current Glucose (mg/dL)")
//    var currentGlucose: Double?
//
//    @Parameter(title: "Is this a fasting reading?")
//    var isFasting: Bool
//
//    @Parameter(title: "Time since last meal (hours)")
//    var timeSinceLastMeal: Double?
//
//    static var parameterSummary: some ParameterSummary {
//        Summary("Analyze glucose level of \(\.$currentGlucose) mg/dL")
//    }
//
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        let healthData = HealthIntents.loadHealthData()
//        let glucose = currentGlucose ?? healthData.glucose
//
//        if glucose == 0 {
//            return .result(dialog: IntentDialog(stringLiteral: "Need your current glucose reading to provide advice."))
//        }
//
//        let (level, advice) = HealthIntents.analyzeGlucoseLevel(glucose, fasting: isFasting)
//        let response = "Glucose: \(Int(glucose)) mg/dL [\(level)]. \(advice)"
//
//        return .result(dialog: IntentDialog(stringLiteral: response))
//    }
//}
//
//// MARK: - Blood Pressure Analysis Intent
//
//struct BloodPressureAdviceIntent: AppIntent {
//    static var title: LocalizedStringResource = "Analyze Blood Pressure"
//    static var description = IntentDescription("Provides personalized blood pressure analysis and recommendations")
//
//    @Parameter(title: "Systolic Pressure (top number)")
//    var systolic: Double?
//
//    @Parameter(title: "Diastolic Pressure (bottom number)")
//    var diastolic: Double?
//
//    @Parameter(title: "Heart Rate (BPM)")
//    var heartRate: Double?
//
//    static var parameterSummary: some ParameterSummary {
//        Summary("Analyze BP reading \(\.$systolic)/\(\.$diastolic)")
//    }
//
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        let healthData = HealthIntents.loadHealthData()
//        let sys = systolic ?? healthData.systolicBP
//        let dia = diastolic ?? healthData.diastolicBP
//
//        if sys == 0 || dia == 0 {
//            return .result(dialog: IntentDialog(stringLiteral: "Need blood pressure readings to provide analysis."))
//        }
//
//        let category: String
//        let advice: String
//
//        switch (sys, dia) {
//        case (..<90, ..<60):
//            category = "LOW"
//            advice = "Stay hydrated and avoid sudden position changes."
//        case (90..<120, 60..<80):
//            category = "NORMAL"
//            advice = "Maintain current lifestyle with regular exercise."
//        case (120..<130, ..<80):
//            category = "ELEVATED"
//            advice = "Reduce sodium intake and increase exercise."
//        case (130..<140, 80..<90):
//            category = "STAGE 1 HTN"
//            advice = "Lifestyle changes needed. Monitor daily."
//        default:
//            category = "STAGE 2 HTN"
//            advice = "Contact healthcare provider immediately."
//        }
//
//        let response = "BP: \(Int(sys))/\(Int(dia)) mmHg [\(category)]. \(advice)"
//        return .result(dialog: IntentDialog(stringLiteral: response))
//    }
//}
//
//// MARK: - Personalized Meal Advice Intent
//
//struct PersonalizedMealAdviceIntent: AppIntent {
//    static var title: LocalizedStringResource = "Get Personalized Meal Advice"
//    static var description = IntentDescription("Provides meal recommendations based on your health data")
//
//    @Parameter(title: "Meal Type")
//    var mealType: MealTypeEntity
//
//    @Parameter(title: "Current Glucose Level (mg/dL)")
//    var currentGlucose: Double?
//
//    @Parameter(title: "How hungry are you? (1-10)")
//    var hungerLevel: Int?
//
//    static var parameterSummary: some ParameterSummary {
//        Summary("Plan my \(\.$mealType) meal")
//    }
//
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        let healthData = HealthIntents.loadHealthData()
//        let glucose = currentGlucose ?? healthData.glucose
//        let meal = mealType.mealType.lowercased()
//
//        var advice: String
//
//        if glucose > 180 {
//            advice = "High glucose: avoid carbs. Focus on lean proteins and vegetables."
//        } else if glucose < 70 {
//            advice = "Low glucose: take 15g glucose tablets first, then recheck."
//        } else {
//            switch meal {
//            case "breakfast":
//                advice = "Try eggs with vegetables, Greek yogurt with nuts, or oatmeal with cinnamon."
//            case "lunch":
//                advice = "Consider grilled chicken salad, quinoa bowl, or turkey wrap."
//            case "dinner":
//                advice = "Light options: baked fish with vegetables or lean protein with salad."
//            case "snack":
//                advice = "Apple with almond butter, hummus with vegetables, or mixed nuts."
//            default:
//                advice = "Balance: 50% vegetables, 25% protein, 25% complex carbs."
//            }
//        }
//
//        let response = "\(meal.capitalized) advice: \(advice)"
//        return .result(dialog: IntentDialog(stringLiteral: response))
//    }
//}
//
//// MARK: - Activity Recommendation Intent
//
//struct ActivityRecommendationIntent: AppIntent {
//    static var title: LocalizedStringResource = "Get Exercise Recommendations"
//    static var description = IntentDescription("Provides safe exercise advice based on your current health status")
//
//    @Parameter(title: "Current Glucose (mg/dL)")
//    var currentGlucose: Double?
//
//    @Parameter(title: "Energy Level (1-10)")
//    var energyLevel: Int?
//
//    @Parameter(title: "Available Time (minutes)")
//    var availableTime: Int?
//
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        let healthData = HealthIntents.loadHealthData()
//        let glucose = currentGlucose ?? healthData.glucose
//        let energy = energyLevel ?? 5
//        let time = availableTime ?? 30
//
//        // Safety checks
//        if glucose < 70 {
//            return .result(dialog: IntentDialog(stringLiteral: "Glucose too low (\(Int(glucose)) mg/dL). Treat first, then try gentle stretching only."))
//        }
//
//        if glucose > 250 {
//            return .result(dialog: IntentDialog(stringLiteral: "Glucose too high (\(Int(glucose)) mg/dL). Light walking only, 10-15 minutes."))
//        }
//
//        // Exercise recommendations
//        let recommendation: String
//        switch (energy, time) {
//        case (1...3, _):
//            recommendation = "Low energy: 10-minute gentle walk or light stretching."
//        case (4...6, 0...15):
//            recommendation = "15-minute brisk walk or bodyweight exercises."
//        case (4...6, 16...45):
//            recommendation = "30-minute walk, bike ride, or resistance training."
//        case (7...10, 0...30):
//            recommendation = "20-minute HIIT session or circuit training."
//        default:
//            recommendation = "45-minute run, cycling, or full strength training."
//        }
//
//        return .result(dialog: IntentDialog(stringLiteral: "Exercise plan (\(time) min): \(recommendation) Carry glucose tablets."))
//    }
//}
//
//// MARK: - BMI Analysis Intent
//
//struct BMIAnalysisIntent: AppIntent {
//    static var title: LocalizedStringResource = "Analyze My BMI"
//    static var description = IntentDescription("Provides BMI analysis and weight management advice")
//
//    @Parameter(title: "Current Weight (lbs)")
//    var weight: Double?
//
//    @Parameter(title: "Height (inches)")
//    var height: Double?
//
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        let healthData = HealthIntents.loadHealthData()
//        let currentWeight = weight ?? healthData.weight
//        let currentHeight = height ?? healthData.height
//
//        if currentWeight == 0 || currentHeight == 0 {
//            return .result(dialog: IntentDialog(stringLiteral: "Need current weight and height to calculate BMI."))
//        }
//
//        let bmi = (currentWeight / (currentHeight * currentHeight)) * 703
//
//        let category: String
//        let advice: String
//
//        switch bmi {
//        case ..<18.5:
//            category = "UNDERWEIGHT"
//            advice = "Focus on nutrient-dense, calorie-rich foods."
//        case 18.5..<25:
//            category = "NORMAL"
//            advice = "Maintain current diet and exercise routine."
//        case 25..<30:
//            category = "OVERWEIGHT"
//            advice = "Aim for 1-2 lbs/week loss through 500-calorie deficit."
//        case 30..<35:
//            category = "OBESITY CLASS I"
//            advice = "Weight loss important. Consider healthcare provider guidance."
//        default:
//            category = "OBESITY CLASS II+"
//            advice = "Consult healthcare provider about comprehensive weight management."
//        }
//
//        let response = "BMI: \(String(format: "%.1f", bmi)) [\(category)]. \(advice)"
//        return .result(dialog: IntentDialog(stringLiteral: response))
//    }
//}
//
//// MARK: - Comprehensive Health Check Intent
//
//struct ComprehensiveHealthCheckIntent: AppIntent {
//    static var title: LocalizedStringResource = "Complete Health Analysis"
//    static var description = IntentDescription("Provides a comprehensive overview of your health metrics and priorities")
//
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        let healthData = HealthIntents.loadHealthData()
//        var summary: [String] = []
//
//        // Quick health checks
//        if healthData.glucose > 0 {
//            let status = healthData.glucose > 180 ? "HIGH" : healthData.glucose < 70 ? "LOW" : "NORMAL"
//            summary.append("Glucose: \(Int(healthData.glucose)) mg/dL [\(status)]")
//        }
//
//        if healthData.systolicBP > 0 && healthData.diastolicBP > 0 {
//            let status = healthData.systolicBP >= 140 ? "HIGH" : "NORMAL"
//            summary.append("BP: \(Int(healthData.systolicBP))/\(Int(healthData.diastolicBP)) [\(status)]")
//        }
//
//        if healthData.weight > 0 && healthData.height > 0 {
//            let bmi = (healthData.weight / (healthData.height * healthData.height)) * 703
//            let status = bmi >= 30 ? "OBESE" : bmi >= 25 ? "OVERWEIGHT" : "NORMAL"
//            summary.append("BMI: \(String(format: "%.1f", bmi)) [\(status)]")
//        }
//
//        if healthData.steps > 0 {
//            let status = healthData.steps >= 10000 ? "EXCELLENT" : healthData.steps >= 7500 ? "GOOD" : "LOW"
//            summary.append("Steps: \(Int(healthData.steps)) [\(status)]")
//        }
//
//        let response = summary.isEmpty ? "No health data available." : "Health Summary: " + summary.joined(separator: ", ")
//        return .result(dialog: IntentDialog(stringLiteral: response))
//    }
//}
//
//// MARK: - Emergency Health Check Intent
//
//struct EmergencyHealthCheckIntent: AppIntent {
//    static var title: LocalizedStringResource = "Emergency Health Alert"
//    static var description = IntentDescription("Checks for concerning health readings that may need immediate attention")
//
//    @Parameter(title: "Current Glucose (mg/dL)")
//    var currentGlucose: Double?
//
//    @Parameter(title: "How are you feeling?")
//    var symptoms: String?
//
//    func perform() async throws -> some IntentResult & ProvidesDialog {
//        let healthData = HealthIntents.loadHealthData()
//        let glucose = currentGlucose ?? healthData.glucose
//
//        // Critical checks
//        if glucose < 54 {
//            return .result(dialog: IntentDialog(stringLiteral: "EMERGENCY: Severe low glucose (\(Int(glucose)) mg/dL). Call 911 immediately."))
//        }
//
//        if glucose > 400 {
//            return .result(dialog: IntentDialog(stringLiteral: "EMERGENCY: Dangerously high glucose (\(Int(glucose)) mg/dL). Check ketones, call doctor, go to ER if ketones positive."))
//        }
//
//        if healthData.systolicBP > 180 || healthData.diastolicBP > 120 {
//            return .result(dialog: IntentDialog(stringLiteral: "EMERGENCY: Hypertensive crisis. Call 911 immediately."))
//        }
//
//        // Warning levels
//        if glucose < 70 {
//            return .result(dialog: IntentDialog(stringLiteral: "WARNING: Low glucose (\(Int(glucose)) mg/dL). Take 15g glucose tablets, recheck in 15 minutes."))
//        }
//
//        if glucose > 250 {
//            return .result(dialog: IntentDialog(stringLiteral: "WARNING: Very high glucose (\(Int(glucose)) mg/dL). Check ketones, increase fluids, contact healthcare provider."))
//        }
//
//        if healthData.systolicBP > 160 || healthData.diastolicBP > 100 {
//            return .result(dialog: IntentDialog(stringLiteral: "WARNING: Severe hypertension. Contact healthcare provider today."))
//        }
//
//        // All clear
//        return .result(dialog: IntentDialog(stringLiteral: "No immediate health concerns detected. Continue regular monitoring."))
//    }
//}
//
//class HealthIntents {
//    // Empty class to hold static methods
//}
//

//
//  HealthIntents.swift
//  health-app
//
//  Created by Victoria Marin on 08/06/25.
//

import AppIntents
import Foundation

// MARK: - Entities

struct MealTypeEntity: AppEntity {
    var id: String
    var mealType: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Meal Type"
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: mealType)
    }
    
    static var defaultQuery = MealTypeEntityQuery()
}

struct MealTypeEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [MealTypeEntity] {
        return identifiers.map { MealTypeEntity(id: $0, mealType: $0) }
    }
    
    func suggestedEntities() async throws -> [MealTypeEntity] {
        return [
            MealTypeEntity(id: "breakfast", mealType: "breakfast"),
            MealTypeEntity(id: "lunch", mealType: "lunch"),
            MealTypeEntity(id: "dinner", mealType: "dinner"),
            MealTypeEntity(id: "snack", mealType: "snack")
        ]
    }
}

// MARK: - Helper Functions

extension HealthIntents {
    static func loadHealthData() -> HealthData {
        let possibleSuiteNames = [
            "group.com.victoria.health",
            "group.com.tuApp.health-data",
            nil
        ]
        
        for suiteName in possibleSuiteNames {
            let userDefaults = suiteName != nil ? UserDefaults(suiteName: suiteName!) : UserDefaults.standard
            
            if let data = userDefaults?.data(forKey: "healthData"),
               let healthData = try? JSONDecoder().decode(HealthData.self, from: data) {
                return healthData
            }
        }
        
        return HealthData() // Return empty data if none found
    }
    
    static func analyzeGlucoseLevel(_ glucose: Double, fasting: Bool = false) -> (String, String) {
        let level: String
        let advice: String
        
        if fasting {
            switch glucose {
            case 0..<70:
                level = "LOW"
                advice = "Consume 15g fast-acting carbs immediately. Recheck in 15 minutes."
            case 70..<100:
                level = "NORMAL"
                advice = "Maintain current diet and exercise routine."
            case 100..<126:
                level = "PREDIABETIC"
                advice = "Focus on low-carb meals and increase physical activity."
            default:
                level = "DIABETIC"
                advice = "Monitor closely, follow medication schedule, avoid high-carb foods."
            }
        } else {
            switch glucose {
            case 0..<70:
                level = "LOW"
                advice = "Have small snack with carbs and protein. Avoid exercise until normalized."
            case 70..<140:
                level = "NORMAL"
                advice = "Proceed with regular activities and meals."
            case 140..<200:
                level = "ELEVATED"
                advice = "Consider light walking, avoid additional carbs, drink water."
            default:
                level = "HIGH"
                advice = "Check ketones if possible, take medication, contact provider if no improvement."
            }
        }
        
        return (level, advice)
    }
}

// MARK: - Quick Glucose Recording Intent

struct RecordGlucoseIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Glucose Reading"
    static var description = IntentDescription("Record a new glucose reading")

    @Parameter(title: "Glucose Level (mg/dL)")
    var glucoseLevel: Double
    
    @Parameter(title: "Is Fasting Reading?")
    var isFasting: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("Record glucose level of \(\.$glucoseLevel) mg/dL")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Validate glucose level
        guard glucoseLevel > 0 && glucoseLevel < 1000 else {
            return .result(dialog: IntentDialog(stringLiteral: "Please enter a valid glucose level between 1-999 mg/dL"))
        }
        
        // Save to UserDefaults
        let possibleSuiteNames = [
            "group.com.victoria.health",
            "group.com.tuApp.health-data",
            nil
        ]
        
        var saved = false
        for suiteName in possibleSuiteNames {
            if let userDefaults = suiteName != nil ? UserDefaults(suiteName: suiteName!) : UserDefaults.standard {
                userDefaults.set(glucoseLevel, forKey: "currentGlucose")
                userDefaults.set(Date(), forKey: "glucoseLastUpdated")
                userDefaults.set(isFasting, forKey: "isFastingReading")
                
                // Also save to history
                var history = userDefaults.array(forKey: "glucoseHistory") as? [[String: Any]] ?? []
                let newEntry: [String: Any] = [
                    "glucose": glucoseLevel,
                    "date": Date(),
                    "isFasting": isFasting
                ]
                history.append(newEntry)
                
                // Keep only last 100 readings
                if history.count > 100 {
                    history = Array(history.suffix(100))
                }
                userDefaults.set(history, forKey: "glucoseHistory")
                
                saved = true
                break
            }
        }
        
        // Determine status and response
        let (level, advice) = HealthIntents.analyzeGlucoseLevel(glucoseLevel, fasting: isFasting)
        let message = "Recorded: \(Int(glucoseLevel)) mg/dL [\(level)]. \(advice)"
        
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - Quick Glucose Intent with Preset Values

struct QuickGlucoseIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Glucose Entry"
    static var description = IntentDescription("Record glucose with preset values")
    
    @Parameter(title: "Glucose Level", default: QuickGlucoseValue.normal120)
    var quickValue: QuickGlucoseValue
    
    static var parameterSummary: some ParameterSummary {
        Summary("Record quick glucose: \(\.$quickValue)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let recordIntent = RecordGlucoseIntent()
        recordIntent.glucoseLevel = quickValue.glucoseValue
        recordIntent.isFasting = false
        
        return try await recordIntent.perform()
    }
}

enum QuickGlucoseValue: String, AppEnum {
    case low65 = "low65"
    case normal90 = "normal90"
    case normal120 = "normal120"
    case elevated160 = "elevated160"
    case high220 = "high220"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Quick Glucose Values")
    
    static var caseDisplayRepresentations: [QuickGlucoseValue: DisplayRepresentation] = [
        .low65: "65 mg/dL (Low)",
        .normal90: "90 mg/dL (Normal)",
        .normal120: "120 mg/dL (Normal)",
        .elevated160: "160 mg/dL (Elevated)",
        .high220: "220 mg/dL (High)"
    ]
    
    var glucoseValue: Double {
        switch self {
        case .low65: return 65
        case .normal90: return 90
        case .normal120: return 120
        case .elevated160: return 160
        case .high220: return 220
        }
    }
}

// MARK: - Personalized Glucose Advice Intent

struct PersonalizedGlucoseAdviceIntent: AppIntent {
    static var title: LocalizedStringResource = "Analyze My Glucose Levels"
    static var description = IntentDescription("Provides personalized advice based on your current glucose readings")
    
    @Parameter(title: "Current Glucose (mg/dL)")
    var currentGlucose: Double?
    
    @Parameter(title: "Is this a fasting reading?")
    var isFasting: Bool
    
    @Parameter(title: "Time since last meal (hours)")
    var timeSinceLastMeal: Double?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Analyze glucose level of \(\.$currentGlucose) mg/dL")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthData = HealthIntents.loadHealthData()
        let glucose = currentGlucose ?? healthData.glucose
        
        if glucose == 0 {
            return .result(dialog: IntentDialog(stringLiteral: "Need your current glucose reading to provide advice."))
        }
        
        let (level, advice) = HealthIntents.analyzeGlucoseLevel(glucose, fasting: isFasting)
        let response = "Glucose: \(Int(glucose)) mg/dL [\(level)]. \(advice)"
        
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

// MARK: - Blood Pressure Analysis Intent

struct BloodPressureAdviceIntent: AppIntent {
    static var title: LocalizedStringResource = "Analyze Blood Pressure"
    static var description = IntentDescription("Provides personalized blood pressure analysis and recommendations")
    
    @Parameter(title: "Systolic Pressure (top number)")
    var systolic: Double?
    
    @Parameter(title: "Diastolic Pressure (bottom number)")
    var diastolic: Double?
    
    @Parameter(title: "Heart Rate (BPM)")
    var heartRate: Double?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Analyze BP reading \(\.$systolic)/\(\.$diastolic)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthData = HealthIntents.loadHealthData()
        let sys = systolic ?? healthData.systolicBP
        let dia = diastolic ?? healthData.diastolicBP
        
        if sys == 0 || dia == 0 {
            return .result(dialog: IntentDialog(stringLiteral: "Need blood pressure readings to provide analysis."))
        }
        
        let category: String
        let advice: String
        
        switch (sys, dia) {
        case (..<90, ..<60):
            category = "LOW"
            advice = "Stay hydrated and avoid sudden position changes."
        case (90..<120, 60..<80):
            category = "NORMAL"
            advice = "Maintain current lifestyle with regular exercise."
        case (120..<130, ..<80):
            category = "ELEVATED"
            advice = "Reduce sodium intake and increase exercise."
        case (130..<140, 80..<90):
            category = "STAGE 1 HTN"
            advice = "Lifestyle changes needed. Monitor daily."
        default:
            category = "STAGE 2 HTN"
            advice = "Contact healthcare provider immediately."
        }
        
        let response = "BP: \(Int(sys))/\(Int(dia)) mmHg [\(category)]. \(advice)"
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

// MARK: - Personalized Meal Advice Intent

struct PersonalizedMealAdviceIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Personalized Meal Advice"
    static var description = IntentDescription("Provides meal recommendations based on your health data")
    
    @Parameter(title: "Meal Type")
    var mealType: MealTypeEntity
    
    @Parameter(title: "Current Glucose Level (mg/dL)")
    var currentGlucose: Double?
    
    @Parameter(title: "How hungry are you? (1-10)")
    var hungerLevel: Int?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Plan my \(\.$mealType) meal")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthData = HealthIntents.loadHealthData()
        let glucose = currentGlucose ?? healthData.glucose
        let meal = mealType.mealType.lowercased()
        
        var advice: String
        
        if glucose > 180 {
            advice = "High glucose: avoid carbs. Focus on lean proteins and vegetables."
        } else if glucose < 70 {
            advice = "Low glucose: take 15g glucose tablets first, then recheck."
        } else {
            switch meal {
            case "breakfast":
                advice = "Try eggs with vegetables, Greek yogurt with nuts, or oatmeal with cinnamon."
            case "lunch":
                advice = "Consider grilled chicken salad, quinoa bowl, or turkey wrap."
            case "dinner":
                advice = "Light options: baked fish with vegetables or lean protein with salad."
            case "snack":
                advice = "Apple with almond butter, hummus with vegetables, or mixed nuts."
            default:
                advice = "Balance: 50% vegetables, 25% protein, 25% complex carbs."
            }
        }
        
        let response = "\(meal.capitalized) advice: \(advice)"
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

// MARK: - Activity Recommendation Intent

struct ActivityRecommendationIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Exercise Recommendations"
    static var description = IntentDescription("Provides safe exercise advice based on your current health status")
    
    @Parameter(title: "Current Glucose (mg/dL)")
    var currentGlucose: Double?
    
    @Parameter(title: "Energy Level (1-10)")
    var energyLevel: Int?
    
    @Parameter(title: "Available Time (minutes)")
    var availableTime: Int?
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthData = HealthIntents.loadHealthData()
        let glucose = currentGlucose ?? healthData.glucose
        let energy = energyLevel ?? 5
        let time = availableTime ?? 30
        
        // Safety checks
        if glucose < 70 {
            return .result(dialog: IntentDialog(stringLiteral: "Glucose too low (\(Int(glucose)) mg/dL). Treat first, then try gentle stretching only."))
        }
        
        if glucose > 250 {
            return .result(dialog: IntentDialog(stringLiteral: "Glucose too high (\(Int(glucose)) mg/dL). Light walking only, 10-15 minutes."))
        }
        
        // Exercise recommendations
        let recommendation: String
        switch (energy, time) {
        case (1...3, _):
            recommendation = "Low energy: 10-minute gentle walk or light stretching."
        case (4...6, 0...15):
            recommendation = "15-minute brisk walk or bodyweight exercises."
        case (4...6, 16...45):
            recommendation = "30-minute walk, bike ride, or resistance training."
        case (7...10, 0...30):
            recommendation = "20-minute HIIT session or circuit training."
        default:
            recommendation = "45-minute run, cycling, or full strength training."
        }
        
        return .result(dialog: IntentDialog(stringLiteral: "Exercise plan (\(time) min): \(recommendation) Carry glucose tablets."))
    }
}

// MARK: - BMI Analysis Intent

struct BMIAnalysisIntent: AppIntent {
    static var title: LocalizedStringResource = "Analyze My BMI"
    static var description = IntentDescription("Provides BMI analysis and weight management advice")
    
    @Parameter(title: "Current Weight (lbs)")
    var weight: Double?
    
    @Parameter(title: "Height (inches)")
    var height: Double?
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthData = HealthIntents.loadHealthData()
        let currentWeight = weight ?? healthData.weight
        let currentHeight = height ?? healthData.height
        
        if currentWeight == 0 || currentHeight == 0 {
            return .result(dialog: IntentDialog(stringLiteral: "Need current weight and height to calculate BMI."))
        }
        
        let bmi = (currentWeight / (currentHeight * currentHeight)) * 703
        
        let category: String
        let advice: String
        
        switch bmi {
        case ..<18.5:
            category = "UNDERWEIGHT"
            advice = "Focus on nutrient-dense, calorie-rich foods."
        case 18.5..<25:
            category = "NORMAL"
            advice = "Maintain current diet and exercise routine."
        case 25..<30:
            category = "OVERWEIGHT"
            advice = "Aim for 1-2 lbs/week loss through 500-calorie deficit."
        case 30..<35:
            category = "OBESITY CLASS I"
            advice = "Weight loss important. Consider healthcare provider guidance."
        default:
            category = "OBESITY CLASS II+"
            advice = "Consult healthcare provider about comprehensive weight management."
        }
        
        let response = "BMI: \(String(format: "%.1f", bmi)) [\(category)]. \(advice)"
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

// MARK: - Comprehensive Health Check Intent

struct ComprehensiveHealthCheckIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Health Analysis"
    static var description = IntentDescription("Provides a comprehensive overview of your health metrics and priorities")
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthData = HealthIntents.loadHealthData()
        var summary: [String] = []
        
        // Quick health checks
        if healthData.glucose > 0 {
            let status = healthData.glucose > 180 ? "HIGH" : healthData.glucose < 70 ? "LOW" : "NORMAL"
            summary.append("Glucose: \(Int(healthData.glucose)) mg/dL [\(status)]")
        }
        
        if healthData.systolicBP > 0 && healthData.diastolicBP > 0 {
            let status = healthData.systolicBP >= 140 ? "HIGH" : "NORMAL"
            summary.append("BP: \(Int(healthData.systolicBP))/\(Int(healthData.diastolicBP)) [\(status)]")
        }
        
        if healthData.weight > 0 && healthData.height > 0 {
            let bmi = (healthData.weight / (healthData.height * healthData.height)) * 703
            let status = bmi >= 30 ? "OBESE" : bmi >= 25 ? "OVERWEIGHT" : "NORMAL"
            summary.append("BMI: \(String(format: "%.1f", bmi)) [\(status)]")
        }
        
        if healthData.steps > 0 {
            let status = healthData.steps >= 10000 ? "EXCELLENT" : healthData.steps >= 7500 ? "GOOD" : "LOW"
            summary.append("Steps: \(Int(healthData.steps)) [\(status)]")
        }
        
        let response = summary.isEmpty ? "No health data available." : "Health Summary: " + summary.joined(separator: ", ")
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

// MARK: - Emergency Health Check Intent

struct EmergencyHealthCheckIntent: AppIntent {
    static var title: LocalizedStringResource = "Emergency Health Alert"
    static var description = IntentDescription("Checks for concerning health readings that may need immediate attention")
    
    @Parameter(title: "Current Glucose (mg/dL)")
    var currentGlucose: Double?
    
    @Parameter(title: "How are you feeling?")
    var symptoms: String?
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthData = HealthIntents.loadHealthData()
        let glucose = currentGlucose ?? healthData.glucose
        
        // Critical checks
        if glucose < 54 {
            return .result(dialog: IntentDialog(stringLiteral: "EMERGENCY: Severe low glucose (\(Int(glucose)) mg/dL). Call 911 immediately."))
        }
        
        if glucose > 400 {
            return .result(dialog: IntentDialog(stringLiteral: "EMERGENCY: Dangerously high glucose (\(Int(glucose)) mg/dL). Check ketones, call doctor, go to ER if ketones positive."))
        }
        
        if healthData.systolicBP > 180 || healthData.diastolicBP > 120 {
            return .result(dialog: IntentDialog(stringLiteral: "EMERGENCY: Hypertensive crisis. Call 911 immediately."))
        }
        
        // Warning levels
        if glucose < 70 {
            return .result(dialog: IntentDialog(stringLiteral: "WARNING: Low glucose (\(Int(glucose)) mg/dL). Take 15g glucose tablets, recheck in 15 minutes."))
        }
        
        if glucose > 250 {
            return .result(dialog: IntentDialog(stringLiteral: "WARNING: Very high glucose (\(Int(glucose)) mg/dL). Check ketones, increase fluids, contact healthcare provider."))
        }
        
        if healthData.systolicBP > 160 || healthData.diastolicBP > 100 {
            return .result(dialog: IntentDialog(stringLiteral: "WARNING: Severe hypertension. Contact healthcare provider today."))
        }
        
        // All clear
        return .result(dialog: IntentDialog(stringLiteral: "No immediate health concerns detected. Continue regular monitoring."))
    }
}

class HealthIntents {
    // Empty class to hold static methods
}
