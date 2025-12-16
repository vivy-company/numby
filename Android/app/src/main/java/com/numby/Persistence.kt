package com.numby

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

data class HistoryEntry(
    val expression: String,
    val result: String,
    val timestamp: Long = System.currentTimeMillis()
)

object Persistence {
    private const val PREFS_NAME = "numby_history"
    private const val KEY_HISTORY = "history"
    private const val MAX_HISTORY_ENTRIES = 100

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun getHistory(context: Context): List<HistoryEntry> {
        val prefs = getPrefs(context)
        val jsonString = prefs.getString(KEY_HISTORY, null) ?: return emptyList()

        return try {
            val jsonArray = JSONArray(jsonString)
            (0 until jsonArray.length()).map { i ->
                val obj = jsonArray.getJSONObject(i)
                HistoryEntry(
                    expression = obj.getString("expression"),
                    result = obj.getString("result"),
                    timestamp = obj.optLong("timestamp", System.currentTimeMillis())
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun addHistoryEntry(context: Context, expression: String, result: String) {
        val history = getHistory(context).toMutableList()

        // Remove duplicate if exists
        history.removeAll { it.expression == expression }

        // Add new entry at the beginning
        history.add(0, HistoryEntry(expression, result))

        // Limit to max entries
        val trimmedHistory = history.take(MAX_HISTORY_ENTRIES)

        saveHistory(context, trimmedHistory)
    }

    fun clearHistory(context: Context) {
        val prefs = getPrefs(context)
        prefs.edit().remove(KEY_HISTORY).apply()
    }

    private fun saveHistory(context: Context, history: List<HistoryEntry>) {
        val jsonArray = JSONArray()
        history.forEach { entry ->
            val obj = JSONObject().apply {
                put("expression", entry.expression)
                put("result", entry.result)
                put("timestamp", entry.timestamp)
            }
            jsonArray.put(obj)
        }

        val prefs = getPrefs(context)
        prefs.edit().putString(KEY_HISTORY, jsonArray.toString()).apply()
    }
}
