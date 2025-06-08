//
//  SuggestionsView.swift
//  swiftChallenge
//
//  Created by Fatima Alonso on 6/7/25.
//

import SwiftUI

// MARK: - Modelo
struct Ingrediente: Identifiable {
    let id = UUID()
    var nombre: String
    var indiceGlucemico: Int
    
    var igCategory: IGCategory {
        switch indiceGlucemico {
        case 0...35: return .low
        case 36...55: return .medium
        case 56...100: return .high
        default: return .medium
        }
    }
}

enum IGCategory {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: return .appleGreen
        case .medium: return .orange
        case .high: return .warmRed
        }
    }
    
    var label: String {
        switch self {
        case .low: return "Low GI"
        case .medium: return "Medium GI"
        case .high: return "High GI"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "checkmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        }
    }
}

struct Comida: Identifiable {
    let id = UUID()
    var nombre: String
    var ingredientes: [Ingrediente]
    var igPromedio: Double {
        let total = ingredientes.map { Double($0.indiceGlucemico) }.reduce(0, +)
        return ingredientes.isEmpty ? 0 : total / Double(ingredientes.count)
    }
    
    var categoria: IGCategory {
        let promedio = Int(igPromedio)
        switch promedio {
        case 0...35: return .low
        case 36...55: return .medium
        case 56...100: return .high
        default: return .medium
        }
    }
}

// MARK: - ViewModel
class SuggestionsViewModel: ObservableObject {
    @Published var ingredientes = [Ingrediente]()
    @Published var comidasSugeridas = [Comida]()
    @Published var isLoading = false
    
    private let todasComidas: [Comida] = [
        Comida(nombre: "Chicken Salad", ingredientes: [
            Ingrediente(nombre: "Lettuce", indiceGlucemico: 10),
            Ingrediente(nombre: "Chicken", indiceGlucemico: 0),
            Ingrediente(nombre: "Tomato", indiceGlucemico: 30),
            Ingrediente(nombre: "Cucumber", indiceGlucemico: 15)
        ]),
        Comida(nombre: "Green Smoothie", ingredientes: [
            Ingrediente(nombre: "Spinach", indiceGlucemico: 15),
            Ingrediente(nombre: "Cucumber", indiceGlucemico: 15),
            Ingrediente(nombre: "Apple", indiceGlucemico: 40)
        ]),
        Comida(nombre: "Yogurt with Walnuts", ingredientes: [
            Ingrediente(nombre: "Yogurt", indiceGlucemico: 35),
            Ingrediente(nombre: "Walnuts", indiceGlucemico: 25)
        ]),
        Comida(nombre: "Grilled Salmon", ingredientes: [
            Ingrediente(nombre: "Salmon", indiceGlucemico: 0),
            Ingrediente(nombre: "Spinach", indiceGlucemico: 15),
            Ingrediente(nombre: "Broccoli", indiceGlucemico: 25)
        ]),
        Comida(nombre: "Quinoa Bowl", ingredientes: [
            Ingrediente(nombre: "Quinoa", indiceGlucemico: 53),
            Ingrediente(nombre: "Avocado", indiceGlucemico: 15),
            Ingrediente(nombre: "Tomato", indiceGlucemico: 30)
        ]),
        Comida(nombre: "Protein Shake", ingredientes: [
            Ingrediente(nombre: "Protein", indiceGlucemico: 0),
            Ingrediente(nombre: "Spinach", indiceGlucemico: 15),
            Ingrediente(nombre: "Berries", indiceGlucemico: 25)
        ]),
        // Nuevas recetas hardcoded
        Comida(nombre: "Veggie Omelette", ingredientes: [
            Ingrediente(nombre: "Eggs", indiceGlucemico: 0),
            Ingrediente(nombre: "Spinach", indiceGlucemico: 15),
            Ingrediente(nombre: "Cheese", indiceGlucemico: 0)
        ]),
        Comida(nombre: "Tuna Salad", ingredientes: [
            Ingrediente(nombre: "Tuna", indiceGlucemico: 0),
            Ingrediente(nombre: "Lettuce", indiceGlucemico: 10),
            Ingrediente(nombre: "Cucumber", indiceGlucemico: 15)
        ]),
        Comida(nombre: "Avocado Toast", ingredientes: [
            Ingrediente(nombre: "Avocado", indiceGlucemico: 15),
            Ingrediente(nombre: "Whole Bread", indiceGlucemico: 45),
            Ingrediente(nombre: "Tomato", indiceGlucemico: 30)
        ]),
        Comida(nombre: "Greek Salad", ingredientes: [
            Ingrediente(nombre: "Lettuce", indiceGlucemico: 10),
            Ingrediente(nombre: "Tomato", indiceGlucemico: 30),
            Ingrediente(nombre: "Cheese", indiceGlucemico: 0),
            Ingrediente(nombre: "Cucumber", indiceGlucemico: 15)
        ]),
        Comida(nombre: "Berry Parfait", ingredientes: [
            Ingrediente(nombre: "Yogurt", indiceGlucemico: 35),
            Ingrediente(nombre: "Berries", indiceGlucemico: 25),
            Ingrediente(nombre: "Walnuts", indiceGlucemico: 25)
        ]),
        Comida(nombre: "Chicken Soup", ingredientes: [
            Ingrediente(nombre: "Chicken", indiceGlucemico: 0),
            Ingrediente(nombre: "Broccoli", indiceGlucemico: 25),
            Ingrediente(nombre: "Spinach", indiceGlucemico: 15)
        ])
    ]
    
