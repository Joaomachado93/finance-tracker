import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.data, order: .reverse) private var todasTransacoes: [Transaction]

    @State private var pesquisa = ""
    @State private var filtroTipo: TransactionType? = nil
    @State private var mostrarAdicionarSheet = false
    @State private var transacaoParaEditar: Transaction? = nil

    private let formatter = CurrencyFormatter.shared

    private var transacoesFiltradas: [Transaction] {
        var resultado = todasTransacoes

        if let filtro = filtroTipo {
            resultado = resultado.filter { $0.tipo == filtro }
        }

        if !pesquisa.isEmpty {
            resultado = resultado.filter {
                $0.descricao.localizedCaseInsensitiveContains(pesquisa) ||
                $0.categoria.localizedCaseInsensitiveContains(pesquisa) ||
                $0.notas.localizedCaseInsensitiveContains(pesquisa)
            }
        }

        return resultado
    }

    private var transacoesAgrupadas: [(String, [Transaction])] {
        let agrupadas = Dictionary(grouping: transacoesFiltradas) { $0.data.mesAno }
        let ordenadas = agrupadas.sorted { lhs, rhs in
            guard let d1 = lhs.value.first?.data, let d2 = rhs.value.first?.data else { return false }
            return d1 > d2
        }
        return ordenadas.map { (chave, transacoes) in
            let primeiraData = transacoes.first?.data ?? Date()
            let titulo = primeiraData.mesAnoFormatado
            return (titulo, transacoes)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if todasTransacoes.isEmpty {
                    estadoVazio
                } else {
                    listaTransacoes
                }
            }
            .navigationTitle("Transações")
            .searchable(text: $pesquisa, prompt: "Pesquisar transações...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrarAdicionarSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $mostrarAdicionarSheet) {
                AddTransactionView()
            }
            .sheet(item: $transacaoParaEditar) { transacao in
                AddTransactionView(transacaoExistente: transacao)
            }
        }
    }

    private var estadoVazio: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            Text("Sem transações")
                .font(.title2.bold())
                .foregroundStyle(.secondary)
            Text("Toque no botão + para adicionar a sua primeira transação")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var listaTransacoes: some View {
        VStack(spacing: 0) {
            // Filtro
            Picker("Filtro", selection: $filtroTipo) {
                Text("Todas").tag(TransactionType?.none)
                Text("Receitas").tag(TransactionType?.some(.receita))
                Text("Despesas").tag(TransactionType?.some(.despesa))
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            List {
                ForEach(transacoesAgrupadas, id: \.0) { secao in
                    let (titulo, transacoes) = secao
                    Section {
                        ForEach(transacoes) { transacao in
                            transacaoRow(transacao)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    transacaoParaEditar = transacao
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        apagarTransacao(transacao)
                                    } label: {
                                        Label("Apagar", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        HStack {
                            Text(titulo)
                            Spacer()
                            let subtotal = transacoes.reduce(0) { $0 + $1.valorComSinal }
                            Text(formatter.formatSigned(subtotal))
                                .foregroundStyle(Color.paraSaldo(subtotal))
                        }
                        .font(.subheadline.bold())
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func transacaoRow(_ transacao: Transaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: transacao.tipo.icon)
                .font(.title3)
                .foregroundStyle(Color.paraTipo(transacao.tipo))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(transacao.descricao)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(transacao.categoria)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.paraTipo(transacao.tipo).opacity(0.1))
                        .clipShape(Capsule())
                    Text(transacao.data.dataFormatada)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text(formatter.formatSigned(transacao.valorComSinal))
                .font(.subheadline.bold())
                .foregroundStyle(Color.paraTipo(transacao.tipo))
        }
        .padding(.vertical, 2)
    }

    private func apagarTransacao(_ transacao: Transaction) {
        withAnimation {
            modelContext.delete(transacao)
        }
    }
}

#Preview {
    TransactionListView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
