//
//  CLIInstallerView.swift
//  Numby
//
//  Dedicated view for CLI tool installation
//

#if os(macOS)
import SwiftUI

struct CLIInstallerView: View {
    @ObservedObject var configManager = Configuration.shared
    @State private var localeVersion: Int = 0

    private var localizedTitle: String { _ = localeVersion; return NSLocalizedString("cliInstaller.title", comment: "") }
    private var localizedSubtitle: String { _ = localeVersion; return NSLocalizedString("cliInstaller.subtitle", comment: "") }
    private var localizedInstallViaHomebrew: String { _ = localeVersion; return NSLocalizedString("cliInstaller.installViaHomebrew", comment: "") }
    private var localizedRunCommand: String { _ = localeVersion; return NSLocalizedString("cliInstaller.runCommand", comment: "") }
    private var localizedNoHomebrew: String { _ = localeVersion; return NSLocalizedString("cliInstaller.noHomebrew", comment: "") }
    private var localizedInstallHomebrew: String { _ = localeVersion; return NSLocalizedString("settings.cli.installHomebrew", comment: "") }
    private var localizedAlternative: String { _ = localeVersion; return NSLocalizedString("cliInstaller.alternative", comment: "") }
    private var localizedDownloadRelease: String { _ = localeVersion; return NSLocalizedString("cliInstaller.downloadRelease", comment: "") }
    private var localizedGithubReleases: String { _ = localeVersion; return NSLocalizedString("settings.cli.githubReleases", comment: "") }
    private var localizedMoveToPath: String { _ = localeVersion; return NSLocalizedString("cliInstaller.moveToPath", comment: "") }
    private var localizedOpenTerminal: String { _ = localeVersion; return NSLocalizedString("cliInstaller.openTerminal", comment: "") }
    private var localizedCopyTooltip: String { _ = localeVersion; return NSLocalizedString("settings.cli.copyTooltip", comment: "") }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                Text(localizedTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(localizedSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            Divider()

            // Installation instructions
            VStack(alignment: .leading, spacing: 16) {
                Text(localizedInstallViaHomebrew)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedRunCommand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("brew install numby")
                            .font(.system(.title3, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)

                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("brew install numby", forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .help(localizedCopyTooltip)
                    }

                    Text(localizedNoHomebrew)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "https://brew.sh")!)
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text(localizedInstallHomebrew)
                        }
                    }
                    .buttonStyle(.link)
                }
                .padding(16)
                .background(Color.accentColor.opacity(0.05))
                .cornerRadius(12)

                Divider()
                    .padding(.vertical, 8)

                Text(localizedAlternative)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedDownloadRelease)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "https://github.com/wiedymi/numby/releases")!)
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text(localizedGithubReleases)
                        }
                    }
                    .buttonStyle(.link)

                    Text(localizedMoveToPath)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    Text("mv numby ~/.local/bin/\nchmod +x ~/.local/bin/numby")
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
                .padding(16)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()

            // Quick action button
            Button(localizedOpenTerminal) {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 600)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LocaleChanged"))) { _ in
            localeVersion += 1
        }
    }
}
#endif
