#if os(macOS)
//
//  HistorySidebarViewController.swift
//  Numby
//
//  Native AppKit sidebar view controller for history
//

import Cocoa
import SwiftUI

class HistorySidebarViewController: NSViewController {
    private var historyManager: HistoryManager!
    var onSessionSelected: ((CalculationSession) -> Void)?

    override func loadView() {
        let historyManager = HistoryManager()
        self.historyManager = historyManager

        let sidebarView = HistorySidebarView(historyManager: historyManager) { [weak self] session in
            self?.onSessionSelected?(session)
        }

        let hostingView = FocuslessHostingView(rootView: sidebarView)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.focusRingType = .none

        self.view = hostingView
    }
}
#endif
