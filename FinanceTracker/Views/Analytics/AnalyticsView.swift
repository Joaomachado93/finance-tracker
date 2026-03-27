import SwiftUI
import SwiftData
import Charts

struct MonthlySummary: Identifiable {
    let id = UUID()
    let mes: Int
    let ano: Int
    let receita: Double
    let despesa: Double
    var saldo: Double { receita - despesa }

    var label: String {
        let nomes = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]
        guard mes >= 1 && mes <= 12 else { return "" }
        return "\(nomes[mes - 1])"
    }

    var sortKey: Int { ano * 100 + mes }
}

struct CategorySummary: Identifiable {
    let id = UUID()
    let categoria: String
    let total: Double
    let percentagem: Double
}

enum PeriodoAnalise: String, CaseIterable, Identifiable {
    case mes = "Mês"
    case ano = "Ano"
    var id: String { rawValue }
}

struct AnalyticsView: View {
    @Query(sort: \Transaction.data, order: .reverse) private var todasTransacoes: [Transaction]

    @State private var periodo: PeriodoAnalise = .mes

    private let formatter = CurrencyFormatter.shared

    // Last 6 months summaries for bar chart
    private var resumoMensal: [MonthlySummary] {
        let calendar = Calendar.current
        let agora = Date()
        var resultados: [MonthlySummary] = []

        for i in 0..<6 {
            guard let mesData = calendar.date(byAdding: .month, value: -i, to: agora) else { continue }
            let mes = calendar.component(.month, from: mesData)
            let ano = calendar.component(.year, from: mesData)

            let transacoesMes = todasTransacoes.filter {
                calendar.component(.month, from: $0.data) == mes &&
                calendar.component(.year, from: $0.data) == ano
            }

            let receita = transacoesMes.filter { $0.tipo == .receita }.reduce(0) { $0 + $1.valor }
            let despesa = transacoesMes.filter { $0.tipo == .despesa }.reduce(0) { $0 + $1.valor }

            resultados.append(MonthlySummary(mes: mes, ano: ano, receita: receita, despesa: despesa))
        }

        return resultados.sorted { $0.sortKey < $1.sortKey }
    }

    // Last 12 months balance evolution for line chart
    private var evolucaoSaldo: [(label: String, saldo: Double)] {
        let calendar = Calendar.current
        let agora = Date()
        var resultados: [(label: String, saldo: Double)] = []
        var saldoAcumulado: Double = 0

        // Get all transactions before 12 months ago for initial balance
        guard let inicio12Meses = calendar.date(byAdding: .month, value: -11, to: agora) else { return [] }
        let inicioDoMes = Date.inicioDoMes(date: inicio12Meses)

        let transacoesAnteriores = todasTransacoes.filter { $0.data < inicioDoMes }
        saldoAcumulado = transacoesAnteriores.reduce(0) { $0 + $1.valorComSinal }

        for i in (0...11).reversed() {
            guard let mesData = calendar.date(byAdding: .month, value: -i, to: agora) else { continue }
            let mes = calendar.component(.month, from: mesData)
            let ano = calendar.component(.year, from: mesData)

            let transacoesMes = todasTransacoes.filter {
                calendar.component(.month, from: $0.data) == mes &&
                calendar.component(.year, from: $0.data) == ano
            }

            saldoAcumulado += transacoesMes.reduce(0) { $0 + $1.valorComSinal }

            let nomes = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]
            let label = mes >= 1 && mes <= 12 ? nomes[mes - 1] : ""
            resultados.append((label: label, saldo: saldoAcumulado))
        }

