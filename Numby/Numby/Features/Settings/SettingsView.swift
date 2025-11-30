//
//  SettingsView.swift
//  Numby
//
//  Settings window for theme, font, and preferences
//

#if os(macOS)

import SwiftUI

struct SettingsView: View {
    // Theme accessed via Theme.current
    @ObservedObject var configManager = Configuration.shared
    @StateObject private var numbyWrapper = NumbyWrapper()

    @State private var selectedFont: String = "SFMono-Regular"
    @State private var availableFonts: [String] = []
    @State private var isUpdatingRates = false
    @State private var lastRatesUpdate: String = "Unknown"
    @State private var ratesAreStale = false
    @State private var availableLocales: [(code: String, name: String)] = []
    @State private var selectedLocale: String = "en-US"
    @State private var localeVersion: Int = 0
    @State private var selectedTheme: Theme = Theme.current

    // Computed properties for localized strings that update when locale changes
    private var localizedLanguageSection: String {
        _ = localeVersion
        return NSLocalizedString("settings.language.section", comment: "")
    }
    private var localizedLanguagePicker: String { _ = localeVersion; return NSLocalizedString("settings.language.picker", comment: "") }
    private var localizedAppearanceSection: String { _ = localeVersion; return NSLocalizedString("settings.appearance.section", comment: "") }
    private var localizedTheme: String { _ = localeVersion; return NSLocalizedString("settings.appearance.theme", comment: "") }
    private var localizedFontSize: String { _ = localeVersion; return NSLocalizedString("settings.appearance.fontSize", comment: "") }
    private var localizedFont: String { _ = localeVersion; return NSLocalizedString("settings.appearance.font", comment: "") }
    private var localizedSyntaxHighlighting: String { _ = localeVersion; return NSLocalizedString("settings.appearance.syntaxHighlighting", comment: "") }
    private var localizedBehaviorSection: String { _ = localeVersion; return NSLocalizedString("settings.behavior.section", comment: "") }
    private var localizedAutoEvaluate: String { _ = localeVersion; return NSLocalizedString("settings.behavior.autoEvaluate", comment: "") }
    private var localizedSplitRatio: String { _ = localeVersion; return NSLocalizedString("settings.behavior.splitRatio", comment: "") }
    private var localizedCurrencySection: String { _ = localeVersion; return NSLocalizedString("settings.currency.section", comment: "") }
    private var localizedLastUpdated: String { _ = localeVersion; return NSLocalizedString("settings.currency.lastUpdated", comment: "") }
    private var localizedStale: String { _ = localeVersion; return NSLocalizedString("settings.currency.stale", comment: "") }
    private var localizedUpdate: String { _ = localeVersion; return NSLocalizedString("settings.currency.update", comment: "") }
    private var localizedUpdating: String { _ = localeVersion; return NSLocalizedString("settings.currency.updating", comment: "") }
    private var localizedCurrencyDesc: String { _ = localeVersion; return NSLocalizedString("settings.currency.description", comment: "") }
    private var localizedCLISection: String { _ = localeVersion; return NSLocalizedString("settings.cli.section", comment: "") }
    private var localizedInstallViaCargo: String { _ = localeVersion; return NSLocalizedString("settings.cli.installViaCargo", comment: "") }
    private var localizedCopyTooltip: String { _ = localeVersion; return NSLocalizedString("settings.cli.copyTooltip", comment: "") }
    private var localizedInstallRust: String { _ = localeVersion; return NSLocalizedString("settings.cli.installRust", comment: "") }
    private var localizedOrInstaller: String { _ = localeVersion; return NSLocalizedString("settings.cli.orInstaller", comment: "") }
    private var localizedOrDownload: String { _ = localeVersion; return NSLocalizedString("settings.cli.orDownload", comment: "") }
    private var localizedGithubReleases: String { _ = localeVersion; return NSLocalizedString("settings.cli.githubReleases", comment: "") }

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
                Picker(localizedTheme, selection: $selectedTheme) {
                    ForEach(Theme.allThemes, id: \.name) { theme in
                        Text(theme.name).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedTheme) { newTheme in
                    Theme.current = newTheme
                }

                // Font size slider
                HStack {
                    Text(localizedFontSize)
                    Slider(value: $configManager.config.fontSize, in: 10...24, step: 1)
                        .onChange(of: configManager.config.fontSize) { _ in
                            configManager.save()
                        }
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
                Text(localizedInstallViaCargo)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("cargo install numby")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("cargo install numby", forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .help(localizedCopyTooltip)
                }

                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://rustup.rs")!)
                }) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text(localizedInstallRust)
                    }
                }
                .buttonStyle(.link)

                Text(localizedOrInstaller)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                HStack {
                    Text("curl -fsSL https://numby.vivy.app/install.sh | bash")
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("curl -fsSL https://numby.vivy.app/install.sh | bash", forType: .string)
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .help(localizedCopyTooltip)
                }

                Text(localizedOrDownload)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://github.com/vivy-company/numby/releases")!)
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
            lastRatesUpdate = NSLocalizedString("settings.currency.never", comment: "")
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
                }
            }
        }
    }
}

#endif
