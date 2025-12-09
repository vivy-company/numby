//
//  Persistence.swift
//  Numby
//
//  Created by Uladzislau Yakauleu on 12.11.25.
//

import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newSession = CalculationSession(context: viewContext)
            newSession.swiftId = UUID()
            newSession.swiftTimestamp = Date()
            newSession.swiftSessionData = Data()
            newSession.searchableText = ""
        }
        do {
            try viewContext.save()
        } catch {
            // Preview context save failed - non-fatal
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Numby")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            // CloudKit may not be available in simulator - non-fatal
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

// Shared Persistence via CoreData + CloudKit for iCloud sync between macOS/iOS
import CoreData

/// Snapshot of a calculator session for history - shared format between iOS and macOS
struct CalculatorSessionSnapshot: Codable {
    let splitTree: SplitTree
    let calculatorStates: [String: CalculatorStateSnapshot]

    struct CalculatorStateSnapshot: Codable {
        let inputText: String
        let results: [String?]
        let cursorPosition: Int
    }
}

class Persistence {
    static let shared = Persistence()

    private let container: NSPersistentCloudKitContainer

    private init() {
        container = PersistenceController.shared.container
    }

    /// Add a simple history entry (for iPhone single-calculator mode)
    func addHistoryEntry(expression: String, result: String) {
        let context = container.viewContext
        let session = CalculationSession(context: context)
        session.swiftId = UUID()
        session.swiftTimestamp = Date()

        // Create full CalculatorSessionSnapshot for cross-platform compatibility
        let leafId = SplitLeafID()
        let splitTree = SplitTree(leafId: leafId)
        let state = CalculatorSessionSnapshot.CalculatorStateSnapshot(
            inputText: expression,
            results: result.components(separatedBy: "\n").map { $0.isEmpty ? nil : $0 },
            cursorPosition: expression.count
        )
        let snapshot = CalculatorSessionSnapshot(
            splitTree: splitTree,
            calculatorStates: [leafId.uuid.uuidString: state]
        )

        do {
            let encoder = JSONEncoder()
            session.swiftSessionData = try encoder.encode(snapshot)
            session.searchableText = expression
            try context.save()
        } catch {
            // Save failed - non-fatal
        }
    }

    /// Save a full calculator session snapshot (for iPad split view mode)
    func saveSession(snapshot: CalculatorSessionSnapshot, searchableText: String) {
        let context = container.viewContext
        let session = CalculationSession(context: context)
        session.swiftId = UUID()
        session.swiftTimestamp = Date()

        do {
            let encoder = JSONEncoder()
            session.swiftSessionData = try encoder.encode(snapshot)
            session.searchableText = searchableText
            try context.save()
        } catch {
            // Save failed - non-fatal
        }
    }

    /// Get history as simple expression/result pairs (for iPhone display)
    func getHistory() -> [(expression: String, result: String)] {
        let context = container.viewContext
        let request: NSFetchRequest<CalculationSession> = CalculationSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CalculationSession.timestamp, ascending: false)]
        do {
            let sessions = try context.fetch(request)
            return sessions.compactMap { session -> (expression: String, result: String)? in
                let data = session.swiftSessionData

                guard let snapshot = try? JSONDecoder().decode(CalculatorSessionSnapshot.self, from: data),
                      let firstState = snapshot.calculatorStates.values.first else {
                    return nil
                }

                let resultStr = firstState.results.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n")
                return (expression: firstState.inputText, result: resultStr)
            }
        } catch {
            return []
        }
    }

    /// Restore a full session snapshot (for iPad)
    func restoreSession(_ session: CalculationSession) -> CalculatorSessionSnapshot? {
        let data = session.swiftSessionData
        return try? JSONDecoder().decode(CalculatorSessionSnapshot.self, from: data)
    }

    /// Get all sessions for history view
    func getSessions() -> [CalculationSession] {
        let context = container.viewContext
        let request: NSFetchRequest<CalculationSession> = CalculationSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CalculationSession.timestamp, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func clearHistory() {
        let context = container.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = CalculationSession.fetchRequest()
        let delete = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try context.execute(delete)
            try context.save()
        } catch {
            // Clear history failed - non-fatal
        }
    }

    func save() {
        try? container.viewContext.save()
    }
}
