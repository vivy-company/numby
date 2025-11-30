/**
 * Syntax highlighting for calculator expressions
 */

import type { SyntaxColors } from "./types";

interface HighlightToken {
  text: string;
  color: string;
}

// Regex patterns for syntax highlighting (from CalculatorImageRenderer.swift)
const PATTERNS: [RegExp, keyof SyntaxColors][] = [
  // Comments first (they override everything)
  [/(\/\/|#).*$/gm, "comments"],
  // Numbers
  [/\b\d+(\.\d+)?\b/g, "numbers"],
  // Operators
  [/[+\-*/()^%=]/g, "operators"],
  // Currency codes
  [
    /\b(USD|EUR|JPY|GBP|CNY|RUB|BYN|BTC|ETH|AUD|CAD|CHF|HKD|INR|KRW|MXN|NOK|NZD|SEK|SGD|TRY|ZAR)\b/gi,
    "currency",
  ],
  // Currency words
  [
    /\b(dollars?|euros?|pounds?|yen|yuan|rmb|rupees?|rubles?|won|francs?|pesos?|krona|krone|lira|bitcoin|ethereum)\b/gi,
    "currency",
  ],
  // Units
  [
    /\b(km|m|cm|mm|kg|g|mg|lb|oz|mi|ft|in|yd|l|ml|gal|pt|qt|mph|kmh|kph|ms|s|min|hr|day|week|month|year|°C|°F|K|celsius|fahrenheit|kelvin)\b/gi,
    "units",
  ],
  // Keywords
  [/\b(in|to|as|of|per|from|into|plus|minus|times|divided by)\b/gi, "keywords"],
  // Functions
  [
    /\b(sin|cos|tan|asin|acos|atan|sinh|cosh|tanh|sqrt|cbrt|ln|log|log10|log2|abs|round|floor|ceil|exp|pow|min|max|avg|sum)\b/gi,
    "functions",
  ],
  // Constants
  [/\b(pi|e|tau|phi|true|false|inf|infinity|nan)\b/gi, "constants"],
];

/**
 * Tokenize an expression with syntax highlighting
 */
export function highlightExpression(
  text: string,
  colors: SyntaxColors
): HighlightToken[] {
  // Track which character indices have been assigned a color
  const colorMap = new Map<number, string>();

  // Initialize with default text color
  for (let i = 0; i < text.length; i++) {
    colorMap.set(i, colors.text);
  }

  // Apply patterns in order (later patterns can override)
  for (const [pattern, colorKey] of PATTERNS) {
    const regex = new RegExp(pattern.source, pattern.flags);
    let match;

    while ((match = regex.exec(text)) !== null) {
      const start = match.index;
      const end = start + match[0].length;
      const color = colors[colorKey];

      for (let i = start; i < end; i++) {
        colorMap.set(i, color);
      }
    }
  }

  // Convert to tokens (merge consecutive chars with same color)
  const tokens: HighlightToken[] = [];
  let currentToken: HighlightToken | null = null;

  for (let i = 0; i < text.length; i++) {
    const color = colorMap.get(i)!;
    const char = text[i];

    if (currentToken && currentToken.color === color) {
      currentToken.text += char;
    } else {
      if (currentToken) {
        tokens.push(currentToken);
      }
      currentToken = { text: char, color };
    }
  }

  if (currentToken) {
    tokens.push(currentToken);
  }

  return tokens;
}

/**
 * Render highlighted expression as HTML spans
 */
export function renderHighlightedHTML(
  text: string,
  colors: SyntaxColors
): string {
  const tokens = highlightExpression(text, colors);
  return tokens
    .map(
      (t) =>
        `<span style="color: ${t.color}">${escapeHtml(t.text)}</span>`
    )
    .join("");
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
