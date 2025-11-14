//
//  MainSplitViewController.swift
//  Numby
//
//  Native split view controller with sidebar
//

import Cocoa
import SwiftUI
import ObjectiveC.runtime

class MainSplitViewController: NSSplitViewController {
    private var calculatorController: CalculatorController!
    private var sidebarItem: NSSplitViewItem!
    private var contentItem: NSSplitViewItem!

    // Shared sidebar state across all tabs in the same window
    static var sharedSidebarState: [String: Bool] = [:] // windowId -> isCollapsed
    private var windowId: String = ""
    private var windowInstanceId: String = ""

    convenience init(calculatorController: CalculatorController, windowId: String, windowInstanceId: String) {
        self.init()
        self.calculatorController = calculatorController
        self.windowId = windowId
        self.windowInstanceId = windowInstanceId
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure split view
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.focusRingType = .none

        // Set background color for the entire split view
        let backgroundColor = ConfigurationManager.shared.config.backgroundColor ?? NSColor.textBackgroundColor
        splitView.wantsLayer = true
        splitView.layer?.backgroundColor = backgroundColor.cgColor

        // Remove split view borders
        view.wantsLayer = true
        view.layer?.backgroundColor = backgroundColor.cgColor
        view.focusRingType = .none

        // Create sidebar
        let sidebarVC = HistorySidebarViewController()
        sidebarVC.onSessionSelected = { [weak self] session in
            self?.restoreSession(session)
        }

        sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        sidebarItem.canCollapse = true
        sidebarItem.minimumThickness = 200
        sidebarItem.maximumThickness = 400
        sidebarItem.allowsFullHeightLayout = true // Full height like Finder
        sidebarItem.titlebarSeparatorStyle = .none

        // Use shared state for this window
        let isCollapsed = MainSplitViewController.sharedSidebarState[windowId] ?? true
        sidebarItem.isCollapsed = isCollapsed
        addSplitViewItem(sidebarItem)
        disableWrapperFocus(for: sidebarItem)

        // Create main content
        let rootView = CalculatorRootView(controller: calculatorController)
            .environmentObject(ThemeManager.shared)
            .environmentObject(ConfigurationManager.shared)

        let contentVC = FocuslessHostingController(rootView: rootView)
        contentItem = NSSplitViewItem(viewController: contentVC)
        contentItem.canCollapse = false
        addSplitViewItem(contentItem)
        disableWrapperFocus(for: contentItem)

        // Set background for content view and remove all borders
        contentVC.view.wantsLayer = true
        contentVC.view.layer?.backgroundColor = backgroundColor.cgColor
        contentVC.view.layer?.borderWidth = 0
        contentVC.view.layer?.borderColor = nil

        // Remove focus ring from hosting views
        if let hostingView = contentVC.view.subviews.first {
            hostingView.wantsLayer = true
            hostingView.layer?.borderWidth = 0
            hostingView.layer?.borderColor = nil
        }

        // Observe sidebar state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sidebarDidToggle),
            name: .sidebarDidToggle,
            object: nil
        )

        DispatchQueue.main.async { [weak self] in
            self?.notifySidebarWidthChanged()
        }
    }

    @objc func toggleSidebar() {
        sidebarItem.animator().isCollapsed.toggle()

        // Save state for this window and notify all tabs
        MainSplitViewController.sharedSidebarState[windowId] = sidebarItem.isCollapsed
        NotificationCenter.default.post(
            name: .sidebarDidToggle,
            object: nil,
            userInfo: ["windowId": windowId, "isCollapsed": sidebarItem.isCollapsed]
        )

        notifySidebarWidthChanged()
    }

    @objc private func sidebarDidToggle(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let notificationWindowId = userInfo["windowId"] as? String,
              let isCollapsed = userInfo["isCollapsed"] as? Bool,
              notificationWindowId == windowId else {
            return
        }

        // Update sidebar state if notification is for this window
        if sidebarItem.isCollapsed != isCollapsed {
            sidebarItem.animator().isCollapsed = isCollapsed
        }

        notifySidebarWidthChanged()
    }

    private func restoreSession(_ session: CalculationSession) {
        let historyManager = HistoryManager()
        guard let snapshot = historyManager.restoreSession(session) else { return }

        // Post notification to create new tab with snapshot
        NotificationCenter.default.post(
            name: .restoreSessionInNewTab,
            object: snapshot
        )
    }

    // MARK: - NSSplitViewDelegate

    override func splitViewDidResizeSubviews(_ notification: Notification) {
        super.splitViewDidResizeSubviews(notification)
        notifySidebarWidthChanged()
    }

    // MARK: - Sidebar width broadcasting

    private func notifySidebarWidthChanged() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.notifySidebarWidthChanged()
            }
            return
        }

        let width: CGFloat
        if sidebarItem.isCollapsed {
            width = 0
        } else {
            width = sidebarItem.viewController.view.bounds.width
        }

        NotificationCenter.default.post(
            name: .sidebarWidthDidChange,
            object: nil,
            userInfo: [
                "windowId": windowInstanceId,
                "width": width
            ]
        )
    }

    private func disableWrapperFocus(for item: NSSplitViewItem) {
        guard let wrapper = item.viewController.view.superview else { return }

        wrapper.focusRingType = .none
        wrapper.postsFrameChangedNotifications = false

        // Don't replace the wrapper's class at runtime as it causes KVO issues
        // Just disable focus ring is sufficient
        // if object_getClass(wrapper) !== FocuslessSplitItemWrapper.self {
        //     object_setClass(wrapper, FocuslessSplitItemWrapper.self)
        // }
    }
}
