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

# 底部
tui-footer-ctrlh-key = Ctrl+H
tui-footer-help-desc = 說明

# 說明面板
tui-help-enter-key = Enter
tui-help-enter-desc = 換行 / 計算
tui-help-ctrls-key = Ctrl+S
tui-help-ctrls-desc = 儲存（未命名時提示）
tui-help-ctrlq-key = Ctrl+Q
tui-help-ctrlq-desc = 退出
tui-help-ctrli-key = Ctrl+I
tui-help-ctrli-desc = 複製可分享的 Markdown
tui-help-ctrly-key = Ctrl+Y
tui-help-ctrly-desc = 複製目前結果
tui-help-ctrll-key = Ctrl+L
tui-help-ctrll-desc = 清除快取
tui-help-ctrlh-key = Ctrl+H
tui-help-ctrlh-desc = 顯示/隱藏說明
tui-help-ctrlshift-t-key = Ctrl+Shift+T
tui-help-ctrlshift-t-desc = 時間格式選擇器
tui-help-ctrlshift-d-key = Ctrl+Shift+D
tui-help-ctrlshift-d-desc = 日期格式選擇器
tui-help-ctrlshift-l-key = Ctrl+Shift+L
tui-help-ctrlshift-l-desc = 語言選擇器
tui-help-f1-key = F1
tui-help-f1-desc = 顯示/隱藏說明
tui-help-esc-key = Esc
tui-help-esc-desc = 關閉說明或對話框

# 語言選擇
tui-locale-title = 語言
tui-locale-footer = ↑/↓ 選擇   Enter 套用   Esc 關閉

# 格式選擇
tui-format-time-title = 時間
tui-format-date-title = 日期
tui-format-footer = ↑/↓ 選擇   ←/→ 切換列表   Enter 套用   Esc 關閉

# 儲存提示
tui-save-default-filename = untitled.numby
tui-save-label = 另存為：
tui-save-hint = （Enter 儲存，Esc 取消）

# 狀態訊息
tui-format-set-status = 格式已設定：時間 {$time}，日期 {$date}
tui-locale-set-status = 語言已切換為 {$name}
tui-quit-ctrlc = 再按一次 Ctrl+C 以退出
tui-quit-esc = 再按一次 Esc 以退出

# Markdown
markdown-results-heading = ### 結果
markdown-results-row = - `{$expr}` → `{$result}`
