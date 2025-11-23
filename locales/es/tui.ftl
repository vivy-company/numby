# Cadenas de la interfaz TUI

# Ayuda de comandos
commands-help = Comandos: :q salir, :w guardar, :lang [idioma] cambiar idioma, :langs listar idiomas

# Tooltip de ayuda
help-commands = Comandos: :q salir  :w guardar  :w <archivo> guardar como  :lang cambiar idioma  :langs listar
help-shortcuts = Atajos: Ctrl+Y copiar resultado  Ctrl+I copiar entrada  Ctrl+A copiar entrada

# Validación de entrada
input-size-limit = Límite de tamaño de entrada alcanzado (máx {$max} caracteres)
line-validation-error = Error de validación de línea: {$error}

# Operaciones de archivo
no-file-to-save = No hay archivo para guardar. Use :w nombre_archivo
file-saved = Archivo guardado: {$path}
error-saving-file = Error al guardar archivo: {$error}
invalid-file-path = Ruta inválida: {$error}

# Comandos de idioma
current-language = Idioma actual: {$name}
available-languages = Idiomas disponibles: {$list}
language-changed = Idioma cambiado a: {$name}
failed-set-language = Error al cambiar idioma: {$error}

# Pie de página
tui-footer-ctrlh-key = Ctrl+H
tui-footer-help-desc = ayuda

# Panel de ayuda
tui-help-enter-key = Enter
tui-help-enter-desc = nueva línea / evaluar
tui-help-ctrls-key = Ctrl+S
tui-help-ctrls-desc = guardar (pide nombre si falta)
tui-help-ctrlq-key = Ctrl+Q
tui-help-ctrlq-desc = salir
tui-help-ctrli-key = Ctrl+I
tui-help-ctrli-desc = copiar markdown compartible
tui-help-ctrly-key = Ctrl+Y
tui-help-ctrly-desc = copiar resultado actual
tui-help-ctrll-key = Ctrl+L
tui-help-ctrll-desc = limpiar caché
tui-help-ctrlh-key = Ctrl+H
tui-help-ctrlh-desc = mostrar/ocultar ayuda
tui-help-ctrlshift-t-key = Ctrl+Shift+T
tui-help-ctrlshift-t-desc = selector de formato de hora
tui-help-ctrlshift-d-key = Ctrl+Shift+D
tui-help-ctrlshift-d-desc = selector de formato de fecha
tui-help-ctrlshift-l-key = Ctrl+Shift+L
tui-help-ctrlshift-l-desc = selector de idioma
tui-help-f1-key = F1
tui-help-f1-desc = mostrar/ocultar ayuda
tui-help-esc-key = Esc
tui-help-esc-desc = cerrar ayuda o diálogo

# Selector de idioma
tui-locale-title = Idioma
tui-locale-footer = ↑/↓ seleccionar   Enter aplicar   Esc cerrar

# Selector de formato
tui-format-time-title = Hora
tui-format-date-title = Fecha
tui-format-footer = ↑/↓ seleccionar   ←/→ cambiar lista   Enter aplicar   Esc cerrar

# Diálogo de guardado
tui-save-default-filename = untitled.numby
tui-save-label = Guardar como:
tui-save-hint = (Enter para guardar, Esc para cancelar)

# Mensajes de estado
tui-format-set-status = Formatos establecidos a hora: {$time}, fecha: {$date}
tui-locale-set-status = Idioma establecido a {$name}
tui-quit-ctrlc = Presiona Ctrl+C otra vez para salir
tui-quit-esc = Presiona Esc otra vez para salir

# Copia / Markdown
markdown-results-heading = ### Resultados
markdown-results-row = - `{$expr}` → `{$result}`
