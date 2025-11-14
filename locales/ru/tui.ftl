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
