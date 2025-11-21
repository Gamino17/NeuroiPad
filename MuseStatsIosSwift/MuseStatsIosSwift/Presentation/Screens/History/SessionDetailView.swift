import SwiftUI

/// Vista de detalle de una sesión
/// Muestra información completa y métricas de una sesión específica
struct SessionDetailView: View {
    let session: Session
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con estado
                    sessionHeader
                    
                    // Información básica
                    basicInfoSection
                    
                    // Métricas
                    if session.summary != nil {
                        metricsSection
                    }
                    
                    // Metadata
                    if session.metadata != nil {
                        metadataSection
                    }
                    
                    // Notas
                    if let notes = session.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Detalle de Sesión")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Session Header
    
    private var sessionHeader: some View {
        VStack(spacing: 12) {
            // Status badge
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(statusText)
                    .font(.subheadline.bold())
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(statusColor.opacity(0.1))
            .cornerRadius(20)
            
            // Type
            Text(session.type.rawValue.capitalized)
                .font(.title.bold())
            
            // Date
            Text(session.startedAt, style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(session.startedAt, style: .time)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    // MARK: - Basic Info
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Información")
                .font(.headline)
            
            InfoRow(label: "ID", value: session.id)
            InfoRow(label: "Dispositivo", value: session.device.rawValue)
            InfoRow(label: "Duración", value: session.formattedDuration)
            
            if let endedAt = session.endedAt {
                InfoRow(label: "Finalizado", value: endedAt.formatted())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Metrics
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Métricas")
                .font(.headline)
            
            if let summary = session.summary {
                VStack(spacing: 12) {
                    if let totalSamples = summary.totalSamples {
                        MetricRow(
                            icon: "waveform",
                            label: "Total de Muestras",
                            value: "\(totalSamples)",
                            color: .blue
                        )
                    }
                    
                    if let quality = summary.goodSampleRate {
                        MetricRow(
                            icon: "checkmark.circle",
                            label: "Calidad de Señal",
                            value: "\(Int(quality * 100))%",
                            color: .green
                        )
                    }
                    
                    if let avgFocus = summary.avgFocus {
                        MetricRow(
                            icon: "brain",
                            label: "Focus Promedio",
                            value: String(format: "%.2f", avgFocus),
                            color: .purple
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Metadata
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Información Técnica")
                .font(.headline)
            
            if let metadata = session.metadata {
                VStack(spacing: 12) {
                    if let appVersion = metadata.appVersion {
                        InfoRow(label: "Versión App", value: appVersion)
                    }
                    
                    if let sdkVersion = metadata.sdkVersion {
                        InfoRow(label: "Versión SDK", value: sdkVersion)
                    }
                    
                    if let deviceModel = metadata.deviceModel {
                        InfoRow(label: "Modelo Dispositivo", value: deviceModel)
                    }
                    
                    if let osVersion = metadata.osVersion {
                        InfoRow(label: "Versión OS", value: osVersion)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Notes
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notas")
                .font(.headline)
            
            Text(notes)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch session.status {
        case .active:
            return .orange
        case .finished:
            return .green
        case .aborted:
            return .red
        }
    }
    
    private var statusText: String {
        switch session.status {
        case .active:
            return "En Progreso"
        case .finished:
            return "Completada"
        case .aborted:
            return "Abortada"
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

// MARK: - Metric Row

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3.bold())
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SessionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SessionDetailView(session: Session(
            id: "test123",
            userId: "user123",
            type: .training5Min,
            device: .museS,
            status: .finished,
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(300),
            duration: 300
        ))
    }
}

