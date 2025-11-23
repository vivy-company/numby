# TUI interface strings

# Commands help
commands-help = Befehle: :q beenden, :w speichern, :lang [sprache] Sprache ändern, :langs Sprachen auflisten

# Help tooltip
help-commands = Befehle: :q beenden  :w speichern  :w <datei> speichern als  :lang Sprache ändern  :langs Sprachen auflisten
help-shortcuts = Tastenkombinationen: Strg+Y Ergebnis kopieren  Strg+I Eingabe kopieren  Strg+A Eingabe kopieren

# Input validation
input-size-limit = Eingabegrößenlimit erreicht ({$max} Zeichen max)
line-validation-error = Zeilenvalidierungsfehler: {$error}

# File operations
no-file-to-save = Keine Datei zum Speichern. Verwenden Sie :w dateiname
file-saved = Datei gespeichert: {$path}
error-saving-file = Fehler beim Speichern der Datei: {$error}
invalid-file-path = Ungültiger Pfad: {$error}

# Language commands
current-language = Aktuelle Sprache: {$name}
available-languages = Verfügbare Sprachen: {$list}
language-changed = Sprache geändert zu: {$name}
failed-set-language = Sprache konnte nicht geändert werden: {$error}

# Fußzeile
tui-footer-ctrlh-key = Ctrl+H
tui-footer-help-desc = Hilfe

# Hilfe-Overlay
tui-help-enter-key = Enter
tui-help-enter-desc = neue Zeile / ausführen
tui-help-ctrls-key = Ctrl+S
tui-help-ctrls-desc = speichern (fragt wenn unbenannt)
tui-help-ctrlq-key = Ctrl+Q
tui-help-ctrlq-desc = beenden
tui-help-ctrli-key = Ctrl+I
tui-help-ctrli-desc = teilbares Markdown kopieren
tui-help-ctrly-key = Ctrl+Y
tui-help-ctrly-desc = aktuelles Ergebnis kopieren
tui-help-ctrll-key = Ctrl+L
tui-help-ctrll-desc = Cache leeren
tui-help-ctrlh-key = Ctrl+H
tui-help-ctrlh-desc = Hilfe umschalten
tui-help-ctrlshift-t-key = Ctrl+Shift+T
tui-help-ctrlshift-t-desc = Zeitformat wählen
tui-help-ctrlshift-d-key = Ctrl+Shift+D
tui-help-ctrlshift-d-desc = Datumsformat wählen
tui-help-ctrlshift-l-key = Ctrl+Shift+L
tui-help-ctrlshift-l-desc = Sprachwahl
tui-help-f1-key = F1
tui-help-f1-desc = Hilfe umschalten
tui-help-esc-key = Esc
tui-help-esc-desc = Hilfe oder Dialog schließen

# Sprachauswahl
tui-locale-title = Sprache
tui-locale-footer = ↑/↓ wählen   Enter anwenden   Esc schließen

# Format-Auswahl
tui-format-time-title = Zeit
tui-format-date-title = Datum
tui-format-footer = ↑/↓ wählen   ←/→ Liste wechseln   Enter anwenden   Esc schließen

# Speichern
tui-save-default-filename = untitled.numby
tui-save-label = Speichern unter:
tui-save-hint = (Enter zum Speichern, Esc zum Abbrechen)

# Statusmeldungen
tui-format-set-status = Formate gesetzt auf Zeit: {$time}, Datum: {$date}
tui-locale-set-status = Sprache eingestellt auf {$name}
tui-quit-ctrlc = Drücke erneut Ctrl+C zum Beenden
tui-quit-esc = Drücke erneut Esc zum Beenden

# Markdown-Ausgabe
markdown-results-heading = ### Ergebnisse
markdown-results-row = - `{$expr}` → `{$result}`
