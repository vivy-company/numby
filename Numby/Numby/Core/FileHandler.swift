//
//  FileHandler.swift
//  Numby
//
//  Handles .numby file export and import
//

#if os(macOS)
import Cocoa
import UniformTypeIdentifiers

class FileHandler {
    static let shared = FileHandler()

    private init() {}

    /// Export calculator content to a .numby file
    /// - Parameters:
    ///   - content: The calculator input text to save
    ///   - window: The window to show the save panel on
    ///   - defaultName: Optional default filename (without extension)
    /// - Returns: URL of the saved file, or nil if cancelled
    @discardableResult
    func exportCalculator(content: String, from window: NSWindow?, defaultName: String? = nil) -> URL? {
        // Ensure main thread
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync {
                exportCalculator(content: content, from: window, defaultName: defaultName)
            }
        }

        let savePanel = NSSavePanel()
        savePanel.title = NSLocalizedString("file.export.title", comment: "")
        savePanel.message = NSLocalizedString("file.export.message", comment: "")
        savePanel.nameFieldLabel = NSLocalizedString("file.export.saveAs", comment: "")
        savePanel.nameFieldStringValue = (defaultName ?? NSLocalizedString("file.untitled", comment: "")) + ".numby"

        // Use registered UTType
        if let numbyType = UTType("vivy.app.numby") {
            savePanel.allowedContentTypes = [numbyType]
        } else if let numbyType = UTType(filenameExtension: "numby") {
            savePanel.allowedContentTypes = [numbyType]
        } else {
            savePanel.allowedContentTypes = [.plainText]
        }

        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.showsHiddenFiles = false
        savePanel.treatsFilePackagesAsDirectories = false

        // Run modal on main run loop to avoid XPC issues
        let response = savePanel.runModal()

        guard response == .OK, let fileURL = savePanel.url else {
            return nil
        }

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            showError(title: NSLocalizedString("file.export.failed", comment: ""), message: String(format: NSLocalizedString("file.export.error", comment: ""), error.localizedDescription), window: window)
            return nil
        }
    }

    /// Import calculator content from a .numby file
    /// - Parameter window: The window to show the open panel on
    /// - Returns: The file content, or nil if cancelled or error
    func importCalculator(from window: NSWindow?) -> String? {
        // Ensure main thread
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync {
                importCalculator(from: window)
            }
        }

        let openPanel = NSOpenPanel()
        openPanel.title = NSLocalizedString("file.import.title", comment: "")
        openPanel.message = NSLocalizedString("file.import.message", comment: "")

        // Use registered UTType
        if let numbyType = UTType("vivy.app.numby") {
            openPanel.allowedContentTypes = [numbyType]
        } else if let numbyType = UTType(filenameExtension: "numby") {
            openPanel.allowedContentTypes = [numbyType]
        } else {
            openPanel.allowedContentTypes = [.plainText]
        }

        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.showsHiddenFiles = false
        openPanel.treatsFilePackagesAsDirectories = false

        // Run modal on main run loop to avoid XPC issues
        let response = openPanel.runModal()

        guard response == .OK, let fileURL = openPanel.url else {
            return nil
        }

        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return content
        } catch {
            showError(title: NSLocalizedString("file.import.failed", comment: ""), message: String(format: NSLocalizedString("file.import.error", comment: ""), error.localizedDescription), window: window)
            return nil
        }
    }

    /// Show error alert
    private func showError(title: String, message: String, window: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: NSLocalizedString("alert.ok", comment: ""))

        if let window = window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }
}
#endif
