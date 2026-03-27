import Foundation

extension Date {
    private static let ptLocale = Locale(identifier: "pt_PT")

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = ptLocale
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = ptLocale
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let dayMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = ptLocale
        f.dateFormat = "d MMM"
        return f
    }()

    var mesAnoFormatado: String {
        let result = Date.monthYearFormatter.string(from: self)
        return result.prefix(1).uppercased() + result.dropFirst()
    }

    var dataFormatada: String {
        Date.shortDateFormatter.string(from: self)
    }

    var diaMesFormatado: String {
        Date.dayMonthFormatter.string(from: self)
    }

    var mesAno: String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        let year = calendar.component(.year, from: self)
        return "\(month)-\(year)"
    }

    var ano: Int {
        Calendar.current.component(.year, from: self)
    }

    var mes: Int {
        Calendar.current.component(.month, from: self)
    }

    static func inicioDoMes(date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    static func inicioDoAno(date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date)
        return calendar.date(from: components) ?? date
    }

    static func mesesPortugues() -> [String] {
        return [
            "Janeiro", "Fevereiro", "Março", "Abril",
            "Maio", "Junho", "Julho", "Agosto",
            "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
    }

    static func nomeMes(_ mes: Int) -> String {
        guard mes >= 1 && mes <= 12 else { return "" }
        return mesesPortugues()[mes - 1]
    }
}
