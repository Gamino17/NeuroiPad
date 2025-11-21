import SwiftUI
import Charts

/// Vista principal de entrenamiento de 5 minutos
/// Muestra contador regresivo y gráfico en tiempo real
struct TrainingView: View {
    @StateObject private var viewModel: TrainingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingStopAlert = false
    
    init(museAdapter: MuseSDKAdapter) {
        _viewModel = StateObject(wrappedValue: TrainingViewModel(museAdapter: museAdapter))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Timer display
                timerDisplay
                
                // Signal quality indicator
                signalQualityIndicator
                
                // Real-time chart
                realtimeChart
                
                // Metrics display
                metricsDisplay
                
                Spacer()
                
                // Control buttons
                controlButtons
            }
            .padding()
        }
        .navigationTitle("Entrenamiento")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingStopAlert = true
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
        }
        .alert("¿Detener entrenamiento?", isPresented: $showingStopAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Detener", role: .destructive) {
                Task {
                    await viewModel.stopTraining()
                    dismiss()
                }
            }
        } message: {
            Text("El entrenamiento aún no ha terminado. ¿Estás seguro de que quieres detenerlo?")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("¡Entrenamiento Completado!", isPresented: $viewModel.showCompletionAlert) {
            Button("Ver Resumen") {
                dismiss()
            }
        } message: {
            Text("Has completado tu sesión de 5 minutos. ¡Buen trabajo!")
        }
        .onAppear {
            Task {
                await viewModel.startTraining()
            }
        }
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text(viewModel.formattedTimeRemaining)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("minutos restantes")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Progress bar
            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.horizontal)
        }
        .padding(24)
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    // MARK: - Signal Quality
    
    private var signalQualityIndicator: some View {
        HStack(spacing: 16) {
            Image(systemName: viewModel.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(viewModel.isConnected ? .green : .red)
            
            Text(viewModel.isConnected ? "Conectado" : "Desconectado")
                .font(.subheadline.bold())
            
            Spacer()
            
            // Signal bars
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= viewModel.signalStrength ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 6, height: CGFloat(index) * 4)
                }
            }
            
            Text("\(Int(viewModel.avgSignalQuality * 100))%")
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
    }
    
    // MARK: - Real-time Chart
    
    private var realtimeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Señal EEG en Tiempo Real")
                .font(.headline)
            
            if viewModel.chartData.isEmpty {
                // Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.9))
                        .frame(height: 200)
                    
                    Text("Esperando datos...")
                        .foregroundColor(.secondary)
                }
            } else {
                Chart {
                    ForEach(viewModel.chartData) { point in
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("EEG", point.value)
                        )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .chartYScale(domain: -1...1)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Metrics Display
    
    private var metricsDisplay: some View {
        HStack(spacing: 16) {
            MetricCard(
                title: "Muestras",
                value: "\(viewModel.totalSamples)",
                icon: "chart.bar.fill",
                color: .blue
            )
            
            MetricCard(
                title: "Calidad",
                value: "\(Int(viewModel.avgSignalQuality * 100))%",
                icon: "waveform.path.ecg",
                color: .green
            )
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        Button(action: {
            showingStopAlert = true
        }) {
            Text("Detener Entrenamiento")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.2))
                .foregroundColor(.red)
                .cornerRadius(12)
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let time: Double
    let value: Double
}

struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TrainingView(museAdapter: MuseSDKAdapter())
        }
    }
}

