# Numby

[![Rust](https://img.shields.io/badge/rust-2021-blue)](https://www.rust-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Crates.io](https://img.shields.io/crates/v/numby)](https://crates.io/crates/numby)

A powerful natural language calculator with both CLI and terminal user interface (TUI). Numby allows you to perform calculations, work with variables, convert between 40+ units across 9 categories, handle currency conversions, calculate percentages, and maintain a history of your computations—all with multi-language support.

## Features

### Core Capabilities
- **Natural Language Calculations**: Evaluate mathematical expressions with natural operators like "plus", "times", "divided by"
- **Interactive TUI**: Split-panel interface with live evaluation and syntax highlighting
- **CLI Mode**: Evaluate expressions directly from the command line or pipe input
- **Variables & History**: Store values, reference previous results with `prev`, `sum`, `average`
- **Date & Time Awareness**: Ask for `now`, `today`, `time in Tokyo`, `next Monday`, or `100 days from today`, and compute date differences
- **File Support**: Save and load calculation files (`.numby` extension) with multi-line expressions
- **Clipboard Integration**: Copy inputs or results with `Ctrl+I` / `Ctrl+Y`

### Mathematical Operations
- **Basic Arithmetic**: `+`, `-`, `*`, `/`, `%`, `^` (exponentiation)
- **Trigonometry**: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `sinh`, `cosh`, `tanh`
- **Logarithms**: `log` (base 10), `ln` (natural log)
- **Other Functions**: `sqrt`, `abs`, `round`, `ceil`, `floor`
- **Constants**: `pi` (π), `e` (Euler's number)
- **Number Formats**: Binary (`0b101`), octal (`0o10`), hex (`0xFF`), scale suffixes (`5k`, `2M`, `3G`)

### Unit Conversions (40+ Units)
- **Length**: meter, km, cm, mm, foot, inch, yard, mile, nautical mile, hand, rod, chain, furlong
- **Time**: seconds, minutes, hours, days, weeks, months, years
- **Temperature**: Celsius, Fahrenheit, Kelvin (with proper conversion formulas)
- **Area**: m², hectare, acre
- **Volume**: liter, ml, m³, pint, quart, gallon, cup, teaspoon, tablespoon
- **Mass/Weight**: gram, kg, tonne, pound, ounce, stone, carat
- **Speed**: m/s, km/h, mph, knot
- **Angles**: degree, radian
- **Data**: bit, byte
- **Energy**: joule, calorie

### Currency & Financial
- **Hundreds of Fiat & Crypto Currencies**: USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, INR plus popular crypto assets (BTC, ETH, etc.) from the fawazahmed0 currency API
- **Automatic Refresh**: On startup Numby fetches latest rates when the cached timestamp is older than 24 hours; `--update-rates` forces a refresh, `--no-update` skips it
- **Offline Support**: Falls back to cached rates in `config.json` when offline
- **Custom Rates**: Override rates with `--rate EUR:0.92`

### Percentage Calculations
- `20% of 100` → 20
- `100 + 10%` → 110 (adds 10% of 100)
- `200 - 25%` → 150 (subtracts 25% of 200)
- Works with currencies: `50% of 200 USD` → 100 USD

### Multilingual Support (9 Languages)
Available in English, Spanish, French, German, Japanese, Russian, Belarusian, Chinese (Simplified & Traditional). Switch with `--locale` or `:lang` command.

### Developer Features
- **Comments**: Use `//` or `#` to annotate calculations (grayed out in TUI)
- **Syntax Highlighting**: Colorized numbers, operators, units, and errors
- **Vim-like Commands**: `:w` to save, `:q` to quit, `:lang` to switch language
- **Configurable**: JSON config at `~/.numby/config.json` for custom units, rates, and aliases

## Installation

### Cargo (Recommended)

```bash
cargo install numby
```

Installs from [crates.io](https://crates.io/crates/numby).

### Automated Installer Script

```bash
curl -fsSL https://numby.vivy.app/install.sh | bash
```

Automatically detects your OS/architecture and installs the latest release binary.

### Download Pre-built Binaries

Download for your platform from [GitHub Releases](https://github.com/vivy-company/numby/releases):

- **Linux**: x86_64, ARM64
- **macOS**: x86_64 (Intel), ARM64 (Apple Silicon)
- **Windows**: x86_64, ARM64

Extract and add to your `PATH`.

### macOS App (Paid)

A native macOS app with graphical interface is available on the **App Store** for **$6**.

The CLI/TUI version remains free and open-source.

### Building from Source

```bash
git clone https://github.com/vivy-company/numby.git
cd numby
cargo build --release
```

Binary available at `target/release/numby`.

## Usage

### Interactive TUI Mode (Default)

```bash
numby
```

Launches the split-panel terminal interface with live evaluation.

**TUI Keybindings:**
- Arrow keys: Navigate cursor
- `Home` / `End`: Jump to line start/end
- `Enter`: Evaluate line and insert newline
- `Ctrl+Y`: Copy current result to clipboard
- `Ctrl+I`: Copy current input to clipboard
- `:q`: Quit | `:w`: Save | `:w <file>`: Save as
- `:lang <locale>`: Switch language | `:langs`: List languages

### CLI Mode (Quick Evaluation)

```bash
# Single expression
numby "2 + 3 * 4"

# With units
numby "100 USD in EUR"

# Natural language
numby "5 meters plus 3 feet in inches"

# Percentage
numby "15% of 200"
```

### File Operations

```bash
# Open existing file
numby calculations.numby

# Or specify with flag
numby --file my_calculations.numby
```

Save from TUI with `:w` or `:w filename.numby`.

### CLI Options

```bash
numby [OPTIONS] [EXPRESSION]

Options:
  -f, --file <PATH>        Open file for editing
      --locale <LOCALE>    Set language (en-US, es, fr, de, ja, ru, be, zh-CN, zh-TW)
      --rate <CURR:RATE>   Override currency rate (e.g., EUR:0.92)
      --update-rates       Force update currency rates from API
      --no-update          Skip automatic rate update
      --format <NAME>      CLI output format: pretty (default), markdown, table/box, plain
  -h, --help              Print help
  -V, --version           Print version
```

### Currency Management

Exchange rates are cached in `config.json` and refreshed from the free fawazahmed0 currency API when the cache is older than 24 hours. Cached rates work offline.

```bash
# Force update
numby --update-rates

# Skip auto-update
numby --no-update

# Override specific rate
numby --rate EUR:0.92 --rate GBP:0.85

# Check current rates
numby "1 USD in EUR"
```

**API Source**: [fawazahmed0/exchange-api](https://github.com/fawazahmed0/exchange-api) (free, no limits)

## Examples

### Basic Arithmetic

```bash
numby "2 + 3 * 4"              # 14
numby "100 / 25"               # 4
numby "2 ^ 8"                  # 256
numby "sqrt(144)"              # 12
```

### Trigonometry & Math Functions

```bash
numby "sin(45)"                # 0.85
numby "cos(pi/3)"              # 0.5
numby "log(1000)"              # 3
numby "abs(-42)"               # 42
```

### Variables & History

```bash
# In TUI:
x = 100
y = 50
total = x + y                  # 150
prev + 10                      # 160 (uses previous result)
sum                            # Sum of all results
average                        # Average of all results
```

### Unit Conversions

```bash
numby "5 meters to feet"       # 16.4 ft
numby "100 km in miles"        # 62.14 mi
numby "32 f to c"              # 0°C (Fahrenheit to Celsius)
numby "2 hours in seconds"     # 7200 s
numby "5 gallons to liters"    # 18.93 L
```

### Currency Conversions

```bash
numby "100 USD in EUR"         # ~92 EUR (live rates)
numby "500 GBP to JPY"         # ~95000 JPY
numby "1 BTC in USD"           # Current Bitcoin price
numby "50 ETH to EUR"          # Ethereum conversion
```

### Percentage Operations

```bash
numby "20% of 500"             # 100
numby "100 + 15%"              # 115 (adds 15% of 100)
numby "200 - 10%"              # 180 (subtracts 10% of 200)
numby "50% of 80 USD"          # 40 USD
```

### Complex Multi-line Calculations

Create a file `budget.numby`:

```
# Monthly budget calculation
income = 5000 USD
rent = 30% of income           # 1500 USD
utilities = 200 USD
food = 500 USD
savings = income - rent - utilities - food
savings in EUR                 # Converted savings
```

Run: `numby budget.numby`

### Natural Language

```bash
numby "5 meters plus 3 feet in inches"
numby "100 divided by 4 times 2"
numby "pi times 10"
```

### Number Formats

```bash
numby "0b1010"                 # Binary: 10
numby "0xFF"                   # Hex: 255
numby "5k + 2M"                # 2,005,000
numby "1_000_000 / 2"          # 500,000
```

### Comments

```
// Budget calculations
income = 4500 USD              # Monthly income
expenses = 3200 USD            // Fixed expenses
savings = income - expenses    # Remaining savings
```

Comments appear grayed out in TUI.

### Multi-language Support

```bash
# Spanish
numby --locale es "100 + 50"

# Japanese
numby --locale ja "10 km to miles"

# Chinese
numby --locale zh-CN "50% of 200"

# Switch language in TUI
:lang de                       # Switch to German
:langs                         # List available languages
```

**Supported**: English, Spanish, French, German, Japanese, Russian, Belarusian, Chinese (Simplified/Traditional)

### Date & Time

```bash
numby "now"                      # Current local time
numby "time in tokyo"            # Current time in a specific timezone
numby "today + 5 days"           # Date arithmetic
numby "days between 2025-01-01 and 2025-01-31"  # Difference in days
numby "next monday"              # Next occurrence of a weekday
```

## Configuration

Numby stores configuration at `~/.numby/config.json`. Auto-generated on first run.

**Configurable Options:**
- **Units**: Custom unit definitions and conversion factors
- **Currencies**: Exchange rates (auto-updated from API)
- **Currency Symbols**: Symbol mappings ($, €, £, ¥, etc.)
- **Operator Aliases**: Natural language mappings ("plus" → "+")
- **Locale**: Default language
- **Padding**: TUI interface spacing

**Example config.json:**

```json
{
  "locale": "en-US",
  "units": {
    "meter": 1.0,
    "foot": 0.3048,
    "mile": 1609.34
  },
  "currencies": {
    "USD": 1.0,
    "EUR": 0.92
  },
  "operator_aliases": {
    "plus": "+",
    "times": "*",
    "divided by": "/"
  }
}
```

Edit to add custom units or override defaults.

## Development

### Running Tests

```bash
# All tests
cargo test

# Specific test suites
cargo test --lib
cargo test --test cli_tests
cargo test --test localization_integration

# i18n tests (require single thread)
cargo test --lib i18n -- --test-threads=1
```

### Building

```bash
# Development build
cargo build

# Optimized release
cargo build --release

# Platform-specific profiles
cargo build --profile release-cli   # CLI/TUI (with LTO)
cargo build --profile release-lib   # macOS app library
```

## Architecture

**Agent-Based Evaluation Pipeline:**
1. **History Agent**: Handles `sum`, `total`, `avg`, `prev`
2. **Variable Agent**: Manages variable assignments
3. **Percentage Agent**: Processes percentage operations
4. **Date/Time Agent**: Understands `now`, relative offsets, day-of-week phrases, and date differences
5. **Unit Agent**: Handles conversions with `in`/`to` across units and currencies
6. **Math Agent**: Fallback for algebraic expressions

**Key Dependencies:**
- [ratatui](https://github.com/ratatui-org/ratatui) - Terminal UI framework
- [crossterm](https://github.com/crossterm-rs/crossterm) - Cross-platform terminal control
- [fasteval2](https://github.com/izihawa/fasteval2) - Expression evaluation engine
- [fluent](https://projectfluent.org/) - Localization framework
- [ropey](https://github.com/cessen/ropey) - Efficient text buffer
- [arboard](https://github.com/1Password/arboard) - Clipboard integration
- [serde](https://serde.rs/) + [serde_json](https://github.com/serde-rs/json) - Configuration serialization

## Contributing

Contributions welcome! Please submit a Pull Request.

**Areas for contribution:**
- Additional unit conversions
- New language translations
- Bug fixes and performance improvements
- Documentation enhancements

## License

MIT License - see [LICENSE](LICENSE) file.

**Note:** The CLI/TUI version is free and open-source. The macOS App Store version ($6) supports ongoing development.
