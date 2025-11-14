import Foundation
import Combine
import AppKit

enum CLIInstallerError: Error {
    case binaryNotFoundInBundle
    case installationFailed(String)
    case uninstallationFailed(String)
    case permissionError
    case userCancelled

    var localizedDescription: String {
        switch self {
        case .binaryNotFoundInBundle:
            return "CLI binary not found in app bundle"
        case .installationFailed(let message):
            return "Installation failed: \(message)"
        case .uninstallationFailed(let message):
            return "Uninstallation failed: \(message)"
        case .permissionError:
            return "Permission denied"
        case .userCancelled:
            return "Installation cancelled by user"
        }
    }
}

class CLIInstaller: ObservableObject {
    @Published var isInstalled: Bool = false
    @Published var isInPath: Bool = false
    @Published var installedVersion: String?
    @Published var bundledVersion: String?

    private var installPath: URL?
    private let installPathKey = "CLIInstallerInstallPath"

    init() {
        // Try to load saved installation path
        if let savedPath = UserDefaults.standard.string(forKey: installPathKey) {
            self.installPath = URL(fileURLWithPath: savedPath)
        }

        updateStatus()
    }

    // MARK: - Status Checking

    func updateStatus() {
        let installed = checkIfInstalled()
        let inPath = checkIfInPath()
        let installedVer = getInstalledVersion()
        let bundledVer = getBundledVersion()

        DispatchQueue.main.async {
            self.isInstalled = installed
            self.isInPath = inPath
            self.installedVersion = installedVer
            self.bundledVersion = bundledVer
        }
    }

    private func checkIfInstalled() -> Bool {
        guard let installPath = installPath else { return false }
        return FileManager.default.fileExists(atPath: installPath.path)
    }

    private func checkIfInPath() -> Bool {
        guard let installPath = installPath else { return false }
        guard let pathEnv = ProcessInfo.processInfo.environment["PATH"] else {
            return false
        }

        let installDirectory = installPath.deletingLastPathComponent()
        let paths = pathEnv.split(separator: ":").map(String.init)
        return paths.contains(installDirectory.path)
    }

    private func getInstalledVersion() -> String? {
        guard checkIfInstalled(), let installPath = installPath else { return nil }

        let process = Process()
        let pipe = Pipe()

        process.executableURL = installPath
        process.arguments = ["--version"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return parseVersion(from: output)
            }
        } catch {
            return nil
        }

