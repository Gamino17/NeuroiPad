import Foundation

/// Caso de uso para iniciar una sesión de entrenamiento de 5 minutos
/// Coordina la conexión con Muse, creación de sesión en backend, y streaming de datos
final class StartTrainingSessionUseCase {
    private let sessionRepository: SessionRepositoryProtocol
    private let museAdapter: MuseSDKAdapter
    private let keychainManager: KeychainManager
    
    private var sampleBuffer: [Sample] = []
    private var currentSession: Session?
    private let batchSize = 50 // Enviar cada 50 muestras (~10 segundos a 5Hz)
    
    init(
        sessionRepository: SessionRepositoryProtocol,
        museAdapter: MuseSDKAdapter,
        keychainManager: KeychainManager = .shared
    ) {
        self.sessionRepository = sessionRepository
        self.museAdapter = museAdapter
        self.keychainManager = keychainManager
    }
    
    /// Inicia una sesión de entrenamiento
    /// - Parameters:
    ///   - device: Dispositivo Muse a usar
    ///   - onProgress: Callback con progreso (0.0 a 1.0)
    ///   - onDataReceived: Callback cuando se reciben datos
    /// - Returns: Sesión creada
    func execute(
        device: MuseDevice,
        onProgress: ((Double) -> Void)? = nil,
        onDataReceived: ((DataPacket) -> Void)? = nil
    ) async throws -> Session {
        // 1. Verificar autenticación
        guard let userId = try? keychainManager.get(.userId) else {
            throw TrainingError.notAuthenticated
        }
        
        print("🚀 Starting training session for user: \(userId)")
        
        // 2. Crear sesión en backend
        let session = try await sessionRepository.createSession(
            userId: userId,
            type: .training5Min,
            device: device.model.sessionDeviceType
        )
        
        currentSession = session
        print("✅ Session created: \(session.id)")
        
        // 3. Configurar callbacks de Muse
        museAdapter.onDataPacket = { [weak self] packet in
            guard let self = self else { return }
            
            // Callback to UI
            onDataReceived?(packet)
            
            // Buffer sample
            let sample = Sample(
                sessionId: session.id,
                timestamp: Date(timeIntervalSince1970: packet.timestamp),
                type: self.mapDataType(packet.type),
                channels: packet.channels,
                quality: packet.quality
            )
            
            self.sampleBuffer.append(sample)
            
            // Enviar batch si alcanza el tamaño
            if self.sampleBuffer.count >= self.batchSize {
                Task {
                    await self.sendBatch()
                }
            }
        }
        
        // 4. Iniciar streaming
        museAdapter.startStreaming()
        print("▶️ Streaming started")
        
        return session
    }
    
    /// Detiene la sesión de entrenamiento
    /// - Parameter summary: Resumen opcional de la sesión
    func stop(summary: SessionSummary? = nil) async throws {
        guard let session = currentSession else {
            throw TrainingError.noActiveSession
        }
        
        print("🛑 Stopping training session: \(session.id)")
        
        // 1. Detener streaming
        museAdapter.stopStreaming()
        
        // 2. Enviar muestras restantes
        if !sampleBuffer.isEmpty {
            await sendBatch()
        }
        
        // 3. Finalizar sesión en backend
        let finishedSession = try await sessionRepository.finishSession(
            id: session.id,
            summary: summary
        )
        
        print("✅ Session finished: \(finishedSession.id)")
        
        // 4. Limpiar estado
        currentSession = nil
        sampleBuffer.removeAll()
    }
    
    /// Aborta la sesión actual
    func abort() async throws {
        guard let session = currentSession else {
            throw TrainingError.noActiveSession
        }
        
        print("⚠️ Aborting session: \(session.id)")
        
        museAdapter.stopStreaming()
        
        _ = try await sessionRepository.abortSession(id: session.id)
        
        currentSession = nil
        sampleBuffer.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Envía el batch de muestras al backend
    private func sendBatch() async {
        guard !sampleBuffer.isEmpty,
              let session = currentSession else {
            return
        }
        
        let samplesToSend = sampleBuffer
        sampleBuffer.removeAll()
        
        do {
            try await sessionRepository.sendSamples(
                sessionId: session.id,
                samples: samplesToSend
            )
            print("📤 Sent batch of \(samplesToSend.count) samples")
        } catch {
            print("❌ Error sending samples: \(error)")
            // Reintroducir muestras en el buffer para reintentar
            sampleBuffer.insert(contentsOf: samplesToSend, at: 0)
        }
    }
    
    /// Mapea el tipo de dato de Muse a Sample.SampleType
    private func mapDataType(_ type: DataPacket.DataType) -> Sample.SampleType {
        switch type {
        case .eeg: return .eeg
        case .accelerometer: return .accelerometer
        case .ppg: return .ppg
        case .gyroscope: return .gyroscope
        }
    }
}

// MARK: - Errors

enum TrainingError: Error, LocalizedError {
    case notAuthenticated
    case noActiveSession
    case museNotConnected
    case sessionCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Usuario no autenticado"
        case .noActiveSession:
            return "No hay sesión activa"
        case .museNotConnected:
            return "Muse no está conectado"
        case .sessionCreationFailed:
            return "Error al crear la sesión"
        }
    }
}

