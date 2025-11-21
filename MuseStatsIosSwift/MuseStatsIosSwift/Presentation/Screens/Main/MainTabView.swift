import SwiftUI

/// Vista principal con tabs después de autenticarse
/// Muestra: Training, History, Settings
struct MainTabView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Training
            ConnectMuseView()
                .tabItem {
                    Label("Entrenar", systemImage: "brain.head.profile")
                }
                .tag(0)
            
            // Tab 2: History
            HistoryView()
                .tabItem {
                    Label("Historial", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
            
            // Tab 3: Settings
            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppCoordinator())
    }
}

