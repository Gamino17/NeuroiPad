import Foundation
import UIKit

/// Protocolo del repositorio de sesiones
protocol SessionRepositoryProtocol {
    func createSession(userId: String, type: Session.SessionType, device: Session.MuseDevice) async throws -> Session
    func getSession(id: String) async throws -> Session
    func getSessions(userId: String, page: Int, limit: Int) async throws -> SessionsListResponse
    func finishSession(id: String, summary: SessionSummary?) async throws -> Session
    func abortSession(id: String) async throws -> Session
    func sendSamples(sessionId: String, samples: [Sample]) async throws
}

/// Implementación del repositorio de sesiones
final class SessionRepository: SessionRepositoryProtocol {
    private let apiClient: APIClient
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    /// Crea una nueva sesión de entrenamiento
    func createSession(
        userId: String,
        type: Session.SessionType,
        device: Session.MuseDevice
    ) async throws -> Session {
        let metadata = SessionMetadata(
            appVersion: Bundle.main.appVersion,
            sdkVersion: "12.0.0", // TODO: Get from Muse SDK
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion
        )
        
        let request = CreateSessionRequest(
            userId: userId,
            type: type.rawValue,
            device: device.rawValue,
            metadata: metadata
        )
        
        let session: Session = try await apiClient.post(
            endpoint: Endpoints.sessions,
            body: request
        )
        
        print("✅ Session created: \(session.id)")
        return session
    }
    
    /// Obtiene una sesión por ID
    func getSession(id: String) async throws -> Session {
        return try await apiClient.get(endpoint: Endpoints.session(id: id))
    }
    
    /// Obtiene lista de sesiones con paginación
    func getSessions(
        userId: String,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> SessionsListResponse {
        let endpoint = Endpoints.withQuery(
            Endpoints.sessions,
            params: [
                "userId": userId,
                "page": String(page),
                "limit": String(limit)
            ]
        )
        
        return try await apiClient.get(endpoint: endpoint)
    }
    
    /// Finaliza una sesión
    func finishSession(
        id: String,
        summary: SessionSummary? = nil
    ) async throws -> Session {
        let request = FinishSessionRequest(
            endedAt: ISO8601DateFormatter().string(from: Date()),
            summary: summary
        )
        
        let session: Session = try await apiClient.put(
            endpoint: Endpoints.finishSession(id: id),
            body: request
        )
        
        print("✅ Session finished: \(session.id)")
        return session
    }
    
    /// Aborta una sesión
    func abortSession(id: String) async throws -> Session {
        return try await apiClient.put(
            endpoint: Endpoints.abortSession(id: id),
            body: Empty()
        )
    }
    
    /// Envía un batch de muestras al backend
    func sendSamples(sessionId: String, samples: [Sample]) async throws {
        let dtos = samples.map { $0.toDTO() }
        let request = CreateSamplesDTO(samples: dtos)
        
        let _: SamplesUploadResponse = try await apiClient.post(
            endpoint: Endpoints.samples(sessionId: sessionId),
            body: request
        )
        
        print("📤 Sent \(samples.count) samples for session \(sessionId)")
    }
}

// MARK: - Supporting Types

struct SamplesUploadResponse: Codable {
    let received: Int
    let sessionId: String
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

