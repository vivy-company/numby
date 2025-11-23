# TUI 界面字符串

# 命令帮助
commands-help = 命令: :q 退出, :w 保存, :lang [语言] 更改语言, :langs 列出语言

# 帮助提示
help-commands = 命令: :q 退出  :w 保存  :w <文件> 另存为  :lang 更改语言  :langs 列表
help-shortcuts = 快捷键: Ctrl+Y 复制结果  Ctrl+I 复制输入  Ctrl+A 复制输入

# 输入验证
input-size-limit = 输入大小达到限制(最多 {$max} 个字符)
line-validation-error = 行验证错误: {$error}

# 文件操作
no-file-to-save = 没有要保存的文件。使用 :w 文件名
file-saved = 文件已保存: {$path}
error-saving-file = 保存文件时出错: {$error}
invalid-file-path = 无效路径: {$error}

# 语言命令
current-language = 当前语言: {$name}
available-languages = 可用语言: {$list}
language-changed = 语言已更改为: {$name}
failed-set-language = 更改语言失败: {$error}

# 底部栏
tui-footer-ctrlh-key = Ctrl+H
tui-footer-help-desc = 帮助

# 帮助面板
tui-help-enter-key = Enter
tui-help-enter-desc = 换行 / 计算
tui-help-ctrls-key = Ctrl+S
tui-help-ctrls-desc = 保存（未命名时提示）
tui-help-ctrlq-key = Ctrl+Q
tui-help-ctrlq-desc = 退出
tui-help-ctrli-key = Ctrl+I
tui-help-ctrli-desc = 复制可分享的 Markdown
tui-help-ctrly-key = Ctrl+Y
tui-help-ctrly-desc = 复制当前结果
tui-help-ctrll-key = Ctrl+L
tui-help-ctrll-desc = 清除缓存
tui-help-ctrlh-key = Ctrl+H
tui-help-ctrlh-desc = 显示/隐藏帮助
tui-help-ctrlshift-t-key = Ctrl+Shift+T
tui-help-ctrlshift-t-desc = 时间格式选择器
tui-help-ctrlshift-d-key = Ctrl+Shift+D
tui-help-ctrlshift-d-desc = 日期格式选择器
tui-help-ctrlshift-l-key = Ctrl+Shift+L
tui-help-ctrlshift-l-desc = 语言选择器
tui-help-f1-key = F1
tui-help-f1-desc = 显示/隐藏帮助
tui-help-esc-key = Esc
tui-help-esc-desc = 关闭帮助或弹窗

# 语言选择
tui-locale-title = 语言
tui-locale-footer = ↑/↓ 选择   Enter 应用   Esc 关闭

# 格式选择
tui-format-time-title = 时间
tui-format-date-title = 日期
tui-format-footer = ↑/↓ 选择   ←/→ 切换列表   Enter 应用   Esc 关闭

# 保存提示
tui-save-default-filename = untitled.numby
tui-save-label = 另存为：
tui-save-hint = （Enter 保存，Esc 取消）

# 状态信息
tui-format-set-status = 格式已设置：时间 {$time}，日期 {$date}
tui-locale-set-status = 语言已切换为 {$name}
tui-quit-ctrlc = 再按一次 Ctrl+C 退出
tui-quit-esc = 再按一次 Esc 退出

# Markdown 复制
markdown-results-heading = ### 结果
markdown-results-row = - `{$expr}` → `{$result}`
