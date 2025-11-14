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
