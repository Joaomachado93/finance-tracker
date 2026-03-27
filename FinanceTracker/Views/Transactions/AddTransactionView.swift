import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.nome) private var customCategories: [Category]

    let transacaoExistente: Transaction?

    @State private var tipo: TransactionType = .despesa
    @State private var descricao = ""
    @State private var valorTexto = ""
    @State private var categoria = ""
    @State private var data = Date()
    @State private var notas = ""

    private var editando: Bool { transacaoExistente != nil }

    private var categorias: [String] {
        let predefinidas = Transaction.categorias(para: tipo)
        let custom = customCategories.filter { $0.tipo == tipo }.map(\.nome)
        return predefinidas + custom
    }

    private var formularioValido: Bool {
        !descricao.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(valorTexto.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0 &&
        !categoria.isEmpty
    }

    init(transacaoExistente: Transaction? = nil) {
        self.transacaoExistente = transacaoExistente
    }

    var body: some View {
        NavigationStack {
            Form {
                // Tipo
                Section {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(TransactionType.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                // Detalhes
                Section("Detalhes") {
                    TextField("Descrição", text: $descricao)
                        .textInputAutocapitalization(.sentences)

                    HStack {
                        Text("€")
                            .foregroundStyle(.secondary)
                        TextField("Valor", text: $valorTexto)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Categoria", selection: $categoria) {
                        Text("Selecionar...").tag("")
                        ForEach(categorias, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }

                    DatePicker("Data", selection: $data, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "pt_PT"))
                }

                // Notas
                Section("Notas (opcional)") {
                    TextField("Notas adicionais...", text: $notas, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(editando ? "Editar Transação" : "Nova Transação")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        guardar()
                    }
                    .bold()
                    .disabled(!formularioValido)
                }
            }
            .onChange(of: tipo) { _, _ in
                if !categorias.contains(categoria) {
                    categoria = ""
                }
            }
            .onAppear {
                if let t = transacaoExistente {
                    tipo = t.tipo
                    descricao = t.descricao
                    valorTexto = String(format: "%.2f", t.valor)
                    categoria = t.categoria
                    data = t.data
                    notas = t.notas
                }
            }
        }
    }

    private func guardar() {
        let valor = Double(valorTexto.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let transacao = transacaoExistente {
            transacao.tipo = tipo
            transacao.descricao = descricao.trimmingCharacters(in: .whitespaces)
            transacao.valor = valor
            transacao.categoria = categoria
            transacao.data = data
            transacao.notas = notas.trimmingCharacters(in: .whitespaces)
        } else {
            let novaTransacao = Transaction(
                descricao: descricao.trimmingCharacters(in: .whitespaces),
                valor: valor,
                tipo: tipo,
                categoria: categoria,
                data: data,
                notas: notas.trimmingCharacters(in: .whitespaces)
            )
            modelContext.insert(novaTransacao)
        }

        dismiss()
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
