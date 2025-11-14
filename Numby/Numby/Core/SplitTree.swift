//
//  SplitTree.swift
//  Numby
//
//  Value-based immutable split tree for managing calculator split views
//

import Foundation
import SwiftUI

/// Direction of a split
enum SplitDirection: Codable, Equatable {
    case horizontal
    case vertical
}

/// Identifier for a leaf node in the split tree
struct SplitLeafID: Codable, Equatable, Hashable {
    let uuid: UUID

    init() {
        self.uuid = UUID()
    }

    init(uuid: UUID) {
        self.uuid = uuid
    }
}

/// Immutable split tree structure
/// Each change creates a new tree value - simplifies state management and enables undo/redo
struct SplitTree: Codable, Equatable {
    var root: Node?

    /// Node in the split tree - either a leaf (calculator instance) or a split
    indirect enum Node: Codable, Equatable {
        case leaf(SplitLeafID)
        case split(direction: SplitDirection, ratio: Float, left: Node, right: Node)

        /// Encode node to support Codable
        enum CodingKeys: String, CodingKey {
            case type, leafId, direction, ratio, left, right
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .leaf(let id):
                try container.encode("leaf", forKey: .type)
                try container.encode(id, forKey: .leafId)
            case .split(let direction, let ratio, let left, let right):
                try container.encode("split", forKey: .type)
                try container.encode(direction, forKey: .direction)
                try container.encode(ratio, forKey: .ratio)
                try container.encode(left, forKey: .left)
                try container.encode(right, forKey: .right)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "leaf":
                let id = try container.decode(SplitLeafID.self, forKey: .leafId)
                self = .leaf(id)
            case "split":
                let direction = try container.decode(SplitDirection.self, forKey: .direction)
                let ratio = try container.decode(Float.self, forKey: .ratio)
                let left = try container.decode(Node.self, forKey: .left)
                let right = try container.decode(Node.self, forKey: .right)
                self = .split(direction: direction, ratio: ratio, left: left, right: right)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid node type")
            }
        }
    }

    /// Initialize with a single leaf
    init(leafId: SplitLeafID = SplitLeafID()) {
        self.root = .leaf(leafId)
    }

    /// Initialize with a root node
    init(root: Node?) {
        self.root = root
    }

    /// Split a leaf node in the given direction
    /// Returns a new tree with the split applied, or nil if the leaf wasn't found
    func split(leafId: SplitLeafID, direction: SplitDirection, ratio: Float = 0.5) -> SplitTree? {
        guard let newRoot = splitNode(root, targetId: leafId, direction: direction, ratio: ratio) else {
            return nil
        }
        return SplitTree(root: newRoot)
    }

    /// Remove a leaf node from the tree
    /// If it's the last leaf, returns nil (empty tree)
    func removeLeaf(leafId: SplitLeafID) -> SplitTree? {
        guard let newRoot = removeLeafFromNode(root, targetId: leafId) else {
            return nil
        }
        return SplitTree(root: newRoot)
    }

    /// Update the split ratio for a split containing the given leaf
    func updateRatio(leafId: SplitLeafID, newRatio: Float) -> SplitTree? {
        guard let newRoot = updateRatioInNode(root, targetId: leafId, newRatio: newRatio) else {
            return nil
        }
        return SplitTree(root: newRoot)
    }

    /// Get all leaf IDs in the tree (in order)
    func getAllLeafIds() -> [SplitLeafID] {
        guard let root = root else { return [] }
        return collectLeafIds(root)
    }

    /// Find the node containing the given leaf ID
    func findNode(leafId: SplitLeafID) -> Node? {
        return findNodeInTree(root, targetId: leafId)
    }

    // MARK: - Private helpers

    private func splitNode(_ node: Node?, targetId: SplitLeafID, direction: SplitDirection, ratio: Float) -> Node? {
        guard let node = node else { return nil }

        switch node {
        case .leaf(let id):
            if id == targetId {
                // Found the target - create split with new leaf
                let newLeafId = SplitLeafID()
                return .split(direction: direction, ratio: ratio, left: .leaf(id), right: .leaf(newLeafId))
            }
            return node

        case .split(let dir, let r, let left, let right):
            // Try splitting in left subtree
            if let newLeft = splitNode(left, targetId: targetId, direction: direction, ratio: ratio) {
                if newLeft != left {
                    return .split(direction: dir, ratio: r, left: newLeft, right: right)
                }
            }

            // Try splitting in right subtree
            if let newRight = splitNode(right, targetId: targetId, direction: direction, ratio: ratio) {
                if newRight != right {
                    return .split(direction: dir, ratio: r, left: left, right: newRight)
                }
            }

            return node
        }
    }

    private func removeLeafFromNode(_ node: Node?, targetId: SplitLeafID) -> Node? {
        guard let node = node else { return nil }

        switch node {
        case .leaf(let id):
            // If this is the target leaf, remove it
            return id == targetId ? nil : node

        case .split(let dir, let r, let left, let right):
            let newLeft = removeLeafFromNode(left, targetId: targetId)
            let newRight = removeLeafFromNode(right, targetId: targetId)

            // If both children are gone, remove this split
            if newLeft == nil && newRight == nil {
                return nil
            }

            // If one child is gone, promote the other
            if newLeft == nil {
                return newRight
            }
            if newRight == nil {
                return newLeft
            }

            // Both children exist, keep the split
            return .split(direction: dir, ratio: r, left: newLeft!, right: newRight!)
        }
    }

    private func updateRatioInNode(_ node: Node?, targetId: SplitLeafID, newRatio: Float) -> Node? {
        guard let node = node else { return nil }

        switch node {
        case .leaf(_):
            return node

        case .split(let dir, let r, let left, let right):
            // Check if this split contains the target leaf
            if containsLeaf(left, targetId: targetId) || containsLeaf(right, targetId: targetId) {
                return .split(direction: dir, ratio: newRatio, left: left, right: right)
            }

            // Recursively update in children
            let newLeft = updateRatioInNode(left, targetId: targetId, newRatio: newRatio)
            let newRight = updateRatioInNode(right, targetId: targetId, newRatio: newRatio)

            if newLeft != left || newRight != right {
                return .split(direction: dir, ratio: r, left: newLeft ?? left, right: newRight ?? right)
            }

            return node
        }
    }

    private func containsLeaf(_ node: Node?, targetId: SplitLeafID) -> Bool {
        guard let node = node else { return false }

        switch node {
        case .leaf(let id):
            return id == targetId
        case .split(_, _, let left, let right):
            return containsLeaf(left, targetId: targetId) || containsLeaf(right, targetId: targetId)
        }
    }

    private func collectLeafIds(_ node: Node) -> [SplitLeafID] {
        switch node {
        case .leaf(let id):
            return [id]
        case .split(_, _, let left, let right):
            return collectLeafIds(left) + collectLeafIds(right)
        }
    }

    private func findNodeInTree(_ node: Node?, targetId: SplitLeafID) -> Node? {
        guard let node = node else { return nil }

        switch node {
        case .leaf(let id):
            return id == targetId ? node : nil
        case .split(_, _, let left, let right):
            return findNodeInTree(left, targetId: targetId) ?? findNodeInTree(right, targetId: targetId)
        }
    }
}

