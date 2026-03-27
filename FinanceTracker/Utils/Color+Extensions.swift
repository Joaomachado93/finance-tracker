import SwiftUI

extension Color {
    static let receita = Color.green
    static let despesa = Color.red
    static let saldoPositivo = Color.green
    static let saldoNegativo = Color.red

    static func paraTipo(_ tipo: TransactionType) -> Color {
        switch tipo {
        case .receita: return .receita
        case .despesa: return .despesa
        }
    }

    static func paraSaldo(_ valor: Double) -> Color {
        valor >= 0 ? .saldoPositivo : .saldoNegativo
    }
}
