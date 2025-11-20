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
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

// iOS-compatible Persistence class
class Persistence {
    static let shared = Persistence()

    private var history: [(expression: String, result: String)] = []

    private init() {
        loadHistory()
    }

    func addHistoryEntry(expression: String, result: String) {
        history.append((expression: expression, result: result))
        saveHistory()
    }

    func getHistory() -> [(expression: String, result: String)] {
        return history
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    func save() {
        saveHistory()
    }

    private func saveHistory() {
        let historyData = history.map { ["expression": $0.expression, "result": $0.result] }
        UserDefaults.standard.set(historyData, forKey: "calculatorHistory")
    }

    private func loadHistory() {
        if let historyData = UserDefaults.standard.array(forKey: "calculatorHistory") as? [[String: String]] {
            history = historyData.compactMap { dict in
                guard let expression = dict["expression"], let result = dict["result"] else { return nil }
                return (expression: expression, result: result)
            }
        }
    }
}
