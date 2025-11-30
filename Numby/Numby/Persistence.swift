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

class Persistence {
    static let shared = Persistence()

    private let container: NSPersistentCloudKitContainer

    private init() {
        container = PersistenceController.shared.container
    }

    func addHistoryEntry(expression: String, result: String) {
        let context = container.viewContext
        let session = CalculationSession(context: context)
        session.id = NSUUID()
        session.timestamp = NSDate()
        let txt = "\(expression)\n= \(result)"
        if let data = txt.data(using: .utf8) {
            session.sessionData = NSData(data: data)
        }
        session.searchableText = txt
        try? context.save()
    }

    func getHistory() -> [(expression: String, result: String)] {
        let context = container.viewContext
        let request: NSFetchRequest<CalculationSession> = CalculationSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CalculationSession.timestamp, ascending: false)]
        do {
            let sessions = try context.fetch(request)
            return sessions.compactMap { session in
                guard let nsData = session.sessionData as? NSData,
                      let data = nsData as Data?,
                      let txt = String(data: data, encoding: .utf8),
                      let range = txt.range(of: "\n= ") else { return nil }
                let expr = String(txt[..<range.lowerBound])
                let res = String(txt[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                return (expression: expr, result: res)
            }
        } catch {
            return []
        }
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
