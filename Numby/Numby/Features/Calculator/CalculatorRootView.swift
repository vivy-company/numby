//
//  CalculatorRootView.swift
//  Numby
//
//  Root view that renders the split tree of calculator instances
//

import SwiftUI
import Combine

/// Root view for a calculator window - renders the split tree
struct CalculatorRootView: View {
    @ObservedObject var controller: CalculatorController
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var configManager: ConfigurationManager
    @FocusedValue(\.calculatorLeafId) private var focusedLeafId: SplitLeafID?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Main calculator content - recursively render split tree
            if let root = controller.splitTree.root {
                NodeView(node: root, controller: controller)
            } else {
                Text("No calculators")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Settings button in bottom-left corner
            Button(action: {
                NSApp.sendAction(#selector(AppDelegate.openSettings), to: nil, from: nil)
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(configManager.config.backgroundColor ?? NSColor.textBackgroundColor).opacity(0.95))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .onChange(of: focusedLeafId) { newFocusedId in
            // Sync focused leaf from SwiftUI focus system to controller
            if let newFocusedId = newFocusedId {
                controller.focusedLeafId = newFocusedId
            }
        }
    }
}

// MARK: - Recursive Node View

struct NodeView: View {
    let node: SplitTree.Node
    @ObservedObject var controller: CalculatorController

    var body: some View {
        switch node {
        case .leaf(let leafId):
            // Render calculator surface for leaf node
            if let instance = controller.calculators[leafId] {
                CalculatorSurfaceView(
                    instance: instance,
                    leafId: leafId,
                    isFocused: controller.focusedLeafId == leafId
                )
                .id(leafId.uuid) // Stable identity for SwiftUI
            } else {
                Text("Calculator not found")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        case .split(let direction, let ratio, let left, let right):
            // Render split view with recursive rendering of children
            SplitView(
                direction: direction,
                ratio: .constant(ratio),
                onRatioChange: { _ in
                    // Ratio changes handled by NSSplitView delegate
                },
                left: { NodeView(node: left, controller: controller) },
                right: { NodeView(node: right, controller: controller) }
            )
        }
    }
}
