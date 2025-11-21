import SwiftUI

/// Vista para conectar a un dispositivo Muse
/// Permite escanear, conectar, y iniciar entrenamiento
struct ConnectMuseView: View {
    @StateObject private var viewModel = ConnectMuseViewModel()
    @State private var navigateToTraining = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Status card
                    statusCard
                    
                    // Device list or scanning indicator
                    if viewModel.isScanning {
                        scanningView
                    } else if !viewModel.discoveredDevices.isEmpty {
                        deviceList
                    } else {
                        emptyStateView
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Conectar Muse")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .background(
                NavigationLink(
                    destination: TrainingView(museAdapter: viewModel.museAdapter),
                    isActive: $navigateToTraining
                ) {
                    EmptyView()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        VStack(spacing: 16) {
            // Connection status icon
            ZStack {
                Circle()
                    .fill(viewModel.connectionStatusColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: viewModel.connectionStatusIcon)
                    .font(.system(size: 36))
                    .foregroundColor(viewModel.connectionStatusColor)
            }
            
            // Status text
            Text(viewModel.connectionStatusText)
                .font(.title3.bold())
            
            if let device = viewModel.connectedDevice {
                Text(device.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    // MARK: - Scanning View
    
    private var scanningView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Buscando dispositivos Muse...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    // MARK: - Device List
    
    private var deviceList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dispositivos encontrados")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.discoveredDevices) { device in
                        DeviceRow(device: device, isConnected: viewModel.connectedDevice?.id == device.id) {
                            Task {
                                await viewModel.connect(to: device)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No se encontraron dispositivos")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Asegúrate de que tu Muse esté encendido y cerca")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if viewModel.isConnected {
                // Start training button
                Button(action: {
                    navigateToTraining = true
                }) {
                    Label("Iniciar Entrenamiento", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                // Disconnect button
                Button(action: {
                    viewModel.disconnect()
                }) {
                    Text("Desconectar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            } else {
                // Scan button
                Button(action: {
                    viewModel.startScanning()
                }) {
                    Label(
                        viewModel.isScanning ? "Buscando..." : "Buscar Dispositivos",
                        systemImage: "magnifyingglass"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isScanning ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isScanning)
            }
        }
    }
}

// MARK: - Device Row

struct DeviceRow: View {
    let device: MuseDevice
    let isConnected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                    
                    Text(device.macAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct ConnectMuseView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectMuseView()
    }
}

