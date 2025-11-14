//
//  StoneNameGenerator.swift
//  Numby
//
//  Generates random stone names for window titles
//

import Foundation

class StoneNameGenerator {
    static let shared = StoneNameGenerator()

    private let stones = [
        "Topaz",
        "Sapphire",
        "Ruby",
        "Emerald",
        "Diamond",
        "Amethyst",
        "Opal",
        "Jade",
        "Turquoise",
        "Onyx",
        "Garnet",
        "Peridot",
        "Aquamarine",
        "Citrine",
        "Moonstone",
        "Obsidian",
        "Quartz",
        "Malachite",
        "Lapis",
        "Agate",
        "Jasper",
        "Amber",
        "Pearl",
        "Coral"
    ]

    private var usedNames: Set<String> = []
    private var isFirstWindow = true

    private init() {}

    /// Get a random unused stone name
    func getRandomName() -> String {
        // First window is always "Numby"
        if isFirstWindow {
            isFirstWindow = false
            return "Numby"
        }
        // If all names are used, reset
        if usedNames.count >= stones.count {
            usedNames.removeAll()
        }

        // Get available names
        let availableNames = stones.filter { !usedNames.contains($0) }

        // Pick random
        guard let name = availableNames.randomElement() else {
            return "Topaz" // Fallback
        }

        usedNames.insert(name)
        return name
    }

    /// Release a name back to the pool when window closes
    func releaseName(_ name: String) {
        usedNames.remove(name)
    }

    /// Reset all used names
    func reset() {
        usedNames.removeAll()
    }
}
