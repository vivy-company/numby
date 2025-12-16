package com.numby.ui.split

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.numby.ui.calculator.CalculatorPane

private val DIVIDER_WIDTH = 8.dp
private val DIVIDER_TOUCH_WIDTH = 24.dp

/**
 * Renders a split tree with draggable dividers.
 */
@Composable
fun SplitPaneLayout(
    state: SplitTreeState,
    onStateChange: (SplitTreeState) -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        SplitNodeContent(
            node = state.root,
            state = state,
            onStateChange = onStateChange,
            modifier = Modifier.fillMaxSize()
        )
    }
}

@Composable
private fun SplitNodeContent(
    node: SplitNode,
    state: SplitTreeState,
    onStateChange: (SplitTreeState) -> Unit,
    modifier: Modifier = Modifier
) {
    when (node) {
        is SplitNode.Leaf -> {
            CalculatorPane(
                modifier = modifier,
                paneId = node.paneId
            )
        }
        is SplitNode.Split -> {
            SplitContainer(
                split = node,
                state = state,
                onStateChange = onStateChange,
                modifier = modifier
            )
        }
    }
}

@Composable
private fun SplitContainer(
    split: SplitNode.Split,
    state: SplitTreeState,
    onStateChange: (SplitTreeState) -> Unit,
    modifier: Modifier = Modifier
) {
    val density = LocalDensity.current
    var containerSize by remember { mutableFloatStateOf(0f) }

    val dividerWidthPx = with(density) { DIVIDER_WIDTH.toPx() }

    when (split.direction) {
        SplitDirection.HORIZONTAL -> {
            Row(
                modifier = modifier
                    .fillMaxSize()
                    .onSizeChanged { containerSize = it.width.toFloat() }
            ) {
                // First pane
                Box(
                    modifier = Modifier
                        .weight(split.ratio)
                        .fillMaxHeight()
                ) {
                    SplitNodeContent(
                        node = split.first,
                        state = state,
                        onStateChange = onStateChange,
                        modifier = Modifier.fillMaxSize()
                    )
                }

                // Draggable divider
                HorizontalDivider(
                    onDrag = { delta ->
                        if (containerSize > 0) {
                            val newRatio = split.ratio + (delta / containerSize)
                            onStateChange(state.updateRatio(split.id, newRatio))
                        }
                    }
                )

                // Second pane
                Box(
                    modifier = Modifier
                        .weight(1f - split.ratio)
                        .fillMaxHeight()
                ) {
                    SplitNodeContent(
                        node = split.second,
                        state = state,
                        onStateChange = onStateChange,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
        }
        SplitDirection.VERTICAL -> {
            Column(
                modifier = modifier
                    .fillMaxSize()
                    .onSizeChanged { containerSize = it.height.toFloat() }
            ) {
                // First pane
                Box(
                    modifier = Modifier
                        .weight(split.ratio)
                        .fillMaxWidth()
                ) {
                    SplitNodeContent(
                        node = split.first,
                        state = state,
                        onStateChange = onStateChange,
                        modifier = Modifier.fillMaxSize()
                    )
                }

                // Draggable divider
                VerticalDivider(
                    onDrag = { delta ->
                        if (containerSize > 0) {
                            val newRatio = split.ratio + (delta / containerSize)
                            onStateChange(state.updateRatio(split.id, newRatio))
                        }
                    }
                )

                // Second pane
                Box(
                    modifier = Modifier
                        .weight(1f - split.ratio)
                        .fillMaxWidth()
                ) {
                    SplitNodeContent(
                        node = split.second,
                        state = state,
                        onStateChange = onStateChange,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
        }
    }
}

@Composable
private fun HorizontalDivider(
    onDrag: (Float) -> Unit
) {
    Box(
        modifier = Modifier
            .width(DIVIDER_WIDTH)
            .fillMaxHeight()
            .background(MaterialTheme.colorScheme.outline)
            .pointerInput(Unit) {
                detectDragGestures { change, dragAmount ->
                    change.consume()
                    onDrag(dragAmount.x)
                }
            }
    )
}

@Composable
private fun VerticalDivider(
    onDrag: (Float) -> Unit
) {
    Box(
        modifier = Modifier
            .height(DIVIDER_WIDTH)
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.outline)
            .pointerInput(Unit) {
                detectDragGestures { change, dragAmount ->
                    change.consume()
                    onDrag(dragAmount.y)
                }
            }
    )
}
