package com.numby.ui.calculator

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.numby.R
import com.numby.ui.split.SplitPaneLayout
import com.numby.ui.theme.LocalSyntaxColors

/**
 * Tab bar component for tablet layout - iOS Safari-style pill tabs.
 * Auto-hides when only 1 tab exists.
 */
@Composable
fun TabBar(
    state: TabContainerState,
    onTabSelected: (String) -> Unit,
    onTabClosed: (String) -> Unit,
    onAddTab: () -> Unit,
    modifier: Modifier = Modifier
) {
    val syntaxColors = LocalSyntaxColors.current
    val showTabBar = state.tabs.size > 1

    AnimatedVisibility(
        visible = showTabBar,
        enter = expandVertically(
            animationSpec = spring(
                dampingRatio = 0.8f,
                stiffness = Spring.StiffnessMedium
            )
        ),
        exit = shrinkVertically(
            animationSpec = spring(
                dampingRatio = 0.8f,
                stiffness = Spring.StiffnessMedium
            )
        )
    ) {
        Surface(
            modifier = modifier
                .fillMaxWidth()
                .height(44.dp),
            color = syntaxColors.background
        ) {
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 12.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Tab items
                state.tabs.forEach { tab ->
                    TabItem(
                        tab = tab,
                        isSelected = tab.id == state.selectedTabId,
                        onClick = { onTabSelected(tab.id) },
                        onClose = { onTabClosed(tab.id) },
                        showCloseButton = state.tabs.size > 1
                    )
                }

                // Add tab button
                IconButton(
                    onClick = onAddTab,
                    modifier = Modifier.size(36.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = stringResource(R.string.new_tab),
                        tint = syntaxColors.text.copy(alpha = 0.7f)
                    )
                }
            }
        }
    }
}

/**
 * Individual tab item - pill-shaped like iOS Safari tabs.
 * Close button on LEFT side before title.
 */
@Composable
private fun TabItem(
    tab: Tab,
    isSelected: Boolean,
    onClick: () -> Unit,
    onClose: () -> Unit,
    showCloseButton: Boolean
) {
    val syntaxColors = LocalSyntaxColors.current

    // iOS-style: selected = 15% opacity, unselected = 5% opacity
    val backgroundColor = if (isSelected) {
        syntaxColors.text.copy(alpha = 0.15f)
    } else {
        syntaxColors.text.copy(alpha = 0.05f)
    }

    val contentColor = if (isSelected) {
        syntaxColors.text
    } else {
        syntaxColors.text.copy(alpha = 0.7f)
    }

    // Pill-shaped tab (16dp corner radius like iOS)
    Surface(
        modifier = Modifier
            .height(36.dp)
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick),
        color = backgroundColor,
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier.padding(start = 8.dp, end = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            // Close button on LEFT (iOS style)
            if (showCloseButton) {
                Box(
                    modifier = Modifier
                        .size(18.dp)
                        .clip(CircleShape)
                        .clickable(onClick = onClose)
                        .background(syntaxColors.text.copy(alpha = 0.1f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = stringResource(R.string.close_tab),
                        modifier = Modifier.size(10.dp),
                        tint = contentColor
                    )
                }
            }

            // Tab title
            Text(
                text = tab.name,
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium,
                color = contentColor,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

/**
 * Full tab container with tab bar and split pane content.
 */
@Composable
fun TabContainerScreen(
    state: TabContainerState,
    onStateChange: (TabContainerState) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.fillMaxSize()) {
        // Tab bar
        TabBar(
            state = state,
            onTabSelected = { tabId ->
                onStateChange(state.selectTab(tabId))
            },
            onTabClosed = { tabId ->
                onStateChange(state.closeTab(tabId))
            },
            onAddTab = {
                onStateChange(state.addTab())
            }
        )

        // Content area with split panes
        state.selectedTab?.let { tab ->
            SplitPaneLayout(
                state = tab.splitState,
                onStateChange = { splitState ->
                    onStateChange(state.updateCurrentTabSplitState(splitState))
                },
                modifier = Modifier.weight(1f)
            )
        }
    }
}
