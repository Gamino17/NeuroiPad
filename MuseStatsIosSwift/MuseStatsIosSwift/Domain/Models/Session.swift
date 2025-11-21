import Foundation

/// Modelo de dominio para una sesión de entrenamiento
/// Representa una sesión completa con su metadata y estado
struct Session: Identifiable, Codable {
    let id: String
    let userId: String
    let type: SessionType
    let device: MuseDevice
    var status: SessionStatus
    let startedAt: Date
    var endedAt: Date?
    var duration: Int? // Duration in seconds
    var summary: SessionSummary?
    var metadata: SessionMetadata?
    var notes: String?
    
    enum SessionType: String, Codable {
        case training5Min = "training_5min"
        case meditation
        case custom
    }
    
    enum SessionStatus: String, Codable {
        case active
        case finished
        case aborted
    }
    
    enum MuseDevice: String, Codable {
        case museS = "muse_s_athena"
        case muse2016 = "muse_2016"
        case muse2 = "muse_2"
    }
}

/// Resumen de métricas de una sesión
struct SessionSummary: Codable {
    var avgFocus: Double?
    var maxFocus: Double?
    var minFocus: Double?
    var totalSamples: Int?
    var goodSampleRate: Double?
}

/// Metadata técnica de la sesión
struct SessionMetadata: Codable {
    var appVersion: String?
    var sdkVersion: String?
    var deviceModel: String?
    var osVersion: String?
}

// MARK: - Helpers

extension Session {
    /// Calcula la duración de la sesión en segundos
    var calculatedDuration: Int? {
        guard let endedAt = endedAt else { return nil }
        return Int(endedAt.timeIntervalSince(startedAt))
    }
    
    /// Verifica si la sesión está activa
    var isActive: Bool {
        return status == .active
    }
    
    /// Formatea la duración como string (ej: "5:00")
    var formattedDuration: String {
        guard let duration = duration else { return "--:--" }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

