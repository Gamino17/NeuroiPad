import SwiftUI
import Combine

/// Punto de entrada principal de la aplicación NeuroiPad
/// Configura el entorno y la navegación inicial
@main
struct NeuroiPadApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(appCoordinator)
        }
    }
}

/// Coordinador principal de la aplicación
/// Maneja la navegación entre flujos autenticados y no autenticados
final class AppCoordinator: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    
    private let authRepository: AuthRepositoryProtocol
    private let keychainManager: KeychainManager
    
    init(
        authRepository: AuthRepositoryProtocol = AuthRepository(),
        keychainManager: KeychainManager = .shared
    ) {
        self.authRepository = authRepository
        self.keychainManager = keychainManager
        
        // Verificar si hay sesión activa
        checkAuthenticationStatus()
    }
    
    /// Verifica si el usuario ya está autenticado
    func checkAuthenticationStatus() {
        isAuthenticated = keychainManager.isAuthenticated()
        
        if isAuthenticated {
            Task {
                do {
                    currentUser = try await authRepository.getCurrentUser()
                } catch {
                    print("❌ Error loading user: \(error)")
                    isAuthenticated = false
                }
            }
        }
    }
    
    /// Realiza login
    func login(email: String, password: String) async throws {
        let payload = try await authRepository.login(email: email, password: password)
        await MainActor.run {
            self.currentUser = payload.user
            self.isAuthenticated = true
        }
    }
    
    /// Realiza registro
    func register(data: RegisterData) async throws {
        let payload = try await authRepository.register(data: data)
        await MainActor.run {
            self.currentUser = payload.user
            self.isAuthenticated = true
        }
    }
    
    /// Cierra sesión
    func logout() {
        do {
            try authRepository.logout()
            currentUser = nil
            isAuthenticated = false
        } catch {
            print("❌ Error logging out: \(error)")
        }
    }
}

/// Vista del coordinador que decide qué mostrar
struct AppCoordinatorView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        Group {
            if coordinator.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: coordinator.isAuthenticated)
    }
}

