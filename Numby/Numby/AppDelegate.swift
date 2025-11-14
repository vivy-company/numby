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

        // Setup notification observers
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRestoreSessionInNewTab(_:)),
            name: .restoreSessionInNewTab,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocaleChanged),
            name: NSNotification.Name("LocaleChanged"),
            object: nil
        )
    }

    @objc private func handleLocaleChanged() {
        updateAllMenuTitles()

        // Refresh all window toolbars and titles
        for window in NSApplication.shared.windows {
            // Recreate toolbar to get fresh localized labels
            if let numbyWindow = window as? NumbyWindow {
                let oldToolbar = window.toolbar
                let newToolbar = NSToolbar(identifier: oldToolbar?.identifier ?? NSToolbar.Identifier("NumbyToolbar"))
                newToolbar.delegate = numbyWindow
                newToolbar.displayMode = .iconOnly
                window.toolbar = newToolbar
            }

            // Update window titles if they're settings or CLI installer windows
            if let settingsWindow = settingsWindowController?.window, window == settingsWindow {
                window.title = "window.settings".localized()
            }
            if let cliWindow = cliInstallerWindowController?.window, window == cliWindow {
                window.title = "window.cliInstaller".localized()
            }
        }
    }

    private func updateAllMenuTitles() {
        guard let mainMenu = NSApplication.shared.mainMenu else { return }

        // Iterate through all menu items and update their titles
        for (index, menuItem) in mainMenu.items.enumerated() {
            guard let submenu = menuItem.submenu else { continue }

            // Update submenu title based on index (menus are in fixed order)
            switch index {
            case 0: break // App menu (no title)
            case 1: submenu.title = "menu.file".localized()
            case 2: submenu.title = "menu.edit".localized()
            case 3: submenu.title = "menu.view".localized()
            case 4: submenu.title = "menu.window".localized()
            case 5: submenu.title = "menu.help".localized()
            default: break
            }

            // Update items within menu
            for item in submenu.items {
                if item.isSeparatorItem { continue }

                // Update title based on action
                if let action = item.action {
                    item.title = localizedTitleForAction(action, tag: item.tag)
                }
            }
        }
    }

    private func localizedTitleForAction(_ action: Selector, tag: Int = 0) -> String {
        switch action {
        // App menu
        case #selector(NSApplication.orderFrontStandardAboutPanel(_:)): return "menu.about".localized()
        case #selector(openSettings): return "menu.settings".localized()
        case #selector(openCLIInstaller): return "menu.installCLI".localized()
        case #selector(NSApplication.hide(_:)): return "menu.hide".localized()
        case #selector(NSApplication.hideOtherApplications(_:)): return "menu.hideOthers".localized()
        case #selector(NSApplication.unhideAllApplications(_:)): return "menu.showAll".localized()
        case #selector(NSApplication.terminate(_:)): return "menu.quit".localized()

        // File menu
        case #selector(createNewWindow): return "menu.newWindow".localized()
        case #selector(createNewTab): return "menu.newTab".localized()
        case #selector(openCalculator): return "menu.openCalculator".localized()
        case #selector(exportCalculator): return "menu.exportCalculator".localized()
        case #selector(NumbyWindow.closeSplit): return "menu.close".localized()

        // Edit menu
        case #selector(UndoManager.undo): return "menu.undo".localized()
        case #selector(UndoManager.redo): return "menu.redo".localized()
        case #selector(NSText.cut(_:)): return "menu.cut".localized()
        case #selector(NSText.copy(_:)): return "menu.copy".localized()
        case #selector(NSText.paste(_:)): return "menu.paste".localized()
        case #selector(NSText.selectAll(_:)): return "menu.selectAll".localized()

        // View menu
        case #selector(toggleHistorySidebar): return "menu.toggleHistory".localized()
        case #selector(NumbyWindow.splitHorizontally): return "menu.splitHorizontally".localized()
        case #selector(NumbyWindow.splitVertically): return "menu.splitVertically".localized()
        case #selector(NSWindow.toggleFullScreen(_:)): return "menu.fullScreen".localized()

        // Window menu
        case #selector(NSWindow.miniaturize(_:)): return "menu.minimize".localized()
        case #selector(NSWindow.zoom(_:)): return "menu.zoom".localized()
        case #selector(NSApplication.arrangeInFront(_:)): return "menu.bringAllToFront".localized()
        case #selector(NSWindow.toggleTabBar(_:)): return "menu.showAllTabs".localized()
        case #selector(NSWindow.selectNextTab(_:)): return "menu.nextTab".localized()
        case #selector(NSWindow.selectPreviousTab(_:)): return "menu.previousTab".localized()
        case #selector(NumbyWindow.selectTab(_:)):
            return tag > 0 ? String(format: "menu.showTab".localized(), tag) : ""

        // Help menu
        case #selector(NSApplication.showHelp(_:)): return "menu.numbyHelp".localized()

        default: return ""
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup window controllers
        windowControllers.removeAll()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
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
            alert.messageText = "alert.nothingToExport".localized()
            alert.informativeText = "alert.emptyCalculator".localized()
            alert.alertStyle = .informational
            alert.addButton(withTitle: "alert.ok".localized())
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

    @objc func toggleHistorySidebar() {
        // Toggle sidebar in the key window
        if let keyWindow = NSApplication.shared.keyWindow as? NumbyWindow {
            keyWindow.toggleSidebar()
        }
    }

    @objc func saveCurrentSession() {
        NotificationCenter.default.post(name: .saveCurrentSession, object: nil)
    }

    @objc func handleRestoreSessionInNewTab(_ notification: Notification) {
        guard let snapshot = notification.object as? CalculatorSessionSnapshot else {
            return
        }

        // Create new tab with restored session
        guard let keyWindow = NSApplication.shared.keyWindow else {
            createNewWindow(withSnapshot: snapshot)
            return
        }

        let controller = CalculatorWindowController(withSnapshot: snapshot)
        windowControllers.append(controller)

        if let newWindow = controller.window {
            keyWindow.addTabbedWindow(newWindow, ordered: .above)
            controller.showWindow(nil)
        }
    }

    func createNewWindow(withSnapshot snapshot: CalculatorSessionSnapshot? = nil) {
        let controller: CalculatorWindowController
        if let snapshot = snapshot {
            controller = CalculatorWindowController(withSnapshot: snapshot)
        } else {
            controller = CalculatorWindowController()
        }
        windowControllers.append(controller)
        controller.showWindow(nil)
    }

    // MARK: - Menu Setup

    private func setupMenus() {
        let mainMenu = NSMenu()

        // App Menu
        let appMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu

        appMenu.addItem(withTitle: "menu.about".localized(), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "menu.settings".localized(), action: #selector(openSettings), keyEquivalent: ",")

        // CLI Installation menu item
        let cliMenuItem = NSMenuItem(title: "menu.installCLI".localized(), action: #selector(openCLIInstaller), keyEquivalent: "")
        cliMenuItem.target = self
        appMenu.addItem(cliMenuItem)
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "menu.hide".localized(), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem({ () -> NSMenuItem in
            let item = NSMenuItem(title: "menu.hideOthers".localized(), action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
            item.keyEquivalentModifierMask = [.command, .option]
            return item
        }())
        appMenu.addItem(withTitle: "menu.showAll".localized(), action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "menu.quit".localized(), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        mainMenu.addItem(appMenuItem)

        // File Menu
        let fileMenu = NSMenu(title: "menu.file".localized())
        let fileMenuItem = NSMenuItem()
        fileMenuItem.submenu = fileMenu

        fileMenu.addItem(withTitle: "menu.newWindow".localized(), action: #selector(createNewWindow), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "menu.newTab".localized(), action: #selector(createNewTab), keyEquivalent: "t")
        fileMenu.addItem(NSMenuItem.separator())

        let openItem = NSMenuItem(title: "menu.openCalculator".localized(), action: #selector(openCalculator), keyEquivalent: "o")
        openItem.target = self
        fileMenu.addItem(openItem)

        let exportItem = NSMenuItem(title: "menu.exportCalculator".localized(), action: #selector(exportCalculator), keyEquivalent: "s")
        exportItem.target = self
        fileMenu.addItem(exportItem)

        fileMenu.addItem(NSMenuItem.separator())
        // Cmd+W handled by closeSplit - closes pane or tab if last pane
        fileMenu.addItem(withTitle: "menu.close".localized(), action: #selector(NumbyWindow.closeSplit), keyEquivalent: "w")

        mainMenu.addItem(fileMenuItem)

        // Edit Menu
        let editMenu = NSMenu(title: "menu.edit".localized())
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu

        editMenu.addItem(withTitle: "menu.undo".localized(), action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "menu.redo".localized(), action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "menu.cut".localized(), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "menu.copy".localized(), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "menu.paste".localized(), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "menu.selectAll".localized(), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        mainMenu.addItem(editMenuItem)

        // View Menu
        let viewMenu = NSMenu(title: "menu.view".localized())
        let viewMenuItem = NSMenuItem()
        viewMenuItem.submenu = viewMenu

        let toggleHistoryItem = NSMenuItem(title: "menu.toggleHistory".localized(), action: #selector(toggleHistorySidebar), keyEquivalent: "h")
        toggleHistoryItem.keyEquivalentModifierMask = [.command, .shift]
        toggleHistoryItem.target = self
        viewMenu.addItem(toggleHistoryItem)

        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "menu.splitHorizontally".localized(), action: #selector(NumbyWindow.splitHorizontally), keyEquivalent: "d")
        viewMenu.addItem(withTitle: "menu.splitVertically".localized(), action: #selector(NumbyWindow.splitVertically), keyEquivalent: "D")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "menu.fullScreen".localized(), action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")

        mainMenu.addItem(viewMenuItem)

        // Window Menu
        let windowMenu = NSMenu(title: "menu.window".localized())
        let windowMenuItem = NSMenuItem()
        windowMenuItem.submenu = windowMenu

        windowMenu.addItem(withTitle: "menu.minimize".localized(), action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "menu.zoom".localized(), action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "menu.bringAllToFront".localized(), action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())

        // Show Tabs
        let showTabsItem = NSMenuItem(title: "menu.showAllTabs".localized(), action: #selector(NSWindow.toggleTabBar(_:)), keyEquivalent: "")
        windowMenu.addItem(showTabsItem)

        windowMenu.addItem(NSMenuItem.separator())

        // Tab navigation shortcuts (these will show on tabs)
        let nextTabItem = NSMenuItem(title: "menu.nextTab".localized(), action: #selector(NSWindow.selectNextTab(_:)), keyEquivalent: "\t")
        nextTabItem.keyEquivalentModifierMask = [.control]
        windowMenu.addItem(nextTabItem)

        let prevTabItem = NSMenuItem(title: "menu.previousTab".localized(), action: #selector(NSWindow.selectPreviousTab(_:)), keyEquivalent: "\t")
        prevTabItem.keyEquivalentModifierMask = [.control, .shift]
        windowMenu.addItem(prevTabItem)

        windowMenu.addItem(NSMenuItem.separator())

        // Add Cmd+1 through Cmd+9 for switching to specific tabs
        for i in 1...9 {
            let tabItem = NSMenuItem(title: String(format: "menu.showTab".localized(), i), action: #selector(NumbyWindow.selectTab(_:)), keyEquivalent: "\(i)")
            tabItem.tag = i
            windowMenu.addItem(tabItem)
        }

        mainMenu.addItem(windowMenuItem)
        NSApplication.shared.windowsMenu = windowMenu

        // Help Menu
        let helpMenu = NSMenu(title: "menu.help".localized())
        let helpMenuItem = NSMenuItem()
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(withTitle: "menu.numbyHelp".localized(), action: #selector(NSApplication.showHelp(_:)), keyEquivalent: "?")

        mainMenu.addItem(helpMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }
}

// MARK: - Window Controller

class CalculatorWindowController: NSWindowController, NSWindowDelegate {
    private var calculatorController: CalculatorController?
    private var restoredSnapshot: CalculatorSessionSnapshot?

    convenience init() {
        let window = NumbyWindow()
        self.init(window: window)
        window.delegate = self

        // Setup content after window is fully initialized
        window.setupContent(withSnapshot: nil)
    }

    convenience init(withSnapshot snapshot: CalculatorSessionSnapshot) {
        let window = NumbyWindow()
        self.init(window: window)
        window.delegate = self
        self.restoredSnapshot = snapshot

        // Setup content after window is fully initialized
        window.setupContent(withSnapshot: snapshot)
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
            alert.messageText = "alert.closeWithoutSaving".localized()
            alert.informativeText = "alert.unsavedContent".localized()
            alert.alertStyle = .warning
            alert.addButton(withTitle: "alert.saveAndClose".localized())
            alert.addButton(withTitle: "alert.closeWithoutSavingButton".localized())
            alert.addButton(withTitle: "alert.cancel".localized())

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                // Save and close
                saveCurrentSession(controller: controller)
                return true
            } else if response == .alertSecondButtonReturn {
                // Close without saving
                return true
            } else {
                // Cancel
                return false
            }
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

    private func saveCurrentSession(controller: CalculatorController) {
        let historyManager = HistoryManager()
        historyManager.saveSession(
            splitTree: controller.splitTree,
            calculators: controller.calculators,
            customName: nil
        )
    }
}

// MARK: - Custom Window Class

class NumbyWindow: NSWindow, NSToolbarDelegate {
    var controller: CalculatorController?
    private weak var windowButtonsBackdrop: NSView?
    private let windowInstanceId = UUID().uuidString
    private var centeredTitleItem: NSToolbarItem?
    private let windowButtonsBackdropWidth: CGFloat = 78
    private weak var lastTextViewResponder: NSTextView?

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
    }

    convenience init() {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
    }

    private func setupWindow() {
        // Set tab title with random stone name
        title = StoneNameGenerator.shared.getRandomName()

        // Set minimum window size
        minSize = NSSize(width: 1200, height: 800)

        center()

        // Enable tabs
        tabbingMode = .preferred
        tabbingIdentifier = "calculator" // Group calculator windows together

        // Configure for full-height sidebar
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        // Create a toolbar with custom title
        let toolbar = NSToolbar(identifier: "NumbyToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.showsBaselineSeparator = false
        self.toolbar = toolbar
        toolbarStyle = .unified
        titlebarSeparatorStyle = .none

        // Center the title relative to window width, not toolbar available space
        toolbar.centeredItemIdentifiers = Set([NSToolbarItem.Identifier("CenteredTitle")])

        // Observe tab changes
        setupTabObserver()

        // Make window background clear for transparent titlebar
        backgroundColor = .clear
        isOpaque = false

        // Disable window restoration completely
        isRestorable = false
        restorationClass = nil

    }

    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        var target = responder

        if let responder = responder,
           String(describing: type(of: responder)).contains("KeyViewProxy"),
           let textView = preferredTextView {
            target = textView
        }

        if let textView = target as? NSTextView {
            lastTextViewResponder = textView
        }

        return super.makeFirstResponder(target)
    }

    override func selectNextKeyView(_ sender: Any?) {
        guard let textView = preferredTextView else {
            super.selectNextKeyView(sender)
            return
        }
        _ = makeFirstResponder(textView)
    }

    override func selectPreviousKeyView(_ sender: Any?) {
        guard let textView = preferredTextView else {
            super.selectPreviousKeyView(sender)
            return
        }
        _ = makeFirstResponder(textView)
    }

    override func becomeKey() {
        super.becomeKey()
        if let textView = preferredTextView {
            _ = makeFirstResponder(textView)
        }
    }

    private var preferredTextView: NSTextView? {
        if let textView = lastTextViewResponder {
            return textView
        }

        if let custom = contentView?.firstDescendant(ofType: CustomNSTextView.self) ??
            contentView?.firstDescendant(ofType: NSTextView.self) {
            lastTextViewResponder = custom
            return custom
        }

        return nil
    }

    private func hasMultipleTabs() -> Bool {
        let count = tabGroup?.windows.count ?? 1
        return count > 1
    }

    // MARK: - NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier.rawValue == "CenteredTitle" {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)

            // Create centered title label - always show "Numby"
            let label = NSTextField(labelWithString: "Numby")
            label.font = .systemFont(ofSize: 13, weight: .medium)
            label.alignment = .center
            label.textColor = .labelColor
            label.isBezeled = false
            label.drawsBackground = false
            label.isEditable = false
            label.isSelectable = false
            label.lineBreakMode = .byTruncatingTail

            // Size the label to fit its content
            label.sizeToFit()

            // Use the label directly as the view
            item.view = label
            item.visibilityPriority = .high
            centeredTitleItem = item
            return item
        } else if itemIdentifier == .toggleSidebar {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            let label = "toolbar.toggleSidebar".localized()
            item.label = label
            item.paletteLabel = label
            item.toolTip = "toolbar.toggleSidebarTooltip".localized()
            item.isBordered = true
            item.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: label)
            item.target = self
            item.action = #selector(toggleSidebar)
            return item
        } else if itemIdentifier.rawValue == "NewTab" {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            let label = "toolbar.newTab".localized()
            item.label = label
            item.paletteLabel = label
            item.toolTip = "toolbar.newTabTooltip".localized()
            item.isBordered = true
            item.image = NSImage(systemSymbolName: "plus", accessibilityDescription: label)
            item.target = NSApp.delegate
            item.action = #selector(AppDelegate.createNewTab)
            return item
        }
        return nil
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .toggleSidebar,
            .flexibleSpace,
            NSToolbarItem.Identifier("CenteredTitle"),
            .flexibleSpace,
            NSToolbarItem.Identifier("NewTab")
            
        ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            .toggleSidebar,
            .flexibleSpace,
            NSToolbarItem.Identifier("CenteredTitle"),
            NSToolbarItem.Identifier("NewTab")
        ]
    }

    private func setupTabObserver() {
        // Observe window becoming key
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.updateTabShortcuts()
        }

        // Observe when tabs are added/removed
        NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateTabShortcuts()
            }
        }
    }

    func setupContent(withSnapshot snapshot: CalculatorSessionSnapshot? = nil) {
        // Create controller and view
        controller = CalculatorController()

        // Restore from snapshot if provided
        if let snapshot = snapshot {
            restoreFromSnapshot(snapshot)
        }

        // Use native split view controller with sidebar
        // Use window's tabGroup identifier to group tabs in same window
        let windowGroupId = self.tabGroup?.identifier ?? (self.identifier?.rawValue ?? UUID().uuidString)
        let splitViewController = MainSplitViewController(
            calculatorController: controller!,
            windowId: windowGroupId,
            windowInstanceId: windowInstanceId
        )

        // Set contentViewController
        contentViewController = splitViewController

        // Sync titlebar appearance after window is shown
        DispatchQueue.main.async { [weak self] in
            self?.syncTitlebarAppearance()
        }
    }

    @objc func toggleSidebar() {
        if let splitVC = contentViewController as? MainSplitViewController {
            splitVC.toggleSidebar()
        }
    }

    private func restoreFromSnapshot(_ snapshot: CalculatorSessionSnapshot) {
        guard let controller = controller else { return }

        // Restore split tree
        controller.splitTree = snapshot.splitTree

        // Restore calculator states
        let leafIds = snapshot.splitTree.getAllLeafIds()
        for leafId in leafIds {
            let key = leafId.uuid.uuidString
            if let state = snapshot.calculatorStates[key] {
                let calculator = CalculatorInstance()
                calculator.inputText = state.inputText
                calculator.cursorPosition = state.cursorPosition
                calculator.results = state.results
                controller.calculators[leafId] = calculator
            } else {
                controller.calculators[leafId] = CalculatorInstance()
            }
        }

        // Set focus to first leaf
        controller.focusedLeafId = leafIds.first
    }

    func cleanupContent() {
        // Clean up resources
        controller?.cleanup()
        controller = nil
        contentViewController = nil
    }

    deinit {
    }

    private func syncTitlebarAppearance() {
        // With full-height sidebar and transparent titlebar, don't manually set backgrounds
        // Let the sidebar and content views show through naturally
    }

    /// Update background color (call this when theme changes)
    func updateBackgroundColor(_ color: NSColor) {
        backgroundColor = .clear
        syncTitlebarAppearance()
        contentView?.needsDisplay = true
    }

    // MARK: - Tab Bar Positioning

    // Let AppKit handle tab bar positioning naturally without any overrides

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
            backdrop.widthAnchor.constraint(equalToConstant: windowButtonsBackdropWidth),
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

    // Removed to disable the + button in tab bar since we have it in toolbar
    // override func newWindowForTab(_ sender: Any?) {
    //     let appDelegate = NSApplication.shared.delegate as? AppDelegate
    //     appDelegate?.createNewTab()
    // }

    @objc func selectTab(_ sender: NSMenuItem) {
        let tabIndex = sender.tag - 1 // Convert 1-based to 0-based
        guard let tabGroup = self.tabGroup else { return }

        let windows = tabGroup.windows
        guard tabIndex >= 0 && tabIndex < windows.count else { return }

        let targetWindow = windows[tabIndex]
        targetWindow.makeKeyAndOrderFront(nil)

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
        let hostingController = FocuslessHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 500, height: 400))
        window.title = "window.settings".localized()
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

        // Listen for locale changes to update window title
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LocaleChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.window?.title = "window.settings".localized()
        }
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
        let hostingController = FocuslessHostingController(rootView: CLIInstallerView())
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 500, height: 600))
        window.title = "window.cliInstaller".localized()
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

        // Listen for locale changes to update window title
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LocaleChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.window?.title = "window.cliInstaller".localized()
        }
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
