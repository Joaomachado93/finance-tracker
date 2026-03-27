import Foundation

struct CurrencyFormatter {
    static let shared = CurrencyFormatter()

    private let formatter: NumberFormatter

    init(currencySymbol: String = "€") {
        formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
    }

    func format(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "\(value) €"
    }

    func formatSigned(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : ""
        return prefix + format(value)
    }
}
