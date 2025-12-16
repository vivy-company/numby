package com.numby.ui.split

import java.util.UUID

/**
 * Direction of a split.
 */
enum class SplitDirection {
    HORIZONTAL,
    VERTICAL
}

/**
 * Represents a node in the split tree.
 *
 * Can be either a leaf (containing calculator pane) or a split (containing two children).
 */
sealed class SplitNode {
    abstract val id: String

    /**
     * A leaf node containing a calculator pane.
     */
    data class Leaf(
        override val id: String = UUID.randomUUID().toString(),
        val paneId: String = UUID.randomUUID().toString()
    ) : SplitNode()

    /**
     * A split node containing two children.
     */
    data class Split(
        override val id: String = UUID.randomUUID().toString(),
        val direction: SplitDirection,
        val first: SplitNode,
        val second: SplitNode,
        val ratio: Float = 0.5f
    ) : SplitNode()
}

/**
 * State for managing the split tree.
 */
data class SplitTreeState(
    val root: SplitNode = SplitNode.Leaf(),
    val focusedPaneId: String? = null
) {
    /**
     * Split a pane in the given direction.
     */
    fun splitPane(paneId: String, direction: SplitDirection): SplitTreeState {
        return copy(
            root = splitNode(root, paneId, direction)
        )
    }

    private fun splitNode(node: SplitNode, targetPaneId: String, direction: SplitDirection): SplitNode {
        return when (node) {
            is SplitNode.Leaf -> {
                if (node.paneId == targetPaneId) {
                    SplitNode.Split(
                        direction = direction,
                        first = node,
                        second = SplitNode.Leaf()
                    )
                } else {
                    node
                }
            }
            is SplitNode.Split -> {
                node.copy(
                    first = splitNode(node.first, targetPaneId, direction),
                    second = splitNode(node.second, targetPaneId, direction)
                )
            }
        }
    }

    /**
     * Close a pane and remove it from the tree.
     */
    fun closePane(paneId: String): SplitTreeState {
        val newRoot = removeNode(root, paneId)
        return if (newRoot != null) {
            copy(root = newRoot)
        } else {
            // If we removed the last pane, create a new one
            SplitTreeState()
        }
    }

    private fun removeNode(node: SplitNode, targetPaneId: String): SplitNode? {
        return when (node) {
            is SplitNode.Leaf -> {
                if (node.paneId == targetPaneId) null else node
            }
            is SplitNode.Split -> {
                val newFirst = removeNode(node.first, targetPaneId)
                val newSecond = removeNode(node.second, targetPaneId)
                when {
                    newFirst == null && newSecond == null -> null
                    newFirst == null -> newSecond
                    newSecond == null -> newFirst
                    else -> node.copy(first = newFirst, second = newSecond)
                }
            }
        }
    }

    /**
     * Update the split ratio for a split node.
     */
    fun updateRatio(splitId: String, ratio: Float): SplitTreeState {
        return copy(
            root = updateNodeRatio(root, splitId, ratio.coerceIn(0.1f, 0.9f))
        )
    }

    private fun updateNodeRatio(node: SplitNode, targetId: String, ratio: Float): SplitNode {
        return when (node) {
            is SplitNode.Leaf -> node
            is SplitNode.Split -> {
                if (node.id == targetId) {
                    node.copy(ratio = ratio)
                } else {
                    node.copy(
                        first = updateNodeRatio(node.first, targetId, ratio),
                        second = updateNodeRatio(node.second, targetId, ratio)
                    )
                }
            }
        }
    }

    /**
     * Get all pane IDs in the tree.
     */
    fun getAllPaneIds(): List<String> {
        return collectPaneIds(root)
    }

    private fun collectPaneIds(node: SplitNode): List<String> {
        return when (node) {
            is SplitNode.Leaf -> listOf(node.paneId)
            is SplitNode.Split -> collectPaneIds(node.first) + collectPaneIds(node.second)
        }
    }

    /**
     * Check if there's only one pane (no splits).
     */
    fun isSinglePane(): Boolean {
        return root is SplitNode.Leaf
    }
}
