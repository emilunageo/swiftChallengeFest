//
//  WidgetGlucoseControl.swift
//  WidgetGlucose
//
//  Created by Victoria Marin on 08/06/25.
//
//
//  GlucoseControlWidget.swift
//  WidgetGlucose
//
//  Created by Victoria Marin on 08/06/25.
//
//
//  GlucoseControlWidget.swift
//  WidgetGlucose
//
//  Created by Victoria Marin on 08/06/25.
//

import AppIntents
import SwiftUI
import WidgetKit

struct GlucoseControlWidget: ControlWidget {
    static let kind: String = "vic.swiftChallenge.GlucoseControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: GlucoseProvider()
        ) { value in
            ControlWidgetButton(action: RecordGlucoseIntent()) {
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .foregroundColor(value.statusColor)
                        Text("\(Int(value.glucose))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(value.statusColor)
                    }
                    
                    Text(value.status)
                        .font(.caption2)
                        .foregroundColor(value.statusColor)
                        .lineLimit(1)
                }
            }
        }
        .displayName("Glucose Monitor")
        .description("Quick glucose level check and recording")
    }
}

extension GlucoseControlWidget {
    struct Value {
        var glucose: Double
        var status: String
        var statusColor: Color
        var lastUpdated: Date
        
        init(glucose: Double = 100) {
            self.glucose = glucose
            self.lastUpdated = Date()
            
            // Determine status and color based on glucose level
            switch glucose {
            case 0..<70:
                self.status = "LOW"
                self.statusColor = .red
            case 70..<140:
                self.status = "NORMAL"
                self.statusColor = .green
            case 140..<200:
                self.status = "HIGH"
                self.statusColor = .orange
            default:
                self.status = "CRITICAL"
                self.statusColor = .red
            }
        }
    }

    struct GlucoseProvider: AppIntentControlValueProvider {
        func previewValue(configuration: GlucoseConfiguration) -> Value {
            GlucoseControlWidget.Value(glucose: 120)
        }

        func currentValue(configuration: GlucoseConfiguration) async throws -> Value {
            let glucoseData = loadCurrentGlucose()
            return GlucoseControlWidget.Value(glucose: glucoseData.glucose)
        }
        
        private func loadCurrentGlucose() -> (glucose: Double, lastUpdated: Date) {
            let possibleSuiteNames = [
                "group.com.victoria.health",
                "group.com.tuApp.health-data",
                nil
            ]
            
            for suiteName in possibleSuiteNames {
                let userDefaults = suiteName != nil ? UserDefaults(suiteName: suiteName!) : UserDefaults.standard
                
                let glucose = userDefaults?.double(forKey: "currentGlucose") ?? 0
                let lastUpdated = userDefaults?.object(forKey: "glucoseLastUpdated") as? Date ?? Date()
                
                if glucose > 0 {
                    return (glucose, lastUpdated)
                }
            }
            
            return (100, Date()) // Default safe value
        }
    }
}

struct GlucoseConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Glucose Monitor Configuration"

    @Parameter(title: "Monitor Name", default: "My Glucose")
    var monitorName: String
}
