//
//  HealthIntents.swift
//  swiftChallenge
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
                advice = "Your glucose is dangerously low. Consume 15g of fast-acting carbs immediately (glucose tablets, juice, or candy). Recheck in 15 minutes."
            case 70..<100:
                level = "NORMAL"
                advice = "Your fasting glucose is in the normal range. Maintain your current diet and exercise routine."
            case 100..<126:
                level = "PREDIABETIC"
                advice = "Your fasting glucose indicates prediabetes. Focus on low-carb meals, increase physical activity, and consider consulting your doctor."
            default:
                level = "DIABETIC"
                advice = "Your fasting glucose is in the diabetic range. Monitor closely, follow your medication schedule, and avoid high-carb foods."
            }
        } else {
            switch glucose {
            case 0..<70:
                level = "LOW"
                advice = "Your glucose is low. Have a small snack with carbs and protein. Avoid strenuous exercise until levels normalize."
            case 70..<140:
                level = "NORMAL"
                advice = "Your glucose level is normal. You can proceed with regular activities and meals."
            case 140..<200:
                level = "ELEVATED"
                advice = "Your glucose is elevated. Consider light exercise like walking, avoid additional carbs, and drink water."
            default:
                level = "HIGH"
                advice = "Your glucose is high. Check ketones if possible, take medication as prescribed, and contact your healthcare provider if it doesn't improve."
            }
        }
        
        return (level, advice)
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
            return .result(dialog: IntentDialog(stringLiteral: "I need your current glucose reading to provide personalized advice. Please check your blood sugar and try again."))
        }
        
        let (level, advice) = HealthIntents.analyzeGlucoseLevel(glucose, fasting: isFasting)
        
        var response = "🩸 Glucose: \(Int(glucose)) mg/dL [\(level)]\n\n📋 Immediate Action: \(advice)"
        
        // Add context-specific advice based on HbA1c if available
        if healthData.hbA1c > 0 {
            if healthData.hbA1c >= 7.0 {
                response += "\n\n⚠️ Note: Your HbA1c of \(String(format: "%.1f", healthData.hbA1c))% indicates need for better long-term control. Focus on consistent monitoring and medication adherence."
            } else {
                response += "\n\n✅ Your HbA1c of \(String(format: "%.1f", healthData.hbA1c))% shows good long-term control. Keep up your current management strategy."
            }
        }
        
        // Add timing-specific advice
        if let hours = timeSinceLastMeal {
            if hours < 2 && glucose > 180 {
                response += "\n\n🍽️ Since it's only \(String(format: "%.1f", hours)) hours after eating, this elevation may be normal post-meal spike."
            } else if hours > 4 && glucose > 140 {
                response += "\n\n⏰ It's been \(String(format: "%.1f", hours)) hours since eating - this reading suggests checking your basal insulin or long-acting medication."
            }
        }
        
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
        let hr = heartRate ?? healthData.heartRate
        
        if sys == 0 || dia == 0 {
            return .result(dialog: IntentDialog(stringLiteral: "I need your blood pressure readings to provide analysis. Please take a reading and try again."))
        }
        
        let category: String
        let advice: String
        
        switch (sys, dia) {
        case (..<90, ..<60):
            category = "LOW (Hypotensive)"
            advice = "Your BP is low. Stay hydrated, avoid sudden position changes, and consider eating something salty. If you feel dizzy or faint, sit down immediately."
        case (90..<120, 60..<80):
            category = "NORMAL"
            advice = "Excellent! Your blood pressure is in the optimal range. Maintain your current lifestyle with regular exercise and healthy diet."
        case (120..<130, ..<80):
            category = "ELEVATED"
            advice = "Your BP is elevated. Focus on reducing sodium intake, increase potassium-rich foods, practice stress management, and aim for 150 minutes of exercise weekly."
        case (130..<140, 80..<90):
            category = "STAGE 1 HYPERTENSION"
            advice = "You have Stage 1 hypertension. Implement lifestyle changes immediately: reduce sodium to <2300mg/day, exercise regularly, limit alcohol, and monitor daily."
        default:
            category = "STAGE 2 HYPERTENSION"
            advice = "You have Stage 2 hypertension. This requires immediate attention. Contact your healthcare provider today to discuss medication options."
        }
        
        var response = "🫀 Blood Pressure: \(Int(sys))/\(Int(dia)) mmHg [\(category)]"
        
        if hr > 0 {
            let hrStatus = hr > 100 ? "ELEVATED" : hr < 60 ? "LOW" : "NORMAL"
            response += "\n💓 Heart Rate: \(Int(hr)) BPM [\(hrStatus)]"
        }
        
        response += "\n\n📋 Recommendation: \(advice)"
        
        // Add personalized advice based on glucose levels if diabetic
        if healthData.glucose > 126 || healthData.hbA1c > 6.5 {
            response += "\n\n🩸 Diabetes Note: As someone with diabetes, keeping BP <130/80 is crucial to prevent complications. Consider ACE inhibitors if prescribed."
        }
        
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
        
        var response = "🍽️ \(meal.capitalized) Recommendations:\n\n"
        
        // Glucose-based recommendations
        if glucose > 180 {
            response += "⚠️ High Glucose Alert: Avoid carbs this meal. Focus on:\n"
            response += "• Lean proteins (chicken, fish, tofu)\n"
            response += "• Non-starchy vegetables (spinach, broccoli, cucumbers)\n"
            response += "• Healthy fats (avocado, nuts, olive oil)\n"
            response += "• Drink plenty of water\n\n"
        } else if glucose < 70 {
            response += "🚨 Low Glucose: You need fast-acting carbs:\n"
            response += "• 15g glucose tablets or\n"
            response += "• 4oz fruit juice or\n"
            response += "• 3-4 glucose gummies\n"
            response += "• Wait 15 minutes, then recheck glucose\n\n"
        } else {
            // Normal glucose - provide meal-specific advice
            switch meal {
            case "breakfast":
                response += "🌅 Good morning! Your glucose is stable. Try:\n"
                response += "• 2 eggs with spinach and 1 slice whole grain toast\n"
                response += "• Greek yogurt with berries and nuts\n"
                response += "• Oatmeal with cinnamon and almonds\n"
            case "lunch":
                response += "☀️ Midday fuel needed. Consider:\n"
                response += "• Grilled chicken salad with olive oil dressing\n"
                response += "• Quinoa bowl with vegetables and beans\n"
                response += "• Turkey and avocado wrap (whole wheat)\n"
            case "dinner":
                response += "🌙 Evening nutrition. Light options:\n"
                response += "• Baked salmon with roasted vegetables\n"
                response += "• Vegetable stir-fry with tofu\n"
                response += "• Lean beef with cauliflower mash\n"
            case "snack":
                response += "🥜 Smart snacking:\n"
                response += "• Apple slices with almond butter\n"
                response += "• Hummus with vegetable sticks\n"
                response += "• Handful of mixed nuts\n"
            default:
                response += "• Focus on balanced portions: 50% vegetables, 25% protein, 25% complex carbs\n"
            }
        }
        
        // Add BMI-based advice
        if healthData.bmi > 25 {
            response += "\n⚖️ Weight Management Tip: Control portions, eat slowly, and include protein with every meal to stay satisfied longer."
        }
        
        // Add BP-based advice
        if healthData.systolicBP > 130 {
            response += "\n🧂 Blood Pressure Note: Keep sodium under 2300mg today. Avoid processed foods and add herbs instead of salt."
        }
        
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
        
        var response = "🏃‍♀️ Exercise Plan (\(time) minutes):\n\n"
        
        // Safety check for glucose levels
        if glucose < 70 {
            response += "🚫 STOP: Glucose too low for exercise (\(Int(glucose)) mg/dL)\n"
            response += "• Treat low glucose first\n"
            response += "• Wait until glucose >100 mg/dL\n"
            response += "• Then try gentle stretching only\n"
            return .result(dialog: IntentDialog(stringLiteral: response))
        }
        
        if glucose > 250 {
            response += "⚠️ Glucose too high for intense exercise (\(Int(glucose)) mg/dL)\n"
            response += "• Light walking only (10-15 minutes)\n"
            response += "• Check for ketones if possible\n"
            response += "• Hydrate well and monitor glucose\n"
            return .result(dialog: IntentDialog(stringLiteral: response))
        }
        
        // Exercise recommendations based on glucose range
        if glucose >= 100 && glucose <= 180 {
            response += "✅ Glucose optimal for exercise (\(Int(glucose)) mg/dL)\n\n"
            
            switch (energy, time) {
            case (1...3, _):
                response += "💤 Low energy detected:\n"
                response += "• 10-minute gentle walk\n"
                response += "• Light stretching routine\n"
                response += "• Breathing exercises\n"
            case (4...6, 0...15):
                response += "⚡ Moderate energy, short time:\n"
                response += "• 15-minute brisk walk\n"
                response += "• Bodyweight exercises (squats, push-ups)\n"
                response += "• Yoga flow\n"
            case (4...6, 16...45):
                response += "⚡ Moderate energy routine:\n"
                response += "• 30-minute walk or bike ride\n"
                response += "• Resistance training (20 min)\n"
                response += "• Swimming laps\n"
            case (7...10, 0...30):
                response += "🔥 High energy, quick workout:\n"
                response += "• 20-minute HIIT session\n"
                response += "• Circuit training\n"
                response += "• Intense bike ride\n"
            default:
                response += "🔥 High energy, extended workout:\n"
                response += "• 45-minute run or cycling\n"
                response += "• Full strength training session\n"
                response += "• Sports activities\n"
            }
        } else if glucose > 180 {
            response += "📈 Elevated glucose (\(Int(glucose)) mg/dL) - Light activity recommended:\n"
            response += "• 20-30 minute walk (can help lower glucose)\n"
            response += "• Gentle yoga\n"
            response += "• Light household activities\n"
        }
        
        // Add safety reminders
        response += "\n🛡️ Safety Reminders:\n"
        response += "• Check glucose before and after exercise\n"
        response += "• Carry glucose tablets\n"
        response += "• Stay hydrated\n"
        
        // Blood pressure considerations
        if healthData.systolicBP > 140 {
            response += "• Avoid heavy lifting due to elevated BP\n"
            response += "• Focus on moderate cardio\n"
        }
        
        return .result(dialog: IntentDialog(stringLiteral: response))
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
            return .result(dialog: IntentDialog(stringLiteral: "I need your current weight and height to calculate BMI. Please provide these measurements."))
        }
        
        let bmi = (currentWeight / (currentHeight * currentHeight)) * 703
        
        let category: String
        let advice: String
        
        switch bmi {
        case ..<18.5:
            category = "UNDERWEIGHT"
            advice = "Focus on nutrient-dense, calorie-rich foods. Add healthy fats like nuts, avocados, and olive oil. Consider consulting a nutritionist."
        case 18.5..<25:
            category = "NORMAL WEIGHT"
            advice = "Great job maintaining a healthy weight! Continue your current diet and exercise routine. Focus on muscle maintenance."
        case 25..<30:
            category = "OVERWEIGHT"
            advice = "Aim to lose 1-2 lbs per week through a 500-calorie daily deficit. Increase physical activity and focus on portion control."
        case 30..<35:
            category = "OBESITY CLASS I"
            advice = "Weight loss is important for your health. Consider working with a healthcare provider. Focus on sustainable lifestyle changes."
        case 35..<40:
            category = "OBESITY CLASS II"
            advice = "Significant weight loss needed. Consult with healthcare providers about comprehensive weight management programs."
        default:
            category = "OBESITY CLASS III"
            advice = "Immediate medical consultation recommended. Consider all available treatments including behavioral, medical, and surgical options."
        }
        
        var response = "⚖️ BMI Analysis:\n"
        response += "• Current BMI: \(String(format: "%.1f", bmi)) [\(category)]\n"
        response += "• Weight: \(String(format: "%.1f", currentWeight)) lbs\n"
        response += "• Height: \(String(format: "%.1f", currentHeight)) inches\n\n"
        response += "📋 Recommendation: \(advice)\n\n"
        
        // Add diabetes-specific advice
        if healthData.glucose > 126 || healthData.hbA1c > 6.5 {
            if bmi >= 25 {
                response += "🩸 Diabetes Note: Losing just 5-10% of body weight can significantly improve blood sugar control. Even small changes make a big difference."
            } else {
                response += "🩸 Diabetes Note: Your healthy weight is great for blood sugar management. Focus on maintaining muscle mass through strength training."
            }
        }
        
        // Add realistic targets
        if bmi >= 25 {
            let targetWeight = (currentHeight * currentHeight * 24.9) / 703
            let weightToLose = currentWeight - targetWeight
            response += "\n🎯 Target: Healthy BMI range would be around \(String(format: "%.0f", targetWeight)) lbs (loss of \(String(format: "%.0f", weightToLose)) lbs)"
        }
        
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

