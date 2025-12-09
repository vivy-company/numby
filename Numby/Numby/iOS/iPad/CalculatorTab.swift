#if os(iOS) || os(visionOS)
import Foundation

/// A tab that contains a split tree with multiple calculator panes
class CalculatorTab: Identifiable {
    let id: UUID
    var name: String

    // Split view controller for this tab
    let controller: iPadCalculatorController

    // Legacy properties for backward compatibility with iPhone
    var text: String {
        get {
            controller.calculators.values.first?.inputText ?? ""
        }
        set {
            controller.calculators.values.first?.inputText = newValue
        }
    }

    var results: [String] {
        get {
            controller.calculators.values.first?.results ?? []
        }
        set {
            controller.calculators.values.first?.results = newValue
        }
    }

    var numbyWrapper: NumbyWrapper {
        controller.calculators.values.first?.numbyWrapper ?? NumbyWrapper()
    }

    init(name: String? = nil) {
        self.id = UUID()
        self.name = name ?? StoneNameGenerator.shared.getRandomName()
        self.controller = iPadCalculatorController()
    }

    init(name: String? = nil, snapshot: CalculatorSessionSnapshot) {
        self.id = UUID()
        self.name = name ?? StoneNameGenerator.shared.getRandomName()
        self.controller = iPadCalculatorController(snapshot: snapshot)
    }

    deinit {
        StoneNameGenerator.shared.releaseName(name)
    }

    func createSnapshot() -> CalculatorSessionSnapshot {
        return controller.createSnapshot()
    }

    func searchableText() -> String {
        return controller.searchableText()
    }
}
#endif
