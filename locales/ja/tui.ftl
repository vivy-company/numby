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

# フッター
tui-footer-ctrlh-key = Ctrl+H
tui-footer-help-desc = ヘルプ

# ヘルプオーバーレイ
tui-help-enter-key = Enter
tui-help-enter-desc = 改行 / 実行
tui-help-ctrls-key = Ctrl+S
tui-help-ctrls-desc = 保存（未命名なら確認）
tui-help-ctrlq-key = Ctrl+Q
tui-help-ctrlq-desc = 終了
tui-help-ctrli-key = Ctrl+I
tui-help-ctrli-desc = 共有用Markdownをコピー
tui-help-ctrly-key = Ctrl+Y
tui-help-ctrly-desc = 現在の結果をコピー
tui-help-ctrll-key = Ctrl+L
tui-help-ctrll-desc = キャッシュをクリア
tui-help-ctrlh-key = Ctrl+H
tui-help-ctrlh-desc = ヘルプ切替
tui-help-ctrlshift-t-key = Ctrl+Shift+T
tui-help-ctrlshift-t-desc = 時刻形式の選択
tui-help-ctrlshift-d-key = Ctrl+Shift+D
tui-help-ctrlshift-d-desc = 日付形式の選択
tui-help-ctrlshift-l-key = Ctrl+Shift+L
tui-help-ctrlshift-l-desc = 言語選択
tui-help-f1-key = F1
tui-help-f1-desc = ヘルプ切替
tui-help-esc-key = Esc
tui-help-esc-desc = ヘルプやダイアログを閉じる

# 言語選択
tui-locale-title = 言語
tui-locale-footer = ↑/↓ 選択   Enter 適用   Esc 閉じる

# フォーマット選択
tui-format-time-title = 時間
tui-format-date-title = 日付
tui-format-footer = ↑/↓ 選択   ←/→ リスト切替   Enter 適用   Esc 閉じる

# 保存プロンプト
tui-save-default-filename = untitled.numby
tui-save-label = 名前を付けて保存:
tui-save-hint = (Enter で保存、Esc でキャンセル)

# ステータス
tui-format-set-status = 形式を設定しました: 時刻 {$time}, 日付 {$date}
tui-locale-set-status = 言語を {$name} に設定しました
tui-quit-ctrlc = もう一度 Ctrl+C で終了
tui-quit-esc = もう一度 Esc で終了

# Markdown
markdown-results-heading = ### 結果
markdown-results-row = - `{$expr}` → `{$result}`
