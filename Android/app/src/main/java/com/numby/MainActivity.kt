package com.numby

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.isImeVisible
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Surface
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.windowsizeclass.ExperimentalMaterial3WindowSizeClassApi
import androidx.compose.material3.windowsizeclass.WindowWidthSizeClass
import androidx.compose.material3.windowsizeclass.calculateWindowSizeClass
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import android.content.res.Configuration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.numby.ui.calculator.CalculatorScreen
import com.numby.ui.calculator.CalculatorViewModel
import com.numby.ui.calculator.InputAccessoryBar
import com.numby.ui.calculator.TabContainerScreen
import com.numby.ui.calculator.TabContainerState
import com.numby.ui.history.HistoryScreen
import com.numby.ui.settings.SettingsScreen
import com.numby.ui.split.SplitDirection
import com.numby.ui.share.CalculatorImageRenderer
import com.numby.ui.theme.LocalSyntaxColors
import com.numby.ui.theme.NumbyTheme
import com.numby.ui.theme.NumbyThemeByName
import com.numby.ui.theme.getSyntaxColorsByName
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request

class MainActivity : ComponentActivity() {
    @OptIn(ExperimentalMaterial3WindowSizeClassApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            val windowSizeClass = calculateWindowSizeClass(this)
            val dataStore = NumbyApplication.getInstance().settingsDataStore
            val theme by dataStore.getTheme().collectAsState(initial = "Catppuccin Mocha")

            NumbyThemeByName(themeName = theme) {
                NumbyApp(
                    isTablet = windowSizeClass.widthSizeClass >= WindowWidthSizeClass.Medium
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NumbyApp(isTablet: Boolean) {
    val navController = rememberNavController()
    val scope = rememberCoroutineScope()

    // Tab state for tablet mode (using remember instead of rememberSaveable due to complex nested types)
    var tabState by remember { mutableStateOf(TabContainerState()) }

    // Check and update currency rates on startup
    LaunchedEffect(Unit) {
        if (NumbyWrapper.needsCurrencyUpdate()) {
            scope.launch {
                try {
                    val json = fetchCurrencyRates()
                    if (json != null) {
                        val app = NumbyApplication.getInstance()
                        val configPath = app.getConfigPath()
                        NumbyWrapper().use { numby ->
                            if (configPath != null) {
                                numby.loadConfig(configPath)
                            }
                            numby.setCurrencyRatesJson(json)
                        }
                        // Notify all calculators about rate update
                        app.notifyRatesUpdated(json)
                    }
                } catch (e: Exception) {
                    // Silently fail - rates will be updated later
                }
            }
        }
    }

    NavHost(
        navController = navController,
        startDestination = "calculator",
        enterTransition = {
            fadeIn(animationSpec = tween(150, easing = LinearEasing))
        },
        exitTransition = {
            fadeOut(animationSpec = tween(150, easing = LinearEasing))
        },
        popEnterTransition = {
            fadeIn(animationSpec = tween(150, easing = LinearEasing))
        },
        popExitTransition = {
            fadeOut(animationSpec = tween(150, easing = LinearEasing))
        }
    ) {
        composable("calculator") {
            if (isTablet) {
                // Tablet layout with tabs and split panes
                TabletLayout(
                    tabState = tabState,
                    onTabStateChange = { tabState = it },
                    onNavigateToSettings = { navController.navigate("settings") },
                    onNavigateToHistory = { navController.navigate("history") }
                )
            } else {
                // Phone layout with iOS-style toolbar
                PhoneLayout(
                    onNavigateToSettings = { navController.navigate("settings") },
                    onNavigateToHistory = { navController.navigate("history") }
                )
            }
        }

        composable("settings") {
            SettingsScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable("history") {
            HistoryScreen(
                onNavigateBack = { navController.popBackStack() },
                onLoadEntry = { expression ->
                    navController.popBackStack()
                    // Will be handled by calculator screen
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class, androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
@Composable
private fun PhoneLayout(
    onNavigateToSettings: () -> Unit,
    onNavigateToHistory: () -> Unit
) {
    val context = LocalContext.current
    val syntaxColors = LocalSyntaxColors.current
    val scope = rememberCoroutineScope()
    val configuration = LocalConfiguration.current
    var calculatorText by remember { mutableStateOf("") }
    var calculatorResults by remember { mutableStateOf<List<String?>>(emptyList()) }
    var clearCalculator by remember { mutableStateOf<(() -> Unit)?>(null) }
    var showShareDialog by remember { mutableStateOf(false) }
    val isKeyboardVisible = WindowInsets.isImeVisible
    // Don't show accessory bar if using physical keyboard
    val hasHardwareKeyboard = configuration.keyboard != Configuration.KEYBOARD_NOKEYS
    val showAccessoryBar = isKeyboardVisible && !hasHardwareKeyboard

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Numby") },
                navigationIcon = {
                    // Left side: Settings, History
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(Icons.Default.Settings, contentDescription = stringResource(R.string.settings))
                    }
                },
                actions = {
                    // History button
                    IconButton(onClick = onNavigateToHistory) {
                        Icon(
                            painter = painterResource(id = R.drawable.ic_history),
                            contentDescription = stringResource(R.string.history)
                        )
                    }
                    // Share button
                    IconButton(onClick = {
                        if (calculatorText.isNotEmpty()) {
                            showShareDialog = true
                        }
                    }) {
                        Icon(Icons.Default.Share, contentDescription = stringResource(R.string.share))
                    }
                    // New calculation button
                    IconButton(onClick = {
                        // Save to history if not empty
                        if (calculatorText.isNotEmpty()) {
                            val result = calculatorResults.filterNotNull().filter { it.isNotEmpty() }.joinToString("\n")
                            Persistence.addHistoryEntry(context, calculatorText, result.ifEmpty { "No result" })
                        }
                        // Clear calculator
                        clearCalculator?.invoke()
                    }) {
                        Icon(Icons.Default.Add, contentDescription = stringResource(R.string.new_calculation))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = syntaxColors.background
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            CalculatorScreen(
                modifier = Modifier.weight(1f),
                onTextChange = { text, results ->
                    calculatorText = text
                    calculatorResults = results
                },
                onGetClearCallback = { callback ->
                    clearCalculator = callback
                }
            )

            // Accessory bar at layout level, shown only when software keyboard is visible
            if (showAccessoryBar) {
                InputAccessoryBar(
                    onInsert = { text ->
                        scope.launch {
                            NumbyApplication.getInstance().sendAccessoryAction(
                                NumbyApplication.AccessoryAction.Insert(text)
                            )
                        }
                    },
                    onBackspace = {
                        scope.launch {
                            NumbyApplication.getInstance().sendAccessoryAction(
                                NumbyApplication.AccessoryAction.Backspace
                            )
                        }
                    },
                    onNewline = {
                        scope.launch {
                            NumbyApplication.getInstance().sendAccessoryAction(
                                NumbyApplication.AccessoryAction.Newline
                            )
                        }
                    }
                )
            }
        }
    }

    // Share dialog matching iOS options
    if (showShareDialog) {
        ShareDialog(
            text = calculatorText,
            results = calculatorResults,
            onDismiss = { showShareDialog = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class, androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
@Composable
private fun TabletLayout(
    tabState: TabContainerState,
    onTabStateChange: (TabContainerState) -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToHistory: () -> Unit
) {
    val context = LocalContext.current
    val syntaxColors = LocalSyntaxColors.current
    val scope = rememberCoroutineScope()
    val configuration = LocalConfiguration.current
    var showMenu by remember { mutableStateOf(false) }
    val isKeyboardVisible = WindowInsets.isImeVisible
    // Don't show accessory bar if using physical keyboard
    val hasHardwareKeyboard = configuration.keyboard != Configuration.KEYBOARD_NOKEYS
    val showAccessoryBar = isKeyboardVisible && !hasHardwareKeyboard

    // Helper functions for splitting
    fun splitHorizontal() {
        tabState.selectedTab?.splitState?.getAllPaneIds()?.firstOrNull()?.let { paneId ->
            val newState = tabState.updateCurrentTabSplitState(
                tabState.selectedTab!!.splitState.splitPane(paneId, SplitDirection.HORIZONTAL)
            )
            onTabStateChange(newState)
        }
    }

    fun splitVertical() {
        tabState.selectedTab?.splitState?.getAllPaneIds()?.firstOrNull()?.let { paneId ->
            val newState = tabState.updateCurrentTabSplitState(
                tabState.selectedTab!!.splitState.splitPane(paneId, SplitDirection.VERTICAL)
            )
            onTabStateChange(newState)
        }
    }

    Scaffold(
        modifier = Modifier.onPreviewKeyEvent { event ->
            if (event.type == KeyEventType.KeyDown && event.isCtrlPressed) {
                when (event.key) {
                    Key.H -> {
                        splitHorizontal()
                        true
                    }
                    Key.J -> {
                        splitVertical()
                        true
                    }
                    Key.T -> {
                        onTabStateChange(tabState.addTab())
                        true
                    }
                    else -> false
                }
            } else {
                false
            }
        },
        topBar = {
            TopAppBar(
                title = { Text("Numby") },
                navigationIcon = {
                    IconButton(onClick = onNavigateToSettings) {
                        Icon(Icons.Default.Settings, contentDescription = stringResource(R.string.settings))
                    }
                },
                actions = {
                    // History button
                    IconButton(onClick = onNavigateToHistory) {
                        Icon(
                            painter = painterResource(id = R.drawable.ic_history),
                            contentDescription = stringResource(R.string.history)
                        )
                    }

                    // Share button
                    IconButton(onClick = {
                        // Share current tab content
                        tabState.selectedTab?.let { tab ->
                            // For simplicity, share functionality will be per-pane in split views
                        }
                    }) {
                        Icon(Icons.Default.Share, contentDescription = stringResource(R.string.share))
                    }

                    // New tab button
                    IconButton(onClick = {
                        onTabStateChange(tabState.addTab())
                    }) {
                        Icon(Icons.Default.Add, contentDescription = stringResource(R.string.new_calculation))
                    }

                    // More menu for split options
                    IconButton(onClick = { showMenu = true }) {
                        Icon(Icons.Default.MoreVert, contentDescription = null)
                    }

                    DropdownMenu(
                        expanded = showMenu,
                        onDismissRequest = { showMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("${stringResource(R.string.split_horizontal)} (Ctrl+H)") },
                            onClick = {
                                showMenu = false
                                splitHorizontal()
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("${stringResource(R.string.split_vertical)} (Ctrl+J)") },
                            onClick = {
                                showMenu = false
                                splitVertical()
                            }
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = syntaxColors.background
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            TabContainerScreen(
                state = tabState,
                onStateChange = onTabStateChange,
                modifier = Modifier.weight(1f)
            )

            // Accessory bar at layout level, shown only when software keyboard is visible
            if (showAccessoryBar) {
                InputAccessoryBar(
                    onInsert = { text ->
                        scope.launch {
                            NumbyApplication.getInstance().sendAccessoryAction(
                                NumbyApplication.AccessoryAction.Insert(text)
                            )
                        }
                    },
                    onBackspace = {
                        scope.launch {
                            NumbyApplication.getInstance().sendAccessoryAction(
                                NumbyApplication.AccessoryAction.Backspace
                            )
                        }
                    },
                    onNewline = {
                        scope.launch {
                            NumbyApplication.getInstance().sendAccessoryAction(
                                NumbyApplication.AccessoryAction.Newline
                            )
                        }
                    }
                )
            }
        }
    }
}

private suspend fun fetchCurrencyRates(): String? = withContext(Dispatchers.IO) {
    try {
        val client = OkHttpClient()
        val request = Request.Builder()
            .url("https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json")
            .build()

        client.newCall(request).execute().use { response ->
            if (response.isSuccessful) {
                response.body?.string()
            } else {
                null
            }
        }
    } catch (e: Exception) {
        null
    }
}

private fun Modifier.padding(dp: Int) = this.padding(dp.dp)

/**
 * Share bottom sheet with preview and action buttons
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ShareDialog(
    text: String,
    results: List<String?>,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val clipboardManager = context.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
    val theme by NumbyApplication.getInstance().settingsDataStore.getTheme().collectAsState(initial = "Catppuccin Mocha")
    val syntaxColors = getSyntaxColorsByName(theme)
    val sheetState = rememberModalBottomSheetState()

    // Build lines with results
    val lines = text.split("\n")
    val imageLines = lines.mapIndexedNotNull { index, line ->
        val trimmed = line.trim()
        if (trimmed.isNotBlank() && index < results.size && !results[index].isNullOrBlank()) {
            Pair(trimmed, results[index]!!)
        } else null
    }

    if (imageLines.isEmpty()) {
        onDismiss()
        return
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = syntaxColors.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp)
        ) {
            // Preview section
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp),
                shape = RoundedCornerShape(12.dp),
                color = syntaxColors.text.copy(alpha = 0.05f)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    imageLines.take(5).forEach { (expression, result) ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = expression,
                                style = androidx.compose.material3.MaterialTheme.typography.bodyMedium,
                                color = syntaxColors.text,
                                modifier = Modifier.weight(1f)
                            )
                            Text(
                                text = "= $result",
                                style = androidx.compose.material3.MaterialTheme.typography.bodyMedium,
                                color = syntaxColors.results
                            )
                        }
                        if (imageLines.indexOf(expression to result) < imageLines.take(5).lastIndex) {
                            Spacer(modifier = Modifier.height(8.dp))
                        }
                    }
                    if (imageLines.size > 5) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "+${imageLines.size - 5} more...",
                            style = androidx.compose.material3.MaterialTheme.typography.bodySmall,
                            color = syntaxColors.text.copy(alpha = 0.5f)
                        )
                    }
                }
            }

            // Action buttons row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                // Copy as Text
                ShareActionButton(
                    icon = {
                        Icon(
                            painter = painterResource(id = R.drawable.ic_copy),
                            contentDescription = null,
                            tint = syntaxColors.text,
                            modifier = Modifier.size(24.dp)
                        )
                    },
                    label = stringResource(R.string.copy_as_text),
                    backgroundColor = syntaxColors.text.copy(alpha = 0.1f),
                    textColor = syntaxColors.text,
                    onClick = {
                        val shareText = imageLines.joinToString("\n") { "${it.first} = ${it.second}" }
                        clipboardManager.setPrimaryClip(
                            android.content.ClipData.newPlainText("Numby", shareText)
                        )
                        android.widget.Toast.makeText(context, R.string.copied, android.widget.Toast.LENGTH_SHORT).show()
                        onDismiss()
                    }
                )

                // Copy as Image
                ShareActionButton(
                    icon = {
                        Icon(
                            painter = painterResource(id = R.drawable.ic_image),
                            contentDescription = null,
                            tint = syntaxColors.text,
                            modifier = Modifier.size(24.dp)
                        )
                    },
                    label = stringResource(R.string.copy_as_image),
                    backgroundColor = syntaxColors.text.copy(alpha = 0.1f),
                    textColor = syntaxColors.text,
                    onClick = {
                        val bitmap = CalculatorImageRenderer.render(
                            lines = imageLines,
                            backgroundColor = syntaxColors.background,
                            textColor = syntaxColors.text,
                            resultColor = syntaxColors.results
                        )
                        if (bitmap != null) {
                            val uri = saveBitmapToCache(context, bitmap)
                            if (uri != null) {
                                clipboardManager.setPrimaryClip(
                                    android.content.ClipData.newUri(context.contentResolver, "Numby Image", uri)
                                )
                            }
                            android.widget.Toast.makeText(context, R.string.copied, android.widget.Toast.LENGTH_SHORT).show()
                        }
                        onDismiss()
                    }
                )

                // Copy as Link
                ShareActionButton(
                    icon = {
                        Icon(
                            painter = painterResource(id = R.drawable.ic_link),
                            contentDescription = null,
                            tint = syntaxColors.text,
                            modifier = Modifier.size(24.dp)
                        )
                    },
                    label = stringResource(R.string.copy_as_link),
                    backgroundColor = syntaxColors.text.copy(alpha = 0.1f),
                    textColor = syntaxColors.text,
                    onClick = {
                        val urlText = imageLines.joinToString("\n") { "${it.first} = ${it.second}" }
                        val encoded = java.net.URLEncoder.encode(urlText, "UTF-8")
                        val url = "https://numby.app/?q=$encoded&theme=${java.net.URLEncoder.encode(theme, "UTF-8")}"
                        clipboardManager.setPrimaryClip(
                            android.content.ClipData.newPlainText("Numby Link", url)
                        )
                        android.widget.Toast.makeText(context, R.string.copied, android.widget.Toast.LENGTH_SHORT).show()
                        onDismiss()
                    }
                )
            }
        }
    }
}

@Composable
private fun ShareActionButton(
    icon: @Composable () -> Unit,
    label: String,
    backgroundColor: androidx.compose.ui.graphics.Color,
    textColor: androidx.compose.ui.graphics.Color,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally,
        modifier = Modifier
            .clickable(onClick = onClick)
            .padding(8.dp)
    ) {
        Surface(
            modifier = Modifier.size(56.dp),
            shape = CircleShape,
            color = backgroundColor
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = androidx.compose.ui.Alignment.Center
            ) {
                icon()
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = label,
            style = androidx.compose.material3.MaterialTheme.typography.labelSmall,
            color = textColor,
            maxLines = 2,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            modifier = Modifier.width(72.dp)
        )
    }
}

private fun saveBitmapToCache(context: android.content.Context, bitmap: Bitmap): android.net.Uri? {
    return try {
        val file = java.io.File(context.cacheDir, "numby_share.png")
        val outputStream = java.io.FileOutputStream(file)
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        outputStream.close()
        androidx.core.content.FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file
        )
    } catch (e: Exception) {
        null
    }
}
