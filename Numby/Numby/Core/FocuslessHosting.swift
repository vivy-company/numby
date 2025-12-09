//
//  FocuslessHosting.swift
//  Numby
//
//  Hosts SwiftUI views without allowing AppKit to draw focus rings
//

#if os(macOS)
import SwiftUI
import AppKit

/// Hosting view that never draws an AppKit focus ring and skips becoming first responder
final class FocuslessHostingView<Content: View>: NSHostingView<Content> {
    override var acceptsFirstResponder: Bool {
        return false
    }

    override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }

    override func drawFocusRingMask() {
    }

    override var focusRingMaskBounds: NSRect {
        .zero
    }
}

/// Hosting controller that wraps content inside a `FocuslessHostingView`
final class FocuslessHostingController<Content: View>: NSHostingController<Content> {
    override func loadView() {
        view = FocuslessHostingView(rootView: rootView)
    }
}

/// Wrapper class used to replace `_NSSplitViewItemViewWrapper` instances so they can never draw focus rings.
final class FocuslessSplitItemWrapper: NSView {
    override var acceptsFirstResponder: Bool {
        return false
    }

    override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }

    override func drawFocusRingMask() {
    }

    override var focusRingMaskBounds: NSRect {
        .zero
    }
}
#endif
