//
//  AppDelegate.swift
//  Numby
//
//  Main app delegate - handles window lifecycle, tab management, and state persistence
//

import Cocoa
import SwiftUI
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    // Store window controllers to maintain strong references
    private var windowControllers: [CalculatorWindowController] = []
    private var settingsWindowController: SettingsWindowController?
    private var cliInstallerWindowController: CLIInstallerWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Disable automatic window restoration
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")

        // Create initial window
        createNewWindow()

        // Configure app behavior
        setupMenus()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup window controllers
        windowControllers.removeAll()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            createNewWindow()
        }
        return true
    }

    // MARK: - Window Management

    @objc func createNewWindow() {
        let controller = CalculatorWindowController()
        windowControllers.append(controller)
        controller.showWindow(nil)
    }

    @objc func createNewTab() {
        guard let keyWindow = NSApplication.shared.keyWindow else {
            createNewWindow()
            return
        }

        let controller = CalculatorWindowController()
        windowControllers.append(controller)

        if let newWindow = controller.window {
            // Disable animations to prevent tab jittering
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0
                keyWindow.addTabbedWindow(newWindow, ordered: .above)
            }, completionHandler: {
                controller.showWindow(nil)
            })
        }
    }

    @objc func openSettings() {
        if let controller = settingsWindowController {
            controller.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = SettingsWindowController()
        controller.cleanupHandler = { [weak self] in
            self?.settingsWindowController = nil
        }
        settingsWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openCLIInstaller() {
        if let controller = cliInstallerWindowController {
            controller.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = CLIInstallerWindowController()
        controller.cleanupHandler = { [weak self] in
            self?.cliInstallerWindowController = nil
        }
        cliInstallerWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func exportCalculator() {
        guard let keyWindow = NSApplication.shared.keyWindow as? NumbyWindow,
              let controller = keyWindow.controller else {
            return
        }

        // Get active calculator content
        guard let activeLeafId = controller.focusedLeafId,
              let calculator = controller.calculators[activeLeafId] else {
            return
        }

        let content = calculator.inputText
        if content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            let alert = NSAlert()
            alert.messageText = "Nothing to Export"
            alert.informativeText = "The current calculator is empty. Add some content before exporting."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        FileHandler.shared.exportCalculator(content: content, from: keyWindow, defaultName: keyWindow.title)
    }

    @objc func openCalculator() {
        guard let keyWindow = NSApplication.shared.keyWindow as? NumbyWindow,
              let controller = keyWindow.controller else {
            return
        }

        // Import content
        guard let content = FileHandler.shared.importCalculator(from: keyWindow) else {
            return
        }

        // Set content to active calculator
        if let activeLeafId = controller.focusedLeafId,
           let calculator = controller.calculators[activeLeafId] {
            calculator.inputText = content
        }
    }

    // MARK: - Menu Setup

    private func setupMenus() {
        let mainMenu = NSMenu()

        // App Menu
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "About Numby", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")

        // CLI Installation menu item
        let cliMenuItem = NSMenuItem(title: "Install Command Line Tool...", action: #selector(openCLIInstaller), keyEquivalent: "")
        cliMenuItem.target = self
        appMenu.addItem(cliMenuItem)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide Numby", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem({ () -> NSMenuItem in
            let item = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
            item.keyEquivalentModifierMask = [.command, .option]
            return item
        }())
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Numby", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        mainMenu.addItem(appMenuItem)

        // File Menu
        let fileMenu = NSMenu(title: "File")
        let fileMenuItem = NSMenuItem()
        fileMenuItem.submenu = fileMenu

        fileMenu.addItem(withTitle: "New Window", action: #selector(createNewWindow), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "New Tab", action: #selector(createNewTab), keyEquivalent: "t")
        fileMenu.addItem(NSMenuItem.separator())

        let openItem = NSMenuItem(title: "Open Calculator...", action: #selector(openCalculator), keyEquivalent: "o")
        openItem.target = self
        fileMenu.addItem(openItem)

        let exportItem = NSMenuItem(title: "Export Calculator...", action: #selector(exportCalculator), keyEquivalent: "s")
        exportItem.target = self
        fileMenu.addItem(exportItem)

        fileMenu.addItem(NSMenuItem.separator())
        // Cmd+W handled by closeSplit - closes pane or tab if last pane
        fileMenu.addItem(withTitle: "Close", action: #selector(NumbyWindow.closeSplit), keyEquivalent: "w")

        mainMenu.addItem(fileMenuItem)

        // Edit Menu
        let editMenu = NSMenu(title: "Edit")
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu

        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        mainMenu.addItem(editMenuItem)

        // View Menu
        let viewMenu = NSMenu(title: "View")
        let viewMenuItem = NSMenuItem()
        viewMenuItem.submenu = viewMenu

        viewMenu.addItem(withTitle: "Split Horizontally", action: #selector(NumbyWindow.splitHorizontally), keyEquivalent: "d")
        viewMenu.addItem(withTitle: "Split Vertically", action: #selector(NumbyWindow.splitVertically), keyEquivalent: "D")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")

        mainMenu.addItem(viewMenuItem)

        // Window Menu
        let windowMenu = NSMenu(title: "Window")
        let windowMenuItem = NSMenuItem()
        windowMenuItem.submenu = windowMenu

        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())

        // Show Tabs
        let showTabsItem = NSMenuItem(title: "Show All Tabs", action: #selector(NSWindow.toggleTabBar(_:)), keyEquivalent: "")
        windowMenu.addItem(showTabsItem)

        windowMenu.addItem(NSMenuItem.separator())

        // Tab navigation shortcuts (these will show on tabs)
        let nextTabItem = NSMenuItem(title: "Select Next Tab", action: #selector(NSWindow.selectNextTab(_:)), keyEquivalent: "\t")
        nextTabItem.keyEquivalentModifierMask = [.control]
        windowMenu.addItem(nextTabItem)

        let prevTabItem = NSMenuItem(title: "Select Previous Tab", action: #selector(NSWindow.selectPreviousTab(_:)), keyEquivalent: "\t")
        prevTabItem.keyEquivalentModifierMask = [.control, .shift]
        windowMenu.addItem(prevTabItem)

        windowMenu.addItem(NSMenuItem.separator())

        // Add Cmd+1 through Cmd+9 for switching to specific tabs
        for i in 1...9 {
            let tabItem = NSMenuItem(title: "Show Tab \(i)", action: #selector(NumbyWindow.selectTab(_:)), keyEquivalent: "\(i)")
            tabItem.tag = i
            windowMenu.addItem(tabItem)
        }

        mainMenu.addItem(windowMenuItem)
        NSApplication.shared.windowsMenu = windowMenu

        // Help Menu
        let helpMenu = NSMenu(title: "Help")
        let helpMenuItem = NSMenuItem()
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(withTitle: "Numby Help", action: #selector(NSApplication.showHelp(_:)), keyEquivalent: "?")

        mainMenu.addItem(helpMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }
}

// MARK: - Window Controller

class CalculatorWindowController: NSWindowController, NSWindowDelegate {
    private var calculatorController: CalculatorController?

    convenience init() {
        let window = NumbyWindow()
        self.init(window: window)
        window.delegate = self

        // Setup content after window is fully initialized
        window.setupContent()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        // Window loaded, delegate is set
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Check if any calculator has content
        guard let numbyWindow = sender as? NumbyWindow,
              let controller = numbyWindow.controller else {
            return true
        }

        // Check all calculator instances for non-empty content
        let hasContent = controller.calculators.values.contains { calculator in
            !calculator.inputText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty
        }

        if hasContent {
            // Show confirmation dialog
            let alert = NSAlert()
            alert.messageText = "Close without saving?"
            alert.informativeText = "This tab contains unsaved content. Are you sure you want to close it?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Close")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            return response == .alertFirstButtonReturn
        }

        return true
    }

    func windowWillClose(_ notification: Notification) {
        // Release stone name
        if let window = window as? NumbyWindow {
            StoneNameGenerator.shared.releaseName(window.title)
            window.cleanupContent()
        }
        calculatorController?.cleanup()
        calculatorController = nil
    }
}

// MARK: - Custom Window Class

class NumbyWindow: NSWindow, NSToolbarDelegate {
    var controller: CalculatorController?
    private weak var windowButtonsBackdrop: NSView?
    private var tabBarIdentifier: NSUserInterfaceItemIdentifier?

    private var tabBarConstraintObserver: NSObjectProtocol?
    private weak var tabBarAccessorySuperview: NSView?
    private var tabBarConstraints: [NSLayoutConstraint] = []
    private var centeredTitleItem: NSToolbarItem?

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
    }

    convenience init() {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
    }

    private func setupWindow() {
        // Set tab title with random stone name
        title = StoneNameGenerator.shared.getRandomName()

        // Set minimum window size
        minSize = NSSize(width: 400, height: 300)

        center()

        // Enable tabs
        tabbingMode = .preferred
        tabbingIdentifier = "calculator" // Group calculator windows together

        // Hide native title - we'll use custom toolbar item
        titleVisibility = .hidden

        // Create a toolbar with custom title
        let toolbar = NSToolbar(identifier: "NumbyToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        self.toolbar = toolbar
        toolbarStyle = .unifiedCompact
        titlebarSeparatorStyle = .none

        // Show title when single tab
        updateTitleVisibility()

        // Observe tab changes
        setupTabObserver()

        // Make window background transparent for theme control
        backgroundColor = .clear
        isOpaque = false

        // Disable window restoration completely
        isRestorable = false
        restorationClass = nil

    }

    private func hasMultipleTabs() -> Bool {
        return tabGroup?.windows.count ?? 1 > 1
    }

    private func updateTitleVisibility() {
        guard let toolbar = self.toolbar else { return }

        if hasMultipleTabs() {
            // Multiple tabs - hide custom title
            toolbar.centeredItemIdentifiers.remove(NSToolbarItem.Identifier("CenteredTitle"))
        } else {
            // Single tab - show centered title
            toolbar.centeredItemIdentifiers.insert(NSToolbarItem.Identifier("CenteredTitle"))
        }

        // Rebuild toolbar items
        toolbar.validateVisibleItems()
    }

    // MARK: - NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier.rawValue == "CenteredTitle" {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)

            // Create centered title label
            let label = NSTextField(labelWithString: title)
            label.font = .systemFont(ofSize: 13)
            label.alignment = .center
            label.textColor = .labelColor
            label.isBezeled = false
            label.drawsBackground = false
            label.isEditable = false
            label.isSelectable = false
            label.lineBreakMode = .byTruncatingTail

            item.view = label
            item.visibilityPriority = .user
            centeredTitleItem = item
            return item
        }
        return nil
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        if hasMultipleTabs() {
            return []
        } else {
            return [
                .flexibleSpace,
                NSToolbarItem.Identifier("CenteredTitle"),
                .flexibleSpace
            ]
        }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .flexibleSpace,
            NSToolbarItem.Identifier("CenteredTitle")
        ]
    }

    private func setupTabObserver() {
        // Observe window becoming key
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.updateTitleVisibility()
            self?.updateTabShortcuts()
        }

        // Observe when tabs are added/removed
        NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateTitleVisibility()
                self?.updateTabShortcuts()
            }
        }
    }

    func setupContent() {
        // Create controller and view
        controller = CalculatorController()

        // Use NSHostingController for proper ViewBridge lifecycle management
        let rootView = CalculatorRootView(controller: controller!)
            .environmentObject(ThemeManager.shared)
            .environmentObject(ConfigurationManager.shared)
        let hostingController = NSHostingController(rootView: rootView)

        // CRITICAL: Set initial frame from window's content rect
        // After setting contentViewController, AppKit will manage sizing automatically
        let initialFrame = NSRect(origin: .zero, size: frame.size)
        hostingController.view.frame = initialFrame
        hostingController.view.autoresizingMask = [.width, .height]

        // Set contentViewController
        contentViewController = hostingController

        // Sync titlebar appearance after window is shown
        DispatchQueue.main.async { [weak self] in
            self?.syncTitlebarAppearance()
        }
    }

    func cleanupContent() {
        // Clean up resources
        controller?.cleanup()
        controller = nil
        contentViewController = nil
        removeTabBarConstraintObservation()
    }

    deinit {
        removeTabBarConstraintObservation()
    }

    private func syncTitlebarAppearance() {
        guard let themeFrame = contentView?.superview else { return }
        guard let titlebarView = themeFrame.value(forKey: "titlebarView") as? NSView else { return }

        // Get background color from configuration (defaults to system background)
        let bgColor = ConfigurationManager.shared.config.backgroundColor ?? NSColor.textBackgroundColor

        // Set titlebar background to match configured color
        titlebarView.wantsLayer = true
        titlebarView.layer?.backgroundColor = bgColor.cgColor

        // Apply same background to toolbar
        if let toolbarView = titlebarView.subviews.first(where: {
            String(describing: type(of: $0)).contains("NSToolbarView")
        }) {
            toolbarView.wantsLayer = true
            toolbarView.layer?.backgroundColor = bgColor.cgColor
        }

        // Hide the titlebar background view
        if let titlebarBackgroundView = titlebarView.subviews.first(where: {
            String(describing: type(of: $0)).contains("TitlebarBackgroundView")
        }) {
            titlebarBackgroundView.isHidden = true
        }
    }

    /// Update background color (call this when theme changes)
    func updateBackgroundColor(_ color: NSColor) {
        backgroundColor = .clear
        syncTitlebarAppearance()
        contentView?.needsDisplay = true
    }

    // MARK: - Tab Bar Positioning

    override func addTitlebarAccessoryViewController(_ childViewController: NSTitlebarAccessoryViewController) {
        super.addTitlebarAccessoryViewController(childViewController)

        if isTabBar(childViewController) {
            tabBarIdentifier = NSUserInterfaceItemIdentifier(rawValue: "NumbyTabBar")
            childViewController.identifier = tabBarIdentifier
            positionTabBar(childViewController)
        }
    }

    private func isTabBar(_ controller: NSTitlebarAccessoryViewController) -> Bool {
        if controller.identifier == tabBarIdentifier {
            return true
        }

        if controller.identifier == nil && controller.view.contains(className: "NSTabBar") {
            return true
        }

        return false
    }

    private func positionTabBar(_ tabBarController: NSTitlebarAccessoryViewController) {
        // Position tab bar to the right
        tabBarController.layoutAttribute = .right
        tabBarController.fullScreenMinHeight = 0

        // Wait a tick to avoid edge cases during startup
        DispatchQueue.main.async { [weak self] in
            self?.setupTabBarConstraints(tabBarController)
        }
    }

    private func setupTabBarConstraints(_ tabBarController: NSTitlebarAccessoryViewController) {
        guard let accessoryView = tabBarController.view.superview else { return }
        guard let titlebarView = accessoryView.superview else { return }
        guard titlebarView.swiftClassName.contains("NSTitlebarView") else { return }
        guard let toolbarView = titlebarView.subviews.first(where: {
            $0.swiftClassName.contains("NSToolbarView")
        }) else { return }

        tabBarAccessorySuperview = accessoryView
        accessoryView.layoutSubtreeIfNeeded()

        if accessoryView.bounds.width <= 1 {
            deferTabBarConstraints(for: accessoryView, controller: tabBarController)
            return
        }

        removeTabBarConstraintObservation()

        // Create backdrop for traffic lights
        addWindowButtonsBackdrop(titlebarView: titlebarView, toolbarView: toolbarView)
        guard let backdrop = windowButtonsBackdrop else { return }

        // Position tab bar accessory with 2pt vertical offset for traffic light alignment
        accessoryView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.deactivate(tabBarConstraints)
        tabBarConstraints = [
            accessoryView.leadingAnchor.constraint(equalTo: backdrop.trailingAnchor),
            accessoryView.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor),
            accessoryView.topAnchor.constraint(equalTo: toolbarView.topAnchor, constant: 2),
            accessoryView.heightAnchor.constraint(equalTo: toolbarView.heightAnchor),
        ]

        NSLayoutConstraint.activate(tabBarConstraints)
    }

    private func deferTabBarConstraints(for accessoryView: NSView, controller: NSTitlebarAccessoryViewController) {
        accessoryView.postsFrameChangedNotifications = true

        guard tabBarConstraintObserver == nil else { return }

        tabBarConstraintObserver = NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: accessoryView,
            queue: .main
        ) { [weak self, weak controller] _ in
            guard let self = self, let controller = controller else { return }
            self.setupTabBarConstraints(controller)
        }
    }

    private func removeTabBarConstraintObservation() {
        if let observer = tabBarConstraintObserver {
            NotificationCenter.default.removeObserver(observer)
            tabBarConstraintObserver = nil
        }

        tabBarAccessorySuperview?.postsFrameChangedNotifications = false
        tabBarAccessorySuperview = nil
    }

    private func addWindowButtonsBackdrop(titlebarView: NSView, toolbarView: NSView) {
        // Check if already exists
        if windowButtonsBackdrop != nil {
            return
        }

        let backdrop = NSView()
        backdrop.wantsLayer = true
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        titlebarView.addSubview(backdrop, positioned: .below, relativeTo: toolbarView)

        NSLayoutConstraint.activate([
            backdrop.leadingAnchor.constraint(equalTo: titlebarView.leadingAnchor),
            backdrop.widthAnchor.constraint(equalToConstant: 78),
            backdrop.topAnchor.constraint(equalTo: toolbarView.topAnchor),
            backdrop.heightAnchor.constraint(equalTo: toolbarView.heightAnchor),
        ])

        windowButtonsBackdrop = backdrop
    }

    // MARK: - Split Actions

    @objc func splitHorizontally() {
        controller?.splitCurrentLeaf(direction: .horizontal)
    }

    @objc func splitVertically() {
        controller?.splitCurrentLeaf(direction: .vertical)
    }

    @objc func closeSplit() {
        guard let controller = controller else { return }

        let leafCount = controller.splitTree.getAllLeafIds().count

        if leafCount > 1 {
            // Multiple panes - close the focused pane
            controller.closeCurrentLeaf()
        } else {
            // Last pane - close the entire tab/window
            performClose(nil)
        }
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(splitHorizontally) ||
           menuItem.action == #selector(splitVertically) {
            return true
        }

        if menuItem.action == #selector(closeSplit) {
            // Always enabled - closes pane or tab
            return true
        }

        return super.validateMenuItem(menuItem)
    }

    // MARK: - Window Delegate

    // MARK: - Tab Support

    override func newWindowForTab(_ sender: Any?) {
        // This enables the "+" button in tab bar
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.createNewTab()
    }

    @objc func selectTab(_ sender: NSMenuItem) {
        let tabIndex = sender.tag - 1 // Convert 1-based to 0-based
        guard let tabGroup = self.tabGroup else { return }

        let windows = tabGroup.windows
        guard tabIndex >= 0 && tabIndex < windows.count else { return }

        windows[tabIndex].makeKeyAndOrderFront(nil)
    }

    // Update tab labels with keyboard shortcuts
    func updateTabShortcuts() {
        guard let tabGroup = self.tabGroup else { return }

        for (index, window) in tabGroup.windows.enumerated() {
            guard index < 9 else { break } // Only first 9 tabs get shortcuts

            // Create accessory view with shortcut label
            let stackView = NSStackView()
            stackView.orientation = .horizontal
            stackView.spacing = 4

            // Shortcut label
            let label = NSTextField(labelWithString: "⌘\(index + 1)")
            label.font = .systemFont(ofSize: 11)
            label.textColor = .secondaryLabelColor
            label.alignment = .right

            stackView.addArrangedSubview(label)

            // Set as tab accessory
            window.tab.accessoryView = stackView
        }
    }

    private func log(_ message: @autoclosure () -> String) {
        let addr = Unmanaged.passUnretained(self).toOpaque()
        Swift.print("[NumbyWindow \(addr)] \(message())")
    }
}

// MARK: - Settings Window Controller

final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    var cleanupHandler: (() -> Void)?

    init() {
        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 500, height: 400))
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.isReleasedWhenClosed = false

        // Add toolbar with unified compact style
        let toolbar = NSToolbar(identifier: "SettingsToolbar")
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        window.toolbarStyle = .unifiedCompact
        window.titlebarSeparatorStyle = .none

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        cleanupHandler?()
        cleanupHandler = nil

        // Release SwiftUI hierarchy explicitly to avoid dangling ViewBridge refs
        DispatchQueue.main.async { [weak self] in
            self?.contentViewController = nil
        }
    }
}

// MARK: - CLI Installer Window Controller

final class CLIInstallerWindowController: NSWindowController, NSWindowDelegate {
    var cleanupHandler: (() -> Void)?

    init() {
        let hostingController = NSHostingController(rootView: CLIInstallerView())
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 500, height: 600))
        window.title = "Install Command Line Tool"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.isReleasedWhenClosed = false

        // Add toolbar with unified compact style
        let toolbar = NSToolbar(identifier: "CLIInstallerToolbar")
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        window.toolbarStyle = .unifiedCompact
        window.titlebarSeparatorStyle = .none

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        cleanupHandler?()
        cleanupHandler = nil

        // Release SwiftUI hierarchy explicitly to avoid dangling ViewBridge refs
        DispatchQueue.main.async { [weak self] in
            self?.contentViewController = nil
        }
    }
}
