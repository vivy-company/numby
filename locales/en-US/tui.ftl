# TUI interface strings

# Commands help
commands-help = Commands: :q quit, :w save, :lang [locale] change language, :langs list languages

# Help tooltip
help-commands = Commands: :q quit  :w save  :w <file> save as  :lang change language  :langs list
help-shortcuts = Shortcuts: Ctrl+Y copy result  Ctrl+I copy input  Ctrl+A copy input

# Input validation
input-size-limit = Input size limit reached ({$max} chars max)
line-validation-error = Line validation error: {$error}

# File operations
no-file-to-save = No file to save to. Use :w filename
file-saved = File saved: {$path}
error-saving-file = Error saving file: {$error}
invalid-file-path = Invalid path: {$error}

# Language commands
current-language = Current language: {$name}
available-languages = Available languages: {$list}
language-changed = Language changed to: {$name}
failed-set-language = Failed to set language: {$error}

# Footer
tui-footer-ctrlh-key = Ctrl+H
tui-footer-help-desc = help

# Help overlay
tui-help-enter-key = Enter
tui-help-enter-desc = newline / eval
tui-help-ctrls-key = Ctrl+S
tui-help-ctrls-desc = save (prompt if unnamed)
tui-help-ctrlq-key = Ctrl+Q
tui-help-ctrlq-desc = quit
tui-help-ctrli-key = Ctrl+I
tui-help-ctrli-desc = copy shareable markdown
tui-help-ctrly-key = Ctrl+Y
tui-help-ctrly-desc = copy current result
tui-help-ctrll-key = Ctrl+L
tui-help-ctrll-desc = clear cache
tui-help-ctrlh-key = Ctrl+H
tui-help-ctrlh-desc = toggle help
tui-help-ctrlshift-t-key = Ctrl+Shift+T
tui-help-ctrlshift-t-desc = time format picker
tui-help-ctrlshift-d-key = Ctrl+Shift+D
tui-help-ctrlshift-d-desc = date format picker
tui-help-ctrlshift-l-key = Ctrl+Shift+L
tui-help-ctrlshift-l-desc = locale picker
tui-help-f1-key = F1
tui-help-f1-desc = toggle help
tui-help-esc-key = Esc
tui-help-esc-desc = close help or prompt

# Locale picker overlay
tui-locale-title = Locale
tui-locale-footer = ↑/↓ select   Enter apply   Esc close

# Format picker overlay
tui-format-time-title = Time
tui-format-date-title = Date
tui-format-footer = ↑/↓ select   ←/→ switch list   Enter apply   Esc close

# Save prompt
tui-save-default-filename = untitled.numby
tui-save-label = Save as:
tui-save-hint = (Enter to save, Esc to cancel)

# Status messages
tui-format-set-status = Formats set to time: {$time}, date: {$date}
tui-locale-set-status = Locale set to {$name}
tui-quit-ctrlc = Press Ctrl+C again to quit
tui-quit-esc = Press Esc again to quit

# Shared copy/markdown helpers
markdown-results-heading = ### Results
markdown-results-row = - `{$expr}` → `{$result}`
