//
//  WidgetGlucose.swift
//  WidgetGlucose
//
//  Created by Victoria Marin on 08/06/25.
//
//
//  GlucoseWidget.swift
//  health-app
//
//  Created by Victoria Marin on 08/06/25.
//
//
//  GlucoseWidget.swift
//  health-app
//
//  Created by Victoria Marin on 08/06/25.
//

import WidgetKit
import SwiftUI

// MARK: - Data Models

struct GlucoseEntry: TimelineEntry {
    let date: Date
    let glucose: Double
    let status: GlucoseStatus
    let lastUpdated: Date
    let trend: GlucoseTrend
}

enum GlucoseStatus {
    case low, normal, elevated, high, critical
    
    var color: Color {
        switch self {
        case .low, .critical: return .red
        case .normal: return .green
        case .elevated: return .orange
        case .high: return .red
        }
    }
    
    var statusText: String {
        switch self {
        case .low: return "LOW"
        case .normal: return "NORMAL"
        case .elevated: return "ELEVATED"
        case .high: return "HIGH"
        case .critical: return "CRITICAL"
        }
    }
    
    var advice: String {
        switch self {
        case .low: return "Take fast-acting carbs"
        case .normal: return "Keep up the good work"
        case .elevated: return "Light exercise recommended"
        case .high: return "Check ketones, take medication"
        case .critical: return "Seek immediate medical help"
        }
    }
}

enum GlucoseTrend {
    case rising, stable, falling
    
    var symbol: String {
        switch self {
        case .rising: return "↗"
        case .stable: return "→"
        case .falling: return "↘"
        }
    }
}

// MARK: - Timeline Provider

struct GlucoseProvider: TimelineProvider {
    func placeholder(in context: Context) -> GlucoseEntry {
        GlucoseEntry(
            date: Date(),
            glucose: 120,
            status: .normal,
            lastUpdated: Date(),
            trend: .stable
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (GlucoseEntry) -> ()) {
        let entry = loadCurrentGlucoseData()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentEntry = loadCurrentGlucoseData()
        
        // Refresh every 15 minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdateDate))
        
        completion(timeline)
    }
    
    private func loadCurrentGlucoseData() -> GlucoseEntry {
        // Load from UserDefaults (similar to your existing health data loading)
        let possibleSuiteNames = [
            "group.com.victoria.health",
            "group.com.tuApp.health-data",
            nil
        ]
        
        var glucose: Double = 0
        var lastUpdated = Date()
        
        for suiteName in possibleSuiteNames {
            let userDefaults = suiteName != nil ? UserDefaults(suiteName: suiteName!) : UserDefaults.standard
            
            glucose = userDefaults?.double(forKey: "currentGlucose") ?? 0
            if let updateTime = userDefaults?.object(forKey: "glucoseLastUpdated") as? Date {
                lastUpdated = updateTime
            }
            
            if glucose > 0 {
                break
            }
        }
        
        // Default values if no data found
        if glucose == 0 {
            glucose = 100 // Default safe value
        }
        
        let status = determineGlucoseStatus(glucose)
        let trend = GlucoseTrend.stable // Could be enhanced to track trends
        
        return GlucoseEntry(
            date: Date(),
            glucose: glucose,
            status: status,
            lastUpdated: lastUpdated,
            trend: trend
        )
    }
    
    private func determineGlucoseStatus(_ glucose: Double) -> GlucoseStatus {
        switch glucose {
        case 0..<54: return .critical
        case 54..<70: return .low
        case 70..<140: return .normal
        case 140..<200: return .elevated
        case 200..<300: return .high
        default: return .critical
        }
    }
}

// MARK: - Widget Views

struct GlucoseWidgetEntryView: View {
    var entry: GlucoseProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallGlucoseWidget(entry: entry)
        case .systemMedium:
            MediumGlucoseWidget(entry: entry)
        case .systemLarge:
            LargeGlucoseWidget(entry: entry)
        default:
            SmallGlucoseWidget(entry: entry)
        }
    }
}

// MARK: - Small Widget (2x2)

struct SmallGlucoseWidget: View {
    let entry: GlucoseEntry
    
