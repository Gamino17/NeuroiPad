import Foundation

/// Adapter para el SDK de Muse usando wrapper de Objective-C
/// Esto evita problemas con el bridging header y Swift
final class MuseSDKAdapter: NSObject {
    
    // MARK: - Callbacks
    
    var onConnectionStateChanged: ((ConnectionState) -> Void)?
    var onDataPacket: ((DataPacket) -> Void)?
    var onMuseDiscovered: ((MuseDevice) -> Void)?
    
    // MARK: - Properties
    
    private let wrapper: MuseWrapper
    private var isScanning = false
    private var isStreaming = false
    
    // MARK: - Initialization
    
    override init() {
        wrapper = MuseWrapper()
        super.init()
        wrapper.delegate = self
        print("🎧 MuseSDKAdapter initialized with Objective-C wrapper")
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        print("🔍 Starting Muse scan...")
        isScanning = true
        wrapper.startScanning()
    }
    
    func stopScanning() {
        print("🛑 Stopping scan...")
        isScanning = false
        wrapper.stopScanning()
    }
    
    func connect(to device: MuseDevice) {
        print("🔗 Connecting to \(device.name)...")
        wrapper.connect(toMuse: device.name)
    }
    
    func disconnect() {
        print("🔌 Disconnecting...")
        wrapper.disconnect()
        isStreaming = false
    }
    
    func startStreaming() {
        print("▶️ Starting streaming...")
        isStreaming = true
        wrapper.startStreaming()
    }
    
    func stopStreaming() {
        print("⏹ Stopping streaming...")
        isStreaming = false
        wrapper.stopStreaming()
    }
    
    deinit {
        disconnect()
    }
}

// MARK: - MuseWrapperDelegate

extension MuseSDKAdapter: MuseWrapperDelegate {
    
    func museDiscovered(_ name: String, macAddress: String) {
        let device = MuseDevice(
            name: name,
            macAddress: macAddress,
            model: inferModel(from: name)
        )
        
        print("📱 Discovered: \(name)")
        onMuseDiscovered?(device)
    }
    
    func museConnectionChanged(_ state: String) {
        print("🔄 Connection state: \(state)")
        
        let connectionState: ConnectionState
        switch state {
        case "connected":
            connectionState = .connected
            isStreaming = true
        case "connecting":
            connectionState = .connecting
        case "disconnected":
            connectionState = .disconnected
            isStreaming = false
        default:
            connectionState = .error(state)
        }
        
        onConnectionStateChanged?(connectionState)
    }
    
    func museDataReceived(_ channels: [NSNumber], timestamp: TimeInterval, type: String) {
        guard isStreaming else { return }
        
        let doubleChannels = channels.map { $0.doubleValue }
        
        let dataType: DataPacket.DataType
        switch type {
        case "EEG":
            dataType = .eeg
        case "ACC":
            dataType = .accelerometer
        case "PPG":
            dataType = .ppg
        default:
            dataType = .eeg
        }
        
        let packet = DataPacket(
            timestamp: timestamp,
            type: dataType,
            channels: doubleChannels,
            quality: nil
        )
        
        onDataPacket?(packet)
    }
    
    private func inferModel(from name: String) -> MuseDevice.Model {
        if name.lowercased().contains("muse s") || name.lowercased().contains("muse-s") {
            return .museS
        } else if name.lowercased().contains("muse 2") || name.lowercased().contains("muse-2") {
            return .muse2
        } else {
            return .muse2016
        }
    }
}

// MARK: - Supporting Types

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case error(String)
}

struct DataPacket {
    let timestamp: TimeInterval
    let type: DataType
    let channels: [Double]
    let quality: Double?
    
    enum DataType {
        case eeg
        case accelerometer
        case ppg
        case gyroscope
    }
}

struct MuseDevice: Identifiable {
    let id = UUID()
    let name: String
    let macAddress: String
    let model: Model
    
    enum Model {
        case museS
        case muse2
        case muse2016
        
        var sessionDeviceType: Session.MuseDevice {
            switch self {
            case .museS: return .museS
            case .muse2: return .muse2
            case .muse2016: return .muse2016
            }
        }
    }
}
