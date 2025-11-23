# TUI interface strings

# Commands help
commands-help = Каманды: :q выхад, :w захаваць, :lang [мова] змяніць мову, :langs спіс моў

# Help tooltip
help-commands = Каманды: :q выхад  :w захаваць  :w <файл> захаваць як  :lang змяніць мову  :langs спіс моў
help-shortcuts = Гарачыя клавішы: Ctrl+Y капіяваць вынік  Ctrl+I капіяваць увод  Ctrl+A капіяваць увод

# Input validation
input-size-limit = Дасягнуты ліміт памеру ўводу ({$max} сімвалаў макс)
line-validation-error = Памылка праверкі радка: {$error}

# File operations
no-file-to-save = Няма файла для захавання. Выкарыстоўвайце :w імяфайла
file-saved = Файл захаваны: {$path}
error-saving-file = Памылка пры захаванні файла: {$error}
invalid-file-path = Недапушчальны шлях: {$error}

# Language commands
current-language = Бягучая мова: {$name}
available-languages = Даступныя мовы: {$list}
language-changed = Мова зменена на: {$name}
failed-set-language = Не атрымалася змяніць мову: {$error}

# Ніжні радок
tui-footer-ctrlh-key = Ctrl+H
tui-footer-help-desc = дапамога

# Акно даведкі
tui-help-enter-key = Enter
tui-help-enter-desc = новы радок / выкананне
tui-help-ctrls-key = Ctrl+S
tui-help-ctrls-desc = захаваць (папросіць імя калі няма)
tui-help-ctrlq-key = Ctrl+Q
tui-help-ctrlq-desc = выхад
tui-help-ctrli-key = Ctrl+I
tui-help-ctrli-desc = скапіраваць Markdown для абмену
tui-help-ctrly-key = Ctrl+Y
tui-help-ctrly-desc = скапіраваць бягучы вынік
tui-help-ctrll-key = Ctrl+L
tui-help-ctrll-desc = ачысціць кэш
tui-help-ctrlh-key = Ctrl+H
tui-help-ctrlh-desc = паказаць/схаваць даведку
tui-help-ctrlshift-t-key = Ctrl+Shift+T
tui-help-ctrlshift-t-desc = выбар фармату часу
tui-help-ctrlshift-d-key = Ctrl+Shift+D
tui-help-ctrlshift-d-desc = выбар фармату даты
tui-help-ctrlshift-l-key = Ctrl+Shift+L
tui-help-ctrlshift-l-desc = выбар мовы
tui-help-f1-key = F1
tui-help-f1-desc = паказаць/схаваць даведку
tui-help-esc-key = Esc
tui-help-esc-desc = закрыць даведку або дыялог

# Выбар мовы
tui-locale-title = Мова
tui-locale-footer = ↑/↓ выбар   Enter прымяніць   Esc закрыць

# Выбар фармату
tui-format-time-title = Час
tui-format-date-title = Дата
tui-format-footer = ↑/↓ выбар   ←/→ змяніць спіс   Enter прымяніць   Esc закрыць

# Захаванне
tui-save-default-filename = untitled.numby
tui-save-label = Захаваць як:
tui-save-hint = (Enter — захаваць, Esc — скасаваць)

# Статусы
tui-format-set-status = Фарматы заданы: час {$time}, дата {$date}
tui-locale-set-status = Мова ўстаноўлена: {$name}
tui-quit-ctrlc = Націсніце Ctrl+C яшчэ раз для выхаду
tui-quit-esc = Націсніце Esc яшчэ раз для выхаду

# Markdown
markdown-results-heading = ### Вынікі
markdown-results-row = - `{$expr}` → `{$result}`
