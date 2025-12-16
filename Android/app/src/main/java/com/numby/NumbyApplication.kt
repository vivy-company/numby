package com.numby

import android.app.Application
import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.map
import java.io.File

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

class NumbyApplication : Application() {

    val settingsDataStore: DataStore<Preferences>
        get() = dataStore

    private var configPath: String? = null

    // Event to notify when currency rates are updated
    private val _ratesUpdatedEvent = MutableSharedFlow<String>()
    val ratesUpdatedEvent: SharedFlow<String> = _ratesUpdatedEvent.asSharedFlow()

    suspend fun notifyRatesUpdated(json: String) {
        _ratesUpdatedEvent.emit(json)
    }

    // Event for accessory bar input (used to send input to focused calculator)
    sealed class AccessoryAction {
        data class Insert(val text: String) : AccessoryAction()
        object Backspace : AccessoryAction()
        object Newline : AccessoryAction()
    }

    private val _accessoryAction = MutableSharedFlow<AccessoryAction>()
    val accessoryAction: SharedFlow<AccessoryAction> = _accessoryAction.asSharedFlow()

    suspend fun sendAccessoryAction(action: AccessoryAction) {
        _accessoryAction.emit(action)
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        initializeConfig()
        // Set global config path override for JNI calls EARLY
        configPath?.let { NumbyWrapper.setConfigPath(it) }
    }

    /**
     * Initialize the config file in app's internal storage.
     * This ensures currency rates can be persisted.
     */
    private fun initializeConfig() {
        val configDir = File(filesDir, "numby")
        if (!configDir.exists()) {
            configDir.mkdirs()
        }

        val configFile = File(configDir, "config.json")
        if (!configFile.exists()) {
            // Create default config
            val defaultConfig = """
{
  "locale": "en-US",
  "precision": 10,
  "currencies": {
    "USD": 1.0
  },
  "rates_updated_at": null,
  "api_rates_date": null
}
            """.trimIndent()
            configFile.writeText(defaultConfig)
        }
        configPath = configFile.absolutePath
    }

    /**
     * Get the config file path for loading/saving configuration.
     */
    fun getConfigPath(): String? = configPath

    companion object {
        private lateinit var instance: NumbyApplication

        fun getInstance(): NumbyApplication = instance

        // Preference keys
        val LOCALE_KEY = stringPreferencesKey("locale")
        val THEME_KEY = stringPreferencesKey("theme")
        val FONT_SIZE_KEY = stringPreferencesKey("font_size")
        val FONT_FAMILY_KEY = stringPreferencesKey("font_family")
        val SYNTAX_HIGHLIGHTING_KEY = stringPreferencesKey("syntax_highlighting")
        val LAST_RATES_FETCH_KEY = stringPreferencesKey("last_rates_fetch")
    }
}

// Extension functions for settings access
suspend fun DataStore<Preferences>.setLocale(locale: String) {
    edit { preferences ->
        preferences[NumbyApplication.LOCALE_KEY] = locale
    }
}

fun DataStore<Preferences>.getLocale(): Flow<String?> {
    return data.map { preferences ->
        preferences[NumbyApplication.LOCALE_KEY]
    }
}

suspend fun DataStore<Preferences>.setTheme(theme: String) {
    edit { preferences ->
        preferences[NumbyApplication.THEME_KEY] = theme
    }
}

fun DataStore<Preferences>.getTheme(): Flow<String> {
    return data.map { preferences ->
        // Default to "Catppuccin Mocha"
        preferences[NumbyApplication.THEME_KEY] ?: "Catppuccin Mocha"
    }
}

suspend fun DataStore<Preferences>.setFontSize(size: String) {
    edit { preferences ->
        preferences[NumbyApplication.FONT_SIZE_KEY] = size
    }
}

fun DataStore<Preferences>.getFontSize(): Flow<String> {
    return data.map { preferences ->
        preferences[NumbyApplication.FONT_SIZE_KEY] ?: "medium"
    }
}

suspend fun DataStore<Preferences>.setSyntaxHighlighting(enabled: Boolean) {
    edit { preferences ->
        preferences[NumbyApplication.SYNTAX_HIGHLIGHTING_KEY] = if (enabled) "true" else "false"
    }
}

fun DataStore<Preferences>.getSyntaxHighlighting(): Flow<Boolean> {
    return data.map { preferences ->
        preferences[NumbyApplication.SYNTAX_HIGHLIGHTING_KEY] != "false"
    }
}

suspend fun DataStore<Preferences>.setFontFamily(fontFamily: String) {
    edit { preferences ->
        preferences[NumbyApplication.FONT_FAMILY_KEY] = fontFamily
    }
}

fun DataStore<Preferences>.getFontFamily(): Flow<String> {
    return data.map { preferences ->
        preferences[NumbyApplication.FONT_FAMILY_KEY] ?: "default"
    }
}

suspend fun DataStore<Preferences>.setLastRatesFetch(timestamp: String) {
    edit { preferences ->
        preferences[NumbyApplication.LAST_RATES_FETCH_KEY] = timestamp
    }
}

fun DataStore<Preferences>.getLastRatesFetch(): Flow<String?> {
    return data.map { preferences ->
        preferences[NumbyApplication.LAST_RATES_FETCH_KEY]
    }
}
