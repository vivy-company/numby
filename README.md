# Numby

[![Rust](https://img.shields.io/badge/rust-2021-blue)](https://www.rust-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful natural language calculator with a terminal user interface (TUI). Numby allows you to perform calculations, work with variables, convert units and currencies, calculate percentages, add comments, and maintain a history of your computations.

## Features

- **Natural Language Calculations**: Evaluate mathematical expressions in a human-readable format
- **Interactive TUI**: User-friendly terminal interface for interactive calculations
- **CLI Mode**: Evaluate expressions directly from the command line
- **Variables**: Store and reuse variables in your calculations
- **Unit Conversion**: Convert between various units (length, etc.)
- **Currency Conversion**: Convert between 300+ currencies with automatic daily updates from free API
- **Percentage Calculations**: Support for percentage expressions and operations
- **Comments**: Support for `//` and `#` comments to annotate calculations (grayed out in TUI)
- **History**: Keep track of your calculation history
- **File Support**: Save and load calculation files (.numby extension)
- **Syntax Highlighting**: Colorized output for better readability
- **Multilingual Support**: Available in English, Spanish, and Chinese

## Installation

### Prerequisites

- Rust (latest stable version recommended)
- Cargo (comes with Rust)

### Option 1: Cargo Install (Recommended for Rust Users)

```bash
cargo install numby
```

This installs the latest version from crates.io.

### Option 2: Prebuilt Binaries

Download the latest release from [GitHub Releases](https://github.com/wiedymi/numby/releases) for your platform.

Or use the automated installer:

```bash
curl -fsSL https://raw.githubusercontent.com/wiedymi/numby/main/install.sh | bash
```

### Option 3: Package Managers

#### macOS (Homebrew)

```bash
brew tap wiedymi/numby
brew install numby
```

#### Windows (Scoop)

```bash
scoop bucket add wiedymi-numby https://github.com/wiedymi/numby
scoop install numby
```

#### Linux

Use the install.sh script above, or build from source.

### Building from Source

```bash
git clone <repository-url>
cd numby
cargo build --release
```

The binary will be available at `target/release/numby`.

### Installation from Source (Optional)

```bash
cargo install --path .
```

This will install `numby` to your Cargo bin directory.

## Usage

### Interactive Mode

```bash
numby
```

This starts the TUI mode where you can interactively enter expressions.

### Evaluate Expression

```bash
numby "2 + 3 * 4"
```

### Open File

```bash
numby my_calculations.numby
```

### Currency Rate Management

Numby automatically updates currency rates daily from a free API (342+ currencies supported). Rates are cached locally and work offline.

```bash
# Force update currency rates
numby --update-rates

# Skip automatic rate update on startup
numby --no-update

# Manually override a specific rate
numby --rate EUR:0.85
```

**Supported Currencies**: USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, INR, BTC, ETH, and 300+ more fiat and cryptocurrencies.

**API Source**: [fawazahmed0/currency-api](https://github.com/fawazahmed0/exchange-api) (free, no rate limits, daily updates)

### Other Options

- `--help`: Show help information
- `--version`: Show version information
- `--locale <LOCALE>`: Set language (e.g., `en-US`, `es`, `zh-CN`)
- `--update-rates`: Force update currency rates from API
- `--no-update`: Skip automatic currency rate update on startup

### Interactive Commands

- `:q` - Quit the application
- `:w` - Save current file
- `:w <filename>` - Save as new file

## Examples

### Basic Calculations

```
2 + 3 * 4
sin(45) + cos(30)
sqrt(16) + log(100)
```

### Variables

```
x = 10
y = 20
x + y * 2
```

### Unit Conversion

```
5 meters to feet
100 km in miles
```

### Currency Conversion

Supports 300+ currencies including fiat and cryptocurrencies:

```
100 USD to EUR
500 GBP in JPY
1 BTC to USD
50 ETH in EUR
1000 CNY to INR
```

Currency rates update automatically every 24 hours. Use `--update-rates` to force an update or `--no-update` to skip the automatic check.

### Complex Expressions

```
distance = 100 km
time = 2 hours
speed = distance / time
speed in mph
```

### Percentage Calculations

```
10% of 100          # Returns 10
50% of 200 USD      # Returns 100 USD
25% of 1000 EUR     # Returns 250 EUR

100 + 10%           # Returns 110 (100 + 10% of 100)
200 - 25%           # Returns 150 (200 - 25% of 200)
100 * 50%           # Returns 50 (100 * 0.5)
100 / 20%           # Returns 500 (100 / 0.2)
```

### Comments

```
10 + 5 // Simple addition
50% of 200 USD # Calculate half of 200 dollars
// This is a comment line (ignored)
# This is also a comment line (ignored)
```

*Both `//` and `#` comment styles are supported. Comments appear grayed out in the TUI for better readability*

### Internationalization

Numby supports multiple languages:

```bash
# Use Spanish
numby --locale es "2 + 2"

# Use Chinese
numby --locale zh-CN "100 meters in feet"

# Default (English or system locale)
numby "5 * 10"
```

**Supported Languages:**
- **English (en-US)** - Default
- **Spanish (es)** - Español
- **Chinese (zh-CN)** - 中文

You can also set the locale in your `config.json`:

```json
{
  "locale": "es",
  ...
}
```

The locale priority is: CLI argument → config file → system locale → en-US fallback.

## Configuration

Numby uses a `config.json` file for configuration. The default configuration includes:

- **Units**: Conversion factors for various length units
- **Currencies**: Exchange rates for different currencies
- **Currency Symbols**: Recognized currency symbols

You can modify `config.json` to add custom units or update currency rates. For current rates, check a financial API or update manually.

See `example.numby` for a sample calculation file.

## Testing

Run tests with:

```bash
# All tests
cargo test

# Unit tests (i18n tests need single thread)
cargo test --lib i18n -- --test-threads=1

# Integration tests
cargo test --test localization_integration
```

## Dependencies

- [ratatui](https://github.com/ratatui-org/ratatui) - Terminal UI library
- [crossterm](https://github.com/crossterm-rs/crossterm) - Terminal manipulation
- [regex](https://github.com/rust-lang/regex) - Regular expressions
- [fasteval2](https://github.com/izihawa/fasteval2) - Fast evaluation of algebraic expressions
- [serde](https://serde.rs/) - Serialization
- [fluent](https://projectfluent.org/) - Localization system
- [arboard](https://github.com/1Password/arboard) - Clipboard operations
- [nu-ansi-term](https://github.com/nushell/nu-ansi-term) - ANSI terminal colors

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.