// MARK: - Comprehensive Health Check Intent

struct ComprehensiveHealthCheckIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Health Analysis"
    static var description = IntentDescription("Provides a comprehensive overview of your health metrics and priorities")
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthData = HealthIntents.loadHealthData()
        
        var response = "📊 COMPREHENSIVE HEALTH REPORT\n\n"
        var priorities: [String] = []
        var strengths: [String] = []
        
        // Glucose Analysis
        if healthData.glucose > 0 {
            response += "🩸 GLUCOSE MANAGEMENT:\n"
            if healthData.glucose > 180 {
                response += "• Current: \(String(format: "%.0f", healthData.glucose)) mg/dL [HIGH]\n"
                priorities.append("Lower blood glucose immediately")
            } else if healthData.glucose < 70 {
                response += "• Current: \(String(format: "%.0f", healthData.glucose)) mg/dL [LOW]\n"
                priorities.append("Treat low blood sugar")
            } else {
                response += "• Current: \(String(format: "%.0f", healthData.glucose)) mg/dL [GOOD]\n"
                strengths.append("Blood glucose in target range")
            }
            
            if healthData.hbA1c > 0 {
                if healthData.hbA1c >= 7.0 {
                    response += "• HbA1c: \(String(format: "%.1f", healthData.hbA1c))% [NEEDS IMPROVEMENT]\n"
                    priorities.append("Improve long-term glucose control")
                } else {
                    response += "• HbA1c: \(String(format: "%.1f", healthData.hbA1c))% [EXCELLENT]\n"
                    strengths.append("Great long-term glucose control")
                }
            }
            response += "\n"
        }
        
        // Blood Pressure Analysis
        if healthData.systolicBP > 0 && healthData.diastolicBP > 0 {
            response += "🫀 CARDIOVASCULAR HEALTH:\n"
            response += "• BP: \(String(format: "%.0f", healthData.systolicBP))/\(String(format: "%.0f", healthData.diastolicBP)) mmHg"
            
            if healthData.systolicBP >= 140 || healthData.diastolicBP >= 90 {
                response += " [HIGH]\n"
                priorities.append("Control blood pressure")
            } else if healthData.systolicBP >= 130 || healthData.diastolicBP >= 80 {
                response += " [ELEVATED]\n"
                priorities.append("Monitor blood pressure closely")
            } else {
                response += " [GOOD]\n"
                strengths.append("Healthy blood pressure")
            }
            
            if healthData.heartRate > 0 {
                if healthData.heartRate > 100 {
                    response += "• Heart Rate: \(String(format: "%.0f", healthData.heartRate)) BPM [HIGH]\n"
                } else if healthData.heartRate < 60 {
                    response += "• Heart Rate: \(String(format: "%.0f", healthData.heartRate)) BPM [LOW]\n"
                } else {
                    response += "• Heart Rate: \(String(format: "%.0f", healthData.heartRate)) BPM [NORMAL]\n"
                }
            }
            response += "\n"
        }
        
        // BMI Analysis
        if healthData.weight > 0 && healthData.height > 0 {
            let bmi = (healthData.weight / (healthData.height * healthData.height)) * 703
            response += "⚖️ WEIGHT MANAGEMENT:\n"
            response += "• BMI: \(String(format: "%.1f", bmi))"
            
            if bmi >= 30 {
                response += " [OBESE]\n"
                priorities.append("Significant weight loss needed")
            } else if bmi >= 25 {
                response += " [OVERWEIGHT]\n"
                priorities.append("Gradual weight loss beneficial")
            } else if bmi < 18.5 {
                response += " [UNDERWEIGHT]\n"
                priorities.append("Healthy weight gain needed")
            } else {
                response += " [HEALTHY]\n"
                strengths.append("Maintaining healthy weight")
            }
            response += "\n"
        }
        
        // Activity Analysis
        if healthData.steps > 0 {
            response += "🚶‍♀️ PHYSICAL ACTIVITY:\n"
            response += "• Daily Steps: \(String(format: "%.0f", healthData.steps))"
            
            if healthData.steps >= 10000 {
                response += " [EXCELLENT]\n"
                strengths.append("Meeting step goals")
            } else if healthData.steps >= 7500 {
                response += " [GOOD]\n"
            } else {
                response += " [NEEDS IMPROVEMENT]\n"
                priorities.append("Increase daily physical activity")
            }
            
            if healthData.activeCalories > 0 {
                response += "• Active Calories: \(String(format: "%.0f", healthData.activeCalories))\n"
            }
            response += "\n"
        }
        
        // Priority Actions
        if !priorities.isEmpty {
            response += "🎯 TOP PRIORITIES:\n"
            for (index, priority) in priorities.enumerated() {
                response += "\(index + 1). \(priority)\n"
            }
            response += "\n"
        }
        
        // Strengths
        if !strengths.isEmpty {
            response += "✅ HEALTH STRENGTHS:\n"
            for strength in strengths {
                response += "• \(strength)\n"
            }
            response += "\n"
        }
        
        // General recommendations
        response += "📋 DAILY FOCUS:\n"
        response += "• Monitor glucose 4x daily\n"
        response += "• Take medications as prescribed\n"
        response += "• Eat balanced meals with controlled portions\n"
        response += "• Stay hydrated (8+ glasses water)\n"
        response += "• Get 7-9 hours quality sleep\n"
        response += "• Manage stress through relaxation techniques\n"
        
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
        
        var alerts: [String] = []
        var emergencyLevel = 0
        
        // Critical glucose levels
        if glucose > 0 {
            if glucose < 54 {
                alerts.append("🚨 SEVERE LOW GLUCOSE (\(Int(glucose)) mg/dL)")
                alerts.append("IMMEDIATE ACTION: Call 911 or have someone drive you to ER")
                emergencyLevel = 3
            } else if glucose < 70 {
                alerts.append("⚠️ LOW GLUCOSE (\(Int(glucose)) mg/dL)")
                alerts.append("ACTION: Treat with 15g fast carbs, recheck in 15 min")
                if emergencyLevel < 2 { emergencyLevel = 2 }
            } else if glucose > 400 {
                alerts.append("🚨 DANGEROUSLY HIGH GLUCOSE (\(Int(glucose)) mg/dL)")
                alerts.append("IMMEDIATE ACTION: Check ketones, call doctor, go to ER if ketones positive")
                emergencyLevel = 3
            } else if glucose > 250 {
                alerts.append("⚠️ VERY HIGH GLUCOSE (\(Int(glucose)) mg/dL)")
                alerts.append("ACTION: Check ketones, increase fluids, contact healthcare provider")
                if emergencyLevel < 2 { emergencyLevel = 2 }
            }
        }
        
        // Critical blood pressure
        if healthData.systolicBP > 180 || healthData.diastolicBP > 120 {
            alerts.append("🚨 HYPERTENSIVE CRISIS")
            alerts.append("IMMEDIATE ACTION: Call 911 - this is a medical emergency")
            emergencyLevel = 3
        } else if healthData.systolicBP > 160 || healthData.diastolicBP > 100 {
            alerts.append("⚠️ SEVERE HYPERTENSION")
            alerts.append("ACTION: Contact healthcare provider today")
            if emergencyLevel < 2 { emergencyLevel = 2 }
        }
        
        // Dangerous heart rate
        if healthData.heartRate > 150 {
            alerts.append("🚨 DANGEROUS HEART RATE (\(Int(healthData.heartRate)) BPM)")
            alerts.append("IMMEDIATE ACTION: Stop all activity, call 911 if persistent")
            emergencyLevel = 3
        } else if healthData.heartRate < 40 {
            alerts.append("🚨 DANGEROUSLY LOW HEART RATE (\(Int(healthData.heartRate)) BPM)")
            alerts.append("IMMEDIATE ACTION: Seek emergency medical care")
            emergencyLevel = 3
        }
        
        // Symptom analysis
        if let symptoms = symptoms?.lowercased() {
            let dangerSymptoms = ["chest pain", "shortness of breath", "severe headache", "confusion", "vomiting", "seizure", "unconscious"]
            let concerningSymptoms = ["dizzy", "nauseous", "weak", "blurred vision", "rapid heartbeat"]
            
            for symptom in dangerSymptoms {
                if symptoms.contains(symptom) {
                    alerts.append("🚨 DANGEROUS SYMPTOM DETECTED: \(symptom)")
                    alerts.append("IMMEDIATE ACTION: Call 911 now")
                    emergencyLevel = 3
                    break
                }
            }
            
            if emergencyLevel < 3 {
                for symptom in concerningSymptoms {
                    if symptoms.contains(symptom) {
                        alerts.append("⚠️ Concerning symptom: \(symptom)")
                        if emergencyLevel < 1 { emergencyLevel = 1 }
                    }
                }
            }
        }
        
        // Generate response based on emergency level
        var response: String
        
        switch emergencyLevel {
        case 3:
            response = "🚨 MEDICAL EMERGENCY DETECTED\n\n"
            response += alerts.joined(separator: "\n")
            response += "\n\n📞 CALL 911 IMMEDIATELY"
            response += "\n\nDo not drive yourself. Have someone else drive or call ambulance."
        case 2:
            response = "⚠️ URGENT MEDICAL ATTENTION NEEDED\n\n"
            response += alerts.joined(separator: "\n")
            response += "\n\n📞 Contact your healthcare provider immediately"
            response += "\nIf unavailable, consider urgent care or ER"
        case 1:
            response = "⚠️ HEALTH CONCERN DETECTED\n\n"
            response += alerts.joined(separator: "\n")
            response += "\n\n📞 Monitor closely and contact healthcare provider if symptoms worsen"
        default:
            response = "✅ NO IMMEDIATE HEALTH CONCERNS DETECTED\n\n"
            
            if glucose > 0 && glucose >= 70 && glucose <= 180 {
                response += "• Glucose: \(Int(glucose)) mg/dL [SAFE RANGE]\n"
            }
            
            if healthData.systolicBP > 0 && healthData.systolicBP < 140 {
                response += "• Blood Pressure: Normal range\n"
            }
            
            if healthData.heartRate > 0 && healthData.heartRate >= 60 && healthData.heartRate <= 100 {
                response += "• Heart Rate: Normal range\n"
            }
            
            response += "\nContinue regular monitoring and maintain healthy habits."
        }
        
        return .result(dialog: IntentDialog(stringLiteral: response))
    }
}

class HealthIntents {
    // Empty class to hold static methods
}
