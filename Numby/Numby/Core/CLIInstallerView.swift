//
//  CLIInstallerView.swift
//  Numby
//
//  Dedicated view for CLI tool installation
//

import SwiftUI

struct CLIInstallerView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)

                Text("Command Line Tool")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Use numby from your terminal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            Divider()

            // Installation instructions
            VStack(alignment: .leading, spacing: 16) {
                Text("Install via Homebrew")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Run this command in your terminal:")
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
                        .help("Copy to clipboard")
                    }

                    Text("If you don't have Homebrew installed:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "https://brew.sh")!)
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("Install Homebrew")
                        }
                    }
                    .buttonStyle(.link)
                }
                .padding(16)
                .background(Color.accentColor.opacity(0.05))
                .cornerRadius(12)

                Divider()
                    .padding(.vertical, 8)

                Text("Alternative: Manual Installation")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Download the latest release:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: {
                        NSWorkspace.shared.open(URL(string: "https://github.com/wiedymi/numby/releases")!)
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("GitHub Releases")
                        }
                    }
                    .buttonStyle(.link)

                    Text("Then move to your PATH:")
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
            Button("Open Terminal") {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 600)
    }
}
