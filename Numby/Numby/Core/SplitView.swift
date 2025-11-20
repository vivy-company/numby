//
//  SplitView.swift
//  Numby
//
//  Native macOS split view component using NSSplitView
//

#if os(macOS)
import SwiftUI
import AppKit

/// SwiftUI wrapper around NSSplitView for native macOS split functionality
struct SplitView<Left: View, Right: View>: NSViewRepresentable {
    let direction: SplitDirection
    @Binding var ratio: Float
    let onRatioChange: (Float) -> Void
    let left: () -> Left
    let right: () -> Right

    func makeNSView(context: Context) -> NSSplitView {
        let splitView = FocuslessSplitView()
        splitView.isVertical = (direction == .horizontal)
        splitView.dividerStyle = .thin
        splitView.delegate = context.coordinator

        // Create left pane
        let leftHosting = FocuslessHostingController(rootView: left())
        leftHosting.view.translatesAutoresizingMaskIntoConstraints = false
        splitView.addArrangedSubview(leftHosting.view)

        // Create right pane
        let rightHosting = FocuslessHostingController(rootView: right())
        rightHosting.view.translatesAutoresizingMaskIntoConstraints = false
        splitView.addArrangedSubview(rightHosting.view)

        // Store hosting controllers to prevent deallocation
        context.coordinator.leftController = leftHosting
        context.coordinator.rightController = rightHosting

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        // Update hosting controller content when views change
        context.coordinator.leftController?.rootView = left()
        context.coordinator.rightController?.rootView = right()

        // Only set initial position, don't fight with user interactions
        if splitView.subviews.count == 2 && !context.coordinator.hasSetInitialPosition {
            context.coordinator.hasSetInitialPosition = true
            let totalSize = direction == .horizontal ? splitView.bounds.width : splitView.bounds.height
            let leftSize = CGFloat(ratio) * totalSize
            splitView.setPosition(leftSize, ofDividerAt: 0)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSSplitViewDelegate {
        var parent: SplitView
        var leftController: FocuslessHostingController<Left>?
        var rightController: FocuslessHostingController<Right>?
        var isUserDragging = false
        var hasSetInitialPosition = false

        init(_ parent: SplitView) {
            self.parent = parent
        }

        func splitViewWillResizeSubviews(_ notification: Notification) {
            // Mark that a resize is about to happen (likely user-initiated)
            isUserDragging = true
        }

        func splitViewDidResizeSubviews(_ notification: Notification) {
            guard isUserDragging,
                  let splitView = notification.object as? NSSplitView,
                  splitView.subviews.count == 2 else {
                isUserDragging = false
                return
            }

            let totalSize = parent.direction == .horizontal ? splitView.bounds.width : splitView.bounds.height
            let leftSize = parent.direction == .horizontal ? splitView.subviews[0].frame.width : splitView.subviews[0].frame.height

            if totalSize > 0 {
                let newRatio = Float(leftSize / totalSize)
                // Only call onRatioChange if the ratio actually changed significantly
                if abs(newRatio - parent.ratio) > 0.01 {
                    DispatchQueue.main.async {
                        self.parent.onRatioChange(newRatio)
                    }
                }
            }

            isUserDragging = false
        }

        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            // Minimum 10% of total size
            let totalSize = parent.direction == .horizontal ? splitView.bounds.width : splitView.bounds.height
            return totalSize * 0.1
        }

        func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            // Maximum 90% of total size
            let totalSize = parent.direction == .horizontal ? splitView.bounds.width : splitView.bounds.height
            return totalSize * 0.9
        }
    }
}

// MARK: - Focus Management Helpers

/// Prevents AppKit from drawing an exterior focus ring around the split view when the window title is clicked.
final class FocuslessSplitView: NSSplitView {
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
