import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Transaction.data, order: .reverse) private var todasTransacoes: [Transaction]

    private let formatter = CurrencyFormatter.shared

    private var saldoTotal: Double {
        todasTransacoes.reduce(0) { $0 + $1.valorComSinal }
    }

    private var transacoesMesAtual: [Transaction] {
        let inicio = Date.inicioDoMes()
        return todasTransacoes.filter { $0.data >= inicio }
    }

    private var transacoesAnoAtual: [Transaction] {
        let inicio = Date.inicioDoAno()
        return todasTransacoes.filter { $0.data >= inicio }
    }

    private var receitaMes: Double {
        transacoesMesAtual.filter { $0.tipo == .receita }.reduce(0) { $0 + $1.valor }
    }

    private var despesaMes: Double {
        transacoesMesAtual.filter { $0.tipo == .despesa }.reduce(0) { $0 + $1.valor }
    }

    private var receitaAno: Double {
        transacoesAnoAtual.filter { $0.tipo == .receita }.reduce(0) { $0 + $1.valor }
    }

    private var despesaAno: Double {
        transacoesAnoAtual.filter { $0.tipo == .despesa }.reduce(0) { $0 + $1.valor }
    }

    private var ultimasTransacoes: [Transaction] {
        Array(todasTransacoes.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Saldo total
                    saldoTotalCard

                    // Resumo do mes
                    resumoCard(
                        titulo: "Este Mês",
                        subtitulo: Date().mesAnoFormatado,
                        receita: receitaMes,
                        despesa: despesaMes,
                        icone: "calendar"
                    )

                    // Resumo do ano
                    resumoCard(
                        titulo: "Este Ano",
                        subtitulo: "\(Date().ano)",
                        receita: receitaAno,
                        despesa: despesaAno,
                        icone: "calendar.badge.clock"
                    )

                    // Ultimas transacoes
                    ultimasTransacoesSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Resumo")
        }
    }

    private var saldoTotalCard: some View {
        VStack(spacing: 8) {
            Text("Saldo Total")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(formatter.format(saldoTotal))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(Color.paraSaldo(saldoTotal))

            Text("Todas as transações")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func resumoCard(
        titulo: String,
        subtitulo: String,
        receita: Double,
        despesa: Double,
        icone: String
    ) -> some View {
        let saldo = receita - despesa

        return VStack(spacing: 16) {
            HStack {
                Image(systemName: icone)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titulo)
                        .font(.headline)
                    Text(subtitulo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(formatter.formatSigned(saldo))
                    .font(.headline)
                    .foregroundStyle(Color.paraSaldo(saldo))
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Receitas", systemImage: "arrow.up.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(formatter.format(receita))
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Label("Despesas", systemImage: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Text(formatter.format(despesa))
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var ultimasTransacoesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Últimas Transações")
                    .font(.headline)
                Spacer()
            }

            if ultimasTransacoes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("Sem transações")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Adicione a sua primeira transação no separador Transações")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(ultimasTransacoes) { transacao in
                    transacaoRow(transacao)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func transacaoRow(_ transacao: Transaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: transacao.tipo.icon)
                .font(.title2)
                .foregroundStyle(Color.paraTipo(transacao.tipo))

            VStack(alignment: .leading, spacing: 2) {
                Text(transacao.descricao)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(transacao.categoria)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatter.formatSigned(transacao.valorComSinal))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.paraTipo(transacao.tipo))
                Text(transacao.data.diaMesFormatado)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
