import Foundation

/// Definición de endpoints de la API
/// Centraliza todas las rutas del backend
enum Endpoints {
    // MARK: - Auth
    
    static let login = "/v1/auth/login"
    static let register = "/v1/auth/register"
    static let refresh = "/v1/auth/refresh"
    
    // MARK: - Users
    
    static let users = "/v1/users"
    
    static func user(id: String) -> String {
        return "/v1/users/\(id)"
    }
    
    // MARK: - Sessions
    
    static let sessions = "/v1/sessions"
    
    static func session(id: String) -> String {
        return "/v1/sessions/\(id)"
    }
    
    static func finishSession(id: String) -> String {
        return "/v1/sessions/\(id)/finish"
    }
    
    static func abortSession(id: String) -> String {
        return "/v1/sessions/\(id)/abort"
    }
    
    // MARK: - Samples
    
    static func samples(sessionId: String) -> String {
        return "/v1/sessions/\(sessionId)/samples"
    }
    
    // MARK: - Metrics
    
    static func metrics(sessionId: String) -> String {
        return "/v1/sessions/\(sessionId)/metrics"
    }
    
    // MARK: - Query Parameters
    
    /// Construye URL con query parameters
    static func withQuery(_ endpoint: String, params: [String: String]) -> String {
        var components = URLComponents(string: endpoint)
        components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components?.string ?? endpoint
    }
}

// MARK: - Request/Response DTOs

/// DTO para login
struct LoginRequest: Codable {
    let email: String
    let password: String
}

/// DTO para registro
struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
    let role: String?
}

/// DTO para refrescar token
struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
}

/// DTO para crear sesión
struct CreateSessionRequest: Codable {
    let userId: String
    let type: String
    let device: String
    let metadata: SessionMetadata?
}

/// DTO para finalizar sesión
struct FinishSessionRequest: Codable {
    let endedAt: String?
    let summary: SessionSummary?
}

/// DTO para respuesta de sessions list
struct SessionsListResponse: Codable {
    let sessions: [Session]
    let total: Int
    let page: Int
    let limit: Int
}

