import Foundation

/// Protocolo del repositorio de autenticación
protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> AuthPayload
    func register(data: RegisterData) async throws -> AuthPayload
    func refreshToken() async throws -> String
    func logout() throws
    func getCurrentUser() async throws -> User?
    func isAuthenticated() -> Bool
}

/// Implementación del repositorio de autenticación
final class AuthRepository: AuthRepositoryProtocol {
    private let apiClient: APIClient
    private let keychainManager: KeychainManager
    
    init(
        apiClient: APIClient = .shared,
        keychainManager: KeychainManager = .shared
    ) {
        self.apiClient = apiClient
        self.keychainManager = keychainManager
    }
    
    /// Login de usuario
    func login(email: String, password: String) async throws -> AuthPayload {
        let request = LoginRequest(email: email, password: password)
        let payload: AuthPayload = try await apiClient.post(
            endpoint: Endpoints.login,
            body: request,
            requiresAuth: false
        )
        
        // Guardar tokens en Keychain
        try keychainManager.saveAuthTokens(
            accessToken: payload.accessToken,
            refreshToken: payload.refreshToken
        )
        
        // Guardar user ID
        try keychainManager.save(payload.user.id, for: .userId)
        
        return payload
    }
    
    /// Registro de nuevo usuario
    func register(data: RegisterData) async throws -> AuthPayload {
        let request = RegisterRequest(
            email: data.email,
            password: data.password,
            name: data.name,
            role: data.role.rawValue
        )
        
        let payload: AuthPayload = try await apiClient.post(
            endpoint: Endpoints.register,
            body: request,
            requiresAuth: false
        )
        
        // Guardar tokens
        try keychainManager.saveAuthTokens(
            accessToken: payload.accessToken,
            refreshToken: payload.refreshToken
        )
        
        try keychainManager.save(payload.user.id, for: .userId)
        
        return payload
    }
    
    /// Refresca el access token usando el refresh token
    func refreshToken() async throws -> String {
        let refreshToken = try keychainManager.getRefreshToken()
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        
        let response: RefreshTokenResponse = try await apiClient.post(
            endpoint: Endpoints.refresh,
            body: request,
            requiresAuth: false
        )
        
        // Guardar nuevo access token
        try keychainManager.save(response.accessToken, for: .accessToken)
        
        return response.accessToken
    }
    
    /// Cierra sesión eliminando tokens
    func logout() throws {
        try keychainManager.logout()
    }
    
    /// Obtiene el usuario actual
    func getCurrentUser() async throws -> User? {
        guard let userId = try? keychainManager.get(.userId) else {
            return nil
        }
        
        let user: User = try await apiClient.get(
            endpoint: Endpoints.user(id: userId)
        )
        
        return user
    }
    
    /// Verifica si hay un usuario autenticado
    func isAuthenticated() -> Bool {
        return keychainManager.isAuthenticated()
    }
}

