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
    @State private var availableLocales: [(code: String, name: String)] = []
    @State private var selectedLocale: String = "en-US"
    @State private var localeVersion: Int = 0

    // Computed properties for localized strings that update when locale changes
    private var localizedLanguageSection: String {
        _ = localeVersion
        return configManager.localizedString("settings.language.section")
    }
    private var localizedLanguagePicker: String { _ = localeVersion; return configManager.localizedString("settings.language.picker") }
    private var localizedAppearanceSection: String { _ = localeVersion; return configManager.localizedString("settings.appearance.section") }
    private var localizedTheme: String { _ = localeVersion; return configManager.localizedString("settings.appearance.theme") }
    private var localizedFontSize: String { _ = localeVersion; return configManager.localizedString("settings.appearance.fontSize") }
    private var localizedFont: String { _ = localeVersion; return configManager.localizedString("settings.appearance.font") }
    private var localizedSyntaxHighlighting: String { _ = localeVersion; return configManager.localizedString("settings.appearance.syntaxHighlighting") }
    private var localizedBehaviorSection: String { _ = localeVersion; return configManager.localizedString("settings.behavior.section") }
    private var localizedAutoEvaluate: String { _ = localeVersion; return configManager.localizedString("settings.behavior.autoEvaluate") }
    private var localizedSplitRatio: String { _ = localeVersion; return configManager.localizedString("settings.behavior.splitRatio") }
    private var localizedCurrencySection: String { _ = localeVersion; return configManager.localizedString("settings.currency.section") }
    private var localizedLastUpdated: String { _ = localeVersion; return configManager.localizedString("settings.currency.lastUpdated") }
    private var localizedStale: String { _ = localeVersion; return configManager.localizedString("settings.currency.stale") }
    private var localizedUpdate: String { _ = localeVersion; return configManager.localizedString("settings.currency.update") }
    private var localizedUpdating: String { _ = localeVersion; return configManager.localizedString("settings.currency.updating") }
    private var localizedCurrencyDesc: String { _ = localeVersion; return configManager.localizedString("settings.currency.description") }
    private var localizedCLISection: String { _ = localeVersion; return configManager.localizedString("settings.cli.section") }
    private var localizedInstallViaHomebrew: String { _ = localeVersion; return configManager.localizedString("settings.cli.installViaHomebrew") }
    private var localizedCopyTooltip: String { _ = localeVersion; return configManager.localizedString("settings.cli.copyTooltip") }
    private var localizedInstallHomebrew: String { _ = localeVersion; return configManager.localizedString("settings.cli.installHomebrew") }
    private var localizedOrDownload: String { _ = localeVersion; return configManager.localizedString("settings.cli.orDownload") }
    private var localizedGithubReleases: String { _ = localeVersion; return configManager.localizedString("settings.cli.githubReleases") }

    var body: some View {
        Form {
            Section(localizedLanguageSection) {
                // Language picker
                Picker(localizedLanguagePicker, selection: $selectedLocale) {
                    ForEach(availableLocales, id: \.code) { locale in
                        Text(locale.name).tag(locale.code)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedLocale) { newLocale in
                    if numbyWrapper.setLocale(newLocale) {
                        configManager.config.locale = newLocale
                        configManager.updateLocale(newLocale)
                        configManager.save()
                        localeVersion += 1
                        NotificationCenter.default.post(name: NSNotification.Name("LocaleChanged"), object: nil)
                    }
                }
            }

            Section(localizedAppearanceSection) {
                // Theme picker
                Picker(localizedTheme, selection: $themeManager.currentTheme) {
                    ForEach(Theme.allThemes, id: \.name) { theme in
                        Text(theme.name).tag(theme)
                    }
                }
                .pickerStyle(.menu)

                // Font size slider
                HStack {
                    Text(localizedFontSize)
                    Slider(value: $configManager.config.fontSize, in: 10...24, step: 1)
                    Text("\(Int(configManager.config.fontSize)) pt")
                        .frame(width: 50)
                }

                // Font picker (monospaced only)
                Picker(localizedFont, selection: $selectedFont) {
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
                Toggle(localizedSyntaxHighlighting, isOn: $configManager.config.syntaxHighlighting)
            }

            Section(localizedBehaviorSection) {
                // Auto-evaluate toggle
                Toggle(localizedAutoEvaluate, isOn: $configManager.config.autoEvaluate)

                // Split ratio
                HStack {
                    Text(localizedSplitRatio)
                    Slider(value: $configManager.config.defaultSplitRatio, in: 0.2...0.9, step: 0.05)
                    Text("\(Int(configManager.config.defaultSplitRatio * 100))%")
                        .frame(width: 50)
                }
            }

            Section(localizedCurrencySection) {
                // Last update info
                HStack {
                    Text(localizedLastUpdated)
                    Spacer()
                    Text(lastRatesUpdate)
                        .foregroundColor(ratesAreStale ? .red : .secondary)
                    if ratesAreStale {
                        Text(localizedStale)
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
                        Text(isUpdatingRates ? localizedUpdating : localizedUpdate)
                    }
                }
                .disabled(isUpdatingRates)

                Text(localizedCurrencyDesc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(localizedCLISection) {
                Text(localizedInstallViaHomebrew)
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
                    .help(localizedCopyTooltip)
                }

                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://brew.sh")!)
                }) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text(localizedInstallHomebrew)
                    }
                }
                .buttonStyle(.link)

                Text(localizedOrDownload)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://github.com/wiedymi/numby/releases")!)
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text(localizedGithubReleases)
                    }
                }
                .buttonStyle(.link)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 550)
        .onAppear {
            loadAvailableFonts()
            if let fontName = configManager.config.fontName, availableFonts.contains(fontName) {
                selectedFont = fontName
            } else if let first = availableFonts.first {
                selectedFont = first
                configManager.config.fontName = first
            }
            loadCurrencyRatesInfo()
            loadAvailableLocales()
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

    private func loadAvailableLocales() {
        availableLocales = numbyWrapper.getAvailableLocales()
        selectedLocale = configManager.config.locale ?? numbyWrapper.getCurrentLocale()
    }

    private func loadCurrencyRatesInfo() {
        if let date = numbyWrapper.getCurrencyRatesUpdateDate() {
            lastRatesUpdate = date
        } else {
            lastRatesUpdate = configManager.localizedString("settings.currency.never")
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
                    print(configManager.localizedString("settings.currency.success"))
                } else {
                    print(configManager.localizedString("settings.currency.failed"))
                }
            }
        }
    }
}
