//
//  SettingsView.swift
//  Numby
//
//  Settings window for theme, font, and preferences
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var configManager = ConfigurationManager.shared
    @StateObject private var numbyWrapper = NumbyWrapper()

    @State private var selectedFont: String = "SFMono-Regular"
    @State private var availableFonts: [String] = []
    @State private var isUpdatingRates = false
    @State private var lastRatesUpdate: String = "Unknown"
    @State private var ratesAreStale = false

    var body: some View {
        Form {
            Section("Appearance") {
                // Theme picker
                Picker("Theme", selection: $themeManager.currentTheme) {
                    ForEach(Theme.allThemes, id: \.name) { theme in
                        Text(theme.name).tag(theme)
                    }
                }
                .pickerStyle(.menu)

                // Font size slider
                HStack {
                    Text("Font Size")
                    Slider(value: $configManager.config.fontSize, in: 10...24, step: 1)
                    Text("\(Int(configManager.config.fontSize)) pt")
                        .frame(width: 50)
                }

                // Font picker (monospaced only)
                Picker("Font", selection: $selectedFont) {
                    ForEach(availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedFont) { newValue in
                    configManager.config.fontName = newValue
                    configManager.save()
                }

                // Syntax highlighting toggle
                Toggle("Syntax Highlighting", isOn: $configManager.config.syntaxHighlighting)
            }

            Section("Behavior") {
                // Auto-evaluate toggle
                Toggle("Auto-evaluate on Input", isOn: $configManager.config.autoEvaluate)

                // Split ratio
                HStack {
                    Text("Default Split Ratio")
                    Slider(value: $configManager.config.defaultSplitRatio, in: 0.2...0.9, step: 0.05)
                    Text("\(Int(configManager.config.defaultSplitRatio * 100))%")
                        .frame(width: 50)
                }
            }

            Section("Currency Rates") {
                // Last update info
                HStack {
                    Text("Last Updated:")
                    Spacer()
                    Text(lastRatesUpdate)
                        .foregroundColor(ratesAreStale ? .red : .secondary)
                    if ratesAreStale {
                        Text("(Stale)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                // Update button
                Button(action: updateCurrencyRates) {
                    HStack {
                        if isUpdatingRates {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Text(isUpdatingRates ? "Updating..." : "Update Currency Rates")
                    }
                }
                .disabled(isUpdatingRates)

                Text("Fetches latest exchange rates for 300+ currencies from free API")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Command Line Tool") {
                Text("Install via Homebrew:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("brew install numby")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("brew install numby", forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .help("Copy to clipboard")
                }

                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://brew.sh")!)
                }) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("Install Homebrew")
                    }
                }
                .buttonStyle(.link)

                Text("Or download from GitHub releases")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://github.com/wiedymi/numby/releases")!)
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("GitHub Releases")
                    }
                }
                .buttonStyle(.link)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 500)
        .onAppear {
            loadAvailableFonts()
            if let fontName = configManager.config.fontName, availableFonts.contains(fontName) {
                selectedFont = fontName
            } else if let first = availableFonts.first {
                selectedFont = first
                configManager.config.fontName = first
            }
            loadCurrencyRatesInfo()
        }
        .onChange(of: configManager.config.fontSize) { _ in
            configManager.save()
        }
        .onChange(of: configManager.config.syntaxHighlighting) { _ in
            configManager.save()
        }
        .onChange(of: configManager.config.autoEvaluate) { _ in
            configManager.save()
        }
        .onChange(of: configManager.config.defaultSplitRatio) { _ in
            configManager.save()
        }
    }

    private func loadAvailableFonts() {
        // Get all available system fonts
        let fontManager = NSFontManager.shared
        availableFonts = fontManager.availableFonts.sorted()

        // Default to first available if selected font not found
        if !availableFonts.contains(selectedFont), let first = availableFonts.first {
            selectedFont = first
        }
    }

    private func loadCurrencyRatesInfo() {
        if let date = numbyWrapper.getCurrencyRatesUpdateDate() {
            lastRatesUpdate = date
        } else {
            lastRatesUpdate = "Never"
        }
        ratesAreStale = numbyWrapper.areCurrencyRatesStale()
    }

    private func updateCurrencyRates() {
        isUpdatingRates = true

        DispatchQueue.global(qos: .userInitiated).async {
            let success = numbyWrapper.updateCurrencyRates()

            DispatchQueue.main.async {
                isUpdatingRates = false
                if success {
                    loadCurrencyRatesInfo()
                    print("Currency rates updated successfully")
                } else {
                    print("Failed to update currency rates")
                }
            }
        }
    }
}
