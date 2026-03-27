import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Resumo", systemImage: "chart.bar.fill")
                }

            TransactionListView()
                .tabItem {
                    Label("Transações", systemImage: "list.bullet.rectangle.fill")
                }

            AnalyticsView()
                .tabItem {
                    Label("Análise", systemImage: "chart.pie.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Definições", systemImage: "gearshape.fill")
                }
        }
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
