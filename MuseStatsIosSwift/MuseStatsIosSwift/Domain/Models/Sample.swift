import Foundation

/// Modelo de dominio para una muestra de datos
/// Puede ser EEG, acelerómetro, PPG, etc.
struct Sample: Identifiable, Codable {
    let id: UUID
    let sessionId: String
    let timestamp: Date
    let type: SampleType
    let channels: [Double]
    var quality: Double?
    var metadata: SampleMetadata?
    
    enum SampleType: String, Codable {
        case eeg = "EEG"
        case accelerometer = "ACC"
        case ppg = "PPG"
        case gyroscope = "GYRO"
    }
    
    init(
        id: UUID = UUID(),
        sessionId: String,
        timestamp: Date = Date(),
        type: SampleType,
        channels: [Double],
        quality: Double? = nil,
        metadata: SampleMetadata? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.type = type
        self.channels = channels
        self.quality = quality
        self.metadata = metadata
    }
}

/// Metadata adicional de una muestra
struct SampleMetadata: Codable {
    var batteryLevel: Int?
    var signalStrength: Int?
}

// MARK: - Helpers

extension Sample {
    /// Convierte el timestamp a Unix timestamp con milisegundos
    var unixTimestamp: Double {
        return timestamp.timeIntervalSince1970
    }
    
    /// Verifica si la muestra tiene buena calidad (>= 0.8)
    var hasGoodQuality: Bool {
        guard let quality = quality else { return false }
        return quality >= 0.8
    }
}

// MARK: - DTO para enviar al backend

extension Sample {
    /// Convierte el Sample a formato DTO para API
    func toDTO() -> SampleDTO {
        return SampleDTO(
            timestamp: unixTimestamp,
            type: type.rawValue,
            channels: channels,
            quality: quality,
            metadata: metadata.map { meta in
                SampleMetadataDTO(
                    batteryLevel: meta.batteryLevel,
                    signalStrength: meta.signalStrength
                )
            }
        )
    }
}

/// DTO para enviar muestras al backend
struct SampleDTO: Codable {
    let timestamp: Double
    let type: String
    let channels: [Double]
    let quality: Double?
    let metadata: SampleMetadataDTO?
}

struct SampleMetadataDTO: Codable {
    let batteryLevel: Int?
    let signalStrength: Int?
}

/// DTO para batch de muestras
struct CreateSamplesDTO: Codable {
    let samples: [SampleDTO]
}

