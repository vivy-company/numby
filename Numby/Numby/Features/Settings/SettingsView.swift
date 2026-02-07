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
    @State private var showUpdateSuccess = false
    @State private var lastRatesUpdate: String = "Unknown"
    @State private var apiRatesDate: String = "Unknown"
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
    private var localizedActiveLineHighlight: String { _ = localeVersion; return NSLocalizedString("settings.appearance.activeLineHighlight", comment: "") }
    private var localizedActiveLineIntensity: String { _ = localeVersion; return NSLocalizedString("settings.appearance.activeLineIntensity", comment: "") }
    private var localizedActiveLineIntensityHint: String { _ = localeVersion; return NSLocalizedString("settings.appearance.activeLineIntensityHint", comment: "") }
    private var localizedNumberSection: String { _ = localeVersion; return NSLocalizedString("settings.number.section", comment: "") }
    private var localizedNumberFormat: String { _ = localeVersion; return NSLocalizedString("settings.number.format", comment: "") }
    private var localizedNumberMaxDecimals: String { _ = localeVersion; return NSLocalizedString("settings.number.maxDecimals", comment: "") }
    private var localizedNumberMaxDecimalsHint: String { _ = localeVersion; return NSLocalizedString("settings.number.maxDecimalsHint", comment: "") }
    private var localizedNumberPretty: String { _ = localeVersion; return NSLocalizedString("settings.number.format.pretty", comment: "") }
    private var localizedNumberPrecision: String { _ = localeVersion; return NSLocalizedString("settings.number.format.precision", comment: "") }
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

                Toggle(localizedActiveLineHighlight, isOn: $configManager.config.activeLineHighlight)
                    .onChange(of: configManager.config.activeLineHighlight) { _ in
                        configManager.save()
                    }

                if configManager.config.activeLineHighlight {
                    HStack {
                        Text(localizedActiveLineIntensity)
                        Slider(value: $configManager.config.activeLineHighlightIntensity, in: 0.02...0.2, step: 0.01)
                            .onChange(of: configManager.config.activeLineHighlightIntensity) { _ in
                                configManager.save()
                            }
                        Text("\(Int(configManager.config.activeLineHighlightIntensity * 100))%")
                            .frame(width: 50)
                    }

                    Text(localizedActiveLineIntensityHint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

            }

            Section(localizedNumberSection) {
                Picker(localizedNumberFormat, selection: $configManager.config.numberFormat) {
                    Text(localizedNumberPretty).tag("pretty")
                    Text(localizedNumberPrecision).tag("precision")
                }
                .pickerStyle(.menu)
                .onChange(of: configManager.config.numberFormat) { newValue in
                    configManager.config.numberFormat = newValue
                    configManager.save()
                    _ = numbyWrapper.setNumberFormat(
                        newValue,
                        maxDecimals: configManager.config.numberMaxDecimals
                    )
                }

                if configManager.config.numberFormat == "precision" {
                    Stepper(
                        "\(localizedNumberMaxDecimals): \(configManager.config.numberMaxDecimals)",
                        value: $configManager.config.numberMaxDecimals,
                        in: 0...15,
                        step: 1
                    )
                    .onChange(of: configManager.config.numberMaxDecimals) { newValue in
                        configManager.config.numberMaxDecimals = newValue
                        configManager.save()
                        _ = numbyWrapper.setNumberFormat(
                            configManager.config.numberFormat,
                            maxDecimals: newValue
                        )
                    }

                    Text(localizedNumberMaxDecimalsHint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }


            Section(localizedCurrencySection) {
                // API Rates Date
                HStack {
                    Text("API Rates Date:")
                    Spacer()
                    Text(apiRatesDate)
                        .foregroundColor(.secondary)
                }

                // Last Updated (when we fetched)
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
                        } else if showUpdateSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        Text(isUpdatingRates ? localizedUpdating : (showUpdateSuccess ? "Updated!" : localizedUpdate))
                            .foregroundColor(showUpdateSuccess ? .green : nil)
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
        // Get last time we fetched from API
        if let date = numbyWrapper.getCurrencyRatesUpdateDate() {
            lastRatesUpdate = date
        } else {
            lastRatesUpdate = NSLocalizedString("settings.currency.never", comment: "")
        }

        // Get the API rates date (when rates were published)
        if let apiDate = numbyWrapper.getApiRatesDate() {
            apiRatesDate = apiDate
        } else {
            apiRatesDate = NSLocalizedString("settings.currency.unknown", comment: "")
        }

        // Use Rust-based staleness check (now handles 7-day tolerance)
        ratesAreStale = numbyWrapper.areCurrencyRatesStale()
    }

    private func updateCurrencyRates() {
        isUpdatingRates = true

        // Use native URLSession for all platforms (works on visionOS)
        numbyWrapper.updateCurrencyRatesNative { success in
            DispatchQueue.main.async {
                isUpdatingRates = false
                if success {
                    // Show success indicator briefly
                    showUpdateSuccess = true
                    // Hide success indicator after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showUpdateSuccess = false
                    }

                    // Add a small delay to ensure file system sync
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        loadCurrencyRatesInfo()
                        // Force UI refresh by updating localeVersion (which triggers view update)
                        localeVersion += 1
                    }
                }
            }
        }
    }
}

#endif
