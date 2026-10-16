#requires -Version 5.1

$ErrorActionPreference = "Stop"

# $true: 每轮只保留最后一条模型回复。
# $false: 保留该轮全部模型回复。
$OnlyFinalResponsePerTurn = $true

$OutputFile = Join-Path `
    ([Environment]::GetFolderPath("Desktop")) `
    "Antigravity_Chat_Export.md"

function Get-TextValue {
    param(
        [object]$Value
    )

    if (
        $Value -is [string] -and
        -not [string]::IsNullOrWhiteSpace($Value)
    ) {
        return $Value.Trim()
    }

    if (
        $null -ne $Value -and
        $Value.PSObject.Properties.Name -contains "text"
    ) {
        return Get-TextValue -Value $Value.text
    }

    if (
        $null -ne $Value -and
        $Value.PSObject.Properties.Name -contains "content"
    ) {
        return Get-TextValue -Value $Value.content
    }

    return $null
}

function Get-EntryText {
    param(
        [object]$Entry
    )

    foreach ($propertyName in @(
        "content",
        "text",
        "message",
        "user_input",
        "response",
        "prompt",
        "output",
        "model_response"
    )) {
        if ($Entry.PSObject.Properties.Name -contains $propertyName) {
            $text = Get-TextValue -Value $Entry.$propertyName

            if (-not [string]::IsNullOrWhiteSpace($text)) {
                return $text
            }
        }
    }

    return $null
}