// MARK: - SwiftUI Helpers

extension SplitTree {
    /// Calculate layout rectangles for all leaves in the tree given a container size
    func calculateLayout(in size: CGSize) -> [SplitLeafID: CGRect] {
        guard let root = root else { return [:] }
        var result: [SplitLeafID: CGRect] = [:]
        calculateLayoutForNode(root, in: CGRect(origin: .zero, size: size), result: &result)
        return result
    }

    private func calculateLayoutForNode(_ node: Node, in rect: CGRect, result: inout [SplitLeafID: CGRect]) {
        switch node {
        case .leaf(let id):
            result[id] = rect

        case .split(let direction, let ratio, let left, let right):
            let (leftRect, rightRect) = splitRect(rect, direction: direction, ratio: ratio)
            calculateLayoutForNode(left, in: leftRect, result: &result)
            calculateLayoutForNode(right, in: rightRect, result: &result)
        }
    }

    private func splitRect(_ rect: CGRect, direction: SplitDirection, ratio: Float) -> (CGRect, CGRect) {
        switch direction {
        case .horizontal:
            let leftWidth = rect.width * CGFloat(ratio)
            let leftRect = CGRect(x: rect.minX, y: rect.minY, width: leftWidth, height: rect.height)
            let rightRect = CGRect(x: rect.minX + leftWidth, y: rect.minY, width: rect.width - leftWidth, height: rect.height)
            return (leftRect, rightRect)

        case .vertical:
            let topHeight = rect.height * CGFloat(ratio)
            let topRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: topHeight)
            let bottomRect = CGRect(x: rect.minX, y: rect.minY + topHeight, width: rect.width, height: rect.height - topHeight)
            return (topRect, bottomRect)
        }
    }
}
