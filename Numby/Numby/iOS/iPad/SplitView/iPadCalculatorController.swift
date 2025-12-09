#if os(iOS) || os(visionOS)
import Foundation

/// Calculator instance for a single pane in the split view
class iPadCalculatorInstance {
    let leafId: SplitLeafID
    var inputText: String = ""
    var results: [String] = []
    var cursorPosition: Int = 0
    let numbyWrapper: NumbyWrapper

    init(leafId: SplitLeafID) {
        self.leafId = leafId
        self.numbyWrapper = NumbyWrapper()
    }
}

/// Manages split tree and calculator instances for iPad
class iPadCalculatorController {

    // MARK: - Properties

    private(set) var splitTree: SplitTree
    private(set) var calculators: [SplitLeafID: iPadCalculatorInstance] = [:]
    var focusedLeafId: SplitLeafID?

    var onSplitTreeChanged: (() -> Void)?
    var onFocusChanged: ((SplitLeafID?) -> Void)?

    // MARK: - Initialization

    init() {
        let initialLeafId = SplitLeafID()
        self.splitTree = SplitTree(leafId: initialLeafId)
        self.calculators[initialLeafId] = iPadCalculatorInstance(leafId: initialLeafId)
        self.focusedLeafId = initialLeafId
    }

    init(snapshot: CalculatorSessionSnapshot) {
        self.splitTree = snapshot.splitTree

        // Recreate calculator instances from snapshot
        for (leafIdString, stateSnapshot) in snapshot.calculatorStates {
            if let uuid = UUID(uuidString: leafIdString) {
                let leafId = SplitLeafID(uuid: uuid)
                let instance = iPadCalculatorInstance(leafId: leafId)
                instance.inputText = stateSnapshot.inputText
                instance.results = stateSnapshot.results.compactMap { $0 }
                instance.cursorPosition = stateSnapshot.cursorPosition
                calculators[leafId] = instance
            }
        }

        // Set focus to first leaf
        focusedLeafId = splitTree.getAllLeafIds().first
    }

    // MARK: - Split Operations

    func splitLeaf(_ leafId: SplitLeafID, direction: SplitDirection, ratio: Float = 0.5) {
        guard let newTree = splitTree.split(leafId: leafId, direction: direction, ratio: ratio) else {
            return
        }

        let oldLeafIds = Set(splitTree.getAllLeafIds())
        splitTree = newTree
        let newLeafIds = splitTree.getAllLeafIds()

        // Find and create calculator for newly created leaf
        for newLeafId in newLeafIds where !oldLeafIds.contains(newLeafId) {
            calculators[newLeafId] = iPadCalculatorInstance(leafId: newLeafId)
            focusedLeafId = newLeafId
        }

        onSplitTreeChanged?()
        onFocusChanged?(focusedLeafId)
    }

    func closeLeaf(_ leafId: SplitLeafID) {
        let leafIds = splitTree.getAllLeafIds()

        // Don't close if it's the last leaf
        guard leafIds.count > 1 else { return }

        // Save pane content to history before closing
        if let instance = calculators[leafId], !instance.inputText.isEmpty {
            // Build expression/result pairs for history
            let lines = instance.inputText.components(separatedBy: "\n")
            var historyText = ""
            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty && index < instance.results.count && !instance.results[index].isEmpty {
                    historyText += "\(trimmed) = \(instance.results[index])\n"
                }
            }
            if !historyText.isEmpty {
                // Save as simple history entry
                Persistence.shared.addHistoryEntry(expression: instance.inputText, result: historyText)
            }
        }

        guard let newTree = splitTree.removeLeaf(leafId: leafId) else {
            return
        }

        splitTree = newTree
        calculators.removeValue(forKey: leafId)

        // Update focus if we closed the focused leaf
        if focusedLeafId == leafId {
            focusedLeafId = splitTree.getAllLeafIds().first
            onFocusChanged?(focusedLeafId)
        }

        onSplitTreeChanged?()
    }

    func updateRatio(_ leafId: SplitLeafID, newRatio: Float) {
        guard let newTree = splitTree.updateRatio(leafId: leafId, newRatio: newRatio) else {
            return
        }
        splitTree = newTree
    }

    // MARK: - Focus

    func setFocus(_ leafId: SplitLeafID) {
        guard calculators[leafId] != nil else { return }
        focusedLeafId = leafId
        onFocusChanged?(leafId)
    }

    // MARK: - Convenience

    func splitCurrentLeaf(direction: SplitDirection) {
        guard let focused = focusedLeafId else { return }
        splitLeaf(focused, direction: direction)
    }

    func closeCurrentLeaf() {
        guard let focused = focusedLeafId else { return }
        closeLeaf(focused)
    }

    var leafCount: Int {
        return splitTree.getAllLeafIds().count
    }

    // MARK: - Snapshot

    func createSnapshot() -> CalculatorSessionSnapshot {
        var calculatorStates: [String: CalculatorSessionSnapshot.CalculatorStateSnapshot] = [:]

        for (leafId, instance) in calculators {
            calculatorStates[leafId.uuid.uuidString] = CalculatorSessionSnapshot.CalculatorStateSnapshot(
                inputText: instance.inputText,
                results: instance.results.map { $0.isEmpty ? nil : $0 },
                cursorPosition: instance.cursorPosition
            )
        }

        return CalculatorSessionSnapshot(
            splitTree: splitTree,
            calculatorStates: calculatorStates
        )
    }

    func searchableText() -> String {
        return calculators.values
            .map { $0.inputText }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
#endif
