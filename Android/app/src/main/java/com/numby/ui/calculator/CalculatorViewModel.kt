package com.numby.ui.calculator

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.numby.EvaluationResult
import com.numby.NumbyApplication
import com.numby.NumbyWrapper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class CalculatorState(
    val inputText: String = "",
    val results: List<String?> = emptyList(),
    val isEvaluating: Boolean = false
)

@OptIn(FlowPreview::class)
class CalculatorViewModel : ViewModel() {
    private val numby = NumbyWrapper()

    private val _state = MutableStateFlow(CalculatorState())
    val state: StateFlow<CalculatorState> = _state.asStateFlow()

    private val inputFlow = MutableStateFlow("")

    init {
        // Load config to get saved currency rates
        NumbyApplication.getInstance().getConfigPath()?.let { path ->
            numby.loadConfig(path)
        }

        // Debounce input changes for evaluation
        viewModelScope.launch {
            inputFlow
                .debounce(100) // 100ms debounce like iOS
                .collect { text ->
                    evaluateAllLines(text)
                }
        }

        // Listen for currency rate updates
        viewModelScope.launch {
            NumbyApplication.getInstance().ratesUpdatedEvent.collect { json ->
                numby.setCurrencyRatesJson(json)
                // Re-evaluate current input with new rates
                evaluateAllLines(_state.value.inputText)
            }
        }
    }

    fun onInputChange(text: String) {
        _state.update { it.copy(inputText = text) }
        inputFlow.value = text
    }

    private suspend fun evaluateAllLines(text: String) {
        if (text.isBlank()) {
            _state.update { it.copy(results = emptyList(), isEvaluating = false) }
            return
        }

        _state.update { it.copy(isEvaluating = true) }

        val lines = text.split("\n")
        val results = withContext(Dispatchers.Default) {
            lines.map { line ->
                if (line.isBlank()) {
                    null
                } else {
                    val result = numby.evaluate(line)
                    if (result.isSuccess) {
                        result.formatted
                    } else {
                        null
                    }
                }
            }
        }

        _state.update { it.copy(results = results, isEvaluating = false) }
    }

    fun clear() {
        _state.update { CalculatorState() }
        inputFlow.value = ""
        numby.clearHistory()
        numby.clearVariables()
    }

    fun clearHistory() {
        numby.clearHistory()
        numby.clearVariables()
    }

    fun setLocale(locale: String) {
        numby.setLocale(locale)
    }

    fun setCurrencyRates(json: String) {
        numby.setCurrencyRatesJson(json)
    }

    override fun onCleared() {
        super.onCleared()
        numby.close()
    }
}
