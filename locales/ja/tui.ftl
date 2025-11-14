# TUI interface strings

# Commands help
commands-help = コマンド: :q 終了, :w 保存, :lang [言語] 言語を変更, :langs 言語一覧

# Help tooltip
help-commands = コマンド: :q 終了  :w 保存  :w <ファイル> 名前を付けて保存  :lang 言語変更  :langs 一覧
help-shortcuts = ショートカット: Ctrl+Y 結果をコピー  Ctrl+I 入力をコピー  Ctrl+A 入力をコピー

# Input validation
input-size-limit = 入力サイズの制限に達しました({$max}文字まで)
line-validation-error = 行検証エラー: {$error}

# File operations
no-file-to-save = 保存するファイルがありません。:w ファイル名 を使用してください
file-saved = ファイルを保存しました: {$path}
error-saving-file = ファイルの保存中にエラーが発生しました: {$error}
invalid-file-path = 無効なパス: {$error}

# Language commands
current-language = 現在の言語: {$name}
available-languages = 利用可能な言語: {$list}
language-changed = 言語を変更しました: {$name}
failed-set-language = 言語の変更に失敗しました: {$error}
