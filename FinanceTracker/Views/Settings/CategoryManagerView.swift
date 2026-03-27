import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.nome) private var customCategories: [Category]

    @State private var showingAdd = false
    @State private var novoNome = ""
    @State private var novoTipo: TransactionType = .despesa

    private var categoriasReceita: [CategoryItem] {
        let predefinidas = Transaction.categoriasReceita.map { CategoryItem(nome: $0, custom: false) }
        let custom = customCategories.filter { $0.tipo == .receita }.map { CategoryItem(nome: $0.nome, custom: true, id: $0.id) }
        return predefinidas + custom
    }

    private var categoriasDespesa: [CategoryItem] {
        let predefinidas = Transaction.categoriasDespesa.map { CategoryItem(nome: $0, custom: false) }
        let custom = customCategories.filter { $0.tipo == .despesa }.map { CategoryItem(nome: $0.nome, custom: true, id: $0.id) }
        return predefinidas + custom
    }

    var body: some View {
        List {
            Section("Categorias de Receita") {
                ForEach(categoriasReceita) { cat in
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(Color.receita)
                            .font(.caption)
                        Text(cat.nome)
                        Spacer()
                        if !cat.custom {
                            Text("Predefinida")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    deleteCategories(from: categoriasReceita, at: indexSet)
                }
            }

            Section("Categorias de Despesa") {
                ForEach(categoriasDespesa) { cat in
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(Color.despesa)
                            .font(.caption)
                        Text(cat.nome)
                        Spacer()
                        if !cat.custom {
                            Text("Predefinida")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    deleteCategories(from: categoriasDespesa, at: indexSet)
                }
            }
        }
        .navigationTitle("Categorias")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddCategorySheet(customCategories: customCategories) { nome, tipo in
                let category = Category(nome: nome, tipo: tipo)
                modelContext.insert(category)
            }
        }
    }

    private func deleteCategories(from list: [CategoryItem], at offsets: IndexSet) {
        for index in offsets {
            let item = list[index]
            guard item.custom, let itemId = item.id else { continue }
            if let category = customCategories.first(where: { $0.id == itemId }) {
                modelContext.delete(category)
            }
        }
    }

    private func addCategory() {
        let nome = novoNome.trimmingCharacters(in: .whitespaces)
        guard !nome.isEmpty else { return }
        let category = Category(nome: nome, tipo: novoTipo)
        modelContext.insert(category)
        novoNome = ""
    }
}

private struct CategoryItem: Identifiable {
    let nome: String
    let custom: Bool
    var id: UUID?

    init(nome: String, custom: Bool, id: UUID? = nil) {
        self.nome = nome
        self.custom = custom
        self.id = id ?? UUID()
    }
}

struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let customCategories: [Category]
    let onSave: (String, TransactionType) -> Void

    @State private var nome = ""
    @State private var tipo: TransactionType = .despesa

    private var nomeValido: Bool {
        let trimmed = nome.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        let existentes = tipo == .receita
            ? Transaction.categoriasReceita + customCategories.filter { $0.tipo == .receita }.map(\.nome)
            : Transaction.categoriasDespesa + customCategories.filter { $0.tipo == .despesa }.map(\.nome)

        return !existentes.contains(where: { $0.lowercased() == trimmed.lowercased() })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tipo") {
                    Picker("Tipo", selection: $tipo) {
                        Text("Receita").tag(TransactionType.receita)
                        Text("Despesa").tag(TransactionType.despesa)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                Section("Nome") {
                    TextField("Nome da categoria", text: $nome)
                        .textInputAutocapitalization(.words)
                }

                if !nome.isEmpty && !nomeValido {
                    Section {
                        Text("Esta categoria já existe.")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Nova Categoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        onSave(nome.trimmingCharacters(in: .whitespaces), tipo)
                        dismiss()
                    }
                    .bold()
                    .disabled(!nomeValido)
                }
            }
        }
    }
}