        return nil
    }

    private func getBundledVersion() -> String? {
        guard let bundlePath = getBundledBinaryPath() else { return nil }

        let process = Process()
        let pipe = Pipe()

        process.executableURL = bundlePath
        process.arguments = ["--version"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return parseVersion(from: output)
            }
        } catch {
            return nil
        }

        return nil
    }

    private func parseVersion(from output: String) -> String? {
        // Extract version from output like "numby 0.1.0" or similar
        let components = output.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        return components.last.map(String.init)
    }

    func needsUpdate() -> Bool {
        guard let installed = installedVersion,
              let bundled = bundledVersion else {
            return false
        }
        return installed != bundled
    }

    // MARK: - Installation

    func install() throws {
        guard let sourcePath = getBundledBinaryPath() else {
            throw CLIInstallerError.binaryNotFoundInBundle
        }

        // MUST be called on main thread - ask user to select installation directory
        // This grants sandbox permission to write to the selected location
        var installDir: URL?
        var selectionError: Error?

        DispatchQueue.main.sync {
            do {
                installDir = try selectInstallationDirectory()
            } catch {
                selectionError = error
            }
        }

        if let error = selectionError {
            throw error
        }

        guard let installDir = installDir else {
            throw CLIInstallerError.userCancelled
        }

        let finalInstallPath = installDir.appendingPathComponent("numby")

        // Remove existing installation if present
        if FileManager.default.fileExists(atPath: finalInstallPath.path) {
            do {
                try FileManager.default.removeItem(at: finalInstallPath)
            } catch {
                throw CLIInstallerError.installationFailed("Failed to remove existing binary: \(error.localizedDescription)")
            }
        }

        // Copy binary
        do {
            try FileManager.default.copyItem(at: sourcePath, to: finalInstallPath)
        } catch {
            throw CLIInstallerError.installationFailed("Failed to copy binary: \(error.localizedDescription)")
        }

        // Set executable permissions
        do {
            let attributes: [FileAttributeKey: Any] = [
                .posixPermissions: 0o755
            ]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: finalInstallPath.path)
        } catch {
            // Clean up on permission failure
            try? FileManager.default.removeItem(at: finalInstallPath)
            throw CLIInstallerError.permissionError
        }

        // Remove quarantine attribute to prevent malware warnings
        removeQuarantineAttribute(from: finalInstallPath)

        // Save the installation path for future reference
        self.installPath = finalInstallPath
        UserDefaults.standard.set(finalInstallPath.path, forKey: installPathKey)

        updateStatus()
    }

    private func removeQuarantineAttribute(from url: URL) {
        // Use FileManager to remove extended attributes (sandbox-compatible)
        do {
            // Try to remove the quarantine attribute using low-level API
            let path = url.path as NSString
            let fileURL = url as NSURL

            // Remove quarantine using setxattr
            let attrName = "com.apple.quarantine"
            let result = removexattr(path.fileSystemRepresentation, attrName, 0)

            if result == 0 {
                print("CLIInstaller: Removed quarantine attribute from \(url.path)")
            } else {
                print("CLIInstaller: Could not remove quarantine attribute (errno: \(errno))")
            }
        }
    }

    private func selectInstallationDirectory() throws -> URL {
        let panel = NSOpenPanel()
        panel.message = """
        Select a directory to install the numby CLI tool

        Recommended: ~/.local/bin (create if it doesn't exist)
        Alternative: /usr/local/bin (may require admin password)

        The selected directory should be in your PATH environment variable.
        """
        panel.prompt = "Install Here"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        // Suggest ~/.local/bin as the default location
        if let homeDir = ProcessInfo.processInfo.environment["HOME"] {
            let suggestedPath = URL(fileURLWithPath: homeDir).appendingPathComponent(".local/bin")
            panel.directoryURL = suggestedPath.deletingLastPathComponent()
        }

        let response = panel.runModal()

        guard response == .OK, let url = panel.url else {
            throw CLIInstallerError.userCancelled
        }

        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        return url
    }

    // MARK: - Uninstallation

    func uninstall() throws {
        guard let installPath = installPath else {
            // Already uninstalled
            updateStatus()
            return
        }

        guard FileManager.default.fileExists(atPath: installPath.path) else {
            // Already uninstalled
            self.installPath = nil
            UserDefaults.standard.removeObject(forKey: installPathKey)
            updateStatus()
            return
        }

        // Try to delete directly first
        do {
            try FileManager.default.removeItem(at: installPath)
        } catch {
            // If direct deletion fails (likely due to sandbox), ask user to grant permission again
            let installDirectory = installPath.deletingLastPathComponent()

            // Ask user to re-grant access to the directory
            var grantedAccess = false
            var permissionError: Error?

            DispatchQueue.main.sync {
                let panel = NSOpenPanel()
                panel.message = """
                To uninstall the CLI tool, please select the directory containing it:

                \(installDirectory.path)
                """
                panel.prompt = "Grant Access"
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.canCreateDirectories = false
                panel.allowsMultipleSelection = false
                panel.directoryURL = installDirectory

                let response = panel.runModal()

                if response == .OK, let selectedURL = panel.url {
                    // Verify user selected the correct directory
                    if selectedURL.path == installDirectory.path {
                        grantedAccess = true
                    } else {
                        permissionError = CLIInstallerError.uninstallationFailed("Wrong directory selected. Please select: \(installDirectory.path)")
                    }
                } else {
                    permissionError = CLIInstallerError.userCancelled
                }
            }

            if let error = permissionError {
                throw error
            }

            if !grantedAccess {
                throw CLIInstallerError.uninstallationFailed("Permission not granted")
            }

            // Try again with granted permission
            do {
                try FileManager.default.removeItem(at: installPath)
            } catch {
                throw CLIInstallerError.uninstallationFailed("Failed to remove binary: \(error.localizedDescription)")
            }
        }

        // Clear saved installation path
        self.installPath = nil
        UserDefaults.standard.removeObject(forKey: installPathKey)

        updateStatus()
    }

    // MARK: - Helper Methods

    private func getBundledBinaryPath() -> URL? {
        guard let resourcePath = Bundle.main.resourcePath else {
            print("CLIInstaller: Bundle.main.resourcePath is nil")
            return nil
        }

        let binaryPath = URL(fileURLWithPath: resourcePath).appendingPathComponent("numby")

        print("CLIInstaller: Looking for binary at: \(binaryPath.path)")
        print("CLIInstaller: Binary exists: \(FileManager.default.fileExists(atPath: binaryPath.path))")

        if FileManager.default.fileExists(atPath: binaryPath.path) {
            return binaryPath
        }

        return nil
    }

    func getInstallLocation() -> String {
        installPath?.path ?? "Not installed"
    }

    func getPathInstruction() -> String {
        """
        export PATH="$HOME/.local/bin:$PATH"
        """
    }

    func getShellConfigFile() -> String {
        // Detect shell and return appropriate config file
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

        if shell.contains("zsh") {
            return "~/.zshrc"
        } else if shell.contains("bash") {
            return "~/.bash_profile"
        } else if shell.contains("fish") {
            return "~/.config/fish/config.fish"
        }

        return "~/.zshrc" // default
    }

    func getFullInstallCommand() -> String {
        let configFile = getShellConfigFile()

        if configFile.contains("fish") {
            return "fish_add_path ~/.local/bin"
        }

        return """
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> \(configFile)
        source \(configFile)
        """
    }
}
