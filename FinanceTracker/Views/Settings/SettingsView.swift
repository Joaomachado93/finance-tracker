import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todasTransacoes: [Transaction]

    @AppStorage("simboloMoeda") private var simboloMoeda = "€"
    @State private var mostrarConfirmacaoLimpar = false
    @State private var mostrarConfirmacaoExportar = false
    @State private var dadosLimpos = false

    var body: some View {
        NavigationStack {
            Form {
                // Moeda
                Section("Moeda") {
                    HStack {
                        Label("Símbolo", systemImage: "eurosign.circle")
                        Spacer()
                        Picker("", selection: $simboloMoeda) {
                            Text("€ Euro").tag("€")
                            Text("$ Dólar").tag("$")
                            Text("£ Libra").tag("£")
                            Text("R$ Real").tag("R$")
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Dados
                Section("Dados") {
                    HStack {
                        Label("Total de transações", systemImage: "number.circle")
                        Spacer()
                        Text("\(todasTransacoes.count)")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        mostrarConfirmacaoExportar = true
                    } label: {
                        Label("Exportar dados", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        mostrarConfirmacaoLimpar = true
                    } label: {
                        Label("Limpar todos os dados", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }

                // Sobre
                Section("Sobre") {
                    HStack {
                        Label("Versão", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Plataforma", systemImage: "iphone")
                        Spacer()
                        Text("iOS 17+")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Armazenamento", systemImage: "internaldrive")
                        Spacer()
                        Text("Local (SwiftData)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "banknote")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        Text("Finanças")
                            .font(.headline)
                        Text("Gerir as suas finanças pessoais de forma simples e eficaz.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Definições")
            .alert("Limpar Dados", isPresented: $mostrarConfirmacaoLimpar) {
                Button("Cancelar", role: .cancel) {}
                Button("Limpar Tudo", role: .destructive) {
                    limparDados()
                }
            } message: {
                Text("Tem a certeza que deseja apagar todas as \(todasTransacoes.count) transações? Esta ação não pode ser revertida.")
            }
            .alert("Exportar Dados", isPresented: $mostrarConfirmacaoExportar) {
                Button("OK") {}
            } message: {
                Text("Funcionalidade de exportação será disponibilizada numa futura atualização.")
            }
            .alert("Dados Limpos", isPresented: $dadosLimpos) {
                Button("OK") {}
            } message: {
                Text("Todas as transações foram apagadas com sucesso.")
            }
        }
    }

    private func limparDados() {
        do {
            try modelContext.delete(model: Transaction.self)
            dadosLimpos = true
        } catch {
            print("Erro ao limpar dados: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
