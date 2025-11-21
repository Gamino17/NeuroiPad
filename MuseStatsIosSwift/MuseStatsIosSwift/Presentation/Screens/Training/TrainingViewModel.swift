import SwiftUI
import Combine

/// ViewModel para la pantalla de entrenamiento
/// Maneja el timer, captura de datos, y sincronización con backend
@MainActor
final class TrainingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var timeRemaining: TimeInterval = 300 // 5 minutos
    @Published var chartData: [ChartDataPoint] = []
    // Multicanal temporalmente deshabilitado
    // @Published var multiChannelData: [EEGChannel: [ChartDataPoint]] = [:]
    @Published var totalSamples = 0
    @Published var avgSignalQuality: Double = 0
    @Published var isConnected = true
    @Published var signalStrength = 5
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showCompletionAlert = false
    
    // MARK: - Dependencies
    
    private let museAdapter: MuseSDKAdapter
    private let trainingUseCase: StartTrainingSessionUseCase
    private let sessionRepository: SessionRepositoryProtocol
    private let keychainManager: KeychainManager
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var currentSession: Session?
    private var sampleBuffer: [Sample] = []
    private let trainingDuration: TimeInterval = 300 // 5 minutos
    private let maxChartPoints = 50 // Mostrar últimos 50 puntos en el gráfico
    
    // MARK: - Computed Properties
    
    var progress: Double {
        return 1.0 - (timeRemaining / trainingDuration)
    }
    
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Initialization
    
    init(
        museAdapter: MuseSDKAdapter,
        sessionRepository: SessionRepositoryProtocol = SessionRepository(),
        keychainManager: KeychainManager = .shared
    ) {
        self.museAdapter = museAdapter
        self.sessionRepository = sessionRepository
        self.keychainManager = keychainManager
        self.trainingUseCase = StartTrainingSessionUseCase(
            sessionRepository: sessionRepository,
            museAdapter: museAdapter,
            keychainManager: keychainManager
        )
        
        setupMuseCallbacks()
    }
    
    // MARK: - Setup
    
    private func setupMuseCallbacks() {
        // Callback de estado de conexión
        museAdapter.onConnectionStateChanged = { [weak self] state in
            guard let self = self else { return }
            Task { @MainActor in
                if case .connected = state {
                    self.isConnected = true
                } else {
                    self.isConnected = false
                }
            }
        }
    }
    
    // MARK: - Training Control
    
    /// Inicia el entrenamiento
    func startTraining() async {
        do {
            // Crear dispositivo mock para testing (cuando SDK esté integrado, obtener el real)
            let mockDevice = MuseDevice(
                name: "Muse-Test",
                macAddress: "00:00:00:00:00:00",
                model: .museS
            )
            
            // Iniciar sesión
            currentSession = try await trainingUseCase.execute(
                device: mockDevice,
                onProgress: { [weak self] progress in
                    // Actualizar progreso si es necesario
                },
                onDataReceived: { [weak self] packet in
                    guard let self = self else { return }
                    Task { @MainActor in
                        self.handleDataPacket(packet)
                    }
                }
            )
            
            // Iniciar timer
            startTimer()
            
            print("✅ Training session started: \(currentSession?.id ?? "unknown")")
            
        } catch {
            showErrorAlert("Error al iniciar entrenamiento: \(error.localizedDescription)")
        }
    }
    
    /// Detiene el entrenamiento
    func stopTraining() async {
        stopTimer()
        
        do {
            let summary = SessionSummary(
                avgFocus: nil,
                maxFocus: nil,
                minFocus: nil,
                totalSamples: totalSamples,
                goodSampleRate: avgSignalQuality
            )
            
            try await trainingUseCase.stop(summary: summary)
            print("✅ Training session stopped")
        } catch {
            print("❌ Error stopping training: \(error)")
        }
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.timeRemaining -= 1
                
                if self.timeRemaining <= 0 {
                    await self.completeTraining()
                }
            }
        }
    }
    
    nonisolated private func stopTimer() {
        Task { @MainActor in
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func completeTraining() async {
        stopTimer()
        await stopTraining()
        showCompletionAlert = true
    }
    
    // MARK: - Data Handling
    
    private func handleDataPacket(_ packet: DataPacket) {
        // Solo procesar datos EEG
        guard packet.type == .eeg else { return }
        
        totalSamples += 1
        
        // Actualizar calidad de señal
        if let quality = packet.quality {
            avgSignalQuality = (avgSignalQuality * Double(totalSamples - 1) + quality) / Double(totalSamples)
            updateSignalStrength(quality: quality)
        }
        
        let timestamp = Date().timeIntervalSince1970
        
        // Multi-canal temporalmente deshabilitado
        // TODO: Re-habilitar cuando se agregue soporte multi-canal
        
        // Agregar al gráfico simple (promedio de los 4 canales para vista legacy)
        let avgValue = packet.channels.reduce(0, +) / Double(packet.channels.count)
        let chartPoint = ChartDataPoint(
            time: timestamp,
            value: avgValue
        )
        
        chartData.append(chartPoint)
        
        // Mantener solo los últimos N puntos
        if chartData.count > maxChartPoints {
            chartData.removeFirst(chartData.count - maxChartPoints)
        }
    }
    
    private func updateSignalStrength(quality: Double) {
        switch quality {
        case 0.9...1.0:
            signalStrength = 5
        case 0.7..<0.9:
            signalStrength = 4
        case 0.5..<0.7:
            signalStrength = 3
        case 0.3..<0.5:
            signalStrength = 2
        default:
            signalStrength = 1
        }
    }
    
    // MARK: - Error Handling
    
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopTimer()
    }
}

