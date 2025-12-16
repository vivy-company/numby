package com.numby.ui.share

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb

/**
 * Renders calculator content as a styled image with macOS-style window frame
 */
object CalculatorImageRenderer {

    private const val TITLE_BAR_HEIGHT = 32f
    private const val CORNER_RADIUS = 12f
    private const val CONTENT_PADDING = 20f
    private const val TRAFFIC_LIGHT_SIZE = 12f
    private const val TRAFFIC_LIGHT_SPACING = 8f
    private const val LINE_SPACING = 6f
    private const val MIN_WIDTH = 350f
    private const val MAX_WIDTH = 700f
    private const val SHADOW_PADDING = 24f

    fun render(
        lines: List<Pair<String, String>>,
        backgroundColor: Color,
        textColor: Color,
        resultColor: Color,
        fontSize: Float = 16f,
        fontName: String = "monospace"
    ): Bitmap? {
        if (lines.isEmpty()) return null

        val scale = 2f // Retina-like quality
        val font = Typeface.MONOSPACE

        val textPaint = Paint().apply {
            isAntiAlias = true
            textSize = fontSize * scale
            typeface = font
            color = textColor.toArgb()
        }

        val resultPaint = Paint().apply {
            isAntiAlias = true
            textSize = fontSize * scale
            typeface = font
            color = resultColor.toArgb()
        }

        val titlePaint = Paint().apply {
            isAntiAlias = true
            textSize = 13f * scale
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            color = textColor.toArgb()
        }

        // Calculate sizes
        var maxExprWidth = 0f
        var maxResultWidth = 0f
        lines.forEach { (expr, result) ->
            maxExprWidth = maxOf(maxExprWidth, textPaint.measureText(expr))
            maxResultWidth = maxOf(maxResultWidth, resultPaint.measureText(result))
        }

        val lineHeight = (textPaint.fontMetrics.bottom - textPaint.fontMetrics.top + LINE_SPACING * scale)
        val totalTextHeight = lineHeight * lines.size
        val gapBetween = 40f * scale

        val frameWidth = maxOf(MIN_WIDTH * scale, minOf(maxExprWidth + gapBetween + maxResultWidth + CONTENT_PADDING * 2 * scale, MAX_WIDTH * scale))
        val frameHeight = TITLE_BAR_HEIGHT * scale + totalTextHeight + CONTENT_PADDING * 2 * scale

        val totalWidth = (frameWidth + SHADOW_PADDING * 2 * scale).toInt()
        val totalHeight = (frameHeight + SHADOW_PADDING * 2 * scale).toInt()

        val bitmap = Bitmap.createBitmap(totalWidth, totalHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Clear with transparent
        canvas.drawColor(android.graphics.Color.TRANSPARENT)

        val frameRect = RectF(
            SHADOW_PADDING * scale,
            SHADOW_PADDING * scale,
            SHADOW_PADDING * scale + frameWidth,
            SHADOW_PADDING * scale + frameHeight
        )

        // Draw shadow
        val shadowPaint = Paint().apply {
            isAntiAlias = true
            color = android.graphics.Color.argb(76, 0, 0, 0) // 30% black
            setShadowLayer(20f * scale, 0f, 8f * scale, android.graphics.Color.argb(76, 0, 0, 0))
        }
        canvas.drawRoundRect(frameRect, CORNER_RADIUS * scale, CORNER_RADIUS * scale, shadowPaint)

        // Draw frame background
        val framePaint = Paint().apply {
            isAntiAlias = true
            color = backgroundColor.toArgb()
        }
        canvas.drawRoundRect(frameRect, CORNER_RADIUS * scale, CORNER_RADIUS * scale, framePaint)

        // Draw title bar
        val titleBarRect = RectF(
            frameRect.left,
            frameRect.top,
            frameRect.right,
            frameRect.top + TITLE_BAR_HEIGHT * scale
        )

        val titleBarPaint = Paint().apply {
            isAntiAlias = true
            color = adjustColor(backgroundColor, 0.08f).toArgb()
        }

        // Draw title bar with rounded top corners only
        val titleBarPath = Path().apply {
            addRoundRect(
                titleBarRect,
                floatArrayOf(
                    CORNER_RADIUS * scale, CORNER_RADIUS * scale, // top left
                    CORNER_RADIUS * scale, CORNER_RADIUS * scale, // top right
                    0f, 0f, // bottom right
                    0f, 0f  // bottom left
                ),
                Path.Direction.CW
            )
        }
        canvas.drawPath(titleBarPath, titleBarPaint)

        // Draw separator line
        val separatorPaint = Paint().apply {
            isAntiAlias = true
            color = android.graphics.Color.argb(25, textColor.red.toInt() * 255, textColor.green.toInt() * 255, textColor.blue.toInt() * 255)
            strokeWidth = 0.5f * scale
        }
        canvas.drawLine(
            frameRect.left, titleBarRect.bottom,
            frameRect.right, titleBarRect.bottom,
            separatorPaint
        )

        // Draw traffic lights
        val trafficLightColors = listOf(
            android.graphics.Color.rgb(255, 95, 86),   // Red
            android.graphics.Color.rgb(255, 189, 46),  // Yellow
            android.graphics.Color.rgb(39, 201, 63)    // Green
        )
        val trafficPaint = Paint().apply { isAntiAlias = true }
        trafficLightColors.forEachIndexed { i, color ->
            trafficPaint.color = color
            val x = frameRect.left + 16f * scale + i * (TRAFFIC_LIGHT_SIZE + TRAFFIC_LIGHT_SPACING) * scale
            val y = titleBarRect.centerY()
            canvas.drawCircle(x + TRAFFIC_LIGHT_SIZE * scale / 2, y, TRAFFIC_LIGHT_SIZE * scale / 2, trafficPaint)
        }

        // Draw title "Numby"
        val title = "Numby"
        val titleWidth = titlePaint.measureText(title)
        val titleX = frameRect.centerX() - titleWidth / 2
        val titleY = titleBarRect.centerY() - (titlePaint.descent() + titlePaint.ascent()) / 2
        canvas.drawText(title, titleX, titleY, titlePaint)

        // Draw content
        val contentTop = titleBarRect.bottom + CONTENT_PADDING * scale
        val contentLeft = frameRect.left + CONTENT_PADDING * scale
        val contentRight = frameRect.right - CONTENT_PADDING * scale

        lines.forEachIndexed { index, (expr, result) ->
            val y = contentTop + lineHeight * (index + 0.7f)

            // Draw expression (left aligned)
            canvas.drawText(expr, contentLeft, y, textPaint)

            // Draw result (right aligned)
            val resultWidth = resultPaint.measureText(result)
            canvas.drawText(result, contentRight - resultWidth, y, resultPaint)
        }

        return bitmap
    }

    private fun adjustColor(color: Color, amount: Float): Color {
        val avg = (color.red + color.green + color.blue) / 3f
        val adjust = if (avg > 0.5f) -amount else amount
        return Color(
            red = (color.red + adjust).coerceIn(0f, 1f),
            green = (color.green + adjust).coerceIn(0f, 1f),
            blue = (color.blue + adjust).coerceIn(0f, 1f),
            alpha = color.alpha
        )
    }
}
