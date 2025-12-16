package com.numby

/**
 * Result from evaluating an expression in the Numby calculator.
 *
 * @property value The numeric result value
 * @property formatted The formatted result string (e.g., "3.11 miles")
 * @property unit The unit string if present (e.g., "miles")
 * @property error Error message if evaluation failed, null on success
 */
data class EvaluationResult(
    val value: Double,
    val formatted: String?,
    val unit: String?,
    val error: String?
) {
    val isSuccess: Boolean get() = error == null
    val isError: Boolean get() = error != null

    companion object {
        fun success(value: Double, formatted: String?, unit: String?): EvaluationResult {
            return EvaluationResult(value, formatted, unit, null)
        }

        fun error(message: String): EvaluationResult {
            return EvaluationResult(0.0, null, null, message)
        }
    }
}
