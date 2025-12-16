package com.numby

import java.io.Closeable

/**
 * JNI wrapper for the Numby Rust library.
 *
 * This class provides a Kotlin-friendly interface to the native Numby calculator engine.
 * Each instance creates a new evaluation context that maintains its own state (variables, history).
 *
 * Usage:
 * ```kotlin
 * NumbyWrapper().use { numby ->
 *     val result = numby.evaluate("5 km in miles")
 *     println(result.formatted) // "3.11 miles"
 * }
 * ```
 */
class NumbyWrapper : Closeable {
    private var contextPtr: Long = 0

    init {
        contextPtr = contextNew()
    }

    /**
     * Evaluate an expression and return the result.
     *
     * @param expression The expression to evaluate (e.g., "5 km in miles", "100 + 20%")
     * @return EvaluationResult containing the value, formatted string, unit, and any error
     */
    fun evaluate(expression: String): EvaluationResult {
        if (contextPtr == 0L) {
            return EvaluationResult.error("Context not initialized")
        }
        return evaluate(contextPtr, expression)
    }

    /**
     * Set a variable in the calculator context.
     *
     * @param name Variable name
     * @param value Numeric value
     * @param unit Optional unit string
     * @return true if successful, false otherwise
     */
    fun setVariable(name: String, value: Double, unit: String? = null): Boolean {
        if (contextPtr == 0L) return false
        return setVariable(contextPtr, name, value, unit) == 0
    }

    /**
     * Load configuration from a file.
     *
     * @param path Path to the configuration JSON file
     * @return true if successful, false otherwise
     */
    fun loadConfig(path: String): Boolean {
        if (contextPtr == 0L) return false
        return loadConfig(contextPtr, path) == 0
    }

    /**
     * Set the locale for the calculator.
     *
     * @param locale Locale code (e.g., "en-US", "de", "zh-CN")
     * @return true if successful, false otherwise
     */
    fun setLocale(locale: String): Boolean {
        if (contextPtr == 0L) return false
        return setLocale(contextPtr, locale) == 0
    }

    /**
     * Set currency rates from JSON data.
     *
     * Expected format: {"date": "2025-01-01", "usd": {"eur": 0.92, "gbp": 0.79, ...}}
     *
     * @param jsonData JSON string with currency rates
     * @return true if successful, false otherwise
     */
    fun setCurrencyRatesJson(jsonData: String): Boolean {
        if (contextPtr == 0L) return false
        return setCurrencyRatesJson(contextPtr, jsonData) == 0
    }

    /**
     * Clear the evaluation history.
     *
     * @return true if successful, false otherwise
     */
    fun clearHistory(): Boolean {
        if (contextPtr == 0L) return false
        return clearHistory(contextPtr) == 0
    }

    /**
     * Clear all variables.
     *
     * @return true if successful, false otherwise
     */
    fun clearVariables(): Boolean {
        if (contextPtr == 0L) return false
        return clearVariables(contextPtr) == 0
    }

    /**
     * Get the number of items in the history.
     *
     * @return History count, or -1 on error
     */
    fun getHistoryCount(): Int {
        if (contextPtr == 0L) return -1
        return getHistoryCount(contextPtr)
    }

    /**
     * Clean up native resources.
     */
    override fun close() {
        if (contextPtr != 0L) {
            contextFree(contextPtr)
            contextPtr = 0
        }
    }

    // JNI methods
    private external fun contextNew(): Long
    private external fun contextFree(ctx: Long)
    private external fun evaluate(ctx: Long, input: String): EvaluationResult
    private external fun setVariable(ctx: Long, name: String, value: Double, unit: String?): Int
    private external fun loadConfig(ctx: Long, path: String): Int
    private external fun setLocale(ctx: Long, locale: String): Int
    private external fun setCurrencyRatesJson(ctx: Long, jsonData: String): Int
    private external fun clearHistory(ctx: Long): Int
    private external fun clearVariables(ctx: Long): Int
    private external fun getHistoryCount(ctx: Long): Int

    companion object {
        init {
            System.loadLibrary("numby")
        }

        // Static JNI methods (no context required)
        @JvmStatic
        external fun getLocale(): String

        @JvmStatic
        external fun getLocalesCount(): Int

        @JvmStatic
        external fun getLocaleCode(index: Int): String?

        @JvmStatic
        external fun getLocaleName(index: Int): String?

        @JvmStatic
        external fun areRatesStale(): Int

        @JvmStatic
        external fun getRatesUpdateDate(): String?

        @JvmStatic
        external fun getApiRatesDate(): String?

        @JvmStatic
        external fun getDefaultConfigPath(): String?

        @JvmStatic
        external fun setConfigPath(path: String): Int

        /**
         * Get all available locales as a list of (code, name) pairs.
         */
        fun getAvailableLocales(): List<Pair<String, String>> {
            val count = getLocalesCount()
            return (0 until count).mapNotNull { index ->
                val code = getLocaleCode(index)
                val name = getLocaleName(index)
                if (code != null && name != null) {
                    code to name
                } else {
                    null
                }
            }
        }

        /**
         * Check if currency rates need to be updated.
         */
        fun needsCurrencyUpdate(): Boolean {
            return areRatesStale() == 1
        }
    }
}