    var body: some View {
        VStack(spacing: 4) {
            // Apple image at top
            Image("manzana-real copy") // Your uploaded apple image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
            
            // Glucose value
            Text("\(Int(entry.glucose))")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(entry.status.color)
            
            Text("mg/dL")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Status
            Text(entry.status.statusText)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(entry.status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(entry.status.color.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(8)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [entry.status.color.opacity(0.1), entry.status.color.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Medium Widget (4x2)

struct MediumGlucoseWidget: View {
    let entry: GlucoseEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Apple and main info
            VStack(spacing: 8) {
                Image("manzana-real copy")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                
                VStack(spacing: 2) {
                    Text("\(Int(entry.glucose))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(entry.status.color)
                    
                    Text("mg/dL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(entry.status.statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.status.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(entry.status.color.opacity(0.2))
                    .cornerRadius(10)
            }
            
            // Right side - Additional info
            VStack(alignment: .leading, spacing: 8) {
                // Trend
                HStack {
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(entry.trend.symbol)
                        .font(.title2)
                        .foregroundColor(entry.status.color)
                }
                
                Divider()
                
                // Last updated
                VStack(alignment: .leading, spacing: 2) {
                    Text("Updated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(timeAgoString(from: entry.lastUpdated))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Divider()
                
                // Quick advice
                Text(entry.status.advice)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    entry.status.color.opacity(0.05),
                    entry.status.color.opacity(0.15),
                    entry.status.color.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Large Widget (4x4)

struct LargeGlucoseWidget: View {
    let entry: GlucoseEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with apple and title
            HStack {
                Image("manzana-real copy")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                
                Text("Glucose Monitor")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(entry.trend.symbol)
                    .font(.title)
                    .foregroundColor(entry.status.color)
            }
            
            // Main glucose display
            VStack(spacing: 8) {
                Text("\(Int(entry.glucose))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(entry.status.color)
                
                Text("mg/dL")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text(entry.status.statusText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.status.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(entry.status.color.opacity(0.2))
                    .cornerRadius(12)
            }
            
            // Glucose range indicator
            GlucoseRangeView(currentGlucose: entry.glucose, status: entry.status)
            
            // Bottom info section
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Last Updated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(timeAgoString(from: entry.lastUpdated))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Target Range")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("70-140 mg/dL")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                // Advice
                Text(entry.status.advice)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    entry.status.color.opacity(0.03),
                    entry.status.color.opacity(0.08),
                    entry.status.color.opacity(0.15),
                    entry.status.color.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Glucose Range Indicator

struct GlucoseRangeView: View {
    let currentGlucose: Double
    let status: GlucoseStatus
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Range Indicator")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                // Gradient track showing ranges
                HStack(spacing: 0) {
                    // Low range (0-70)
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 70)
                    
                    // Normal range (70-140)
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 70)
                    
                    // Elevated range (140-200)
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 60)
                    
                    // High range (200+)
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 50)
                }
                .cornerRadius(4)
                .clipped()
                
                // Current glucose indicator
                Circle()
                    .fill(status.color)
                    .frame(width: 12, height: 12)
                    .offset(x: glucosePosition(currentGlucose))
            }
            .frame(maxWidth: 250)
        }
    }
    
    private func glucosePosition(_ glucose: Double) -> CGFloat {
        let maxWidth: CGFloat = 250
        let position = min(max(glucose / 300.0, 0), 1) * maxWidth
        return position - 6 // Center the circle
    }
}

// MARK: - Helper Functions

private func timeAgoString(from date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    let minutes = Int(interval / 60)
    
    if minutes < 1 {
        return "Just now"
    } else if minutes < 60 {
        return "\(minutes)m ago"
    } else {
        let hours = minutes / 60
        return "\(hours)h ago"
    }
}

// MARK: - Widget Configuration

struct GlucoseWidget: Widget {
    let kind: String = "GlucoseWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GlucoseProvider()) { entry in
            GlucoseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Glucose Monitor")
        .description("Keep track of your glucose levels at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

struct GlucoseWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small widget preview
            GlucoseWidgetEntryView(entry: GlucoseEntry(
                date: Date(),
                glucose: 125,
                status: .normal,
                lastUpdated: Date().addingTimeInterval(-900), // 15 minutes ago
                trend: .stable
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small - Normal")
            
            // Medium widget preview
            GlucoseWidgetEntryView(entry: GlucoseEntry(
                date: Date(),
                glucose: 180,
                status: .elevated,
                lastUpdated: Date().addingTimeInterval(-600), // 10 minutes ago
                trend: .rising
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium - Elevated")
            
            // Large widget preview
            GlucoseWidgetEntryView(entry: GlucoseEntry(
                date: Date(),
                glucose: 65,
                status: .low,
                lastUpdated: Date().addingTimeInterval(-300), // 5 minutes ago
                trend: .falling
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large - Low")
        }
    }
}
