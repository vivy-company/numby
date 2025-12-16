package com.numby.ui.calculator

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items as gridItems
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.isImeVisible
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.input.OffsetMapping
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.input.TransformedText
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.numby.NumbyApplication
import com.numby.R
import com.numby.ui.theme.CalculatorInputStyle
import com.numby.ui.theme.CalculatorResultStyle
import com.numby.ui.theme.LocalSyntaxColors
import com.numby.ui.theme.SyntaxColors

/**
 * Main calculator screen with input and results overlay.
 * Matches iOS UX with line-aligned results.
 */
@OptIn(androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
@Composable
fun CalculatorScreen(
    modifier: Modifier = Modifier,
    viewModel: CalculatorViewModel = viewModel(),
    onTextChange: ((String, List<String?>) -> Unit)? = null,
    onGetClearCallback: (((() -> Unit)) -> Unit)? = null
) {
    val state by viewModel.state.collectAsState()
    val scrollState = rememberScrollState()
    val density = LocalDensity.current
    val syntaxColors = LocalSyntaxColors.current
    val keyboardController = LocalSoftwareKeyboardController.current

    var textFieldValue by remember { mutableStateOf(TextFieldValue(state.inputText)) }
    var textLayoutResult by remember { mutableStateOf<TextLayoutResult?>(null) }
    val focusRequester = remember { FocusRequester() }
    var isFocused by remember { mutableStateOf(false) }

    // Auto-focus and show keyboard on launch
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
        keyboardController?.show()
    }

    // Listen for accessory bar actions when focused
    LaunchedEffect(isFocused) {
        if (isFocused) {
            NumbyApplication.getInstance().accessoryAction.collect { action ->
                when (action) {
                    is NumbyApplication.AccessoryAction.Insert -> {
                        val newText = textFieldValue.text.substring(0, textFieldValue.selection.start) +
                                action.text +
                                textFieldValue.text.substring(textFieldValue.selection.end)
                        val newCursor = textFieldValue.selection.start + action.text.length
                        textFieldValue = TextFieldValue(newText, TextRange(newCursor))
                        viewModel.onInputChange(newText)
                    }
                    is NumbyApplication.AccessoryAction.Backspace -> {
                        if (textFieldValue.selection.start > 0) {
                            val newText = textFieldValue.text.substring(0, textFieldValue.selection.start - 1) +
                                    textFieldValue.text.substring(textFieldValue.selection.end)
                            val newCursor = textFieldValue.selection.start - 1
                            textFieldValue = TextFieldValue(newText, TextRange(newCursor))
                            viewModel.onInputChange(newText)
                        }
                    }
                    is NumbyApplication.AccessoryAction.Newline -> {
                        val newText = textFieldValue.text.substring(0, textFieldValue.selection.start) +
                                "\n" +
                                textFieldValue.text.substring(textFieldValue.selection.end)
                        val newCursor = textFieldValue.selection.start + 1
                        textFieldValue = TextFieldValue(newText, TextRange(newCursor))
                        viewModel.onInputChange(newText)
                    }
                }
            }
        }
    }

    // Expose clear callback to parent
    LaunchedEffect(Unit) {
        onGetClearCallback?.invoke {
            viewModel.clear()
            textFieldValue = TextFieldValue("")
        }
    }

    // Notify parent of text changes
    LaunchedEffect(state.inputText, state.results) {
        onTextChange?.invoke(state.inputText, state.results)
    }

    // Sync state changes - also handle when state is cleared externally
    if (textFieldValue.text != state.inputText) {
        textFieldValue = TextFieldValue(state.inputText, TextRange(state.inputText.length))
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Main calculator area
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(scrollState)
                .clickable { focusRequester.requestFocus() }
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                // Input text field
                BasicTextField(
                    value = textFieldValue,
                    onValueChange = { newValue ->
                        textFieldValue = newValue
                        viewModel.onInputChange(newValue.text)
                    },
                    modifier = Modifier
                        .weight(1f)
                        .focusRequester(focusRequester)
                        .onFocusChanged { focusState ->
                            isFocused = focusState.isFocused
                        },
                    textStyle = CalculatorInputStyle.copy(
                        color = MaterialTheme.colorScheme.onBackground
                    ),
                    cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Ascii,
                        imeAction = ImeAction.None,
                        autoCorrectEnabled = false,
                        capitalization = KeyboardCapitalization.None
                    ),
                    visualTransformation = SyntaxHighlightTransformation(syntaxColors),
                    onTextLayout = { textLayoutResult = it },
                    decorationBox = { innerTextField ->
                        Box {
                            if (textFieldValue.text.isEmpty()) {
                                Text(
                                    text = stringResource(R.string.calculator_hint),
                                    style = CalculatorInputStyle,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                                )
                            }
                            innerTextField()
                        }
                    }
                )

                // Results overlay - aligned with input lines
                if (state.results.isNotEmpty()) {
                    Spacer(modifier = Modifier.width(16.dp))
                    ResultsOverlay(
                        results = state.results,
                        textLayoutResult = textLayoutResult,
                        lineHeight = with(density) { CalculatorInputStyle.lineHeight.toDp() },
                        resultColor = syntaxColors.results
                    )
                }
            }
        }

        // Accessory bar is now handled at the layout level (MainActivity)
        // to ensure only one bar shows for all split panes
    }
}

