//
//  HistoryManager.swift
//  Numby
//
//  Manager for calculator history persistence and search
//

import Foundation
import CoreData
import Combine

// CalculatorSessionSnapshot is defined in Persistence.swift for cross-platform compatibility

/// Manager for calculator history operations
class HistoryManager: ObservableObject {
    @Published var sessions: [CalculationSession] = []
    @Published var searchQuery: String = ""
    @Published var filteredSessions: [CalculationSession] = []

    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context

        setupObservers()
        fetchSessions()
    }

    private func setupObservers() {
        // Watch for search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.filterSessions(query: query)
            }
            .store(in: &cancellables)

        // Watch for sessions changes to update filtered list
        $sessions
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.filterSessions(query: self.searchQuery)
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD Operations

    /// Fetch all sessions from CoreData
    func fetchSessions() {
        let request: NSFetchRequest<CalculationSession> = CalculationSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CalculationSession.timestamp, ascending: false)]

        do {
            sessions = try viewContext.fetch(request)
        } catch {
            sessions = []
        }
    }

    /// Save a new calculator session
    func saveSession(
        splitTree: SplitTree,
        calculators: [SplitLeafID: CalculatorInstance],
        customName: String? = nil
    ) {
        let session = CalculationSession(context: viewContext)
        session.swiftId = UUID()
        session.swiftTimestamp = Date()
        session.customName = customName

        // Create snapshot
        var calculatorStates: [String: CalculatorSessionSnapshot.CalculatorStateSnapshot] = [:]
        for (leafId, calculator) in calculators {
            calculatorStates[leafId.uuid.uuidString] = CalculatorSessionSnapshot.CalculatorStateSnapshot(
                inputText: calculator.inputText,
                results: calculator.results,
                cursorPosition: calculator.cursorPosition
            )
        }

        let snapshot = CalculatorSessionSnapshot(
            splitTree: splitTree,
            calculatorStates: calculatorStates
        )

        // Encode to binary data
        do {
            let encoder = JSONEncoder()
            session.swiftSessionData = try encoder.encode(snapshot)

            // Build searchable text from all input text
            let searchableText = calculatorStates.values
                .map { $0.inputText }
                .joined(separator: "\n")
            session.searchableText = searchableText

            try viewContext.save()
            fetchSessions()
        } catch {
            // Save failed - non-fatal
        }
    }

    /// Update session name
    func updateSessionName(session: CalculationSession, newName: String?) {
        session.customName = newName

        do {
            try viewContext.save()
            fetchSessions()
        } catch {
            // Update failed - non-fatal
        }
    }

    /// Delete a session
    func deleteSession(_ session: CalculationSession) {
        viewContext.delete(session)

        do {
            try viewContext.save()
            fetchSessions()
        } catch {
            // Delete failed - non-fatal
        }
    }

    /// Restore a session snapshot
    func restoreSession(_ session: CalculationSession) -> CalculatorSessionSnapshot? {
        let data = session.swiftSessionData
        return try? JSONDecoder().decode(CalculatorSessionSnapshot.self, from: data)
    }

    // MARK: - Search

    private func filterSessions(query: String) {
        if query.isEmpty {
            filteredSessions = sessions
        } else {
            let lowercasedQuery = query.lowercased()
            filteredSessions = sessions.filter { session in
                // Search in custom name
                if let name = session.customName,
                   name.lowercased().contains(lowercasedQuery) {
                    return true
                }

                // Search in searchable text (all calculator inputs)
                if let searchableText = session.searchableText,
                   searchableText.lowercased().contains(lowercasedQuery) {
                    return true
                }

                // Search in formatted timestamp
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                let dateString = formatter.string(from: session.swiftTimestamp)
                if dateString.lowercased().contains(lowercasedQuery) {
                    return true
                }

                return false
            }
        }
    }

    // MARK: - Helpers

    /// Get display name for a session
    func displayName(for session: CalculationSession) -> String {
        if let customName = session.customName, !customName.isEmpty {
            return customName
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.swiftTimestamp)
    }

    /// Get preview text for a session (first line of input)
    func previewText(for session: CalculationSession) -> String {
        guard let searchableText = session.searchableText else {
            return ""
        }

        let lines = searchableText.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        if let firstLine = nonEmptyLines.first {
            return firstLine.count > 50 ? String(firstLine.prefix(50)) + "..." : firstLine
        }

        return ""
    }
}
