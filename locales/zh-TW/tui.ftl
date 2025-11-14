# TUI interface strings

# Commands help
commands-help = 指令：:q 退出、:w 儲存、:lang [語言] 更改語言、:langs 列出語言

# Help tooltip
help-commands = 指令：:q 退出  :w 儲存  :w <檔案> 另存新檔  :lang 更改語言  :langs 列表
help-shortcuts = 快捷鍵：Ctrl+Y 複製結果  Ctrl+I 複製輸入  Ctrl+A 複製輸入

# Input validation
input-size-limit = 已達到輸入大小限制（最多 {$max} 字元）
line-validation-error = 行驗證錯誤：{$error}

# File operations
no-file-to-save = 沒有要儲存的檔案。請使用 :w 檔名
file-saved = 檔案已儲存：{$path}
error-saving-file = 儲存檔案時發生錯誤：{$error}
invalid-file-path = 無效的路徑：{$error}

# Language commands
current-language = 目前語言：{$name}
available-languages = 可用語言：{$list}
language-changed = 語言已更改為：{$name}
failed-set-language = 更改語言失敗：{$error}