/**
 * Results overlay positioned to align with input lines.
 */
@Composable
private fun ResultsOverlay(
    results: List<String?>,
    textLayoutResult: TextLayoutResult?,
    lineHeight: Dp,
    resultColor: Color
) {
    Column {
        results.forEachIndexed { index, result ->
            val height = if (textLayoutResult != null && index < textLayoutResult.lineCount) {
                with(LocalDensity.current) {
                    (textLayoutResult.getLineBottom(index) - textLayoutResult.getLineTop(index)).toDp()
                }
            } else {
                lineHeight
            }

            Box(
                modifier = Modifier.height(height),
                contentAlignment = Alignment.CenterStart
            ) {
                if (result != null) {
                    Text(
                        text = result,
                        style = CalculatorResultStyle,
                        color = resultColor,
                        maxLines = 1
                    )
                }
            }
        }
    }
}

/**
 * Input accessory bar with quick-access buttons.
 * Single horizontal scroll with all items.
 * Public so it can be used at the layout level (not per-pane).
 */
@Composable
fun InputAccessoryBar(
    onInsert: (String) -> Unit,
    onBackspace: () -> Unit,
    onNewline: () -> Unit
) {
    val syntaxColors = LocalSyntaxColors.current

    val allItems = listOf(
        // Operators
        AccessoryItem("+", "+"),
        AccessoryItem("−", "-"),
        AccessoryItem("×", "*"),
        AccessoryItem("÷", "/"),
        AccessoryItem("^", "^"),
        AccessoryItem("%", "%"),
        AccessoryItem("(", "("),
        AccessoryItem(")", ")"),
        AccessoryItem("=", "="),
        // Currencies
        AccessoryItem("USD", " USD"),
        AccessoryItem("EUR", " EUR"),
        AccessoryItem("GBP", " GBP"),
        AccessoryItem("JPY", " JPY"),
        AccessoryItem("CNY", " CNY"),
        AccessoryItem("RUB", " RUB"),
        AccessoryItem("BYN", " BYN"),
        AccessoryItem("BTC", " BTC"),
        AccessoryItem("ETH", " ETH"),
        // Units
        AccessoryItem("km", " km"),
        AccessoryItem("m", " m"),
        AccessoryItem("cm", " cm"),
        AccessoryItem("mi", " mi"),
        AccessoryItem("ft", " ft"),
        AccessoryItem("kg", " kg"),
        AccessoryItem("g", " g"),
        AccessoryItem("lb", " lb"),
        AccessoryItem("oz", " oz"),
        AccessoryItem("°C", " °C"),
        AccessoryItem("°F", " °F"),
        // Functions
        AccessoryItem("sqrt", "sqrt("),
        AccessoryItem("sin", "sin("),
        AccessoryItem("cos", "cos("),
        AccessoryItem("log", "log(")
    )

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(44.dp),
        color = syntaxColors.background,
        shadowElevation = 4.dp
    ) {
        Row(
            modifier = Modifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Scrollable items
            LazyRow(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight(),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                contentPadding = PaddingValues(horizontal = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                items(allItems) { item ->
                    AccessoryButton(
                        text = item.display,
                        onClick = { onInsert(item.insert) }
                    )
                }
            }

            // Fixed action buttons on the right
            Row(
                modifier = Modifier.padding(end = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                AccessoryButton(
                    text = "↵",
                    onClick = onNewline
                )
                AccessoryButton(
                    text = "⌫",
                    onClick = onBackspace
                )
            }
        }
    }
}

private data class AccessoryItem(
    val display: String,
    val insert: String
)

@Composable
private fun AccessoryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val syntaxColors = LocalSyntaxColors.current
    val defaultWidth = when {
        text.length > 3 -> 52.dp
        text.length > 2 -> 44.dp
        else -> 36.dp
    }

    Surface(
        modifier = modifier
            .then(if (modifier == Modifier) Modifier.width(defaultWidth) else Modifier)
            .height(36.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(8.dp),
        color = syntaxColors.text.copy(alpha = 0.1f)
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = text,
                style = MaterialTheme.typography.labelMedium.copy(
                    fontWeight = FontWeight.Medium
                ),
                color = syntaxColors.text.copy(alpha = 0.9f)
            )
        }
    }
}

