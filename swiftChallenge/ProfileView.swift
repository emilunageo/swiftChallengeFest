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
            return .green
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

// MARK: - Health Data Model
struct HealthData {
    var age: Int?
    var weight: Double = 0.0
    var glucose: Double = 0.0
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
            ScrollView {
                VStack(spacing: 20) {
                    profileSection
                    nameFieldsSection
                    medicalConditionSection
                    healthDataSection
                }
                .padding()
            }
            .navigationTitle("Health Profile")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .onAppear {
                requestHealthAccess()
                fetchContactName()
            }
        }
    }
    
    // MARK: - Profile Section with Static Profile Icon
    private var profileSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 150))
                .foregroundColor(.blue)
                .frame(width: 150, height: 150)
        }
    }
    
    // MARK: - Name Fields Section
    private var nameFieldsSection: some View {
        HStack(spacing: 8) {
            Text(firstName.isEmpty ? "First Name" : firstName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(firstName.isEmpty ? .secondary : .primary)
            
            Text(lastName.isEmpty ? "Last Name" : lastName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(lastName.isEmpty ? .secondary : .primary)
        }
    }
    
    // MARK: - Medical Condition Section

    
    // MARK: - Health Data Section
    private var healthDataSection: some View {
        VStack(spacing: 12) {
            if !authorizationStatus {
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text("Health Access Required")
                        .font(.headline)
                    Text("Allow access to view your health data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Allow Access") {
                        requestHealthAccess()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
            } else if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading health data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
            } else {
                VStack(spacing: 12) {
                    HealthCard(
                        title: "Age",
                        value: healthData.age != nil ? "\(healthData.age!)" : "No data",
                        unit: "years",
                        icon: "person.fill",
                        color: .green
                    )
                    HealthCard(
                        title: "Weight",
                        value: healthData.weight > 0 ? String(format: "%.1f", healthData.weight) : "No data",
                        unit: "kg",
                        icon: "scalemass.fill",
                        color: .blue
                    )
                    HealthCard(
                        title: "Blood Glucose",
                        value: healthData.glucose > 0 ? String(format: "%.1f", healthData.glucose) : "No data",
                        unit: "mg/dL",
                        icon: "drop.fill",
                        color: .red
                    )
                }
            }
        }
    }
    private var medicalConditionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "stethoscope")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Medical Condition")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Menu {
                ForEach(MedicalCondition.allCases, id: \.self) { condition in
                    Button(action: {
                        selectedCondition = condition
                    }) {
                        HStack {
                            Image(systemName: condition.icon)
                                .foregroundColor(condition.color)
                            Text(condition.rawValue)
                            if selectedCondition == condition {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedCondition.icon)
                        .font(.title3)
                        .foregroundColor(selectedCondition.color)
                        .frame(width: 25)
                    
                    Text(selectedCondition.rawValue)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
    // MARK: - HealthKit Functions
    private func requestHealthAccess() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
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
        fetchGlucose { glucose in
            self.healthData.glucose = glucose
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
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
    
    private func fetchGlucose(completion: @escaping (Double) -> Void) {
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
            
            let total = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "mg/dL")) }
            let average = total / Double(samples.count)
            completion(average)
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
                    // Heuristic: first contact with non-empty given & family name could be user
                    if !contact.givenName.isEmpty && !contact.familyName.isEmpty {
                        DispatchQueue.main.async {
                            // Only set if fields are empty to avoid overwriting user edits
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

// MARK: - Health Card View
struct HealthCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if value != "No data" {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ProfileView()
}
