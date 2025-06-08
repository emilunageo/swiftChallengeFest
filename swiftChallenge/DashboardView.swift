//
//  DashboardView.swift
//  swiftChallenge
//
//  Created by Fatima Alonso on 6/7/25.
//

import SwiftUI
import Charts
import HealthKit

// MARK: - Models
typealias Timestamp = Date
struct GlucoseEntry: Identifiable {
    let id = UUID()
    let time: Timestamp
    let level: Double  // mg/dL
}



struct ActivityEntry: Identifiable {
    let id = UUID()
    let time: Timestamp
    let activity: Double
    
}

struct ExerciseSample: Identifiable {
    let id = UUID()
    let time: Date
    let minutes: Double
}

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f
}()






    

// MARK: - Main Dashboard View
struct DashboardView: View {
    // Datos de muestra internos
    private let glucoseData: [GlucoseEntry] = [
        .init(time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!, level: 110),
        .init(time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!, level: 95),
        .init(time: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!, level: 85),
        .init(time: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date())!, level: 88),
        .init(time: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!, level: 105)
    ]
    private let activityData: [ActivityEntry] = [
        .init(time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!, activity: 5),
        .init(time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!, activity: 30),
        .init(time: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!, activity: 45),
        .init(time: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date())!, activity: 15),
        .init(time: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!, activity: 5)
    ]
    
    private let exerciseData: [ExerciseSample] = [
        .init(time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!, minutes: 10),
        .init(time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!, minutes: 2),
        .init(time: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!, minutes: 15),
        .init(time: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date())!, minutes: 7),
        .init(time: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!, minutes: 12)
    ]

    private let lowThreshold = 70.0
    private let highThreshold = 170.0
    private let currentGlucose = 130.0
    
    private var maxGlucose: Double {
        glucoseData.map(\.level).max() ?? 0
    }
    
    private var minGlucose: Double {
        glucoseData.map(\.level).min() ?? 0
    }
    
    private var avgGlucose: Double {
        guard !glucoseData.isEmpty else {return 0}
        let sum = glucoseData.map(\.level).reduce(0,+)
        return sum / Double(glucoseData.count)
        
    }
    

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Glucose level")
                    .font(.headline)
                GlucoseGauge(current: currentGlucose,
                             minLevel: lowThreshold,
                             maxLevel: highThreshold)
                .frame(width: 150, height: 150)
                Divider()
            
                
                Text("Glucose vs Time")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                GlucoseTimeChart(data: glucoseData)
                    .padding(.horizontal, 20)
                    .frame(height: 200)
                Divider()
                Text("Glucose vs Physical Activity")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ExerciseSummaryCardView(data: exerciseData)


                

                
            }
            .padding()
        }
    }
}


// MARK: - Circular Gauge

struct GlucoseGauge: View {

    let current: Double
    let minLevel: Double
    let maxLevel: Double
    
    private var normalized: Double {
            let range = maxLevel - minLevel
            let val = current - minLevel
            return Swift.max(0, Swift.min(1, val / range))
        }
    
    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 20)
            Circle()
                .trim(from: 0, to: normalized)
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.green, .yellow, .orange, .red]), startPoint: .topLeading, endPoint: .bottomTrailing))
                  
                      

               
            VStack {
                Text("\(Int(current))").font(.title).bold()
                Text("mg/dL").font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Glucosa vs Tiempo Chart
struct GlucoseTimeChart: View {
    let data: [GlucoseEntry]
    var body: some View {
        Chart(data) { entry in
            LineMark(x: .value("Hora", entry.time), y: .value("Glucosa", entry.level))
                .interpolationMethod(.catmullRom).foregroundStyle(.red)
            PointMark(x: .value("Hora", entry.time), y: .value("Glucosa", entry.level))
                .foregroundStyle(.red)
        }
        .chartYScale(domain: 50...180)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { mark in
                AxisGridLine().foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
            }
        }
    }
}

// MARK: - Exercise Minutes
struct ExerciseSummaryCardView: View {
    let data: [ExerciseSample]
    @Environment(\.colorScheme) var colorScheme

    private var totalMinutes: Int {
        Int(data.map(\.minutes).reduce(0, +))
    }

    private func dayOnly(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private var dailyTotals: [(date: Date, minutes: Double)] {
        let grouped = Dictionary(grouping: data, by: { dayOnly($0.time) })
        return grouped.map { key, samples in
            (date: key, minutes: samples.map(\.minutes).reduce(0, +))
        }
        .sorted(by: { $0.date < $1.date })
    }

    private var weeklyAverage: Double {
        guard !dailyTotals.isEmpty else { return 0 }
        return dailyTotals.map(\.minutes).reduce(0, +) / Double(dailyTotals.count)
    }

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f
    }()

    // 🚀 Glucose Insight (simplified model)
    private var glucoseCorrelationText: String {
        // Fake comparison logic (replace with real glucose input if needed)
        let exerciseImpact = weeklyAverage
        if exerciseImpact >= 30 {
            return "Increased activity appears to lower glucose."
        } else if exerciseImpact >= 15 {
            return "Moderate activity has a stable effect on glucose."
        } else {
            return "Low exercise may be linked to higher glucose."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Exercise Minutes", systemImage: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline.bold())
                Spacer()
            }

            HStack(alignment: .top) {
                Text("\(totalMinutes) min")
                    .font(.system(size: 36, weight: .black, design: .default))
                    .foregroundColor(.primary)

                Spacer()

                Text(glucoseCorrelationText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140, alignment: .trailing)
            }
        }
        .padding(.horizontal)
    }
}





// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
            

