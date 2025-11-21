import SwiftUI

/// Vista de historial de sesiones
/// Muestra lista de entrenamientos pasados con sus métricas
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedSession: Session?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadSessions()
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                Task {
                    await viewModel.loadSessions()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Cargando historial...")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Sin sesiones")
                .font(.title2.bold())
            
            Text("Completa tu primer entrenamiento para ver el historial")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Sessions List
    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Summary stats
                summaryStats
                
                // Sessions
                ForEach(viewModel.sessions) { session in
                    SessionRow(session: session)
                        .onTapGesture {
                            selectedSession = session
                        }
                }
                
                // Load more button
                if viewModel.hasMorePages {
                    loadMoreButton
                }
            }
            .padding()
        }
    }
    
    // MARK: - Summary Stats
    
    private var summaryStats: some View {
        VStack(spacing: 16) {
            Text("Resumen")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total",
                    value: "\(viewModel.totalSessions)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatCard(
                    title: "Esta Semana",
                    value: "\(viewModel.sessionsThisWeek)",
                    icon: "calendar",
                    color: .green
                )
                
                StatCard(
                    title: "Racha",
                    value: "\(viewModel.currentStreak) días",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    // MARK: - Load More Button
    
    private var loadMoreButton: some View {
        Button(action: {
            Task {
                await viewModel.loadMoreSessions()
            }
        }) {
            if viewModel.isLoadingMore {
                ProgressView()
            } else {
                Text("Cargar más")
                    .font(.subheadline.bold())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: Session
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(session.type.rawValue.capitalized)
                    .font(.headline)
                
                Spacer()
                
                Text(session.formattedDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Date
            Text(session.startedAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Metrics
            if let summary = session.summary {
                HStack(spacing: 16) {
                    if let totalSamples = summary.totalSamples {
                        MetricBadge(
                            icon: "waveform",
                            value: "\(totalSamples)",
                            label: "muestras"
                        )
                    }
                    
                    if let quality = summary.goodSampleRate {
                        MetricBadge(
                            icon: "checkmark.circle",
                            value: "\(Int(quality * 100))%",
                            label: "calidad"
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
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
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Metric Badge

struct MetricBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}