        return resultados
    }

    // Expenses by category for selected period
    private var despesasPorCategoria: [CategorySummary] {
        let calendar = Calendar.current
        let agora = Date()

        let transacoesFiltradas: [Transaction]
        switch periodo {
        case .mes:
            let mes = calendar.component(.month, from: agora)
            let ano = calendar.component(.year, from: agora)
            transacoesFiltradas = todasTransacoes.filter {
                $0.tipo == .despesa &&
                calendar.component(.month, from: $0.data) == mes &&
                calendar.component(.year, from: $0.data) == ano
            }
        case .ano:
            let ano = calendar.component(.year, from: agora)
            transacoesFiltradas = todasTransacoes.filter {
                $0.tipo == .despesa &&
                calendar.component(.year, from: $0.data) == ano
            }
        }

        let agrupadas = Dictionary(grouping: transacoesFiltradas) { $0.categoria }
        let totalGeral = transacoesFiltradas.reduce(0) { $0 + $1.valor }

        return agrupadas.map { (cat, trans) in
            let total = trans.reduce(0) { $0 + $1.valor }
            let pct = totalGeral > 0 ? (total / totalGeral) * 100 : 0
            return CategorySummary(categoria: cat, total: total, percentagem: pct)
        }
        .sorted { $0.total > $1.total }
    }

    // Summary stats for selected period
    private var totalReceitaPeriodo: Double {
        transacoesPeriodo.filter { $0.tipo == .receita }.reduce(0) { $0 + $1.valor }
    }

    private var totalDespesaPeriodo: Double {
        transacoesPeriodo.filter { $0.tipo == .despesa }.reduce(0) { $0 + $1.valor }
    }

    private var taxaPoupanca: Double {
        guard totalReceitaPeriodo > 0 else { return 0 }
        return ((totalReceitaPeriodo - totalDespesaPeriodo) / totalReceitaPeriodo) * 100
    }

    private var transacoesPeriodo: [Transaction] {
        let calendar = Calendar.current
        let agora = Date()
        switch periodo {
        case .mes:
            let mes = calendar.component(.month, from: agora)
            let ano = calendar.component(.year, from: agora)
            return todasTransacoes.filter {
                calendar.component(.month, from: $0.data) == mes &&
                calendar.component(.year, from: $0.data) == ano
            }
        case .ano:
            let ano = calendar.component(.year, from: agora)
            return todasTransacoes.filter {
                calendar.component(.year, from: $0.data) == ano
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Periodo picker
                    Picker("Período", selection: $periodo) {
                        ForEach(PeriodoAnalise.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Summary stats
                    statsCards

                    // Bar chart: income vs expenses
                    graficoBarras

                    // Pie chart: expenses by category
                    graficoPizza

                    // Line chart: balance evolution
                    graficoLinha
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Análise")
        }
    }

    private var statsCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(
                    titulo: "Receitas",
                    valor: formatter.format(totalReceitaPeriodo),
                    cor: .green,
                    icone: "arrow.up.circle.fill"
                )
                statCard(
                    titulo: "Despesas",
                    valor: formatter.format(totalDespesaPeriodo),
                    cor: .red,
                    icone: "arrow.down.circle.fill"
                )
            }

            HStack(spacing: 12) {
                let saldo = totalReceitaPeriodo - totalDespesaPeriodo
                statCard(
                    titulo: "Saldo",
                    valor: formatter.formatSigned(saldo),
                    cor: Color.paraSaldo(saldo),
                    icone: "banknote"
                )
                statCard(
                    titulo: "Taxa Poupança",
                    valor: String(format: "%.1f%%", taxaPoupanca),
                    cor: taxaPoupanca >= 0 ? .blue : .orange,
                    icone: "percent"
                )
            }
        }
        .padding(.horizontal)
    }

    private func statCard(titulo: String, valor: String, cor: Color, icone: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icone)
                    .foregroundStyle(cor)
                Text(titulo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(valor)
                .font(.headline)
                .foregroundStyle(cor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var graficoBarras: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Receitas vs Despesas")
                .font(.headline)
                .padding(.horizontal)

            if resumoMensal.allSatisfy({ $0.receita == 0 && $0.despesa == 0 }) {
                semDadosView
            } else {
                Chart(resumoMensal) { item in
                    BarMark(
                        x: .value("Mês", item.label),
                        y: .value("Valor", item.receita)
                    )
                    .foregroundStyle(.green)
                    .position(by: .value("Tipo", "Receita"))

                    BarMark(
                        x: .value("Mês", item.label),
                        y: .value("Valor", item.despesa)
                    )
                    .foregroundStyle(.red)
                    .position(by: .value("Tipo", "Despesa"))
                }
                .chartForegroundStyleScale([
                    "Receita": .green,
                    "Despesa": .red
                ])
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text(abreviarValor(val))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 220)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var graficoPizza: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Despesas por Categoria")
                .font(.headline)
                .padding(.horizontal)

            if despesasPorCategoria.isEmpty {
                semDadosView
            } else {
                Chart(despesasPorCategoria) { item in
                    SectorMark(
                        angle: .value("Valor", item.total),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Categoria", item.categoria))
                    .cornerRadius(4)
                }
                .frame(height: 220)
                .padding(.horizontal)

                // Legend
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(despesasPorCategoria) { item in
                        HStack {
                            Text(item.categoria)
                                .font(.caption)
                            Spacer()
                            Text(formatter.format(item.total))
                                .font(.caption.bold())
                            Text(String(format: "(%.0f%%)", item.percentagem))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var graficoLinha: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evolução do Saldo")
                .font(.headline)
                .padding(.horizontal)

            if evolucaoSaldo.allSatisfy({ $0.saldo == 0 }) {
                semDadosView
            } else {
                Chart {
                    ForEach(Array(evolucaoSaldo.enumerated()), id: \.offset) { index, item in
                        LineMark(
                            x: .value("Mês", item.label),
                            y: .value("Saldo", item.saldo)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Mês", item.label),
                            y: .value("Saldo", item.saldo)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .blue.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Mês", item.label),
                            y: .value("Saldo", item.saldo)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(30)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text(abreviarValor(val))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 220)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var semDadosView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("Sem dados suficientes")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    private func abreviarValor(_ valor: Double) -> String {
        let abs = Swift.abs(valor)
        let sinal = valor < 0 ? "-" : ""
        if abs >= 1000 {
            return "\(sinal)\(String(format: "%.0f", abs / 1000))k"
        }
        return "\(sinal)\(String(format: "%.0f", abs))€"
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
