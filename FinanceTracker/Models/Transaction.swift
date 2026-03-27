import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case receita = "Receita"
    case despesa = "Despesa"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .receita: return "arrow.up.circle.fill"
        case .despesa: return "arrow.down.circle.fill"
        }
    }
}

@Model
final class Transaction {
    var id: UUID
    var descricao: String
    var valor: Double
    var tipoRaw: String
    var categoria: String
    var data: Date
    var notas: String

    var tipo: TransactionType {
        get { TransactionType(rawValue: tipoRaw) ?? .despesa }
        set { tipoRaw = newValue.rawValue }
    }

    var valorComSinal: Double {
        tipo == .receita ? valor : -valor
    }

    init(
        id: UUID = UUID(),
        descricao: String = "",
        valor: Double = 0,
        tipo: TransactionType = .despesa,
        categoria: String = "",
        data: Date = Date(),
        notas: String = ""
    ) {
        self.id = id
        self.descricao = descricao
        self.valor = valor
        self.tipoRaw = tipo.rawValue
        self.categoria = categoria
        self.data = data
        self.notas = notas
    }

    static var categoriasReceita: [String] {
        ["Salário", "Freelance", "Investimentos", "IRS Reembolso", "Outros"]
    }

    static var categoriasDespesa: [String] {
        ["Alimentação", "Transportes", "Habitação", "Saúde", "Educação", "Lazer", "Roupa", "Tecnologia", "Impostos", "Seguros", "Outros"]
    }

    static func categorias(para tipo: TransactionType) -> [String] {
        switch tipo {
        case .receita: return categoriasReceita
        case .despesa: return categoriasDespesa
        }
    }
}
