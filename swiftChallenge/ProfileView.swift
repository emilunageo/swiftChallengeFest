//
//  ProfileView.swift
//  swiftChallenge
//
//  Created by Fatima Alonso on 6/7/25.
//
import SwiftUI
import HealthKit
import Contacts

// MARK: - Medical Condition Enum
enum MedicalCondition: String, CaseIterable {
    case none = "None"
    case diabetes = "Diabetes"
    case hypertension = "Hypertension"
    case heartDisease = "Heart Disease"
    case asthma = "Asthma"
    case arthritis = "Arthritis"
    case thyroidDisorder = "Thyroid Disorder"
    case chronicKidneyDisease = "Chronic Kidney Disease"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .none:
            return "checkmark.circle.fill"
        case .diabetes:
            return "drop.fill"
        case .hypertension:
            return "heart.fill"
        case .heartDisease:
            return "heart.text.square.fill"
        case .asthma:
            return "lungs.fill"
        case .arthritis:
            return "figure.walk"
        case .thyroidDisorder:
            return "pills.fill"
        case .chronicKidneyDisease:
            return "kidneys.fill"
        case .other:
            return "cross.case.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .none:
            return .appleGreen
        case .diabetes:
            return .red
        case .hypertension:
            return .orange
        case .heartDisease:
            return .red
        case .asthma:
            return .blue
        case .arthritis:
            return .purple
        case .thyroidDisorder:
            return .yellow
        case .chronicKidneyDisease:
            return .brown
        case .other:
            return .gray
        }
    }
}

// MARK: - Enhanced Health Data Model
struct HealthData : Decodable {
    var age: Int?
    var weight: Double = 0.0
    var height: Double = 0.0
    var bmi: Double = 0.0
    var glucose: Double = 0.0
    var fastingGlucose: Double = 0.0
    var hbA1c: Double = 0.0
    var InsulinDelivery: Double = 0.0
    var heartRate: Double = 0.0
    var systolicBP: Double = 0.0
    var diastolicBP: Double = 0.0
    var steps: Double = 0.0
    var activeCalories: Double = 0.0
}

