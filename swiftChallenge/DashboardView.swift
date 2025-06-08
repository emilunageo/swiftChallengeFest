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

struct GlucoseActivityCorrelation: Identifiable {
    let id = UUID()
    let time: Date
    let glucose: Double
    let activity: Double
}

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f
}()

// MARK: - Main Dashboard View
struct DashboardView: View {
    // HealthKit
    private let healthStore = HKHealthStore()
    
    // Estado para los datos
    @State private var glucoseData: [GlucoseEntry] = []
    @State private var activityData: [ActivityEntry] = []
    @State private var exerciseData: [ExerciseSample] = []
    @State private var correlationData: [GlucoseActivityCorrelation] = []
    @State private var currentGlucose: Double = 0.0
    @State private var isLoading = true
    @State private var authorizationStatus = false
    
    private let lowThreshold = 70.0
    private let highThreshold = 170.0
    private let targetMin = 80.0
    private let targetMax = 130.0
    
    private var maxGlucose: Double {
        glucoseData.map(\.level).max() ?? 0
    }
    
    private var minGlucose: Double {
        glucoseData.map(\.level).min() ?? 0
    }
    
    private var avgGlucose: Double {
        guard !glucoseData.isEmpty else { return 0 }
        let sum = glucoseData.map(\.level).reduce(0,+)
        return sum / Double(glucoseData.count)
    }
    
    private var timeInRange: Double {
        guard !glucoseData.isEmpty else { return 0 }
        let inRange = glucoseData.filter { $0.level >= targetMin && $0.level <= targetMax }.count
        return (Double(inRange) / Double(glucoseData.count)) * 100
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !authorizationStatus {
                    healthAccessSection
                } else if isLoading {
                    loadingSection
                } else {
                    // Sección de glucosa actual
                    currentGlucoseSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Gráfica de glucosa en el tiempo
                    glucoseTimeSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Estadísticas de glucosa
                    glucoseStatsSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Gráfica de correlación glucosa vs actividad
                    glucoseActivitySection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Resumen de ejercicio
                    exerciseSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            requestHealthAccess()
        }
    }
    
