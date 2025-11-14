//
//  CalculatorController.swift
//  Numby
//
//  Controller for calculator business logic and state management
//

import Foundation
import Combine
import SwiftUI

/// Controller managing calculator state, split tree, and business logic
class CalculatorController: ObservableObject {
    /// Current split tree state
    @Published var splitTree: SplitTree

    /// Currently focused leaf ID
    @Published var focusedLeafId: SplitLeafID?

    /// Calculator instances keyed by leaf ID
    @Published var calculators: [SplitLeafID: CalculatorInstance] = [:]

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Initialize with single leaf
        let initialLeafId = SplitLeafID()
        self.splitTree = SplitTree(leafId: initialLeafId)
        self.focusedLeafId = initialLeafId

        // Create initial calculator instance
        self.calculators[initialLeafId] = CalculatorInstance()

        setupObservers()
    }

    private func setupObservers() {
        // Watch for split tree changes to sync calculator instances
        $splitTree
            .sink { [weak self] tree in
                self?.syncCalculatorInstances(tree: tree)
            }
            .store(in: &cancellables)
    }

    // MARK: - Split Management

    /// Split the currently focused leaf
    func splitCurrentLeaf(direction: SplitDirection, ratio: Float = 0.5) {
        guard let focusedId = focusedLeafId else { return }
        splitLeaf(leafId: focusedId, direction: direction, ratio: ratio)
    }

    /// Split a specific leaf
    func splitLeaf(leafId: SplitLeafID, direction: SplitDirection, ratio: Float = 0.5) {
        guard let newTree = splitTree.split(leafId: leafId, direction: direction, ratio: ratio) else {
            return
        }

        let oldLeafIds = Set(splitTree.getAllLeafIds())
        splitTree = newTree
        let newLeafIds = splitTree.getAllLeafIds()

        // Find the newly created leaf ID and create calculator for it
        var newlyCreatedLeafId: SplitLeafID?
        for newLeafId in newLeafIds {
            // Check if this is a NEW leaf (not in old set)
            if !oldLeafIds.contains(newLeafId) {
                newlyCreatedLeafId = newLeafId
            }

            // Create calculator if it doesn't exist
            if calculators[newLeafId] == nil {
                calculators[newLeafId] = CalculatorInstance()
            }
        }

        // Update focus to the newly created leaf
        if let newId = newlyCreatedLeafId {
            focusedLeafId = newId
        }
    }

    /// Close the currently focused leaf
    func closeCurrentLeaf() {
        guard let focusedId = focusedLeafId else { return }
        closeLeaf(leafId: focusedId)
    }

    /// Close a specific leaf
    func closeLeaf(leafId: SplitLeafID) {
        guard let newTree = splitTree.removeLeaf(leafId: leafId) else {
            // Can't remove the last leaf
            return
        }

        // Remove calculator instance
        calculators.removeValue(forKey: leafId)

        splitTree = newTree

        // Update focus to first remaining leaf if focused leaf was closed
        if focusedLeafId == leafId {
            focusedLeafId = splitTree.getAllLeafIds().first
        }
    }

    /// Update split ratio for the focused leaf's parent split
    func updateCurrentRatio(newRatio: Float) {
        guard let focusedId = focusedLeafId else { return }
        updateRatio(leafId: focusedId, newRatio: newRatio)
    }

    /// Update split ratio
    func updateRatio(leafId: SplitLeafID, newRatio: Float) {
        guard let newTree = splitTree.updateRatio(leafId: leafId, newRatio: newRatio) else {
            return
        }
        splitTree = newTree
    }

    // MARK: - Focus Management

    /// Set focus to a specific leaf
    func setFocus(leafId: SplitLeafID) {
        if calculators[leafId] != nil {
            focusedLeafId = leafId
        }
    }

    /// Navigate focus in a direction
    func navigateFocus(direction: FocusDirection) {
        // TODO: Implement spatial navigation based on visual position
        // For now, just cycle through leaves
        let leafIds = splitTree.getAllLeafIds()
        guard !leafIds.isEmpty, let currentId = focusedLeafId else { return }

        if let currentIndex = leafIds.firstIndex(of: currentId) {
            let nextIndex = (currentIndex + 1) % leafIds.count
            focusedLeafId = leafIds[nextIndex]
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        // Clean up each calculator instance to break ObservableObject references
        for (_, instance) in calculators {
            instance.inputText = ""
            instance.results = []
            instance.cursorPosition = 0
        }
        
        cancellables.removeAll()
        calculators.removeAll()
        focusedLeafId = nil
    }

    // MARK: - State Restoration

    /// Restore split tree from saved state
    func restoreSplitTree(_ tree: SplitTree) {
        splitTree = tree

        // Recreate calculator instances for all leaves
        let leafIds = tree.getAllLeafIds()
        calculators.removeAll()

        for leafId in leafIds {
            calculators[leafId] = CalculatorInstance()
        }

        // Set focus to first leaf
        focusedLeafId = leafIds.first
    }

    // MARK: - Private Helpers

    private func syncCalculatorInstances(tree: SplitTree) {
        let currentLeafIds = Set(tree.getAllLeafIds())
        let existingLeafIds = Set(calculators.keys)

        // Remove calculators for deleted leaves
        for leafId in existingLeafIds.subtracting(currentLeafIds) {
            calculators.removeValue(forKey: leafId)
        }

        // Add calculators for new leaves
        for leafId in currentLeafIds.subtracting(existingLeafIds) {
            calculators[leafId] = CalculatorInstance()
        }
    }
}

// MARK: - Supporting Types

enum FocusDirection {
    case up, down, left, right
}

/// Individual calculator instance with its own state
class CalculatorInstance: ObservableObject {
    /// Calculator wrapper for Rust FFI
    @Published var numby: NumbyWrapper

    /// Input text
    @Published var inputText: String = ""

    /// Cursor position
    @Published var cursorPosition: Int = 0

    /// Results for each line
    @Published var results: [String?] = []

    /// Split ratio for input/results panels (default 0.5)
    @Published var splitRatio: Double = 0.5

    init() {
        self.numby = NumbyWrapper()
        setupObservers()
    }

    private func setupObservers() {
        // Watch for input text changes to recompute results
        $inputText
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.evaluateAllLines()
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    /// Evaluate all lines in input text
    func evaluateAllLines() {
        let lines = inputText.components(separatedBy: .newlines)
        results = lines.map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }

            // Evaluate line using Numby
            return numby.evaluate(expression: trimmed)
        }
    }

    /// Insert text at cursor
    func insertText(_ text: String) {
        let index = inputText.index(inputText.startIndex, offsetBy: cursorPosition)
        inputText.insert(contentsOf: text, at: index)
        cursorPosition += text.count
        evaluateAllLines()
    }

    /// Delete character before cursor
    func deleteBackward() {
        guard cursorPosition > 0 else { return }
        let index = inputText.index(inputText.startIndex, offsetBy: cursorPosition - 1)
        inputText.remove(at: index)
        cursorPosition -= 1
        evaluateAllLines()
    }

    /// Move cursor
    func moveCursor(by offset: Int) {
        cursorPosition = max(0, min(inputText.count, cursorPosition + offset))
    }

    /// Clear all input and history
    func clearAll() {
        inputText = ""
        results = []
        cursorPosition = 0
        numby.clearHistory()
    }

    deinit {
        // Clean up Combine subscriptions to prevent memory leaks
        cancellables.removeAll()
        // Clear published properties to break ObservableObject references
        inputText = ""
        results = []
        // Clear history when instance is deallocated
        numby.clearHistory()
        // numby will be cleaned up by its own deinit
    }
}
