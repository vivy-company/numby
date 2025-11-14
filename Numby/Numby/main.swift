//
//  main.swift
//  Numby
//
//  Main entry point for AppDelegate-based app
//

@preconcurrency import AppKit
import Foundation

// Set app locale from configuration before app launches
if let savedLocale = ConfigurationManager.shared.config.locale {
    // Map Rust locale codes to Swift/Apple locale codes
    let swiftLocale: String
    switch savedLocale {
    case "zh-CN":
        swiftLocale = "zh-Hans"
    case "zh-TW":
        swiftLocale = "zh-Hant"
    case "en-US":
        swiftLocale = "en"
    default:
        swiftLocale = savedLocale
    }
    UserDefaults.standard.set([swiftLocale], forKey: "AppleLanguages")
    UserDefaults.standard.synchronize()
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
