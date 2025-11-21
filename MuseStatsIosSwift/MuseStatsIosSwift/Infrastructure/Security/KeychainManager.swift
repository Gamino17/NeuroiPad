import Foundation
import Security

/// Manager para almacenamiento seguro en Keychain
/// Maneja tokens JWT y otras credenciales sensibles
final class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    enum KeychainKey: String {
        case accessToken = "com.neuroipad.accessToken"
        case refreshToken = "com.neuroipad.refreshToken"
        case userId = "com.neuroipad.userId"
    }
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
        case invalidData
    }
    
    // MARK: - Save
    
    /// Guarda un valor string en el Keychain
    /// - Parameters:
    ///   - value: Valor a guardar
    ///   - key: Key del Keychain
    /// - Throws: KeychainError si falla la operación
    func save(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // Primero intentar eliminar si existe
        try? delete(key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateItem
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - Get
    
    /// Obtiene un valor string del Keychain
    /// - Parameter key: Key del Keychain
    /// - Returns: Valor almacenado
    /// - Throws: KeychainError si no se encuentra o falla la operación
    func get(_ key: KeychainKey) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return value
    }
    
    // MARK: - Delete
    
    /// Elimina un valor del Keychain
    /// - Parameter key: Key del Keychain
    /// - Throws: KeychainError si falla la operación
    func delete(_ key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - Clear All
    
    /// Elimina todos los valores del Keychain de la app
    func clearAll() throws {
        try delete(.accessToken)
        try delete(.refreshToken)
        try delete(.userId)
    }
    
    // MARK: - Convenience Methods
    
    /// Guarda tokens de autenticación
    func saveAuthTokens(accessToken: String, refreshToken: String) throws {
        try save(accessToken, for: .accessToken)
        try save(refreshToken, for: .refreshToken)
    }
    
    /// Obtiene el access token
    func getAccessToken() throws -> String {
        return try get(.accessToken)
    }
    
    /// Obtiene el refresh token
    func getRefreshToken() throws -> String {
        return try get(.refreshToken)
    }
    
    /// Verifica si hay un usuario autenticado
    func isAuthenticated() -> Bool {
        return (try? getAccessToken()) != nil
    }
    
    /// Cierra sesión eliminando todos los tokens
    func logout() throws {
        try clearAll()
    }
}

