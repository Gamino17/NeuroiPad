import Foundation

/// Modelo de dominio para un usuario
struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let role: UserRole
    var profile: UserProfile?
    var settings: UserSettings?
    let createdAt: Date?
    
    enum UserRole: String, Codable {
        case athlete
        case coach
        case admin
    }
}

/// Perfil del usuario
struct UserProfile: Codable {
    var age: Int?
    var gender: String?
    var experience: Experience?
    
    enum Experience: String, Codable {
        case beginner
        case intermediate
        case advanced
    }
}

/// Configuración del usuario
struct UserSettings: Codable {
    var notifications: Bool
    var dataSharing: Bool
    
    init(notifications: Bool = true, dataSharing: Bool = false) {
        self.notifications = notifications
        self.dataSharing = dataSharing
    }
}

// MARK: - Authentication

/// Payload de autenticación
struct AuthPayload: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: User
}

/// Credenciales de login
struct LoginCredentials {
    let email: String
    let password: String
}

/// Datos de registro
struct RegisterData {
    let email: String
    let password: String
    let name: String
    let role: User.UserRole
}

