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
}

struct Comida: Identifiable {
    let id = UUID()
    var nombre: String
    var ingredientes: [Ingrediente]
    var igPromedio: Double {
        let total = ingredientes.map { Double($0.indiceGlucemico) }.reduce(0, +)
        return ingredientes.isEmpty ? 0 : total / Double(ingredientes.count)
    }
}

// MARK: - ViewModel
class SuggestionsViewModel: ObservableObject {
    @Published var ingredientes = [Ingrediente]()
    @Published var comidasSugeridas = [Comida]()
    
    private let todasComidas: [Comida] = [
        Comida(nombre: "Chicken Salad", ingredientes: [
            Ingrediente(nombre: "Lettuce", indiceGlucemico: 10),
            Ingrediente(nombre: "Chicken", indiceGlucemico: 0),
            Ingrediente(nombre: "Tomato", indiceGlucemico: 30)
        ]),
        Comida(nombre: "Green smoothie", ingredientes: [
            Ingrediente(nombre: "Spinach", indiceGlucemico: 15),
            Ingrediente(nombre: "Cucumber", indiceGlucemico: 15),
            Ingrediente(nombre: "Apple", indiceGlucemico: 40)
        ]),
        Comida(nombre: "Yogurt with walnuts", ingredientes: [
            Ingrediente(nombre: "Yogurt", indiceGlucemico: 35),
            Ingrediente(nombre: "Walnuts", indiceGlucemico: 25)
        ])
    ]
    
    func recomendar() {
        let disponibles = Set(ingredientes.map { $0.nombre.lowercased() })
        let posibles = todasComidas.filter { comida in
            let reqs = Set(comida.ingredientes.map { $0.nombre.lowercased() })
            return reqs.isSubset(of: disponibles)
        }
        comidasSugeridas = posibles.filter { $0.igPromedio <= 50 }
    }
}

// MARK: - View
struct SuggestionsView: View {
    @StateObject private var vm = SuggestionsViewModel()
    @State private var nuevoIngrediente = ""
    
    var body: some View {
        NavigationView {
            VStack {
                HStack(spacing: 12) {
                    TextField("Available Ingredients", text: $nuevoIngrediente)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: agregarIngrediente) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.title)
                            
                    }
                    .padding(.horizontal)
                    
                   
                }

                Button(action: vm.recomendar) {
                    Text("Recommend")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                List {
                    Section(header: Text("Ingredients")
                        .foregroundColor(.green)
                        .font(.headline)) {
                            ForEach(vm.ingredientes) { item in
                                Text(item.nombre)
                            }
                            .onDelete(perform: eliminarIngrediente)
                        }
                    
                    Section(header: Text("Meal ideas")
                        .foregroundColor(.green)
                        .font(.headline)) {
                            if vm.comidasSugeridas.isEmpty {
                                Text("Add ingredients and press 'Recommend'")
                                    .italic()
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(vm.comidasSugeridas) { comida in
                                    VStack(alignment: .leading) {
                                        Text(comida.nombre)
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        Text("Average GI: \(Int(comida.igPromedio))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                }
                
            
            }
            .background(Color.green.opacity(0.05))
            .navigationTitle("What's there to eat?")
        }
    }
    
    // MARK: - Funciones
    private func agregarIngrediente() {
        let texto = nuevoIngrediente.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { return }
        let igEstimado = estimarIG(para: texto)
        vm.ingredientes.append(Ingrediente(nombre: texto, indiceGlucemico: igEstimado))
        nuevoIngrediente = ""
    }
    
    private func eliminarIngrediente(at offsets: IndexSet) {
        vm.ingredientes.remove(atOffsets: offsets)
    }
    
    private func estimarIG(para nombre: String) -> Int {
        let mapping: [String: Int] = [
            "lettuce": 10, "spinach": 15, "cucumber": 15, "tomato": 30,
            "apple": 40, "white bread": 75, "white rice": 70,
            "pasta": 55, "walnuts": 25, "chicken": 0,
            "yogurt": 35
        ]
        let clave = nombre.lowercased()
        return mapping[clave, default: 50]
    }
}

// MARK: - Preview
struct RecomendadorView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionsView()
    }
}