    func recomendar() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isLoading = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let disponibles = Set(self.ingredientes.map { $0.nombre.lowercased() })
            
            // Si no hay ingredientes, mostrar todas las recetas saludables
            if disponibles.isEmpty {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.comidasSugeridas = self.todasComidas.filter { $0.igPromedio <= 60 }
                    self.isLoading = false
                }
                return
            }
            
            var recomendaciones: [Comida] = []
            
            // Buscar recetas que contengan AL MENOS UN ingrediente disponible
            for comida in self.todasComidas {
                let ingredientesReceta = Set(comida.ingredientes.map { $0.nombre.lowercased() })
                let tieneIngredienteComun = !ingredientesReceta.isDisjoint(with: disponibles)
                
                if tieneIngredienteComun && comida.igPromedio <= 65 {
                    recomendaciones.append(comida)
                }
            }
            
            // Si no hay coincidencias, mostrar las 3 recetas más saludables
            if recomendaciones.isEmpty {
                recomendaciones = self.todasComidas
                    .sorted { $0.igPromedio < $1.igPromedio }
                    .prefix(3)
                    .map { $0 }
            }
            
            withAnimation(.easeInOut(duration: 0.5)) {
                self.comidasSugeridas = recomendaciones
                self.isLoading = false
            }
        }
    }
}

// MARK: - View
struct SuggestionsView: View {
    @StateObject private var vm = SuggestionsViewModel()
    @State private var nuevoIngrediente = ""
    @State private var showingEmptyAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Input Section
                    inputSection
                    
                    // Recommend Button
                    recommendButton
                    
                    // Ingredients Section
                    if !vm.ingredientes.isEmpty {
                        ingredientsSection
                    }
                    
