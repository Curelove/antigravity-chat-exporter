# Antigravity Chat Exporter

> **双击即可把本机 Antigravity 对话无损导出为 Markdown，并自动写进系统剪贴板。**  
> 专为 Windows 打造的 Google Antigravity 本地会话导出工具。直接只读解析本机会话摘要库与 `transcript` 日志，通过可视化列表按「会话标题 + 工作区 + 首句摘要」精准点选，支持 **纯净复盘模式** 与 **含完整 Thinking 推理及工具调用记录的详尽模式**。

<!-- 请在 GitHub 网页端编辑此文件，将录制好的 6 秒导出与粘贴预览 GIF 直接拖拽到下方替换下一行 -->
![Antigravity Chat Exporter 演示](请在此处拖拽上传双击cmd选择会话序号一键导出Markdown并粘贴到编辑器的演示.gif)

---

## 核心特性

- **双击即用，告别乱码与盲找日志**：自带 `运行-导出Antigravity对话.cmd` 一键启动器，自动扫描本机 `.gemini\antigravity*` 目录，直观列出每个会话的**保存标题、关联工作区路径与首句摘要**，输入数字编号即可导出。
- **双模式满足不同场景**：
  - **简洁模式 (`n`)**：仅保留用户提问与每轮最终模型回复，剔除繁杂的中间工具调用，生成的 `Antigravity_Chat_Export.md` 最适合直接丢进 Obsidian 归档复盘。
  - **详尽模式 (`y`)**：按原始时间线完整还原模型推理过程（`thinking` / `reasoning` / `analysis`）、工具调用记录与参数、中间回复及最终回复，生成 `Antigravity_Chat_Export_Detailed.md`，是复盘 Agent 执行链路与排障的利器。
- **桌面落盘 + 剪贴板双同步**：导出完成瞬间，不仅在桌面生成排好版的 `.md` 文件，还会**自动将全文写入 Windows 剪贴板**，切到笔记软件直接 `Ctrl + V` 就能用。
- **100% 本地只读，绝对安全**：完全在离线本机环境运行，以只读方式查询 SQLite 摘要库与 `.jsonl` 日志，绝不联网上传，绝不修改任何 Antigravity 原始数据。

---

## 3 步快速开始

### 1. 环境准备

- **系统**：Windows 10 / 11（自带 PowerShell 5.1+），且本机已安装使用过 Antigravity。
- **依赖**：需安装 **Python 3**（用于只读读取本地 SQLite 会话摘要库）。可在终端输入以下命令验证：

```powershell
py -3 --version
```

若未显示版本号，请前往 [Python 官网](https://www.python.org/downloads/windows/) 下载安装，并在安装时勾选 `Add python.exe to PATH`。

### 2. 下载并启动

1. 点击本仓库右上角绿色的 **`Code -> Download ZIP`**（或前往 [Releases](https://github.com/Curelove/antigravity-chat-exporter/releases) 下载）并解压。
2. 直接双击运行文件夹内的启动脚本：

```text
运行-导出Antigravity对话.cmd
```

*(注意：请勿直接双击 `.ps1` 文件，Windows 默认会用记事本打开它。)*

### 3. 选择模式与会话编号

1. 根据提示选择导出粒度（输入 `y` 为详尽模式，输入 `n` 为简洁模式）。
2. 在列出的会话菜单中查看工作区与标题：

```text
[1] 2026-10-17 15:42  [Desktop]
    Netaba 趋势与 3D 档案空间规划
    工作区：C:\Users\用户名\Desktop
    首句：你接手 Bangumi Manager 的后续开发……
    来源：antigravity，ID：a2d15cb0...
```

3. 输入目标会话编号（如 `1`）并回车，桌面即刻生成 Markdown 文件并自动复制到剪贴板。

---

## 技术说明与常见问题 (FAQ)

### 支持扫描的本地路径

脚本会自动检索当前 Windows 用户目录下的以下位置与数据文件：

```text
%USERPROFILE%\.gemini\antigravity
%USERPROFILE%\.gemini\antigravity-ide
%USERPROFILE%\.gemini\antigravity-cli
conversation_summaries.db
brain\<会话ID>\.system_generated\logs\transcript.jsonl
brain\<会话ID>\.system_generated\logs\transcript_full.jsonl
```

### 常见问题排查

- **为什么详尽模式里某些会话没有出现「模型详细过程」或「工具调用记录」？**
  详尽模式严格忠于本机日志，仅导出 Antigravity 实际写入本地 `transcript` 的字段，不会凭空伪造。不同模型或版本保存的字段略有差异，可在导出的文件中按 `Ctrl + F` 搜索 `模型详细过程` 或 `工具调用记录` 定位。
- **会话菜单显示 `[未关联工作区]` 或未显示标题？**
  代表本地摘要数据库未记录该会话的工作区路径，或本机未正确安装 Python 3，但这**完全不影响从日志中正常导出对话正文**。
- **提示「未识别到可导出的用户或模型消息」？**
  可能是 Antigravity 新版本调整了日志 JSON 结构，欢迎在 [Issues](https://github.com/Curelove/antigravity-chat-exporter/issues) 反馈你的 Antigravity 版本号与脱敏报错截图（**切勿上传包含个人隐私的 `.db` 或 `.jsonl` 原文件**）。

---

## 隐私提醒与免责声明

导出的详尽 Markdown 中可能包含你的本地文件路径、终端命令或代码片段，公开分享前请留意脱敏。本项目采用 MIT 许可证开源，不隶属于 Google 或 Antigravity 团队。
