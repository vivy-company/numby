# Agents in Numby

Numby is a natural language calculator that employs a modular architecture composed of specialized \"agents\" responsible for parsing, evaluating, and processing different aspects of user input. These agents work collaboratively to handle complex calculations, unit conversions, currency exchanges, and more. This document provides a comprehensive overview of the agents, their responsibilities, interaction rules, and guidelines for extension.

## Overview

The agent system in Numby is designed to process natural language expressions through a pipeline of specialized components. Input is first preprocessed (e.g., replacing natural language operators like \"plus\" with \"+\") and then routed to relevant agents based on detected patterns (e.g., unit keywords, percentage symbols). The core evaluation uses the `fasteval2` library for safe, fast algebraic expression parsing.

Agents are not autonomous AI entities but modular functions or subroutines that handle domain-specific logic. They are invoked sequentially or conditionally during the evaluation process in `src/evaluator.rs`.

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
- Replaces natural language operators: `plus` → `+`, `minus` → `-`, `times` / `multiplied by` → `*`, `divided by` / `divide by` → `/`, `subtract` → `-`, `and` / `with` → `+`, `mod` → `%`.
- Injects constants: `pi` / `PI` → 3.14159..., `e` / `E` → 2.71828...
- Handles function prefixes: `log ` → `log10(`, `ln ` → `ln(`, `abs ` → `abs(`, etc. (includes trig: `sinh`, `cosh`, `tanh`, `arcsin` → `asin`, etc.).
- Parses number formats: Binary (`0b10`), octal (`0o10`), hex (`0x10`).
- Applies scales: `k` / `kilo` / `thousand` → ×1000, `M` / `mega` / `million` → ×1e6, `G` / `giga` / `billion` → ×1e9, `T` / `tera` → ×1e12, `b` (billion) → ×1e9.
- Replaces variables from state (e.g., `x` → `10.0` if `x = 10`).

**Rules**:
- Variable replacement uses word boundaries (`\b`) to avoid partial matches.
- Scales and functions are applied before core evaluation.
- Units/currencies are extracted but not converted here; passed to conversion agents.
- If input is a history command (`sum`, `total`, `average` / `avg`, `prev`), short-circuit to history agent.

**Invocation**: Always first in the pipeline (`evaluate_expr` function).

**Example**:
- Input: `x plus 5 kilo meters`
- After: Variables replaced, `plus` → `+`, `kilo` → ×1000, units extracted: `5 * 1000 meters` → routed to math + unit agents.

### 2. Mathematical Expression Evaluator Agent
**Responsibility**: Core computation of algebraic expressions using `fasteval2::ez_eval`.

**Key Features**:
- Supports full algebraic operations: `+`, `-`, `*`, `/`, `%`, parentheses, functions (e.g., `sin`, `cos`, `sqrt`, `log10`, `ln`, `abs`, `round`, `ceil`, `floor`).
- Handles variable assignments: `x = 10 + 2` stores `(12.0, None)` in state.
- Pretty-prints results: Uses `prettify_number` for abbreviations (e.g., `1000` → `1.0k`, `1e6` → `1.0M`).
- Integrates units from variables (if assigned with units, preserves them).

**Rules**:
- Assignments (`=`) are detected and executed first; result is the assigned value, no history addition.
- Non-assignment expressions add to history (unless history commands).
- Fallback for simple numbers (parses as `f64` directly).
- Errors (invalid expr) return `None`.
- Bitwise operations (e.g., `&`, `^`, `<<`, `>>`) are not supported (float-focused; use integer casts if extended).

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

### 4. Unit Conversion Agent
**Responsibility**: Converts between compatible units (length, time, area, volume, weight, angular, data).

**Key Features**:
- Triggered by `in` or `to` keywords: `value unit1 in unit2`.
- Supports multiple categories (from `config.json`):
  - **Length**: m, cm, km, ft, inch, mile, etc.
  - **Time**: second, minute, hour, day, week, month, year.
  - **Temperature**: celsius, fahrenheit, kelvin (special affine conversion: to/from Celsius).
  - **Area**: m2, hectare, acre.
  - **Volume**: m3, liter, gallon, cup.
  - **Weight**: gram, pound, ounce.
  - **Angular**: radian, degree.
  - **Data**: bit, byte.
- Conversion formula: `value * (factor_unit1 / factor_unit2)` (factors relative to base unit).
- Temperature: `F = C * 9/5 + 32`, `K = C + 273.15`.

**Rules**:
- Detects category from target unit (`right` side).
- Assumes simple format: `number unit1 to unit2` (splits on whitespace).
- For complex left expressions, falls back (no recursion to avoid loops).
- Units are case-insensitive; plural forms supported (e.g., `meters`, `feet`).
- Extracts units from main expr if no explicit conversion (appends to result).

**Invocation**: After percentage, via `find(" in ")` or `find(" to ")`; routes to category-specific functions (e.g., `evaluate_generic_conversion`, `evaluate_temperature_conversion`).

**Example**:
- Input: `5 meters in feet`
- Output: `16.40 feet` (5 * 1 / 0.3048).

### 5. Currency Conversion Agent
**Responsibility**: Converts currencies using rates from config/state.

**Key Features**:
- Rates from `config.json` (e.g., USD:1.0, EUR:0.85) or CLI `--rate CURR:RATE`.
- Format: `value CURR1 in CURR2` (currencies uppercase).
- Supports symbols: `$` (USD), `€` (EUR), etc.

**Rules**:
- Similar to units: `value * (rate1 / rate2)`.
- Case-insensitive for detection, but rates keyed uppercase.
- Fetches live rates? (Code has `reqwest` but not used; future feature via API).
- Integrates with unit agent (currencies treated as a unit type).

**Invocation**: In unit agent, if target is uppercase and in rates map.

**Example**:
- Input: `100 USD in EUR` (with EUR:0.85)
- Output: `85.00 EUR`.

### 6. History Management Agent
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

**Invocation**: In preprocessing (early detection).

**Example**:
- After `10 + 20` (adds 30), `5 * 6` (adds 30): `sum` → `60`, `avg` → `30`, `prev` → `30`.

### 7. Variable Management Agent
**Responsibility**: Handles variable storage and retrieval (integrated with math agent).

**Key Features**:
- Assignment: `var = expr` evaluates `expr`, stores `(value, unit)` if unit present.
- Retrieval: Replaces `var` with value in expr (preserves unit if any).
- Units stored optionally (e.g., `dist = 5 km` → `(5000.0, Some("km"))`).

**Rules**:
- Variables are word-boundaried (`\bvar\b`).
- Overwrites existing vars.
- Units propagate in results if present.

**Invocation**: During preprocessing (replacement) and assignment detection.

**Example**:
- `x = 10 km`: Stores `(10000.0, Some("km"))`.
- `x + 5 m`: Replaces to `10000 + 5` → `10005 m` (appends unit).

## Agent Interaction Rules

1. **Pipeline Order**:
   - Preprocessing → History Check → Percentage → Unit/Currency Conversion → Math Evaluation.
   - Fallback: If an agent fails/doesn't match, proceed to next (ultimately math or `None`).

2. **Pattern Priority**:
   - Regex for percentages/units checked explicitly.
   - Natural language processed before symbols.
   - Comments ignored entirely.

3. **State Sharing**:
   - All agents access shared `AppState` (variables, history, units, rates).
   - Locks (`Mutex`) prevent races in TUI (multi-thread potential).

4. **Error and Fallback**:
   - Invalid input → `None` (display empty in TUI).
   - Partial matches → Basic math fallback.
   - Limit recursion (e.g., no expr eval in unit left for simplicity).

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

To add a new agent (e.g., date/time calculator):

1. **Define Patterns**: Add regex/keyword detection in `evaluate_expr`.
2. **Implement Logic**: New function like `evaluate_date_conversion`, returning `Option<String>`.
3. **Integrate Pipeline**: Insert check after relevant agent (e.g., after units).
4. **Update Config**: If needed, add to `config.json` (e.g., new unit map).
5. **Highlighting**: Add keywords to TUI `keywords` array in `tui.rs`.
6. **Tests**: Add to `evaluator.rs` tests (use `create_test_units` helper).
7. **Docs**: Update examples in README.md and this file.

**Example Extension - Date Agent**:
- Keywords: `days since`, `add days to`.
- Logic: Use `chrono` crate (add dep), parse dates, compute diffs.
- Rule: If pattern matches, eval dates → return formatted diff.

## Performance Considerations

- `fasteval2`: O(1) for most expr (compiled internally).
- Regex: Cached globally; avoid broad patterns.
- History: Grows linearly; consider capping (e.g., last 1000).
- TUI: Re-evals all lines on render (for display); optimize for large files.

## Limitations and Future Agents

- **Current Limits**: No bitwise (float math), limited recursion, no live API fetches (reqwest unused).
- **Planned Agents**:
  - **Date/Time Agent**: Handle dates, durations (e.g., \"2 weeks from now\").
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
- [ ] **CLI Output and Exit**: For command-line invocations, print the result in green (using `ansi_term::Colour::Green`) for success or red for errors, then call `std::process::exit(0)`.
- [ ] **File Operations Verification**: When saving via `:w` or `:w <filename>`, check for write errors (e.g., permissions), update the status bar with success/error messages (timed to fade after 3-5 seconds), and refresh the terminal title if filename changes.
- [ ] **Clipboard Operations**: If copy actions are triggered (Ctrl+Y for result, Ctrl+I/A for input), verify successful clipboard write using the `clipboard` crate and optionally update status (e.g., "Copied to clipboard").
- [ ] **Error Logging**: For any failures (e.g., regex mismatches, eval errors), log to status (TUI) or stderr (CLI) without crashing; provide user-friendly messages like "Error evaluating expression".
- [ ] **Build and Test Validation**: After modifications to agents or evaluation logic, run `cargo clippy` to ensure no Clippy issues or warnings. Execute `cargo test` to confirm all tests pass, including unit tests for preprocessing, conversions, and history management in `tests/cli_tests.rs` and `evaluator.rs`.

This checklist is implicitly enforced in the codebase (e.g., in `evaluator.rs` for validation/history, `tui.rs` for rendering/clipboard, `main.rs` for CLI). It promotes reliability and ease of debugging.

For issues or contributions, see [README.md](README.md) or open a PR!

