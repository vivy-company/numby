//
//  main.swift
//  Numby
//
//  Main entry point for AppDelegate-based app
//

import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
