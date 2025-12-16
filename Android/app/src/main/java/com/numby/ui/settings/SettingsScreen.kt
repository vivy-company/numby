package com.numby.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import android.content.Intent
import android.net.Uri
import com.numby.NumbyApplication
import com.numby.NumbyWrapper
import com.numby.R
import com.numby.getFontFamily
import com.numby.getFontSize
import com.numby.getLastRatesFetch
import com.numby.getLocale
import com.numby.getSyntaxHighlighting
import com.numby.getTheme
import com.numby.setFontFamily
import com.numby.setFontSize
import com.numby.setLastRatesFetch
import com.numby.setLocale
import com.numby.setSyntaxHighlighting
import com.numby.setTheme
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import com.numby.ui.theme.AllThemes
import com.numby.ui.theme.NumbyTheme as ThemeModel
import com.numby.ui.theme.getThemeByName
import com.numby.ui.theme.searchThemes
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val dataStore = NumbyApplication.getInstance().settingsDataStore

    var showLanguageDialog by remember { mutableStateOf(false) }
    var showThemeDialog by remember { mutableStateOf(false) }
    var showFontSizeDialog by remember { mutableStateOf(false) }
    var showFontFamilyDialog by remember { mutableStateOf(false) }
    var currentLocale by remember { mutableStateOf("en-US") }
    var currentTheme by remember { mutableStateOf("mocha") }
    var currentFontSize by remember { mutableStateOf("medium") }
    var currentFontFamily by remember { mutableStateOf("default") }
    var syntaxHighlighting by remember { mutableStateOf(true) }
    var isUpdatingRates by remember { mutableStateOf(false) }
    var apiRatesDate by remember { mutableStateOf<String?>(null) }
    var lastRatesFetch by remember { mutableStateOf<String?>(null) }
    var ratesAreStale by remember { mutableStateOf(false) }

    // Load current settings
    LaunchedEffect(Unit) {
        currentLocale = dataStore.getLocale().first() ?: "en-US"
        currentTheme = dataStore.getTheme().first()
        currentFontSize = dataStore.getFontSize().first()
        currentFontFamily = dataStore.getFontFamily().first()
        syntaxHighlighting = dataStore.getSyntaxHighlighting().first()
        apiRatesDate = NumbyWrapper.getApiRatesDate()
        lastRatesFetch = dataStore.getLastRatesFetch().first()
        ratesAreStale = NumbyWrapper.needsCurrencyUpdate()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = null
                        )
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
        ) {
            // Language section
            SettingsSection(title = stringResource(R.string.language)) {
                val localeName = remember(currentLocale) {
                    NumbyWrapper.getAvailableLocales()
                        .find { it.first == currentLocale }
                        ?.second ?: currentLocale
                }

                ListItem(
                    headlineContent = { Text(stringResource(R.string.language)) },
                    supportingContent = { Text(localeName) },
                    modifier = Modifier.clickable { showLanguageDialog = true }
                )
            }

            HorizontalDivider()

            // Appearance section
            SettingsSection(title = stringResource(R.string.appearance)) {
                val themeName = getThemeDisplayName(currentTheme)
                val fontSizeDisplayName = when (currentFontSize) {
                    "small" -> stringResource(R.string.font_size_small)
                    "medium" -> stringResource(R.string.font_size_medium)
                    "large" -> stringResource(R.string.font_size_large)
                    "extra_large" -> stringResource(R.string.font_size_extra_large)
                    else -> stringResource(R.string.font_size_medium)
                }
                val fontFamilyDisplayName = if (currentFontFamily == "default") {
                    stringResource(R.string.font_default)
                } else {
                    currentFontFamily
                }

                ListItem(
                    headlineContent = { Text(stringResource(R.string.theme)) },
                    supportingContent = { Text(themeName) },
                    trailingContent = {
                        ThemePreviewDots(currentTheme)
                    },
                    modifier = Modifier.clickable { showThemeDialog = true }
                )

                ListItem(
                    headlineContent = { Text(stringResource(R.string.font_size)) },
                    supportingContent = { Text(fontSizeDisplayName) },
                    modifier = Modifier.clickable { showFontSizeDialog = true }
                )

                ListItem(
                    headlineContent = { Text(stringResource(R.string.font)) },
                    supportingContent = { Text(fontFamilyDisplayName) },
                    modifier = Modifier.clickable { showFontFamilyDialog = true }
                )

                ListItem(
                    headlineContent = { Text(stringResource(R.string.syntax_highlighting)) },
                    supportingContent = { Text(stringResource(R.string.syntax_highlighting_desc)) },
                    trailingContent = {
                        Switch(
                            checked = syntaxHighlighting,
                            onCheckedChange = { enabled ->
                                syntaxHighlighting = enabled
                                scope.launch {
                                    dataStore.setSyntaxHighlighting(enabled)
                                }
                            }
                        )
                    }
                )
            }

            HorizontalDivider()

            // Currency section
            SettingsSection(title = stringResource(R.string.currency)) {
                // API Rates Date (when the API data was published)
                ListItem(
                    headlineContent = { Text(stringResource(R.string.api_rates_date)) },
                    supportingContent = {
                        Text(
                            text = apiRatesDate ?: stringResource(R.string.unknown),
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                )

                // Last Fetched (when user clicked update)
                ListItem(
                    headlineContent = { Text(stringResource(R.string.last_fetched)) },
                    supportingContent = {
                        Text(
                            text = lastRatesFetch ?: stringResource(R.string.never),
                            color = if (ratesAreStale) MaterialTheme.colorScheme.error
                                   else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    },
                    trailingContent = {
                        if (ratesAreStale) {
                            Text(
                                text = stringResource(R.string.rates_stale),
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.labelSmall
                            )
                        }
                    }
                )

                // Update button
                ListItem(
                    headlineContent = {
                        Text(
                            text = if (isUpdatingRates) stringResource(R.string.updating)
                                   else stringResource(R.string.update_rates),
                            color = if (isUpdatingRates) MaterialTheme.colorScheme.onSurfaceVariant
                                   else MaterialTheme.colorScheme.primary
                        )
                    },
                    trailingContent = {
                        if (isUpdatingRates) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp
                            )
                        }
                    },
                    modifier = Modifier.clickable(enabled = !isUpdatingRates) {
                        scope.launch {
                            isUpdatingRates = true
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
                                    // Update timestamps
                                    apiRatesDate = NumbyWrapper.getApiRatesDate()
                                    val now = SimpleDateFormat("MMM d, yyyy HH:mm", Locale.getDefault()).format(Date())
                                    dataStore.setLastRatesFetch(now)
                                    lastRatesFetch = now
                                    ratesAreStale = false
                                    android.widget.Toast.makeText(context, R.string.rates_updated, android.widget.Toast.LENGTH_SHORT).show()
                                }
                            } finally {
                                isUpdatingRates = false
                            }
                        }
                    }
                )

                // API Info
                ListItem(
                    headlineContent = {
                        Text(
                            text = stringResource(R.string.currency_api_info),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                )
            }

            HorizontalDivider()

            // About section
            SettingsSection(title = stringResource(R.string.about)) {
                val versionName = "1.0.0"
                ListItem(
                    headlineContent = { Text("Numby") },
                    supportingContent = { Text(stringResource(R.string.version, versionName)) }
                )

                ListItem(
                    headlineContent = { Text("GitHub") },
                    supportingContent = { Text("github.com/vivy-company/numby") },
                    modifier = Modifier.clickable {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/vivy-company/numby"))
                        context.startActivity(intent)
                    }
                )
            }
        }
    }

    // Language bottom sheet
    if (showLanguageDialog) {
        LanguagePickerSheet(
            currentLocale = currentLocale,
            onLocaleSelected = { code ->
                scope.launch {
                    dataStore.setLocale(code)
                    currentLocale = code
                    NumbyWrapper().use { it.setLocale(code) }
                }
                showLanguageDialog = false
            },
            onDismiss = { showLanguageDialog = false }
        )
    }

    // Theme picker bottom sheet
    if (showThemeDialog) {
        ThemePickerSheet(
            currentTheme = currentTheme,
            onThemeSelected = { themeName ->
                scope.launch {
                    dataStore.setTheme(themeName)
                    currentTheme = themeName
                }
                showThemeDialog = false
            },
            onDismiss = { showThemeDialog = false }
        )
    }

    // Font size picker bottom sheet
    if (showFontSizeDialog) {
        FontSizePickerSheet(
            currentSize = currentFontSize,
            onSizeSelected = { size ->
                scope.launch {
                    dataStore.setFontSize(size)
                    currentFontSize = size
                }
                showFontSizeDialog = false
            },
            onDismiss = { showFontSizeDialog = false }
        )
    }

    // Font family picker bottom sheet
    if (showFontFamilyDialog) {
        FontFamilyPickerSheet(
            currentFont = currentFontFamily,
            onFontSelected = { font ->
                scope.launch {
                    dataStore.setFontFamily(font)
                    currentFontFamily = font
                }
                showFontFamilyDialog = false
            },
            onDismiss = { showFontFamilyDialog = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun LanguagePickerSheet(
    currentLocale: String,
    onLocaleSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState()
    val availableLocales = remember { NumbyWrapper.getAvailableLocales() }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
        ) {
            Text(
                text = stringResource(R.string.language),
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(bottom = 16.dp)
            )

            availableLocales.forEach { (code, name) ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onLocaleSelected(code) }
                        .padding(vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = code == currentLocale,
                        onClick = null
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = name,
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ThemePickerSheet(
    currentTheme: String,
    onThemeSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var searchQuery by remember { mutableStateOf("") }
    val filteredThemes = remember(searchQuery) {
        searchThemes(searchQuery)
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxSize(0.9f)
                .padding(horizontal = 16.dp)
        ) {
            Text(
                text = stringResource(R.string.theme),
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            // Results on top
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(6.dp),
                reverseLayout = false
            ) {
                items(filteredThemes) { theme ->
                    ThemeOptionItem(
                        theme = theme,
                        isSelected = currentTheme == theme.name,
                        onClick = { onThemeSelected(theme.name) }
                    )
                }
            }

            // Search at bottom (closer to keyboard)
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text(stringResource(R.string.search_themes)) },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 12.dp, bottom = 16.dp),
                singleLine = true
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FontSizePickerSheet(
    currentSize: String,
    onSizeSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState()
    val fontSizes = listOf(
        "small" to R.string.font_size_small,
        "medium" to R.string.font_size_medium,
        "large" to R.string.font_size_large,
        "extra_large" to R.string.font_size_extra_large
    )

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
        ) {
            Text(
                text = stringResource(R.string.font_size),
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(bottom = 16.dp)
            )

            fontSizes.forEach { (size, labelRes) ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onSizeSelected(size) }
                        .padding(vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = size == currentSize,
                        onClick = null
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = stringResource(labelRes),
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FontFamilyPickerSheet(
    currentFont: String,
    onFontSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    // Get available monospaced fonts
    val monospacedFonts = remember {
        val fonts = mutableListOf("default" to "System Default")
        // Common monospaced fonts available on Android
        val commonMonoFonts = listOf(
            "monospace" to "Monospace",
            "Roboto Mono" to "Roboto Mono",
            "Droid Sans Mono" to "Droid Sans Mono",
            "Courier" to "Courier",
            "Cutive Mono" to "Cutive Mono"
        )

        // Check which fonts are available
        for ((fontName, displayName) in commonMonoFonts) {
            try {
                val typeface = android.graphics.Typeface.create(fontName, android.graphics.Typeface.NORMAL)
                if (typeface != android.graphics.Typeface.DEFAULT) {
                    fonts.add(fontName to displayName)
                }
            } catch (e: Exception) {
                // Font not available
            }
        }

        // Always add monospace as it's guaranteed
        if (!fonts.any { it.first == "monospace" }) {
            fonts.add("monospace" to "Monospace")
        }

        fonts
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
        ) {
            Text(
                text = stringResource(R.string.select_font),
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.padding(bottom = 16.dp)
            )

            LazyColumn(
                modifier = Modifier.heightIn(max = 400.dp)
            ) {
                items(monospacedFonts) { (fontKey, fontName) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onFontSelected(fontKey) }
                            .padding(vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = fontKey == currentFont,
                            onClick = null
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = fontName,
                            style = MaterialTheme.typography.bodyLarge,
                            fontFamily = if (fontKey == "default") null
                                        else androidx.compose.ui.text.font.FontFamily.Monospace
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun ThemeOptionItem(
    theme: ThemeModel,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val previewColors = listOf(
        theme.syntax.background,
        theme.syntax.text,
        theme.syntax.keyword,
        theme.syntax.function,
        theme.syntax.results
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(theme.syntax.background)
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = if (isSelected) MaterialTheme.colorScheme.primary
                else theme.syntax.text.copy(alpha = 0.2f),
                shape = RoundedCornerShape(12.dp)
            )
            .clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Theme info
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = theme.name,
                        style = MaterialTheme.typography.titleSmall,
                        color = theme.syntax.text
                    )
                    if (isSelected) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = null,
                            tint = theme.syntax.keyword,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
                Text(
                    text = if (theme.isDark) "Dark" else "Light",
                    style = MaterialTheme.typography.bodySmall,
                    color = theme.syntax.text.copy(alpha = 0.6f)
                )
            }

            // Color preview strip
            Row(
                horizontalArrangement = Arrangement.spacedBy(3.dp)
            ) {
                previewColors.drop(1).forEach { color ->
                    Box(
                        modifier = Modifier
                            .size(16.dp)
                            .clip(CircleShape)
                            .background(color)
                            .border(1.dp, theme.syntax.text.copy(alpha = 0.1f), CircleShape)
                    )
                }
            }
        }
    }
}

@Composable
private fun ThemePreviewDots(theme: String) {
    val themeModel = getThemeByName(theme)
    val colors = if (themeModel != null) {
        listOf(themeModel.syntax.keyword, themeModel.syntax.function, themeModel.syntax.currency)
    } else {
        listOf(Color.Blue, Color.Magenta, Color.Green)
    }

    Row(
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        colors.forEach { color ->
            Box(
                modifier = Modifier
                    .size(16.dp)
                    .clip(CircleShape)
                    .background(color)
            )
        }
    }
}

private fun getThemeDisplayName(theme: String): String {
    return getThemeByName(theme)?.name ?: theme
}

@Composable
private fun SettingsSection(
    title: String,
    content: @Composable () -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )
        content()
    }
}

private suspend fun fetchCurrencyRates(): String? = withContext(Dispatchers.IO) {
    val primaryUrl = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json"
    val fallbackUrl = "https://latest.currency-api.pages.dev/v1/currencies/usd.min.json"

    try {
        val client = OkHttpClient()

        // Try primary URL first
        var request = Request.Builder().url(primaryUrl).build()
        client.newCall(request).execute().use { response ->
            if (response.isSuccessful) {
                return@withContext response.body?.string()
            }
        }

        // Try fallback URL
        request = Request.Builder().url(fallbackUrl).build()
        client.newCall(request).execute().use { response ->
            if (response.isSuccessful) {
                return@withContext response.body?.string()
            }
        }

        null
    } catch (e: Exception) {
        null
    }
}
