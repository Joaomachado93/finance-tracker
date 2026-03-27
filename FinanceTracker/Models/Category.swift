import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var nome: String
    var tipoRaw: String

    var tipo: TransactionType {
        get { TransactionType(rawValue: tipoRaw) ?? .despesa }
        set { tipoRaw = newValue.rawValue }
    }

    init(nome: String, tipo: TransactionType) {
        self.id = UUID()
        self.nome = nome
        self.tipoRaw = tipo.rawValue
    }
}
