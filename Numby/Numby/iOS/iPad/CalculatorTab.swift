#if os(iOS) || os(visionOS)
import Foundation

class CalculatorTab: Identifiable {
    let id: UUID
    var name: String
    var text: String = ""
    var results: [String] = []
    let numbyWrapper: NumbyWrapper

    init(name: String? = nil) {
        self.id = UUID()
        self.name = name ?? StoneNameGenerator.shared.getRandomName()
        self.numbyWrapper = NumbyWrapper()
    }

    deinit {
        StoneNameGenerator.shared.releaseName(name)
    }
}
#endif
