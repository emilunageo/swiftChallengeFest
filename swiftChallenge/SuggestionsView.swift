//
//  RefriView.swift
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
        Comida(nombre: "Ensalada de pollo", ingredientes: [
            Ingrediente(nombre: "Lechuga", indiceGlucemico: 10),
            Ingrediente(nombre: "Pollo", indiceGlucemico: 0),
            Ingrediente(nombre: "Tomate", indiceGlucemico: 30)
        ]),
        Comida(nombre: "Batido verde", ingredientes: [
            Ingrediente(nombre: "Espinaca", indiceGlucemico: 15),
            Ingrediente(nombre: "Pepino", indiceGlucemico: 15),
            Ingrediente(nombre: "Manzana", indiceGlucemico: 40)
        ]),
        Comida(nombre: "Yogurt con nueces", ingredientes: [
            Ingrediente(nombre: "Yogurt", indiceGlucemico: 35),
            Ingrediente(nombre: "Nueces", indiceGlucemico: 25)
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
                    TextField("Ingrediente disponible", text: $nuevoIngrediente)
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
                    Text("Recomendar")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                List {
                    Section(header: Text("Ingredientes")
                        .foregroundColor(.green)
                        .font(.headline)) {
                            ForEach(vm.ingredientes) { item in
                                Text(item.nombre)
                            }
                            .onDelete(perform: eliminarIngrediente)
                        }
                    
                    Section(header: Text("Ideas de comida")
                        .foregroundColor(.green)
                        .font(.headline)) {
                            if vm.comidasSugeridas.isEmpty {
                                Text("Añade ingredientes y pulsa 'Recomendar'")
                                    .italic()
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(vm.comidasSugeridas) { comida in
                                    VStack(alignment: .leading) {
                                        Text(comida.nombre)
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        Text("IG promedio: \(Int(comida.igPromedio))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                }
                
            
            }
            .background(Color.green.opacity(0.05))
            .navigationTitle("Qué hay para comer?")
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
            "lechuga": 10, "espinaca": 15, "pepino": 15, "tomate": 30,
            "manzana verde": 40, "pan blanco": 75, "arroz blanco": 70,
            "pasta": 55, "nueces": 25, "pechuga de pollo": 0,
            "yogur natural": 35
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
