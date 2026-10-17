# Antigravity Chat Exporter

将本机 Antigravity 对话导出为 Markdown 文件的 Windows 工具。

工具会读取 Antigravity 本地保存的会话摘要和 transcript 日志，让用户通过会话标题、工作区和首句摘要选择目标对话。支持简洁导出，也支持导出本地日志中实际保存的详细过程、工具调用和中间模型回复。

## 功能

- 自动扫描本机已安装的 Antigravity 会话数据。
- 显示 Antigravity 保存的会话标题、工作区名称和工作区路径。
- 用户输入编号选择需要导出的会话。
- 支持简洁模式和详尽模式。
- 简洁模式默认只保留每轮最后一条模型回复。
- 详尽模式尝试导出本地日志中保存的：
  - 模型详细过程字段，例如 `thinking`、`reasoning`、`analysis`；
  - 工具调用记录和工具参数；
  - 中间模型回复；
  - 最终模型回复。
- 导出为桌面的 Markdown 文件。
- 自动将导出内容复制到 Windows 剪贴板。
- 仅以只读方式访问 Antigravity 数据库和日志，不修改 Antigravity 数据。

## 系统要求

- Windows 10 或 Windows 11。
- Windows PowerShell 5.1 或更高版本。
- 已安装并实际使用过 Antigravity。
- Python 3。

Python 用于只读查询 Antigravity 的本地 SQLite 会话摘要数据库，从而获得会话标题和工作区路径。

可在 PowerShell 中检查 Python：

```powershell
py -3 --version
```

如果没有显示版本号，请先从 [Python 官方网站](https://www.python.org/downloads/windows/) 安装 Python 3。安装时建议勾选 `Add python.exe to PATH`。

## 下载与运行

1. 在本仓库页面点击绿色的 `Code` 按钮。
2. 点击 `Download ZIP`。
3. 将下载的压缩包解压到任意位置。
4. 双击运行：

```text
运行-导出Antigravity对话.cmd
```

不要直接双击 `Export-AntigravityChat.ps1`。Windows 默认会用记事本打开 `.ps1` 文件，这是正常的安全行为。

## 使用方法

程序启动后会先询问导出模式：

```text
包含详尽内容请输入 y，简洁导出请输入 n:
```

输入：

```text
y
```

使用详尽模式。

输入：

```text
n
```

使用简洁模式。

随后，程序会显示最近的会话列表，例如：

```text
[1] 2026-10-17 15:42  [Desktop]
    Netaba 趋势与 3D 档案空间规划
    工作区：C:\Users\用户名\Desktop
    首句：你接手 Bangumi Manager 的后续开发……
    来源：antigravity，ID：a2d15cb0...
```

输入目标会话前的编号，例如：

```text
1
```

导出成功后，桌面会生成相应文件，并自动复制内容到剪贴板。

## 导出文件

简洁模式输出文件：

```text
Antigravity_Chat_Export.md
```

详尽模式输出文件：

```text
Antigravity_Chat_Export_Detailed.md
```

同一模式下再次导出会覆盖桌面中已有的同名文件。

## 简洁模式

简洁模式适合保存可阅读、适合复盘或导入 Obsidian 的对话记录。

默认情况下，每轮只保留最后一条模型回复，减少工具执行过程和中间说明带来的干扰。

导出内容包括：

- 会话标题；
- 工作区路径；
- 用户消息；
- 每轮最终模型回复。

## 详尽模式

详尽模式适合排查任务执行过程、查看工具调用记录，或保留 Antigravity 在本地日志中写入的完整可用信息。

详尽模式会尝试按原始日志顺序导出：

- 用户消息；
- 模型详细过程；
- 工具调用记录；
- 工具调用参数；
- 中间模型回复；
- 最终模型回复。

导出文件中可能出现以下标题：

```text
### 模型详细过程 1

### 工具调用记录 2

### 模型回复 3
```

详尽模式只能导出 Antigravity 实际写入本机日志的字段。不同 Antigravity 版本、不同模型、不同会话保存的信息可能不同。

工具不会生成、推断或补充日志中不存在的内容。

## 会话列表说明

会话菜单优先使用 Antigravity 本地摘要数据库中保存的信息：

- 方括号内容：工作区目录名；
- 第二行：Antigravity 会话标题；
- `工作区`：该会话关联的实际工作区路径；
- `首句`：用于辅助辨认标题为空或名称相近的会话；
- `ID`：仅用于排障和区分，不需要依据它选择会话。

如果显示：

```text
[未关联工作区]
```

表示 Antigravity 的本地摘要数据库没有为该会话保存工作区路径。这不会阻止对话导出。

## 支持的本地目录

脚本会自动检查当前 Windows 用户目录下的以下位置：

```text
%USERPROFILE%\.gemini\antigravity
%USERPROFILE%\.gemini\antigravity-ide
%USERPROFILE%\.gemini\antigravity-cli
```

当前版本会读取以下本地数据：

```text
conversation_summaries.db
brain\<会话ID>\.system_generated\logs\transcript.jsonl
brain\<会话ID>\.system_generated\logs\transcript_full.jsonl
```

## 隐私和安全

- 本工具完全在本机运行。
- 不上传、不发送、不联网读取你的 Antigravity 对话。
- 不修改 Antigravity 数据库、会话日志或任何 Antigravity 配置。
- 详尽模式可能导出本地文件路径、终端命令、工具参数、代码和项目内容。
- 导出的 Markdown 可能包含敏感信息，请自行妥善保管。
- 不要将导出的 Markdown、`.gemini` 目录、`.db` 数据库文件或 `.jsonl` 日志文件提交到公开 GitHub 仓库。

## 常见问题

### 双击 `.ps1` 后被记事本打开

这是 Windows 对 PowerShell 脚本的默认安全行为。

请双击运行：

```text
运行-导出Antigravity对话.cmd
```

不要直接双击 `.ps1` 文件。

### 提示未检测到 Python

安装 Python 3 后重新运行。

安装完成后，在 PowerShell 中执行：

```powershell
py -3 --version
```

确认显示 Python 版本号。

### 菜单没有显示会话标题或工作区

通常是 Python 不可用、Antigravity 本地数据库格式变化，或该会话没有摘要记录。

脚本仍可能可以从 transcript 日志中导出对话。请提交 Issue，并提供：

- Antigravity 版本；
- Windows 版本；
- 工具窗口中完整的报错文字；
- 已脱敏的输出截图或文字。

请勿上传个人对话、`.gemini` 目录、SQLite 数据库或 transcript 日志。

### 详尽模式没有出现“模型详细过程”或“工具调用记录”

这不一定表示工具出错。

详尽模式只能导出 Antigravity 实际写入本机 transcript 日志的字段。某些会话可能仅保存最终回复，或者只保存部分工具调用信息。

可以用记事本或 Obsidian 打开导出的详尽文件，按 `Ctrl+F` 搜索：

```text
模型详细过程
```

或：

```text
工具调用记录
```

### 导出文件为空或提示“未识别到可导出的用户或模型消息”

这通常表示 Antigravity 更新了 transcript 日志的数据结构。

请提交 Issue，并提供 Antigravity 版本与完整报错文字。不要上传包含私人聊天内容的日志文件。

## 兼容性与维护

Antigravity 的本地数据库和日志格式可能随版本更新调整。本项目会尽力适配常见版本，但不承诺永久兼容未来所有版本。

欢迎提交 Issue 或 Pull Request，以帮助适配新的 Antigravity 本地数据格式。

本项目不隶属于 Google、Antigravity 或任何相关产品团队。
