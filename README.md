# Antigravity Chat Exporter

将本机 Antigravity 对话导出为 Markdown 文件的 Windows 工具。

它会读取 Antigravity 本地保存的会话摘要和 transcript 日志，让用户从标题清单中选择需要导出的对话，而不是只能导出最新对话。

## 功能

- 自动扫描本机已安装的 Antigravity 会话数据。
- 优先显示 Antigravity 内部保存的会话标题。
- 显示 Antigravity 记录的工作区名称和工作区路径。
- 用户自行输入编号选择导出的会话。
- 导出为桌面的 `Antigravity_Chat_Export.md`。
- 自动将导出内容复制到 Windows 剪贴板。
- 支持保留每轮最后一条模型回复，减少工具调用和中间信息干扰。
- 仅以只读方式访问 Antigravity 数据库和日志，不修改 Antigravity 数据。

## 系统要求

- Windows 10 或 Windows 11。
- Windows PowerShell 5.1 或更高版本。
- 已安装并实际使用过 Antigravity。
- Python 3。

Python 用于只读查询 Antigravity 的本地 SQLite 会话摘要数据库，以获得会话标题和工作区路径。

可在命令行检查 Python 是否可用：

```powershell
py -3 --version
```

如果没有显示版本号，请先从 [Python 官方网站](https://www.python.org/downloads/windows/) 安装 Python 3。安装时请勾选 `Add python.exe to PATH`。

## 使用方法

1. 在本仓库页面点击绿色的 `Code` 按钮。
2. 选择 `Download ZIP`，解压到任意位置。
3. 双击运行：

```text
运行-导出Antigravity对话.cmd
```

4. 在打开的窗口中查看会话列表。
5. 输入目标会话前的编号，例如：

```text
1
```

6. 导出完成后，在桌面找到：

```text
Antigravity_Chat_Export.md
```

导出的完整 Markdown 内容也会自动复制到剪贴板。

## 会话列表说明

会话列表会尽可能显示以下信息：

```text
[1] 2026-10-16 23:36  [Desktop]
    Bangumi Manager 自定义查询分区开发
    工作区：C:\Users\用户名\Desktop
    首句：你接手 Bangumi Manager 的后续开发……
    来源：antigravity，ID：bb52e7ed...
```

- 第一行的方括号内容是 Antigravity 保存的工作区目录名。
- 第二行是 Antigravity 保存的会话标题。
- `工作区` 是 Antigravity 为该会话记录的实际工作区路径。
- `首句` 仅用于辅助辨认标题为空或相似的会话。
- ID 仅用于排障和区分，不需要根据它选择会话。

如果会话显示为 `未关联工作区`，表示 Antigravity 的本地摘要数据库没有保存该会话的工作区信息。这不会影响对话导出。

## 导出格式

每次导出会覆盖桌面已有的：

```text
Antigravity_Chat_Export.md
```

导出文件包含：

- 会话标题；
- 工作区路径；
- 用户消息；
- Antigravity 的模型回复；
- 按轮次组织的 Markdown 结构。

默认仅保留每轮的最后一条模型回复。若需要保留模型在一轮中的全部回复，打开 `Export-AntigravityChat.ps1`，找到：

```powershell
$OnlyFinalResponsePerTurn = $true
```

改为：

```powershell
$OnlyFinalResponsePerTurn = $false
```

## 支持的本地目录

脚本会自动检查当前 Windows 用户目录下的以下位置：

```text
%USERPROFILE%\.gemini\antigravity
%USERPROFILE%\.gemini\antigravity-ide
%USERPROFILE%\.gemini\antigravity-cli
```

当前已适配的 Antigravity 数据包括：

```text
conversation_summaries.db
brain\<会话ID>\.system_generated\logs\transcript.jsonl
brain\<会话ID>\.system_generated\logs\transcript_full.jsonl
```

Antigravity 的本地数据格式可能随版本更新而调整。若脚本不能显示标题、工作区或无法导出，请提交 Issue，并附上报错文字和 Antigravity 版本号。请勿上传包含个人对话内容的数据库或日志文件。

## 隐私和安全

- 本工具完全在本机运行。
- 不上传、不发送、不联网读取你的 Antigravity 对话。
- 不修改 Antigravity 数据库和日志。
- 导出的 Markdown 可能包含敏感对话、文件路径、代码和项目内容，请自行妥善保管。
- 不要把导出的 Markdown、`.gemini` 目录、`conversation_summaries.db` 或 `transcript.jsonl` 提交到 GitHub。

## 常见问题

### 双击 `.ps1` 后被记事本打开

这是 Windows 对 PowerShell 脚本的默认安全行为。

请双击运行：

```text
运行-导出Antigravity对话.cmd
```

不要直接双击 `.ps1` 文件。

### 提示未检测到 Python

安装 Python 3 后重新运行。安装完成后可在 PowerShell 中执行：

```powershell
py -3 --version
```

确认显示版本号。

### 菜单只显示首句摘要，没有 Antigravity 标题或工作区

通常是 Python 不可用、Antigravity 数据库格式变更，或该会话本身没有摘要记录。对话日志仍可能可以正常导出。

请在 GitHub Issues 中提供：

- Antigravity 版本；
- Windows 版本；
- 工具窗口中的完整报错文字；
- 不包含私密内容的截图或脱敏后的诊断结果。

### 导出的文件为空或显示“未识别到可导出的用户或模型消息”

这通常表示 Antigravity 更新了 transcript 日志的字段结构。请提交 Issue，并说明 Antigravity 版本和完整报错文字。

## 贡献与兼容性

欢迎提交 Issue 或 Pull Request，以适配新的 Antigravity 数据格式。

本项目不隶属于 Google、Antigravity 或任何相关产品团队。
