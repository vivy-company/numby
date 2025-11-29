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
    private var localizedInstallViaCargo: String { _ = localeVersion; return NSLocalizedString("settings.cli.installViaCargo", comment: "") }
    private var localizedRunCommand: String { _ = localeVersion; return NSLocalizedString("cliInstaller.runCommand", comment: "") }
    private var localizedNoRust: String { _ = localeVersion; return NSLocalizedString("cliInstaller.noRust", comment: "") }
    private var localizedInstallRust: String { _ = localeVersion; return NSLocalizedString("settings.cli.installRust", comment: "") }
    private var localizedOrInstaller: String { _ = localeVersion; return NSLocalizedString("settings.cli.orInstaller", comment: "") }
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
                Text(localizedInstallViaCargo)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedRunCommand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("cargo install numby")
                            .font(.system(.title3, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)

                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString("cargo install numby", forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .help(localizedCopyTooltip)
                    }

                    Text(localizedNoRust)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "https://rustup.rs")!)
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text(localizedInstallRust)
                        }
                    }
                    .buttonStyle(.link)
                }
                .padding(16)
                .background(Color.accentColor.opacity(0.05))
                .cornerRadius(12)

                Text(localizedOrInstaller)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("curl -fsSL https://numby.vivy.app/install.sh | bash")
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("curl -fsSL https://numby.vivy.app/install.sh | bash", forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .help(localizedCopyTooltip)
                }

                Divider()
                    .padding(.vertical, 8)

                Text(localizedAlternative)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedDownloadRelease)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "https://github.com/vivy-company/numby/releases")!)
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
