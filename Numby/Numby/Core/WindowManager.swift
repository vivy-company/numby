//
//  WindowManager.swift
//  Numby
//
//  Manages window state and coordination across multiple windows
//

import Foundation
import AppKit
import SwiftUI
import Combine

/// Global window manager for coordinating multiple calculator windows
class WindowManager: ObservableObject {
    static let shared = WindowManager()

    /// All active calculator windows
    @Published private(set) var windows: [NumbyWindow] = []

    private init() {
        setupNotifications()
    }

    private func setupNotifications() {
        // Listen for window lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    // MARK: - Window Registration

    func register(window: NumbyWindow) {
        if !windows.contains(where: { $0 === window }) {
            windows.append(window)
        }
    }

    func unregister(window: NumbyWindow) {
        windows.removeAll { $0 === window }
    }

    // MARK: - Window Queries

    var activeWindow: NumbyWindow? {
        windows.first { $0.isKeyWindow }
    }

    var allControllers: [CalculatorController] {
        windows.compactMap { $0.controller }
    }

    // MARK: - Notifications

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        // Use weak reference to avoid accessing deallocated memory
        guard let window = notification.object as? NumbyWindow,
              !window.isReleasedWhenClosed || window.isVisible else { return }
        
        // Additional safety check
        guard window.windowNumber != -1 else { return }
        
        register(window: window)
    }

    @objc private func windowWillClose(_ notification: Notification) {
        // Use weak reference and check if window is still valid
        guard let window = notification.object as? NumbyWindow else { return }

        unregister(window: window)
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Configuration Management

extension WindowManager {
    /// Save all window states for restoration
    func saveWindowStates() -> Data? {
        let states = windows.compactMap { window -> WindowState? in
            guard let controller = window.controller else { return nil }

            return WindowState(
                frame: NSStringFromRect(window.frame),
                splitTree: controller.splitTree,
                windowLevel: window.level.rawValue
            )
        }

        return try? JSONEncoder().encode(states)
    }

    /// Restore windows from saved states
    func restoreWindowStates(from data: Data) {
        guard let states = try? JSONDecoder().decode([WindowState].self, from: data) else {
            return
        }

        for state in states {
            let window = NumbyWindow()
            window.setFrame(NSRectFromString(state.frame), display: true)
            window.controller?.restoreSplitTree(state.splitTree)
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Window State

struct WindowState: Codable {
    let frame: String
    let splitTree: SplitTree
    let windowLevel: Int
}