struct ProfileView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var healthData = HealthData()
    @State private var selectedCondition: MedicalCondition = .none
    @State private var isLoading = false
    @State private var authorizationStatus = false
    
    private let healthStore = HKHealthStore()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.lightGray, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileSection
                        nameSection
                        medicalConditionSection
                        
                        if authorizationStatus {
                            if isLoading {
                                loadingSection
                            } else {
                                basicHealthSection
                                glucoseRelatedSection
                                cardiovascularSection
                                activitySection
                            }
                        } else {
                            healthAccessSection
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Health Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                requestHealthAccess()
                fetchContactName()
            }
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.warmRed],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Name Section
    private var nameSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text(firstName.isEmpty ? "First Name" : firstName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(firstName.isEmpty ? .secondary : .primary)
                
                Text(lastName.isEmpty ? "Last Name" : lastName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(lastName.isEmpty ? .secondary : .primary)
            }
            
            if !firstName.isEmpty || !lastName.isEmpty {
                Text("Welcome to your health dashboard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Medical Condition Section
    private var medicalConditionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "stethoscope")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("Medical Condition")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Menu {
                ForEach(MedicalCondition.allCases, id: \.self) { condition in
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedCondition = condition
                        }
                    }) {
                        HStack {
                            Image(systemName: condition.icon)
                                .foregroundColor(condition.color)
                            Text(condition.rawValue)
                            if selectedCondition == condition {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appleGreen)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selectedCondition.icon)
                        .font(.title2)
                        .foregroundColor(selectedCondition.color)
                        .frame(width: 30)
                    
                    Text(selectedCondition.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Health Access Section
    private var healthAccessSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Health Access Required")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Allow access to view your comprehensive health data including glucose monitoring, cardiovascular metrics, and activity levels")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: requestHealthAccess) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Allow Health Access")
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
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.appleGreen)
            
            Text("Loading your health data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Basic Health Section
    private var basicHealthSection: some View {
        HealthSectionCard(
            title: "Basic Metrics",
            icon: "person.fill",
            iconColor: .appleGreen
        ) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ModernHealthCard(
                    title: "Age",
                    value: healthData.age != nil ? "\(healthData.age!)" : "No data",
                    unit: "years",
                    icon: "person.fill",
                    color: .blue
                )
                
                ModernHealthCard(
                    title: "Weight",
                    value: healthData.weight > 0 ? String(format: "%.1f", healthData.weight) : "No data",
                    unit: "kg",
                    icon: "scalemass.fill",
                    color: .purple
                )
                
                ModernHealthCard(
                    title: "Height",
                    value: healthData.height > 0 ? String(format: "%.0f", healthData.height) : "No data",
                    unit: "cm",
                    icon: "ruler.fill",
                    color: .green
                )
                
                ModernHealthCard(
                    title: "BMI",
                    value: healthData.bmi > 0 ? String(format: "%.1f", healthData.bmi) : "No data",
                    unit: "",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange,
                    isImportant: healthData.bmi > 25 || (healthData.bmi > 0 && healthData.bmi < 18.5)
                )
            }
        }
    }
    
    // MARK: - Glucose Related Section
    private var glucoseRelatedSection: some View {
        HealthSectionCard(
            title: "Glucose & Diabetes",
            icon: "drop.fill",
            iconColor: .red
        ) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ModernHealthCard(
                    title: "Avg Glucose",
                    value: healthData.glucose > 0 ? String(format: "%.0f", healthData.glucose) : "No data",
                    unit: "mg/dL",
                    icon: "drop.fill",
                    color: .red,
                    isImportant: healthData.glucose > 140
                )
                
                ModernHealthCard(
                    title: "Fasting Glucose",
                    value: healthData.fastingGlucose > 0 ? String(format: "%.0f", healthData.fastingGlucose) : "No data",
                    unit: "mg/dL",
                    icon: "moon.fill",
                    color: .indigo,
                    isImportant: healthData.fastingGlucose > 100
                )
                
                ModernHealthCard(
                    title: "HbA1c",
                    value: healthData.hbA1c > 0 ? String(format: "%.1f", healthData.hbA1c) : "No data",
                    unit: "%",
                    icon: "chart.bar.fill",
                    color: .red,
                    isImportant: healthData.hbA1c > 7.0
                )
                
                ModernHealthCard(
                    title: "Insulin",
                    value: healthData.InsulinDelivery > 0 ? String(format: "%.1f", healthData.InsulinDelivery) : "No data",
                    unit: "μU/mL",
                    icon: "syringe.fill",
                    color: .cyan
                )
            }
        }
    }
    
    // MARK: - Cardiovascular Section
    private var cardiovascularSection: some View {
        HealthSectionCard(
            title: "Cardiovascular",
            icon: "heart.fill",
            iconColor: .pink
        ) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ModernHealthCard(
                    title: "Heart Rate",
                    value: healthData.heartRate > 0 ? String(format: "%.0f", healthData.heartRate) : "No data",
                    unit: "bpm",
                    icon: "heart.fill",
                    color: .pink,
                    isImportant: healthData.heartRate > 100 || (healthData.heartRate > 0 && healthData.heartRate < 60)
                )
                
                ModernHealthCard(
                    title: "Systolic BP",
                    value: healthData.systolicBP > 0 ? String(format: "%.0f", healthData.systolicBP) : "No data",
                    unit: "mmHg",
                    icon: "arrow.up.circle.fill",
                    color: .red,
                    isImportant: healthData.systolicBP > 140
                )
                
                ModernHealthCard(
                    title: "Diastolic BP",
                    value: healthData.diastolicBP > 0 ? String(format: "%.0f", healthData.diastolicBP) : "No data",
                    unit: "mmHg",
                    icon: "arrow.down.circle.fill",
                    color: .orange,
                    isImportant: healthData.diastolicBP > 90
                )
                
                ModernHealthCard(
                    title: "BP Status",
                    value: getBPStatus(),
                    unit: "",
                    icon: "checkmark.seal.fill",
                    color: getBPStatusColor(),
                    isImportant: healthData.systolicBP > 140 || healthData.diastolicBP > 90
                )
            }
        }
    }
    
    // MARK: - Activity Section
    private var activitySection: some View {
        HealthSectionCard(
            title: "Physical Activity",
            icon: "figure.walk",
            iconColor: .appleGreen
        ) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ModernHealthCard(
                    title: "Steps Today",
                    value: healthData.steps > 0 ? String(format: "%.0f", healthData.steps) : "No data",
                    unit: "steps",
                    icon: "figure.walk",
                    color: .appleGreen,
                    isImportant: healthData.steps < 8000 && healthData.steps > 0
                )
                
                ModernHealthCard(
                    title: "Active Calories",
                    value: healthData.activeCalories > 0 ? String(format: "%.0f", healthData.activeCalories) : "No data",
                    unit: "cal",
                    icon: "flame.fill",
                    color: .orange
                )
                
                ModernHealthCard(
                    title: "Activity Goal",
                    value: getActivityGoalStatus(),
                    unit: "",
                    icon: "target",
                    color: getActivityGoalColor()
                )
                
                ModernHealthCard(
                    title: "Glucose Impact",
                    value: getGlucoseActivityImpact(),
                    unit: "",
                    icon: "arrow.down.circle.fill",
                    color: .appleGreen
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getBPStatus() -> String {
        if healthData.systolicBP == 0 || healthData.diastolicBP == 0 {
            return "No data"
        }
        
        if healthData.systolicBP >= 140 || healthData.diastolicBP >= 90 {
            return "High"
        } else if healthData.systolicBP >= 130 || healthData.diastolicBP >= 80 {
            return "Elevated"
        } else {
            return "Normal"
        }
    }
    
    private func getBPStatusColor() -> Color {
        let status = getBPStatus()
        switch status {
        case "Normal":
            return .appleGreen
        case "Elevated":
            return .orange
        case "High":
            return .red
        default:
            return .gray
        }
    }
    
    private func getActivityGoalStatus() -> String {
        if healthData.steps == 0 {
            return "No data"
        }
        
        if healthData.steps >= 10000 {
            return "Achieved"
        } else if healthData.steps >= 8000 {
            return "Close"
        } else {
            return "Needs Work"
        }
    }
    
    private func getActivityGoalColor() -> Color {
        let status = getActivityGoalStatus()
        switch status {
        case "Achieved":
            return .appleGreen
        case "Close":
            return .orange
        case "Needs Work":
            return .red
        default:
            return .gray
        }
    }
    
    private func getGlucoseActivityImpact() -> String {
        if healthData.steps == 0 {
            return "No data"
        }
        
        if healthData.steps >= 8000 {
            return "Beneficial"
        } else {
            return "Increase Activity"
        }
    }
    
    // MARK: - HealthKit Functions
    private func requestHealthAccess() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            // Agregamos tipos adicionales relacionados con glucosa
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
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
        
        // Datos básicos
        group.enter()
        fetchAge { age in
            self.healthData.age = age
            group.leave()
        }
        
        group.enter()
        fetchWeight { weight in
            self.healthData.weight = weight
            group.leave()
        }
        
        group.enter()
        fetchHeight { height in
            self.healthData.height = height
            group.leave()
        }
        
        group.enter()
        fetchBMI { bmi in
            self.healthData.bmi = bmi
            group.leave()
        }
        
        // Datos relacionados con glucosa
        group.enter()
        fetchAverageGlucose { glucose in
            self.healthData.glucose = glucose
            group.leave()
        }
        
        group.enter()
        fetchFastingGlucose { glucose in
            self.healthData.fastingGlucose = glucose
            group.leave()
        }
        
        // Datos cardiovasculares
        group.enter()
        fetchHeartRate { heartRate in
            self.healthData.heartRate = heartRate
            group.leave()
        }
        
        group.enter()
        fetchBloodPressure { systolic, diastolic in
            self.healthData.systolicBP = systolic
            self.healthData.diastolicBP = diastolic
            group.leave()
        }
        
        // Datos de actividad
        group.enter()
        fetchSteps { steps in
            self.healthData.steps = steps
            group.leave()
        }
        
        group.enter()
        fetchActiveCalories { calories in
            self.healthData.activeCalories = calories
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    // MARK: - Individual Fetch Functions
    private func fetchAge(completion: @escaping (Int?) -> Void) {
        do {
            let birthDate = try healthStore.dateOfBirthComponents()
            if let date = birthDate.date {
                let age = Calendar.current.dateComponents([.year], from: date, to: Date()).year
                completion(age)
            } else {
                completion(nil)
            }
        } catch {
            completion(nil)
        }
    }
    
    private func fetchWeight(completion: @escaping (Double) -> Void) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(0.0)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            
            if let sample = results?.first as? HKQuantitySample {
                let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                completion(weight)
            } else {
                completion(0.0)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeight(completion: @escaping (Double) -> Void) {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            completion(0.0)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            
            if let sample = results?.first as? HKQuantitySample {
                let height = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
                completion(height)
            } else {
                completion(0.0)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBMI(completion: @escaping (Double) -> Void) {
        guard let bmiType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) else {
            completion(0.0)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: bmiType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            
            if let sample = results?.first as? HKQuantitySample {
                let bmi = sample.quantity.doubleValue(for: HKUnit.count())
                completion(bmi)
            } else {
                completion(0.0)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageGlucose(completion: @escaping (Double) -> Void) {
        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            completion(0.0)
            return
        }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: glucoseType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
            
            guard let samples = results as? [HKQuantitySample], !samples.isEmpty else {
                completion(0.0)
                return
            }
            
            let total = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "mg/dL")) }
            let average = total / Double(samples.count)
            completion(average)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchFastingGlucose(completion: @escaping (Double) -> Void) {
        guard let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
            completion(0.0)
            return
        }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: glucoseType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
            
            guard let samples = results as? [HKQuantitySample], !samples.isEmpty else {
                completion(0.0)
                return
            }
            
            // Filtrar muestras que podrían ser de ayuno (entre 6 AM y 9 AM)
            let fastingSamples = samples.filter { sample in
                let hour = Calendar.current.component(.hour, from: sample.startDate)
                return hour >= 6 && hour <= 9
            }
            
            if !fastingSamples.isEmpty {
                let total = fastingSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "mg/dL")) }
                let average = total / Double(fastingSamples.count)
                completion(average)
            } else {
                completion(0.0)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeartRate(completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(0.0)
            return
        }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { _, results, _ in
            
            guard let samples = results as? [HKQuantitySample], !samples.isEmpty else {
                completion(0.0)
                return
            }
            
            let total = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "count/min")) }
            let average = total / Double(samples.count)
            completion(average)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBloodPressure(completion: @escaping (Double, Double) -> Void) {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            completion(0.0, 0.0)
            return
        }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let group = DispatchGroup()
        var systolic: Double = 0.0
        var diastolic: Double = 0.0
        
        // Fetch systolic
        group.enter()
        let systolicQuery = HKSampleQuery(sampleType: systolicType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { _, results, _ in
            
            if let samples = results as? [HKQuantitySample], !samples.isEmpty {
                let total = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.millimeterOfMercury()) }
                systolic = total / Double(samples.count)
            }
            group.leave()
        }
        
        // Fetch diastolic
        group.enter()
        let diastolicQuery = HKSampleQuery(sampleType: diastolicType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { _, results, _ in
            
            if let samples = results as? [HKQuantitySample], !samples.isEmpty {
                let total = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.millimeterOfMercury()) }
                diastolic = total / Double(samples.count)
            }
            group.leave()
        }
        
        healthStore.execute(systolicQuery)
        healthStore.execute(diastolicQuery)
        
        group.notify(queue: .main) {
            completion(systolic, diastolic)
        }
    }
    
    private func fetchSteps(completion: @escaping (Double) -> Void) {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0.0)
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            
            if let sum = result?.sumQuantity() {
                let steps = sum.doubleValue(for: .count())
                completion(steps)
            } else {
                completion(0.0)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveCalories(completion: @escaping (Double) -> Void) {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0.0)
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: caloriesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            
            if let sum = result?.sumQuantity() {
                let calories = sum.doubleValue(for: .kilocalorie())
                completion(calories)
            } else {
                completion(0.0)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Contacts Framework: Fetch User Name
    private func fetchContactName() {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else { return }
            
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey]
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
            
            do {
                try store.enumerateContacts(with: request) { contact, stop in
                    if !contact.givenName.isEmpty && !contact.familyName.isEmpty {
                        DispatchQueue.main.async {
                            if self.firstName.isEmpty { self.firstName = contact.givenName }
                            if self.lastName.isEmpty { self.lastName = contact.familyName }
                        }
                        stop.pointee = true
                    }
                }
            } catch {
                // handle error if needed
            }
        }
    }
}

// MARK: - Custom Views
struct HealthSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct ModernHealthCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    var isImportant: Bool = false
    
    var body: some View {

        Text("Profile")

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if isImportant {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if value != "No data" && !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isImportant ? color.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )

    }
}

#Preview {
    ProfileView()
}
