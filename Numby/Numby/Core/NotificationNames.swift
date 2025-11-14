//
//  NotificationNames.swift
//  Numby
//
//  Notification names for app-wide communication
//

import Foundation

extension Notification.Name {
    /// Posted when the history sidebar should be toggled
    static let toggleHistorySidebar = Notification.Name("toggleHistorySidebar")

    /// Posted when a session should be restored in a new tab
    /// Object: CalculatorSessionSnapshot
    static let restoreSessionInNewTab = Notification.Name("restoreSessionInNewTab")

    /// Posted when the current session should be saved
    static let saveCurrentSession = Notification.Name("saveCurrentSession")

    /// Posted when sidebar state changes (userInfo: windowId, isCollapsed)
    static let sidebarDidToggle = Notification.Name("sidebarDidToggle")

    /// Posted when the sidebar width changes (userInfo: windowId, width)
    static let sidebarWidthDidChange = Notification.Name("sidebarWidthDidChange")

}
