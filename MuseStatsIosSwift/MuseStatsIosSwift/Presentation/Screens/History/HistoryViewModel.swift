import SwiftUI
import Combine

/// ViewModel para la pantalla de historial
/// Maneja la carga y paginación de sesiones pasadas
@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var currentPage = 1
    @Published var hasMorePages = true
    
    // Computed stats
    @Published var totalSessions = 0
    @Published var sessionsThisWeek = 0
    @Published var currentStreak = 0
    
    private let sessionRepository: SessionRepositoryProtocol
    private let keychainManager: KeychainManager
    private let pageSize = 20
    
    init(
        sessionRepository: SessionRepositoryProtocol = SessionRepository(),
        keychainManager: KeychainManager = .shared
    ) {
        self.sessionRepository = sessionRepository
        self.keychainManager = keychainManager
    }
    
    /// Carga las sesiones del usuario
    func loadSessions() async {
        guard let userId = try? keychainManager.get(.userId) else {
            showErrorAlert("Usuario no autenticado")
            return
        }
        
        isLoading = true
        currentPage = 1
        
        do {
            let response = try await sessionRepository.getSessions(
                userId: userId,
                page: currentPage,
                limit: pageSize
            )
            
            sessions = response.sessions
            totalSessions = response.total
            hasMorePages = currentPage * pageSize < response.total
            
            calculateStats()
            
        } catch {
            showErrorAlert("Error al cargar sesiones: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Carga más sesiones (paginación)
    func loadMoreSessions() async {
        guard !isLoadingMore && hasMorePages else { return }
        guard let userId = try? keychainManager.get(.userId) else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let response = try await sessionRepository.getSessions(
                userId: userId,
                page: currentPage,
                limit: pageSize
            )
            
            sessions.append(contentsOf: response.sessions)
            hasMorePages = currentPage * pageSize < response.total
            
        } catch {
            currentPage -= 1 // Revertir si falla
            showErrorAlert("Error al cargar más sesiones")
        }
        
        isLoadingMore = false
    }
    
    /// Calcula estadísticas
    private func calculateStats() {
        // Sesiones esta semana
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        sessionsThisWeek = sessions.filter { session in
            session.startedAt >= weekAgo
        }.count
        
        // Racha actual (días consecutivos con al menos una sesión)
        currentStreak = calculateStreak()
    }
    
    private func calculateStreak() -> Int {
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Agrupar sesiones por día
        let sessionsByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startedAt)
        }
        
        // Contar días consecutivos
        while sessionsByDay[currentDate] != nil {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        return streak
    }
    
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }
}