/**
 * Syntax highlighting visual transformation.
 */
private class SyntaxHighlightTransformation(
    private val colors: SyntaxColors
) : VisualTransformation {

    private val numberPattern = Regex("""\b\d+\.?\d*\b""")
    private val operatorPattern = Regex("""[+\-*/^%=]""")
    private val unitPattern = Regex(
        """\b(km|m|cm|mm|miles?|mi|ft|feet|in|inch|yards?|yd|""" +
        """kg|g|grams?|lb|lbs?|oz|ounces?|""" +
        """l|L|liters?|ml|mL|gal|gallons?|""" +
        """°[CF]|celsius|fahrenheit|kelvin|K|""" +
        """Hz|kHz|MHz|GHz|""" +
        """B|KB|MB|GB|TB|bytes?|""" +
        """W|kW|MW|V|A|Ω|ohms?|""" +
        """Pa|kPa|bar|psi|atm|""" +
        """mph|km/h|m/s|knots?|""" +
        """s|sec|seconds?|min|minutes?|h|hrs?|hours?|days?|weeks?|months?|years?)\b""",
        RegexOption.IGNORE_CASE
    )
    private val currencyPattern = Regex(
        """\b(USD|EUR|GBP|JPY|CNY|RUB|BYN|CAD|AUD|CHF|HKD|SGD|SEK|NOK|DKK|""" +
        """NZD|MXN|BRL|KRW|INR|ZAR|TRY|PLN|THB|IDR|MYR|PHP|CZK|ILS|CLP|""" +
        """BTC|ETH|BNB|XRP|ADA|SOL|DOGE|DOT|USDT|USDC)\b""",
        RegexOption.IGNORE_CASE
    )
    private val functionPattern = Regex(
        """\b(sin|cos|tan|asin|acos|atan|sinh|cosh|tanh|""" +
        """sqrt|cbrt|abs|ceil|floor|round|""" +
        """log|log10|log2|ln|exp|pow|""" +
        """min|max|avg|sum|""" +
        """pi|e|tau)\b""",
        RegexOption.IGNORE_CASE
    )
    private val keywordPattern = Regex(
        """\b(in|to|as|of|per|from|plus|minus|times|divided by|""" +
        """today|now|yesterday|tomorrow)\b""",
        RegexOption.IGNORE_CASE
    )
    private val commentPattern = Regex("""(//|#).*$""", RegexOption.MULTILINE)

    override fun filter(text: AnnotatedString): TransformedText {
        val highlighted = buildAnnotatedString {
            append(text.text)

            // Apply comment highlighting first (highest priority)
            commentPattern.findAll(text.text).forEach { match ->
                addStyle(SpanStyle(color = colors.comment), match.range.first, match.range.last + 1)
            }

            // Find comment ranges to skip other highlighting within them
            val commentRanges = commentPattern.findAll(text.text).map { it.range }.toList()
            fun isInComment(index: Int) = commentRanges.any { index in it }

            // Apply other highlighting (skip if in comment)
            currencyPattern.findAll(text.text).forEach { match ->
                if (!isInComment(match.range.first)) {
                    addStyle(SpanStyle(color = colors.currency), match.range.first, match.range.last + 1)
                }
            }

            functionPattern.findAll(text.text).forEach { match ->
                if (!isInComment(match.range.first)) {
                    addStyle(SpanStyle(color = colors.function), match.range.first, match.range.last + 1)
                }
            }

            unitPattern.findAll(text.text).forEach { match ->
                if (!isInComment(match.range.first)) {
                    addStyle(SpanStyle(color = colors.unit), match.range.first, match.range.last + 1)
                }
            }

            keywordPattern.findAll(text.text).forEach { match ->
                if (!isInComment(match.range.first)) {
                    addStyle(SpanStyle(color = colors.keyword), match.range.first, match.range.last + 1)
                }
            }

            numberPattern.findAll(text.text).forEach { match ->
                if (!isInComment(match.range.first)) {
                    addStyle(SpanStyle(color = colors.number), match.range.first, match.range.last + 1)
                }
            }

            operatorPattern.findAll(text.text).forEach { match ->
                if (!isInComment(match.range.first)) {
                    addStyle(SpanStyle(color = colors.operator), match.range.first, match.range.last + 1)
                }
            }
        }

        return TransformedText(highlighted, OffsetMapping.Identity)
    }
}

/**
 * Standalone calculator pane for use in split views.
 */
@Composable
fun CalculatorPane(
    modifier: Modifier = Modifier,
    paneId: String,
    viewModel: CalculatorViewModel = viewModel(key = paneId)
) {
    Column(modifier = modifier.fillMaxSize()) {
        CalculatorScreen(
            modifier = Modifier.weight(1f),
            viewModel = viewModel
        )
    }
}