    // MARK: - Current Glucose Section
    private var currentGlucoseSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nivel Actual de Glucosa")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Última medición: \(timeFormatter.string(from: glucoseData.last?.time ?? Date()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            GlucoseGauge(current: currentGlucose,
                         minLevel: lowThreshold,
                         maxLevel: highThreshold,
                         targetMin: targetMin,
                         targetMax: targetMax)
            .frame(width: 180, height: 180)
            
            glucoseStatusText
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var glucoseStatusText: some View {
        HStack {
            Image(systemName: glucoseStatusIcon)
                .foregroundColor(glucoseStatusColor)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(glucoseStatusTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(glucoseStatusColor)
                
                Text(glucoseStatusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(glucoseStatusColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var glucoseStatusIcon: String {
        if currentGlucose < lowThreshold { return "exclamationmark.triangle.fill" }
        if currentGlucose > highThreshold { return "exclamationmark.triangle.fill" }
        if currentGlucose >= targetMin && currentGlucose <= targetMax { return "checkmark.circle.fill" }
        return "minus.circle.fill"
    }
    
    private var glucoseStatusColor: Color {
        if currentGlucose < lowThreshold { return .red }
        if currentGlucose > highThreshold { return .orange }
        if currentGlucose >= targetMin && currentGlucose <= targetMax { return .green }
        return .yellow
    }
    
    private var glucoseStatusTitle: String {
        if currentGlucose < lowThreshold { return "Glucosa Baja" }
        if currentGlucose > highThreshold { return "Glucosa Alta" }
        if currentGlucose >= targetMin && currentGlucose <= targetMax { return "En Rango Objetivo" }
        return "Fuera de Rango"
    }
    
    private var glucoseStatusDescription: String {
        if currentGlucose < lowThreshold { return "Considera consumir carbohidratos rápidos" }
        if currentGlucose > highThreshold { return "Monitorea y considera actividad física" }
        if currentGlucose >= targetMin && currentGlucose <= targetMax { return "Mantén tu rutina actual" }
        return "Mantente hidratado y activo"
    }
    
    // MARK: - Glucose Time Section
    private var glucoseTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tendencia de Glucosa")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Últimas 24 horas • Rango objetivo: \(Int(targetMin))-\(Int(targetMax)) mg/dL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            EnhancedGlucoseTimeChart(data: glucoseData,
                                   targetMin: targetMin,
                                   targetMax: targetMax,
                                   lowThreshold: lowThreshold,
                                   highThreshold: highThreshold)
                .frame(height: 220)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Glucose Stats Section
    private var glucoseStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Estadísticas del Día")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatCard(title: "Promedio", value: "\(Int(avgGlucose))", unit: "mg/dL", color: .blue)
                StatCard(title: "Tiempo en Rango", value: "\(Int(timeInRange))", unit: "%", color: .green)
                StatCard(title: "Máximo", value: "\(Int(maxGlucose))", unit: "mg/dL", color: .orange)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Glucose Activity Section
    private var glucoseActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Glucosa vs Actividad Física")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Correlación entre niveles de glucosa y actividad")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            GlucoseActivityChart(data: correlationData)
                .frame(height: 200)
            
            Text("💡 Tip: La actividad física regular ayuda a mantener niveles estables de glucosa")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Exercise Section
    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Resumen de Ejercicio")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ExerciseSummaryCardView(data: exerciseData)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Health Access Section
    private var healthAccessSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Acceso a Salud Requerido")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Permite acceso para ver tu monitoreo de glucosa, niveles de actividad y datos de ejercicio")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: requestHealthAccess) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Permitir Acceso a Salud")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.red.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color.red.opacity(0.4), radius: 12, x: 0, y: 6)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.green)
            
            Text("Cargando tus datos de salud...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - HealthKit Functions
    private func requestHealthAccess() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            DispatchQueue.main.async {
                self.authorizationStatus = success
                if success {
                    self.loadHealthData()
                }
            }
        }
    }
    
    private func loadHealthData() {
        isLoading = true
        
        let group = DispatchGroup()
        
        // Obtener datos de glucosa
        group.enter()
        fetchGlucoseData { data in
            self.glucoseData = data
            self.currentGlucose = data.last?.level ?? 0.0
            group.leave()
        }
        
        // Obtener datos de actividad
        group.enter()
        fetchActivityData { data in
            self.activityData = data
            group.leave()
        }
        
        // Obtener datos de ejercicio
        group.enter()
        fetchExerciseData { data in
            self.exerciseData = data
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.createCorrelationData()
            self.isLoading = false
        }
    }
    
    private func createCorrelationData() {
        correlationData = zip(glucoseData, activityData).map { glucose, activity in
            GlucoseActivityCorrelation(
                time: glucose.time,
                glucose: glucose.level,
                activity: activity.activity
            )
        }
    }
    
    private func fetchGlucoseData(completion: @escaping ([GlucoseEntry]) -> Void) {
        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: glucoseType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, _ in
            
            guard let samples = results as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    completion(self.createSampleGlucoseData())
                }
                return
            }
            
            let glucoseEntries = samples.map { sample in
                GlucoseEntry(
                    time: sample.startDate,
                    level: sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
                )
            }
            
            DispatchQueue.main.async {
                completion(glucoseEntries.isEmpty ? self.createSampleGlucoseData() : glucoseEntries)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActivityData(completion: @escaping ([ActivityEntry]) -> Void) {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        
        var interval = DateComponents()
        interval.hour = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepsType,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate),
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, results, _ in
            guard let results = results else {
                DispatchQueue.main.async {
                    completion(self.createSampleActivityData())
                }
                return
            }
            
            var activityEntries: [ActivityEntry] = []
            
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let steps = sum.doubleValue(for: .count())
                    let activityLevel = min(steps / 100, 50)
                    
                    activityEntries.append(ActivityEntry(
                        time: statistics.startDate,
                        activity: activityLevel
                    ))
                }
            }
            
            DispatchQueue.main.async {
                completion(activityEntries.isEmpty ? self.createSampleActivityData() : activityEntries)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchExerciseData(completion: @escaping ([ExerciseSample]) -> Void) {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        
        var interval = DateComponents()
        interval.hour = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate),
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, results, _ in
            guard let results = results else {
                DispatchQueue.main.async {
                    completion(self.createSampleExerciseData())
                }
                return
            }
            
            var exerciseEntries: [ExerciseSample] = []
            
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let minutes = sum.doubleValue(for: .minute())
                    
                    if minutes > 0 {
                        exerciseEntries.append(ExerciseSample(
                            time: statistics.startDate,
                            minutes: minutes
                        ))
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(exerciseEntries.isEmpty ? self.createSampleExerciseData() : exerciseEntries)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Sample Data (más realista)
    private func createSampleGlucoseData() -> [GlucoseEntry] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            // Madrugada (valores bajos)
            .init(time: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: today)!, level: 85),
            .init(time: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today)!, level: 90),
            
            // Desayuno (subida)
            .init(time: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)!, level: 110),
            .init(time: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!, level: 145),
            .init(time: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!, level: 125),
            .init(time: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today)!, level: 105),
            
            // Almuerzo (segunda subida)
            .init(time: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!, level: 95),
            .init(time: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: today)!, level: 120),
            .init(time: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!, level: 155),
            .init(time: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!, level: 135),
            .init(time: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today)!, level: 115),
            
            // Tarde (estabilización)
            .init(time: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today)!, level: 100),
            .init(time: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!, level: 110),
            
            // Cena (tercera subida)
            .init(time: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!, level: 130),
            .init(time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!, level: 140),
            .init(time: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: today)!, level: 125),
            .init(time: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: today)!, level: 110),
            .init(time: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: today)!, level: 95)
        ]
    }
    
    private func createSampleActivityData() -> [ActivityEntry] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            .init(time: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: today)!, activity: 5),
            .init(time: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today)!, activity: 15),
            .init(time: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)!, activity: 25),
            .init(time: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!, activity: 45),
            .init(time: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!, activity: 35),
            .init(time: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today)!, activity: 20),
            .init(time: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!, activity: 10),
            .init(time: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: today)!, activity: 15),
            .init(time: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!, activity: 30),
            .init(time: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!, activity: 40),
            .init(time: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: today)!, activity: 35),
            .init(time: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today)!, activity: 25),
            .init(time: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!, activity: 20),
            .init(time: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!, activity: 15),
            .init(time: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!, activity: 10),
            .init(time: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: today)!, activity: 8),
            .init(time: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: today)!, activity: 5),
            .init(time: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: today)!, activity: 3)
        ]
    }
    
    private func createSampleExerciseData() -> [ExerciseSample] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            .init(time: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today)!, minutes: 5),
            .init(time: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!, minutes: 30),
            .init(time: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!, minutes: 2),
            .init(time: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!, minutes: 20),
            .init(time: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!, minutes: 15),
            .init(time: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!, minutes: 10)
        ]
    }
}