                    // Suggestions Section
                    suggestionsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.lightGray.ignoresSafeArea())
            .navigationTitle("What's for dinner?")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Empty Field", isPresented: $showingEmptyAlert) {
            Button("OK") { }
        } message: {
            Text("Please enter an ingredient name")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appleGreen, .green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("Find Healthy Recipes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Add ingredients and discover meals with low glycemic index")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.appleGreen)
                    .font(.title3)
                
                Text("Add Ingredient")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                TextField("e.g. chicken, lettuce, tomato...", text: $nuevoIngrediente)
                    .textFieldStyle(CustomTextFieldStyle())
                    .submitLabel(.done)
                    .onSubmit {
                        agregarIngrediente()
                    }
                
                Button(action: agregarIngrediente) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: [.appleGreen, .green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .appleGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(nuevoIngrediente.isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3), value: nuevoIngrediente.isEmpty)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Recommend Button
    private var recommendButton: some View {
        Button(action: vm.recomendar) {
            HStack(spacing: 12) {
                if vm.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(vm.isLoading ? "Finding recipes..." : "Recommend Meals")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: vm.ingredientes.isEmpty ? [.gray, .gray.opacity(0.8)] : [.appleGreen, .green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(
                color: vm.ingredientes.isEmpty ? .clear : .appleGreen.opacity(0.4),
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .disabled(vm.ingredientes.isEmpty || vm.isLoading)
        .scaleEffect(vm.ingredientes.isEmpty ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: vm.ingredientes.isEmpty)
    }
    
    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "basket.fill")
                    .foregroundColor(.appleGreen)
                    .font(.title3)
                
                Text("Available Ingredients")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(vm.ingredientes.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appleGreen)
                    .clipShape(Capsule())
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(vm.ingredientes) { ingrediente in
                    IngredientCard(ingrediente: ingrediente) {
                        withAnimation(.spring(response: 0.4)) {
                            if let index = vm.ingredientes.firstIndex(where: { $0.id == ingrediente.id }) {
                                vm.ingredientes.remove(at: index)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Suggestions Section
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.appleGreen)
                    .font(.title3)
                
                Text("Meal Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !vm.comidasSugeridas.isEmpty {
                    Text("\(vm.comidasSugeridas.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appleGreen)
                        .clipShape(Capsule())
                }
            }
            
            if vm.comidasSugeridas.isEmpty && !vm.isLoading {
                EmptyStateView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.comidasSugeridas) { comida in
                        MealCard(comida: comida)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Funciones
    private func agregarIngrediente() {
        let texto = nuevoIngrediente.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else {
            showingEmptyAlert = true
            return
        }
        
        // Verificar si ya existe
        guard !vm.ingredientes.contains(where: { $0.nombre.lowercased() == texto.lowercased() }) else {
            nuevoIngrediente = ""
            return
        }
        
        let igEstimado = estimarIG(para: texto)
        
        withAnimation(.spring(response: 0.4)) {
            vm.ingredientes.append(Ingrediente(nombre: texto.capitalized, indiceGlucemico: igEstimado))
        }
        
        nuevoIngrediente = ""
    }
    
    private func estimarIG(para nombre: String) -> Int {
        let mapping: [String: Int] = [
            "lettuce": 10, "spinach": 15, "cucumber": 15, "tomato": 30,
            "apple": 40, "white bread": 75, "white rice": 70,
            "pasta": 55, "walnuts": 25, "chicken": 0, "salmon": 0,
            "yogurt": 35, "broccoli": 25, "avocado": 15,
            "quinoa": 53, "protein": 0, "berries": 25
        ]
        let clave = nombre.lowercased()
        return mapping[clave, default: 50]
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.lightGray)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appleGreen.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Ingredient Card
struct IngredientCard: View {
    let ingrediente: Ingrediente
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: ingrediente.igCategory.icon)
                .foregroundColor(ingrediente.igCategory.color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ingrediente.nombre)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("GI: \(ingrediente.indiceGlucemico)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.warmRed)
                    .font(.title3)
            }
        }
        .padding(12)
        .background(ingrediente.igCategory.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ingrediente.igCategory.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Meal Card
struct MealCard: View {
    let comida: Comida
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(comida.nombre)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: comida.categoria.icon)
                            .foregroundColor(comida.categoria.color)
                            .font(.caption)
                        
                        Text("Average GI: \(Int(comida.igPromedio))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(comida.categoria.label)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(comida.categoria.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(comida.categoria.color.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Image(systemName: "heart.fill")
                    .foregroundColor(.appleGreen)
                    .font(.title2)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(comida.ingredientes) { ingrediente in
                        Text(ingrediente.nombre)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.lightGray)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.cardBackground, comida.categoria.color.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(comida.categoria.color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: comida.categoria.color.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No suggestions yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Add ingredients and press 'Recommend' to discover delicious recipes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 30)
    }
}

// MARK: - Preview
struct SuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionsView()
    }
}
