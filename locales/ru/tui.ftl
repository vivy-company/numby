# TUI interface strings

# Commands help
commands-help = Команды: :q выход, :w сохранить, :lang [язык] изменить язык, :langs список языков

# Help tooltip
help-commands = Команды: :q выход  :w сохранить  :w <файл> сохранить как  :lang изменить язык  :langs список
help-shortcuts = Горячие клавиши: Ctrl+Y копировать результат  Ctrl+I копировать ввод  Ctrl+A копировать ввод

# Input validation
input-size-limit = Достигнут лимит размера ввода ({$max} символов макс)
line-validation-error = Ошибка проверки строки: {$error}

# File operations
no-file-to-save = Нет файла для сохранения. Используйте :w имяфайла
file-saved = Файл сохранен: {$path}
error-saving-file = Ошибка при сохранении файла: {$error}
invalid-file-path = Недопустимый путь: {$error}

# Language commands
current-language = Текущий язык: {$name}
available-languages = Доступные языки: {$list}
language-changed = Язык изменен на: {$name}
failed-set-language = Не удалось изменить язык: {$error}

# Нижняя панель
tui-footer-ctrlh-key = Ctrl+H
tui-footer-help-desc = помощь

# Окно справки
tui-help-enter-key = Enter
tui-help-enter-desc = новая строка / выполнить
tui-help-ctrls-key = Ctrl+S
tui-help-ctrls-desc = сохранить (спросит имя если нет)
tui-help-ctrlq-key = Ctrl+Q
tui-help-ctrlq-desc = выход
tui-help-ctrli-key = Ctrl+I
tui-help-ctrli-desc = копировать Markdown для обмена
tui-help-ctrly-key = Ctrl+Y
tui-help-ctrly-desc = копировать текущий результат
tui-help-ctrll-key = Ctrl+L
tui-help-ctrll-desc = очистить кэш
tui-help-ctrlh-key = Ctrl+H
tui-help-ctrlh-desc = показать/скрыть справку
tui-help-ctrlshift-t-key = Ctrl+Shift+T
tui-help-ctrlshift-t-desc = выбор формата времени
tui-help-ctrlshift-d-key = Ctrl+Shift+D
tui-help-ctrlshift-d-desc = выбор формата даты
tui-help-ctrlshift-l-key = Ctrl+Shift+L
tui-help-ctrlshift-l-desc = выбор языка
tui-help-f1-key = F1
tui-help-f1-desc = показать/скрыть справку
tui-help-esc-key = Esc
tui-help-esc-desc = закрыть справку или окно

# Выбор языка
tui-locale-title = Язык
tui-locale-footer = ↑/↓ выбрать   Enter применить   Esc закрыть

# Выбор форматов
tui-format-time-title = Время
tui-format-date-title = Дата
tui-format-footer = ↑/↓ выбрать   ←/→ сменить список   Enter применить   Esc закрыть

# Сохранение
tui-save-default-filename = untitled.numby
tui-save-label = Сохранить как:
tui-save-hint = (Enter — сохранить, Esc — отмена)

# Статусы
tui-format-set-status = Форматы заданы: время {$time}, дата {$date}
tui-locale-set-status = Язык установлен: {$name}
tui-quit-ctrlc = Нажмите Ctrl+C ещё раз для выхода
tui-quit-esc = Нажмите Esc ещё раз для выхода

# Markdown
markdown-results-heading = ### Результаты
markdown-results-row = - `{$expr}` → `{$result}`
