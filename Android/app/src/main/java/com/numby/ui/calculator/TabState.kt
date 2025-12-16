package com.numby.ui.calculator

import com.numby.ui.split.SplitTreeState
import java.util.UUID

/**
 * Represents a single tab with its own split tree state.
 */
data class Tab(
    val id: String = UUID.randomUUID().toString(),
    val name: String = "Calculator",
    val splitState: SplitTreeState = SplitTreeState()
)

/**
 * State for managing multiple tabs.
 */
data class TabContainerState(
    val tabs: List<Tab> = listOf(Tab()),
    val selectedTabId: String = tabs.firstOrNull()?.id ?: ""
) {
    val selectedTab: Tab?
        get() = tabs.find { it.id == selectedTabId }

    val selectedIndex: Int
        get() = tabs.indexOfFirst { it.id == selectedTabId }.coerceAtLeast(0)

    /**
     * Add a new tab.
     */
    fun addTab(): TabContainerState {
        val newTab = Tab()
        return copy(
            tabs = tabs + newTab,
            selectedTabId = newTab.id
        )
    }

    /**
     * Close a tab by ID.
     */
    fun closeTab(tabId: String): TabContainerState {
        if (tabs.size <= 1) {
            // Don't close the last tab, just reset it
            return copy(
                tabs = listOf(Tab()),
                selectedTabId = tabs.first().id
            )
        }

        val index = tabs.indexOfFirst { it.id == tabId }
        val newTabs = tabs.filter { it.id != tabId }
        val newSelectedId = when {
            tabId != selectedTabId -> selectedTabId
            index >= newTabs.size -> newTabs.last().id
            else -> newTabs[index].id
        }

        return copy(
            tabs = newTabs,
            selectedTabId = newSelectedId
        )
    }

    /**
     * Select a tab by ID.
     */
    fun selectTab(tabId: String): TabContainerState {
        return copy(selectedTabId = tabId)
    }

    /**
     * Update the split state for the current tab.
     */
    fun updateCurrentTabSplitState(splitState: SplitTreeState): TabContainerState {
        return copy(
            tabs = tabs.map { tab ->
                if (tab.id == selectedTabId) {
                    tab.copy(splitState = splitState)
                } else {
                    tab
                }
            }
        )
    }

    /**
     * Rename a tab.
     */
    fun renameTab(tabId: String, name: String): TabContainerState {
        return copy(
            tabs = tabs.map { tab ->
                if (tab.id == tabId) {
                    tab.copy(name = name)
                } else {
                    tab
                }
            }
        )
    }
}
