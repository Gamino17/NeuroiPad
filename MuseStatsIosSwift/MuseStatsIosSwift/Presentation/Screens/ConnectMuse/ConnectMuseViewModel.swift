import SwiftUI
import Combine

/// ViewModel para la pantalla de conexión a Muse
/// Maneja el escaneo, conexión y estado de dispositivos
@MainActor
final class ConnectMuseViewModel: ObservableObject {
    @Published var discoveredDevices: [MuseDevice] = []
    @Published var connectedDevice: MuseDevice?
    @Published var isScanning = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var showError = false
    @Published var errorMessage = ""
    
    let museAdapter: MuseSDKAdapter
    
    init(museAdapter: MuseSDKAdapter = MuseSDKAdapter()) {
        self.museAdapter = museAdapter
        setupCallbacks()
    }
    
    // MARK: - Computed Properties
    
    var isConnected: Bool {
        if case .connected = connectionState {
            return true
        }
        return false
    }
    
    var connectionStatusText: String {
        switch connectionState {
        case .disconnected:
            return "Desconectado"
        case .connecting:
            return "Conectando..."
        case .connected:
            return "Conectado"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var connectionStatusIcon: String {
        switch connectionState {
        case .disconnected:
            return "wifi.slash"
        case .connecting:
            return "wifi.exclamationmark"
        case .connected:
            return "wifi"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    var connectionStatusColor: Color {
        switch connectionState {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .error:
            return .red
        }
    }
    
    // MARK: - Setup
    
    private func setupCallbacks() {
        // Callback cuando se descubre un dispositivo
        museAdapter.onMuseDiscovered = { [weak self] device in
            guard let self = self else { return }
            Task { @MainActor in
                if !self.discoveredDevices.contains(where: { $0.id == device.id }) {
                    self.discoveredDevices.append(device)
                }
            }
        }
        
        // Callback cuando cambia el estado de conexión
        museAdapter.onConnectionStateChanged = { [weak self] state in
            guard let self = self else { return }
            Task { @MainActor in
                self.connectionState = state
                
                if case .error(let message) = state {
                    self.showErrorAlert(message)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    /// Inicia el escaneo de dispositivos Muse
    func startScanning() {
        discoveredDevices.removeAll()
        isScanning = true
        
        museAdapter.startScanning()
        
        // Detener automáticamente después de 30 segundos
        Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 segundos
            stopScanning()
        }
    }
    
    /// Detiene el escaneo
    func stopScanning() {
        isScanning = false
        museAdapter.stopScanning()
    }
    
    /// Conecta a un dispositivo Muse
    func connect(to device: MuseDevice) async {
        stopScanning()
        connectedDevice = device
        museAdapter.connect(to: device)
        
        // Esperar a que se conecte (timeout 10 segundos)
        let startTime = Date()
        while case .connecting = connectionState {
            if Date().timeIntervalSince(startTime) > 10 {
                showErrorAlert("Timeout al conectar. Intenta de nuevo.")
                disconnect()
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundo
        }
    }
    
    /// Desconecta del dispositivo actual
    func disconnect() {
        museAdapter.disconnect()
        connectedDevice = nil
        connectionState = .disconnected
    }
    
    // MARK: - Error Handling
    
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }
}

