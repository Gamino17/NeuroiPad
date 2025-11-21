import SwiftUI
import Combine

/// ViewModel para la pantalla de autenticación
/// Maneja login y registro de usuarios
@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Validación
    var isLoginValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 8
    }
    
    var isRegisterValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && password.count >= 8
    }
    
    /// Realiza login
    func login(coordinator: AppCoordinator) async {
        guard isLoginValid else { return }
        
        isLoading = true
        
        do {
            try await coordinator.login(email: email, password: password)
            clearForm()
        } catch APIClient.APIError.unauthorized {
            showErrorAlert("Credenciales incorrectas. Verifica tu email y contraseña.")
        } catch APIClient.APIError.serverError(let code, let message) {
            showErrorAlert("Error del servidor (\(code)): \(message ?? "Unknown")")
        } catch APIClient.APIError.networkError(let error) {
            showErrorAlert("Error de conexión: \(error.localizedDescription)")
        } catch {
            showErrorAlert("Error inesperado: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Realiza registro
    func register(coordinator: AppCoordinator) async {
        guard isRegisterValid else { return }
        
        isLoading = true
        
        do {
            let registerData = RegisterData(
                email: email,
                password: password,
                name: name,
                role: .athlete
            )
            
            try await coordinator.register(data: registerData)
            clearForm()
        } catch APIClient.APIError.serverError(409, _) {
            showErrorAlert("Este email ya está registrado. Intenta iniciar sesión.")
        } catch APIClient.APIError.serverError(let code, let message) {
            showErrorAlert("Error del servidor (\(code)): \(message ?? "Unknown")")
        } catch APIClient.APIError.networkError(let error) {
            showErrorAlert("Error de conexión: \(error.localizedDescription)")
        } catch {
            showErrorAlert("Error inesperado: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Limpia el formulario
    func clearForm() {
        email = ""
        password = ""
        name = ""
    }
    
    /// Muestra un alert de error
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }
}

