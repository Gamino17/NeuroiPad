import Foundation

/// Cliente HTTP para comunicación con el backend
/// Maneja autenticación, serialización y errores
final class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let baseURL: URL
    private let keychainManager: KeychainManager
    
    init(
        baseURL: String = APIConfig.baseURL,
        session: URLSession = .shared,
        keychainManager: KeychainManager = .shared
    ) {
        self.baseURL = URL(string: baseURL)!
        self.session = session
        self.keychainManager = keychainManager
    }
    
    enum APIError: Error {
        case invalidURL
        case noData
        case decodingError(Error)
        case serverError(Int, String?)
        case unauthorized
        case networkError(Error)
    }
    
    // MARK: - Generic Request
    
    /// Realiza una petición HTTP genérica
    /// - Parameters:
    ///   - endpoint: Endpoint a llamar
    ///   - method: Método HTTP
    ///   - body: Body opcional (será codificado a JSON)
    ///   - requiresAuth: Si requiere autenticación
    /// - Returns: Respuesta decodificada
    func request<T: Decodable, B: Encodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: B? = nil as Empty?,
        requiresAuth: Bool = true
    ) async throws -> T {
        // Construir URL completa concatenando baseURL + endpoint
        let urlString = baseURL.absoluteString + endpoint
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        print("🌐 API Request: \(method.rawValue) \(urlString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header if required
        if requiresAuth {
            let token = try keychainManager.getAccessToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode body if present
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("📤 Request body: \(bodyString)")
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type: \(type(of: response))")
                throw APIError.serverError(0, "Invalid response")
            }
            
            print("📥 Response status: \(httpResponse.statusCode)")
            
            // Handle HTTP errors
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                
                let errorMessage = String(data: data, encoding: .utf8)
                throw APIError.serverError(httpResponse.statusCode, errorMessage)
            }
            
            // Decode response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ Decoding error: \(error)")
                print("📦 Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            print("❌ API Error: \(error)")
            throw error
        } catch {
            print("❌ Network Error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// GET request
    func get<T: Decodable>(
        endpoint: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .get,
            body: nil as Empty?,
            requiresAuth: requiresAuth
        )
    }
    
    /// POST request
    func post<T: Decodable, B: Encodable>(
        endpoint: String,
        body: B,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .post,
            body: body,
            requiresAuth: requiresAuth
        )
    }
    
    /// PUT request
    func put<T: Decodable, B: Encodable>(
        endpoint: String,
        body: B,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .put,
            body: body,
            requiresAuth: requiresAuth
        )
    }
    
    /// DELETE request
    func delete<T: Decodable>(
        endpoint: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .delete,
            body: nil as Empty?,
            requiresAuth: requiresAuth
        )
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// Empty type for requests without body
struct Empty: Codable {}

/// API Configuration
enum APIConfig {
    static let baseURL = "http://192.168.1.105:3000"  // Backend local en Mac (sin /v1)
    // static let baseURL = "http://localhost:3000" // Solo si backend en iPad
    // static let baseURL = "https://api.neuroipad.com" // Production
}