// MARK: - Enhanced Circular Gauge
struct GlucoseGauge: View {
    let current: Double
    let minLevel: Double
    let maxLevel: Double
    let targetMin: Double
    let targetMax: Double
    
    private var normalized: Double {
        let range = maxLevel - minLevel
        let val = current - minLevel
        return Swift.max(0, Swift.min(1, val / range))
    }
    
    var body: some View {
        ZStack {
            // Fondo del círculo
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 16)
            
            // Círculo principal con gradiente
            Circle()
                .trim(from: 0, to: normalized)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270 * normalized - 90)
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Marcadores para rango objetivo
            Circle()
                .trim(from: (targetMin - minLevel) / (maxLevel - minLevel),
                      to: (targetMax - minLevel) / (maxLevel - minLevel))
                .stroke(Color.green.opacity(0.3), lineWidth: 20)
                .rotationEffect(.degrees(-90))
            
            // Valor central
            VStack(spacing: 4) {
                Text("\(Int(current))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("mg/dL")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Enhanced Glucose Time Chart
struct EnhancedGlucoseTimeChart: View {
    let data: [GlucoseEntry]
    let targetMin: Double
    let targetMax: Double
    let lowThreshold: Double
    let highThreshold: Double
    
    var body: some View {
        Chart {
            // Área de rango objetivo
            RectangleMark(
                xStart: .value("Start", data.first?.time ?? Date()),
                xEnd: .value("End", data.last?.time ?? Date()),
                yStart: .value("Target Min", targetMin),
                yEnd: .value("Target Max", targetMax)
            )
            .foregroundStyle(Color.green.opacity(0.1))
            
            // Línea de glucosa
            ForEach(data) { entry in
                LineMark(
                    x: .value("Hora", entry.time),
                    y: .value("Glucosa", entry.level)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                // Puntos en la línea
                PointMark(
                    x: .value("Hora", entry.time),
                    y: .value("Glucosa", entry.level)
                )
                .foregroundStyle(pointColor(for: entry.level))
                .symbol(.circle)
                .symbolSize(40)
            }
            
            // Líneas de referencia
            RuleMark(y: .value("Objetivo Min", targetMin))
                .foregroundStyle(Color.green.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            
            RuleMark(y: .value("Objetivo Max", targetMax))
                .foregroundStyle(Color.green.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
        }
        .chartYScale(domain: 60...180)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { mark in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                    .font(.caption)
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 30)) { mark in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel()
                    .font(.caption)
            }
        }
    }
    
    private func pointColor(for glucose: Double) -> Color {
        if glucose < lowThreshold { return .red }
        if glucose > highThreshold { return .orange }
        if glucose >= targetMin && glucose <= targetMax { return .green }
        return .yellow
    }
}

// MARK: - Glucose Activity Correlation Chart
struct GlucoseActivityChart: View {
    let data: [GlucoseActivityCorrelation]
    
    var body: some View {
        Chart(data) { item in
            PointMark(
                x: .value("Actividad", item.activity),
                y: .value("Glucosa", item.glucose)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .symbolSize(60)
            .opacity(0.7)
        }
        .chartXAxis {
            AxisMarks { mark in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel {
                    Text("Actividad")
                        .font(.caption)
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 30)) { mark in
                AxisGridLine()
                    .foregroundStyle(.gray.opacity(0.3))
                AxisValueLabel()
                    .font(.caption)
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Exercise Summary
struct ExerciseSummaryCardView: View {
    let data: [ExerciseSample]
    @Environment(\.colorScheme) var colorScheme

    private var totalMinutes: Int {
        Int(data.map(\.minutes).reduce(0, +))
    }

    private var weeklyAverage: Double {
        let dailyTotal = data.map(\.minutes).reduce(0, +)
        return dailyTotal / 7.0 // Promedio semanal aproximado
    }

    private var glucoseCorrelationText: String {
        let exerciseImpact = weeklyAverage
        if exerciseImpact >= 30 {
            return "🎯 Alta actividad ayuda a estabilizar glucosa"
        } else if exerciseImpact >= 15 {
            return "⚡ Actividad moderada mantiene control glucémico"
        } else {
            return "📈 Más ejercicio podría mejorar control de glucosa"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Minutos de Ejercicio", systemImage: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline.bold())
                Spacer()
                
                Text("Hoy")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalMinutes)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Text("minutos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Meta: 30 min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: Double(totalMinutes), total: 30.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .frame(width: 80)
                }
            }
            
            Text(glucoseCorrelationText)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
