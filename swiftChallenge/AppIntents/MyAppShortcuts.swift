//
//  MyAppShortcuts.swift
//  swiftChallenge
//
//  Created by Victoria Marin on 08/06/25.
//

import AppIntents

struct HealthAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
            AppShortcut(
                intent: PersonalizedGlucoseAdviceIntent(),
                phrases: [
                    "Check my glucose levels with ${applicationName}",
                    "Give me blood sugar advice with ${applicationName}",
                    "How are my glucose readings with ${applicationName}?",
                    "Help me manage my glucose with ${applicationName}",
                    "Analyze my blood sugar trends using ${applicationName}",
                    "What should I do about my glucose levels with ${applicationName}?"
                ],
                shortTitle: "Glucose Analysis",
                systemImageName: "drop.fill"
            );
            
            AppShortcut(
                intent: BloodPressureAdviceIntent(),
                phrases: [
                    "Check my blood pressure with ${applicationName}",
                    "Analyze my BP readings with ${applicationName}",
                    "Give me blood pressure advice using ${applicationName}",
                    "How is my cardiovascular health with ${applicationName}?",
                    "Help me understand my blood pressure with ${applicationName}",
                    "What should I know about my BP with ${applicationName}?"
                ],
                shortTitle: "Blood Pressure",
                systemImageName: "heart.circle"
            );
            
            AppShortcut(
                intent: PersonalizedMealAdviceIntent(),
                phrases: [
                    "What should I eat for \(\.$mealType) with ${applicationName}?",
                    "Give me meal advice based on my glucose with ${applicationName}",
                    "Help me plan my \(\.$mealType) using ${applicationName}",
                    "What foods are good for my health with ${applicationName}?",
                    "Recommend foods for my condition with ${applicationName}",
                    "Plan my next meal with ${applicationName}"
                ],
                shortTitle: "Meal Planning",
                systemImageName: "fork.knife.circle"
            );
            
            AppShortcut(
                intent: ActivityRecommendationIntent(),
                phrases: [
                    "What exercise should I do with ${applicationName}?",
                    "Give me activity advice based on my health with ${applicationName}",
                    "How much should I exercise with ${applicationName}?",
                    "Recommend workouts for my condition using ${applicationName}",
                    "Help me plan my exercise with ${applicationName}",
                    "What's safe for me to do with ${applicationName}?"
                ],
                shortTitle: "Exercise Plan",
                systemImageName: "figure.run"
            );
            
            AppShortcut(
                intent: BMIAnalysisIntent(),
                phrases: [
                    "Analyze my BMI with ${applicationName}",
                    "What does my BMI mean with ${applicationName}?",
                    "Give me weight advice with ${applicationName}",
                    "Help me understand my body metrics using ${applicationName}",
                    "Check my health status with ${applicationName}",
                    "What should I know about my weight with ${applicationName}?"
                ],
                shortTitle: "BMI Analysis",
                systemImageName: "scalemass.fill"
            );
            
            AppShortcut(
                intent: ComprehensiveHealthCheckIntent(),
                phrases: [
                    "Give me a complete health analysis with ${applicationName}",
                    "Check all my health metrics with ${applicationName}",
                    "Analyze my overall health using ${applicationName}",
                    "What should I focus on health-wise with ${applicationName}?",
                    "Give me my health summary with ${applicationName}",
                    "What are my health priorities with ${applicationName}?"
                ],
                shortTitle: "Health Overview",
                systemImageName: "medical.thermometer"
            );
            
            AppShortcut(
                intent: EmergencyHealthCheckIntent(),
                phrases: [
                    "Is my glucose level dangerous with ${applicationName}?",
                    "Check if my readings are concerning with ${applicationName}",
                    "Should I be worried about my health with ${applicationName}?",
                    "Are my levels normal with ${applicationName}?",
                    "Do I need medical attention with ${applicationName}?",
                    "Alert me about concerning readings with ${applicationName}"
                ],
                shortTitle: "Health Alert",
                systemImageName: "exclamationmark.triangle.fill"
            )
    }
}
