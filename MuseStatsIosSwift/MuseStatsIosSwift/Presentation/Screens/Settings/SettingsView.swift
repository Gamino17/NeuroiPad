import SwiftUI

/// Vista de configuración y perfil del usuario
/// Permite ver información del usuario y cerrar sesión
struct SettingsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User section
                Section {
                    userProfileRow
                }
                
                // App info
                Section("Aplicación") {
                    InfoSettingRow(
                        icon: "info.circle",
                        title: "Versión",
                        value: Bundle.main.appVersion
                    )
                    
                    InfoSettingRow(
                        icon: "number",
                        title: "Build",
                        value: Bundle.main.buildNumber
                    )
                }
                
                // About
                Section("Acerca de") {
                    NavigationLink(destination: AboutView()) {
                        SettingRow(icon: "info.circle", title: "Acerca de NeuroiPad")
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        SettingRow(icon: "link", title: "Sitio Web")
                    }
                }
                
                // Danger zone
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Cerrar Sesión")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Ajustes")
            .alert("¿Cerrar sesión?", isPresented: $showLogoutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar Sesión", role: .destructive) {
                    coordinator.logout()
                }
            } message: {
                Text("¿Estás seguro de que quieres cerrar sesión?")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - User Profile Row
    
    private var userProfileRow: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text(coordinator.currentUser?.name.prefix(2).uppercased() ?? "??")
                    .font(.title3.bold())
                    .foregroundColor(.blue)
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(coordinator.currentUser?.name ?? "Usuario")
                    .font(.headline)
                
                Text(coordinator.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Role badge
                Text(coordinator.currentUser?.role.rawValue.capitalized ?? "")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Setting Row

struct SettingRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
        }
    }
}

// MARK: - Info Setting Row

struct InfoSettingRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("NeuroiPad")
                        .font(.title.bold())
                    
                    Text("v\(Bundle.main.appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Acerca de")
                        .font(.headline)
                    
                    Text("NeuroiPad es una aplicación de entrenamiento de neurofeedback que te permite realizar sesiones de 5 minutos con tu banda Muse, capturando datos EEG en tiempo real y sincronizándolos con la nube.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 12) {
                    Text("Características")
                        .font(.headline)
                    
                    FeatureRow(icon: "brain", text: "Captura de datos EEG en tiempo real")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Visualización de señales")
                    FeatureRow(icon: "icloud.and.arrow.up", text: "Sincronización automática")
                    FeatureRow(icon: "lock.shield", text: "Almacenamiento seguro")
                }
                
                // Tech stack
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tecnologías")
                        .font(.headline)
                    
                    Text("• SwiftUI & Combine\n• Clean Architecture + MVVM\n• Muse SDK (LibMuse)\n• MongoDB + NestJS Backend")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Credits
                Text("Desarrollado con ❤️ por NeuroiPad Team")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 40)
            }
            .padding()
        }
        .navigationTitle("Acerca de")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppCoordinator())
    }
}

