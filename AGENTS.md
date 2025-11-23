# Agents in Numby

Numby is a natural language calculator that employs a modular architecture composed of specialized \"agents\" responsible for parsing, evaluating, and processing different aspects of user input. These agents work collaboratively to handle calculations, unit and currency conversions, percentage math, and human-friendly date/time queries. This document provides a current overview of the agents, their responsibilities, interaction rules, and guidelines for extension.

## Overview

The agent system in Numby is designed to process natural language expressions through a pipeline of specialized components. Input is first preprocessed (e.g., replacing natural language operators like \"plus\" with \"+\") and then routed to relevant agents based on detected patterns (e.g., unit keywords, percentage symbols, date phrases). The core evaluation uses the `fasteval2` library for safe, fast algebraic expression parsing.

Agents are modular functions or subroutines that handle domain-specific logic. They are invoked in priority order by `AgentRegistry` in `src/evaluator/mod.rs`.

Key principles:
- **Modularity**: Each agent focuses on a single responsibility (e.g., unit conversion vs. mathematical functions).
- **Pattern Matching**: Agents are triggered by regex patterns or keyword detection.
- **Error Handling**: Failed agent invocations return `None`, allowing fallback to basic evaluation.
- **State Management**: Agents share access to shared state (variables, history, units) via `Arc<Mutex<...>>` for thread-safety in the TUI.

## Core Agents

### 1. Preprocessing Agent
**Responsibility**: Normalizes input for downstream agents by handling comments, natural language substitutions, constants, and scales.

**Key Features**:
- Strips comments starting with `//` or `#`.
- Normalizes numbers: removes underscores/commas, converts simple word numbers (`one`..`ninety`) to digits, and separates numbers from currency symbols/uppercase unit codes (e.g., `100USD` → `100 USD`).
- Normalizes currency symbols both as prefixes and suffixes: `$100` / `100$` → `100 USD`, `€` → `EUR`, `£` → `GBP`, `¥` → `JPY`, `₹` → `INR`, `￥` → `CNY`.
- Replaces natural language operators: `plus` → `+`, `minus` → `-`, `times` / `multiplied by` → `*`, `divided by` / `divide by` → `/`, `subtract` → `-`, `and` / `with` → `+`, `mod` → `%` (case-insensitive).
- Injects constants: `pi` / `PI` → 3.14159..., `e` / `E` → 2.71828...
- Handles helper functions and symbols: `sqrt(x)` → `x^0.5`, `ln(x)` → base-10 log via change-of-base, Unicode `π`/`×`/`÷` normalization, and parses `sin 30` → `sin(30)`.
- Parses number formats: Binary (`0b10`), octal (`0o10`), hex (`0x10`).
- Applies scales: `k` / `kilo` / `thousand` → ×1000, `M` / `mega` / `million` → ×1e6, `G` / `giga` / `billion` → ×1e9, `T` / `tera` → ×1e12, `b` (billion) → ×1e9, plus suffix/word variants.
- Replaces variables from state (e.g., `x` → `10.0` or `10.0 m` if unit stored).

**Rules**:
- Variable replacement uses cached word-boundary regexes (capped at 1000 entries) and only touches the right side of assignments (`x = 5 m` keeps the left name intact).
- Scales, functions, and symbol replacements are applied before core evaluation.
- Currency symbols may be rewritten even in conversion expressions (with care to avoid breaking `100$ to eur`). Actual conversion happens later.
- If input is a history command (`sum`, `total`, `average` / `avg`, `prev`), preprocessing short-circuits to the history agent.

**Invocation**: Always first in the pipeline (`evaluate_expr` function).

**Example**:
- Input: `x plus 5 kilo meters`
- After: Variables replaced, `plus` → `+`, `kilo` → ×1000, units extracted: `5 * 1000 meters` → routed to math + unit agents.

### 2. Mathematical Expression Evaluator Agent
**Responsibility**: Core computation of algebraic expressions using `fasteval2::ez_eval`.

**Key Features**:
- Supports algebraic operations: `+`, `-`, `*`, `/`, `%`, parentheses, and functions (e.g., `sin`, `cos`, `sqrt`, `log10`, `ln`, `abs`, `round`, `ceil`, `floor`).
- Handles variable assignments: `x = 10 + 2` stores `(12.0, None)` in state (unit kept if present).
- Pretty-prints results: Uses `prettify_number` for abbreviations (e.g., `1000` → `1.0k`, `1e6` → `1.0M`).
- Understands history tokens inside larger expressions (`sum + 10`, `avg to USD`) by replacing them before evaluation.
- Supports inline unit algebra and conversions during evaluation (e.g., `100 usd to eur + 5`, `10 m * 2`).

**Rules**:
- Assignments (`=`) are detected and executed first; result is the assigned value, no history addition.
- Non-assignment expressions add to history (unless they are history commands or evaluation is flagged as preview-only).
- History tokens are resolved before math to allow mixed expressions.
- Unit algebra is lightweight (multiplication/division only; no squared unit tracking yet) and retains a single unit when possible.
- Errors (invalid expr) return `None` and bubble to the next agent.

**Invocation**: After preprocessing, if no special patterns (e.g., units, percentages) match.

**Example**:
- Input: `round(3.7) * pi`
- Output: `11.63` (rounded to 2 decimals for small numbers).

### 3. Percentage Calculation Agent
**Responsibility**: Handles percentage-based expressions like `X% of Y` or `X ±/* / Y%`.

**Key Features**:
- `X% of Y`: Computes `(X / 100) * Y`; preserves units/currencies from Y.
- `X + Y%`: Interprets as `X + (X * Y/100)` (percentage of base).
- `X - Y%`: `X - (X * Y/100)`.
- `X * Y%`: `X * (Y / 100)`.
- `X / Y%`: `X / (Y / 100)`.

**Rules**:
- Uses regex: `(\d+(?:\.\d+)?)%\s*of\s*(.+)` for "of", and `(\d+(?:\.\d+)?)\s*([+\-*/])\s*(\d+(?:\.\d+)?)%` for operations.
- Recursively evaluates `Y` or base via `evaluate_expr`.
- Short-circuits the pipeline; no further agents invoked.
- Preserves units: If Y has units (e.g., `50% of 200 USD` → `100 USD`).

**Invocation**: Checked after preprocessing, before units (regex priority).

**Example**:
- Input: `25% of 1000 EUR`
- Output: `250 EUR`.

### 4. Date/Time Agent
**Responsibility**: Answers natural date/time prompts and performs relative date math.

**Key Features**:
- Keywords: `now`, `today`, `tomorrow`, `yesterday`, `time in <city/tz>`, day-of-week phrases (`next monday`, `last friday`, `this sunday`).
- Relative offsets: `100 days from today`, `3 hours ago`, `2 weeks from now`, including chains like `yesterday + 2 days`.
- Date arithmetic: `2025-01-01 + 30 days`, `2025-02-10 - 1 week`.
- Differences: `days between 2025-01-01 and 2025-01-31` → returns day count.
- Timezone resolution via IANA names, common abbreviations, and auto-generated city aliases (built from `chrono_tz` list). Falls back to system timezone or `config.default_timezone`.
- Formatting respects `config.time_format` / `config.date_format` (default ISO).

**Rules**:
- Pattern-matched with cached regexes; triggered before unit/math agents.
- Does not add results to history (add_to_history = false) and returns plain strings, not numeric values.
- Uses local time when no timezone is supplied; `now in UTC` / `time in tokyo` use resolved offsets.

**Example**:
- Input: `time in tokyo`
- Output: `2025-11-23 22:15 JST` (example output; exact value depends on current time).

### 5. Unit Conversion Agent
**Responsibility**: Converts between compatible units and currencies.

**Key Features**:
- Triggered by `in` or `to` keywords: `value unit1 in unit2`.
- Supports categories from `config.json`: **length**, **time**, **temperature**, **area**, **volume**, **weight**, **angular**, **data**, **speed**, plus custom groups (e.g., energy).
- Treats currencies as another unit family using the shared rates map, so `100 usd in eur` flows through the same logic.
- If direct conversion fails, evaluates the left side as an expression (e.g., `10 + 5 m in cm`, `sum to usd`).
- Can feed converted values into trailing math when evaluation continues in the core (e.g., `sum to USD + 100`).
- Conversion formula: `value * (factor_unit1 / factor_unit2)` (factors relative to base unit); temperature uses affine formulas (`F = C * 9/5 + 32`, `K = C + 273.15`).

**Rules**:
- Detects category from the target unit (`right` side) using lowercase/plural matching.
- Attempts direct conversion first; if it fails, preprocesses and evaluates the left expression, then converts the numeric result (retaining any unit it produced).
- Units and currencies are case-insensitive; plural forms and currency symbols are normalized during preprocessing.
- Custom units defined in `config.custom_units` are included automatically.

**Invocation**: After percentage and date/time agents, via `find(" in ")` or `find(" to ")`; routes to category-specific functions (e.g., `evaluate_generic_conversion`, `evaluate_temperature_conversion`).

**Example**:
- Input: `5 meters in feet`
- Output: `16.40 feet` (5 * 1 / 0.3048).

### 6. Currency Conversion Agent
**Responsibility**: Converts currencies using the shared rates map (fiat + popular crypto).

**Key Features**:
- Rates come from `config.json` and can be refreshed via the live fawazahmed0 currency API (`--update-rates` or automatic when cache is >24h old). CLI overrides via `--rate CURR:RATE` merge into the map.
- Format: `value CURR1 in CURR2`; accepts symbols like `$`, `€`, `£`, `¥`, `₹`, `￥` that are normalized during preprocessing.
- Conversion uses the same path as unit conversion: `value * (rate1 / rate2)` with uppercase currency codes.

**Rules**:
- Detection is case-insensitive; actual map keys are uppercase currency codes.
- Currency conversion is executed inside the unit conversion path and also inside the core evaluator for cases with trailing math.

**Example**:
- Input: `100 USD in EUR`
- Output: `85.00 EUR` (value depends on current rates).

### 7. History Management Agent
**Responsibility**: Tracks and queries computation history.

**Key Features**:
- Stores results (f64) in `history` vec after successful evaluations (skips assignments/history cmds).
- Commands:
  - `sum` / `total`: Sums all history.
  - `average` / `avg`: Mean of history.
  - `prev`: Last result.
- No addition to history for these commands.

**Rules**:
- History shared via `Arc<Mutex<Vec<f64>>>`.
- Commands are exact matches (trimmed, lowercase).
- Short-circuits evaluation; returns formatted result.
- History tokens can also be embedded in larger expressions via the core evaluator (e.g., `sum + 10`).

**Invocation**: First agent in registry priority.

**Example**:
- After `10 + 20` (adds 30), `5 * 6` (adds 30): `sum` → `60`, `avg` → `30`, `prev` → `30`.

### 8. Variable Management Agent
**Responsibility**: Handles variable storage and retrieval (integrated with math agent).

**Key Features**:
- Assignment: `var = expr` evaluates `expr`, stores `(value, unit)` if unit present.
- Retrieval: Replaces `var` with value in expr (preserves unit if any).
- Units stored optionally (e.g., `dist = 5 km` → `(5000.0, Some("km"))`).

**Rules**:
- Variables are word-boundaried (`\bvar\b`).
- Overwrites existing vars.
- Units propagate in results if present.

**Invocation**: Runs after the history agent; preprocessing already expands variable reads, while this agent handles assignments and bare variable expressions.

**Example**:
- `x = 10 km`: Stores `(10000.0, Some("km"))`.
- `x + 5 m`: Replaces to `10000 + 5` → `10005 m` (appends unit).

## Agent Interaction Rules

1. **Pipeline Order**:
   - Preprocessing → History → Variable → Percentage → Date/Time → Unit/Currency Conversion → Math (fallback).
   - Agents are sorted by priority in `AgentRegistry`; if one returns `None`, evaluation falls through to the next.

2. **Pattern Priority**:
   - Regex/keyword checks for history, percentage, and date/time run before conversion/math.
   - Natural language operators and symbols are normalized during preprocessing before agent checks.
   - Comments are stripped before any pattern matching.

3. **State Sharing**:
   - All agents access shared `AppState` (variables, history, units, rates).
   - Locks (`Mutex`) prevent races in TUI (multi-thread potential).

4. **Error and Fallback**:
   - Invalid input → `None` (display empty in TUI/CLI error message).
   - If an agent declines (`None`), processing continues with lower-priority agents.
   - Unit conversion retries by evaluating the left expression when a direct conversion fails; otherwise math is the final fallback.

5. **TUI Integration**:
   - Agents run on Enter (current line) or full input eval.
   - Results displayed right-aligned; input highlighted (variables blue, keywords colored, comments gray).
   - Copy: Ctrl+Y (result), Ctrl+I/A (input).

6. **File Handling**:
   - Loads `.numby` files into input buffer.
   - Saves via `:w` (preserves comments, multi-line).

7. **Configuration**:
   - Units/rates from `config.json` (loaded at startup).
   - CLI overrides: `--rate CURR:RATE` merges into state.
   - Extend by adding to JSON (e.g., new units: `"au": 1.496e11` for astronomical).

## Extension Guidelines

To add a new agent (e.g., statistics over arrays):

1. **Define Patterns**: Add regex/keyword detection in `evaluate_expr`.
2. **Implement Logic**: New function like `evaluate_date_conversion`, returning `Option<String>`.
3. **Integrate Pipeline**: Insert check after relevant agent (e.g., after units).
4. **Update Config**: If needed, add to `config.json` (e.g., new unit map).
5. **Highlighting**: Add keywords to TUI `keywords` array in `tui.rs`.
6. **Tests**: Add to `evaluator.rs` tests (use `create_test_units` helper).
7. **Docs**: Update examples in README.md and this file.

**Example Extension - Statistics Agent**:
- Keywords: `median`, `stddev`, or list literals like `[1,2,3]`.
- Logic: Parse list inputs, compute metrics, and return prettified numbers.
- Rule: Insert after percentage/date agents but before unit/math so numeric results can flow into conversions.

## Performance Considerations

- `fasteval2`: O(1) for most expr (compiled internally).
- Regex: Cached globally; avoid broad patterns.
- History: Grows linearly; consider capping (e.g., last 1000).
- TUI: Re-evals all lines on render (for display); optimize for large files.

## Limitations and Future Agents

- **Current Limits**: Bitwise ops are unsupported; unit algebra is simplified (no squared/cubic unit tracking); date/time parsing is English-first; currency refresh requires network access when the cache is stale (otherwise falls back to cached rates).
- **Planned Agents**:
  - **Statistics Agent**: Mean, median, stddev on history or lists.
  - **AI Integration Agent**: Use LLMs for ambiguous natural language (e.g., \"half of pi squared\").
  - **Graphing Agent**: Output ASCII charts for functions/series.

## Post-Interaction Checklist

After each agent invocation or full evaluation cycle, the following checks are performed to ensure correctness, data integrity, and optimal user experience:

- [ ] **Result Validation**: Confirm the output is a valid `f64` or properly formatted string. If evaluation returns `None` (e.g., invalid expression), display an empty result in the TUI or an error message in CLI mode.
- [ ] **Unit and Currency Preservation**: If units, currencies, or scales were detected during processing, append them to the prettified result (e.g., `1.0k m` or `85.00 EUR`).
- [ ] **History Management**: Add the numeric result to the `history` vector only for successful non-assignment expressions and non-history commands. Skip for assignments (`=`) and special commands (`sum`, `avg`, etc.).
- [ ] **Number Prettification**: Apply the `prettify_number` function to format large or small numbers appropriately (e.g., `1000` → `1.0k`, `1000000` → `1.0M`, `0.001` → `0.00` with 2 decimals for small values).
- [ ] **State Synchronization**: Drop all `Mutex` guards to release locks on shared state (`variables`, `history`, `status`), preventing deadlocks in the multi-threaded TUI environment.
- [ ] **TUI Re-rendering**: In interactive mode, refresh the UI: highlight input on the left (variables in blue, keywords colored, comments gray), display results right-aligned on the right, and update the cursor position accurately (handling multi-line navigation with Up/Down/Home/End).
- [ ] **CLI Output**: For command-line invocations, print results using `nu_ansi_term::Color`; the process exits normally after printing.
- [ ] **File Operations Verification**: When saving via `:w` or `:w <filename>`, check for write errors (e.g., permissions), update the status bar with success/error messages (timed to fade after 3-5 seconds), and refresh the terminal title if filename changes.
- [ ] **Clipboard Operations**: If copy actions are triggered (Ctrl+Y for result, Ctrl+I/A for input), verify successful clipboard write using the `clipboard` crate and optionally update status (e.g., "Copied to clipboard").
- [ ] **Error Logging**: For any failures (e.g., regex mismatches, eval errors), log to status (TUI) or stderr (CLI) without crashing; provide user-friendly messages like "Error evaluating expression".
- [ ] **Build and Test Validation**: After modifications to agents or evaluation logic, run `cargo clippy` to ensure no Clippy issues or warnings. Execute `cargo test` to confirm all tests pass, including unit tests for preprocessing, conversions, and history management in `tests/cli_tests.rs` and `evaluator.rs`.

This checklist is implicitly enforced in the codebase (e.g., in `evaluator.rs` for validation/history, `tui.rs` for rendering/clipboard, `main.rs` for CLI). It promotes reliability and ease of debugging.

For issues or contributions, see [README.md](README.md) or open a PR!
