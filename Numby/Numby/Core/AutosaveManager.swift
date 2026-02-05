//
//  AutosaveManager.swift
//  Numby
//
//  Autosave current calculator sessions for restore on relaunch.
//

#if os(macOS)
import Foundation
import AppKit

struct AutosavedWindowState: Codable {
    let frame: String
    let windowLevel: Int
    let snapshot: CalculatorSessionSnapshot
}

final class AutosaveManager {
    static let shared = AutosaveManager()

    private let autosaveKey = "numby.autosave.windows"
    private var pendingWorkItem: DispatchWorkItem?

    private init() {}

    func scheduleAutosave() {
        pendingWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.saveNow()
        }
        pendingWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
    }

    func saveNow() {
        let windows = WindowManager.shared.windows
        let states: [AutosavedWindowState] = windows.compactMap { window in
            guard let controller = window.controller else { return nil }
            let snapshot = controller.createSnapshot()
            return AutosavedWindowState(
                frame: NSStringFromRect(window.frame),
                windowLevel: window.level.rawValue,
                snapshot: snapshot
            )
        }

        guard let data = try? JSONEncoder().encode(states) else { return }
        UserDefaults.standard.set(data, forKey: autosaveKey)
    }

    func loadAutosavedStates() -> [AutosavedWindowState] {
        guard let data = UserDefaults.standard.data(forKey: autosaveKey),
              let states = try? JSONDecoder().decode([AutosavedWindowState].self, from: data) else {
            return []
        }
        return states
    }
}
#endif