function Wrap-InCodeBlock {
    param(
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $cleanText = ($Text -replace "`r`n", "`n").Trim()
    $maxTicks = 0

    foreach ($match in [regex]::Matches($cleanText, '`+')) {
        if ($match.Length -gt $maxTicks) {
            $maxTicks = $match.Length
        }
    }

    $fence = '`' * [Math]::Max(3, $maxTicks + 1)

    return "$fence`n$cleanText`n$fence"
}

function Get-PlainText {
    param(
        [AllowNull()]
        [string]$Text,

        [int]$MaxLength = 90
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $clean = $Text -replace "`r`n|`r|`n", " "
    $clean = $clean -replace "\s+", " "
    $clean = $clean.Trim()

    $clean = $clean -replace `
        "(?s)<ADDITIONAL_METADATA>.*?</ADDITIONAL_METADATA>", `
        ""

    $clean = $clean -replace "</?USER_REQUEST>", ""

    $clean = $clean -replace `
        "(?s)<USER_SETTINGS_CHANGE>.*?</USER_SETTINGS_CHANGE>", `
        ""

    $clean = $clean.Trim()

    if ($clean.Length -gt $MaxLength) {
        return $clean.Substring(0, $MaxLength) + "..."
    }

    return $clean
}

function Convert-WorkspaceUriToPath {
    param(
        [string]$WorkspaceUri
    )

    if ([string]::IsNullOrWhiteSpace($WorkspaceUri)) {
        return ""
    }

    try {
        $decodedUri = [System.Uri]::UnescapeDataString($WorkspaceUri)

        if ($decodedUri -match "^file:///") {
            $path = $decodedUri -replace "^file:///", ""
            return $path -replace "/", "\"
        }

        return $decodedUri
    }
    catch {
        return $WorkspaceUri
    }
}

function Get-FirstUserMessage {
    param(
        [string]$TranscriptPath
    )

    foreach (
        $line in Get-Content `
            -Path $TranscriptPath `
            -Encoding UTF8 `
            -ErrorAction SilentlyContinue
    ) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        try {
            $entry = $line | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            continue
        }

        $type = [string]$entry.type
        $source = [string]$entry.source

        $isUserMessage = (
            $type -match "USER_INPUT|USER_MESSAGE" -or
            $source -match "USER|USER_EXPLICIT"
        )

        if (-not $isUserMessage) {
            continue
        }

        $text = Get-EntryText -Entry $entry

        if (-not [string]::IsNullOrWhiteSpace($text)) {
            return Get-PlainText -Text $text
        }
    }

    return ""
}

function ConvertFrom-Base64Utf8 {
    param(
        [string]$Base64Text
    )

    if ([string]::IsNullOrWhiteSpace($Base64Text)) {
        return ""
    }

    try {
        $bytes = [System.Convert]::FromBase64String($Base64Text)
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    catch {
        return ""
    }
}

function Get-ConversationSummaryIndex {
    param(
        [string]$DataRoot
    )

    $index = @{}

    $summaryDatabase = Join-Path `
        $DataRoot `
        "conversation_summaries.db"

    if (-not (Test-Path $summaryDatabase)) {
        return $index
    }

    $pythonCommand = Get-Command `
        py `
        -ErrorAction SilentlyContinue

    if ($null -eq $pythonCommand) {
        $pythonCommand = Get-Command `
            python `
            -ErrorAction SilentlyContinue
    }

    if ($null -eq $pythonCommand) {
        Write-Host `
            "未检测到 Python，菜单将只显示首句摘要。" `
            -ForegroundColor Yellow

        return $index
    }

    $temporaryPythonFile = Join-Path `
        $env:TEMP `
        "read_antigravity_conversation_summaries.py"

    $pythonCode = @'
import base64
import json
import sqlite3
import sys

database_path = sys.argv[1]

def encode_text(value):
    text = "" if value is None else str(value)
    return base64.b64encode(
        text.encode("utf-8")
    ).decode("ascii")

connection = sqlite3.connect(
    "file:{}?mode=ro".format(
        database_path.replace("\\", "/")
    ),
    uri=True
)

try:
    cursor = connection.cursor()

    rows = cursor.execute(
        """
        SELECT
            conversation_id,
            title,
            preview,
            workspace_uris,
            project_id
        FROM conversation_summaries
        """
    ).fetchall()

    for row in rows:
        fields = [
            encode_text(row[0]),
            encode_text(row[1]),
            encode_text(row[2]),
            encode_text(row[3]),
            encode_text(row[4])
        ]

        print("|".join(fields))
finally:
    connection.close()
'@

    try {
        Set-Content `
            -Path $temporaryPythonFile `
            -Value $pythonCode `
            -Encoding UTF8

        if ($pythonCommand.Name -ieq "py.exe") {
            $summaryLines = @(
                & py -3 `
                    $temporaryPythonFile `
                    $summaryDatabase
            )
        }
        else {
            $summaryLines = @(
                & python `
                    $temporaryPythonFile `
                    $summaryDatabase
            )
        }

        foreach ($summaryLine in $summaryLines) {
            if ([string]::IsNullOrWhiteSpace($summaryLine)) {
                continue
            }

            $parts = $summaryLine.Split("|")

            if ($parts.Count -ne 5) {
                continue
            }

            $conversationId = ConvertFrom-Base64Utf8 `
                -Base64Text $parts[0]

            if ([string]::IsNullOrWhiteSpace($conversationId)) {
                continue
            }

            $title = ConvertFrom-Base64Utf8 `
                -Base64Text $parts[1]

            $preview = ConvertFrom-Base64Utf8 `
                -Base64Text $parts[2]

            $workspaceUrisText = ConvertFrom-Base64Utf8 `
                -Base64Text $parts[3]

            $projectId = ConvertFrom-Base64Utf8 `
                -Base64Text $parts[4]

            $workspacePath = ""

            if (-not [string]::IsNullOrWhiteSpace($workspaceUrisText)) {
                try {
                    $workspaceUris = @(
                        $workspaceUrisText | ConvertFrom-Json
                    )

                    if ($workspaceUris.Count -gt 0) {
                        $workspacePath = Convert-WorkspaceUriToPath `
                            -WorkspaceUri `
                            ([string]$workspaceUris[0])
                    }
                }
                catch {
                    $workspacePath = ""
                }
            }

            $index[$conversationId] = [PSCustomObject]@{
                Title = $title
                Preview = $preview
                WorkspacePath = $workspacePath
                ProjectId = $projectId
            }
        }
    }
    catch {
        Write-Host `
            "读取会话标题和工作区失败：$($_.Exception.Message)" `
            -ForegroundColor Yellow
    }
    finally {
        Remove-Item `
            -Path $temporaryPythonFile `
            -Force `
            -ErrorAction SilentlyContinue
    }

    return $index
}

function Get-ConversationLogs {
    $dataRoots = @(
        (Join-Path $env:USERPROFILE ".gemini\antigravity"),
        (Join-Path $env:USERPROFILE ".gemini\antigravity-ide"),
        (Join-Path $env:USERPROFILE ".gemini\antigravity-cli")
    ) | Where-Object {
        Test-Path $_
    }

    $logs = foreach ($dataRoot in $dataRoots) {
        $brainRoot = Join-Path $dataRoot "brain"

        if (-not (Test-Path $brainRoot)) {
            continue
        }

        $summaryIndex = Get-ConversationSummaryIndex `
            -DataRoot $dataRoot

        Get-ChildItem `
            -Path $brainRoot `
            -Directory `
            -ErrorAction SilentlyContinue |
        ForEach-Object {
            $sessionDirectory = $_

            $normalLog = Join-Path `
                $sessionDirectory.FullName `
                ".system_generated\logs\transcript.jsonl"

            $fullLog = Join-Path `
                $sessionDirectory.FullName `
                ".system_generated\logs\transcript_full.jsonl"

            $transcript = $null

            if (Test-Path $normalLog) {
                $transcript = Get-Item $normalLog
            }
            elseif (Test-Path $fullLog) {
                $transcript = Get-Item $fullLog
            }

            if ($null -eq $transcript) {
                return
            }

            $conversationId = $sessionDirectory.Name
            $summary = $summaryIndex[$conversationId]

            $title = ""
            $preview = ""
            $workspacePath = ""

            if ($null -ne $summary) {
                $title = $summary.Title
                $preview = $summary.Preview
                $workspacePath = $summary.WorkspacePath
            }

            $firstUserMessage = Get-FirstUserMessage `
                -TranscriptPath $transcript.FullName

            if ([string]::IsNullOrWhiteSpace($title)) {
                $title = $preview
            }

            if ([string]::IsNullOrWhiteSpace($title)) {
                $title = $firstUserMessage
            }

            if ([string]::IsNullOrWhiteSpace($title)) {
                $title = "未命名对话"
            }

            $workspaceName = ""

            if (-not [string]::IsNullOrWhiteSpace($workspacePath)) {
                $workspaceName = Split-Path `
                    -Path $workspacePath `
                    -Leaf
            }

            if ([string]::IsNullOrWhiteSpace($workspaceName)) {
                $workspaceName = "未关联工作区"
            }

            [PSCustomObject]@{
                Transcript = $transcript
                ConversationId = $conversationId
                Title = Get-PlainText `
                    -Text $title `
                    -MaxLength 90
                FirstUserMessage = $firstUserMessage
                WorkspaceName = $workspaceName
                WorkspacePath = $workspacePath
                LastWriteTime = $transcript.LastWriteTime
                Source = Split-Path $dataRoot -Leaf
            }
        }
    }

    return @(
        $logs | Sort-Object LastWriteTime -Descending
    )
}

try {
    $logs = Get-ConversationLogs

    if ($logs.Count -eq 0) {
        throw "未找到会话日志。已检查 .gemini\antigravity、antigravity-ide、antigravity-cli 下的 brain 目录。"
    }

    Write-Host ""
    Write-Host "可导出的最近会话：" -ForegroundColor Cyan

    $shownLogs = @(
        $logs | Select-Object -First 30
    )

    for ($i = 0; $i -lt $shownLogs.Count; $i++) {
        $session = $shownLogs[$i]

        Write-Host ""

        Write-Host (
            "[{0}] {1:yyyy-MM-dd HH:mm}  [{2}]" -f `
            ($i + 1), `
            $session.LastWriteTime, `
            $session.WorkspaceName
        ) -ForegroundColor Cyan

        Write-Host (
            "    {0}" -f $session.Title
        ) -ForegroundColor White

        if (-not [string]::IsNullOrWhiteSpace($session.WorkspacePath)) {
            Write-Host (
                "    工作区：{0}" -f $session.WorkspacePath
            ) -ForegroundColor DarkGray
        }

        if (
            -not [string]::IsNullOrWhiteSpace($session.FirstUserMessage) -and
            $session.FirstUserMessage -ne $session.Title
        ) {
            Write-Host (
                "    首句：{0}" -f $session.FirstUserMessage
            ) -ForegroundColor DarkGray
        }

        Write-Host (
            "    来源：{0}，ID：{1}..." -f `
            $session.Source, `
            $session.ConversationId.Substring(0, 8)
        ) -ForegroundColor DarkGray
    }

    Write-Host ""

    $selection = Read-Host `
        "请输入要导出的会话编号（输入 q 取消）"

    if ($selection -eq "q") {
        Write-Host "已取消。" -ForegroundColor Yellow
        exit 0
    }

    $selectedIndex = 0

    if (-not [int]::TryParse($selection, [ref]$selectedIndex)) {
        throw "请输入有效的数字编号。"
    }

    if (
        $selectedIndex -lt 1 -or
        $selectedIndex -gt $shownLogs.Count
    ) {
        throw "编号超出范围。"
    }

    $selectedSession = $shownLogs[$selectedIndex - 1]
    $selectedLog = $selectedSession.Transcript

    Write-Host ""
    Write-Host (
        "正在导出：{0}" -f $selectedSession.Title
    ) -ForegroundColor Cyan

    Write-Host (
        "读取日志：{0}" -f $selectedLog.FullName
    ) -ForegroundColor DarkGray

    $turns = New-Object System.Collections.Generic.List[object]
    $currentTurn = $null

    foreach (
        $line in Get-Content `
            -Path $selectedLog.FullName `
            -Encoding UTF8
    ) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        try {
            $entry = $line | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            continue
        }

        $type = [string]$entry.type
        $source = [string]$entry.source
        $text = Get-EntryText -Entry $entry

        if ([string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        $isUserMessage = (
            $type -match "USER_INPUT|USER_MESSAGE" -or
            $source -match "USER|USER_EXPLICIT"
        )

        $isModelMessage = (
            $type -match "PLANNER_RESPONSE|MODEL_RESPONSE|ASSISTANT" -or
            $source -match "MODEL|ASSISTANT"
        ) -and $type -notmatch "TOOL|COMMAND|THOUGHT"

        if ($isUserMessage) {
            $currentTurn = [PSCustomObject]@{
                UserText = $text
                ModelResponses = New-Object `
                    System.Collections.Generic.List[string]
            }

            $turns.Add($currentTurn)
        }
        elseif ($isModelMessage) {
            if ($null -eq $currentTurn) {
                $currentTurn = [PSCustomObject]@{
                    UserText = "会话开始"
                    ModelResponses = New-Object `
                        System.Collections.Generic.List[string]
                }

                $turns.Add($currentTurn)
            }

            $currentTurn.ModelResponses.Add($text)
        }
    }

    if ($turns.Count -eq 0) {
        throw "日志已找到，但未识别到可导出的用户或模型消息。"
    }

    $builder = New-Object System.Text.StringBuilder
    $turnNumber = 0

    [void]$builder.AppendLine("# $($selectedSession.Title)")
    [void]$builder.AppendLine()

    if (-not [string]::IsNullOrWhiteSpace($selectedSession.WorkspacePath)) {
        [void]$builder.AppendLine(
            "> 工作区：$($selectedSession.WorkspacePath)"
        )
        [void]$builder.AppendLine()
    }

    foreach ($turn in $turns) {
        $turnNumber++

        [void]$builder.AppendLine("## 第 $turnNumber 轮对话")
        [void]$builder.AppendLine()

        [void]$builder.AppendLine("### 用户")
        [void]$builder.AppendLine()
        [void]$builder.AppendLine(
            (Wrap-InCodeBlock -Text $turn.UserText)
        )
        [void]$builder.AppendLine()

        if ($turn.ModelResponses.Count -gt 0) {
            if ($OnlyFinalResponsePerTurn) {
                $modelText = $turn.ModelResponses[
                    $turn.ModelResponses.Count - 1
                ]
            }
            else {
                $modelText = $turn.ModelResponses -join "`n`n---`n`n"
            }

            [void]$builder.AppendLine("### Antigravity")
            [void]$builder.AppendLine()
            [void]$builder.AppendLine(
                (Wrap-InCodeBlock -Text $modelText)
            )
            [void]$builder.AppendLine()
        }
    }

    $markdown = $builder.ToString().TrimEnd()

    if ([string]::IsNullOrWhiteSpace($markdown)) {
        throw "导出结果为空，已停止写入文件。"
    }

    Set-Content `
        -Path $OutputFile `
        -Value $markdown `
        -Encoding UTF8

    Set-Clipboard -Value $markdown

    Write-Host ""
    Write-Host (
        "导出完成：共 {0} 轮对话。" -f $turnNumber
    ) -ForegroundColor Green

    Write-Host (
        "文件位置：{0}" -f $OutputFile
    ) -ForegroundColor Green

    Write-Host "内容已复制到剪贴板。" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host (
        "导出失败：{0}" -f $_.Exception.Message
    ) -ForegroundColor Red
}

Write-Host ""
Read-Host "按 Enter 键关闭窗口"
