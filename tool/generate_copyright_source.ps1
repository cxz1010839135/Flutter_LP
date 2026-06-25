# 生成软件著作权登记用源程序鉴别材料（前30页 + 后30页，每页50行）
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\generate_copyright_source.ps1

param(
    [string]$Version = "1.7.9",
    [string]$SoftwareName = "领鹏智能机器人上位机软件",
    [int]$Pages = 30,
    [int]$LinesPerPage = 50
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

$outDir = Join-Path $root "docs\copyright"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$utf8 = New-Object System.Text.UTF8Encoding $false

$files = Get-ChildItem -Path (Join-Path $root "lib") -Recurse -Filter *.dart | Sort-Object FullName
$allLines = New-Object System.Collections.Generic.List[string]

foreach ($f in $files) {
    $rel = $f.FullName.Substring($root.Path.Length + 1).Replace("\", "/")
    [void]$allLines.Add("")
    [void]$allLines.Add("// ===== File: $rel =====")
    foreach ($line in [System.IO.File]::ReadAllLines($f.FullName, $utf8)) {
        [void]$allLines.Add($line)
    }
}

$total = $allLines.Count
$need = $LinesPerPage * $Pages
Write-Host "Total source lines: $total"

function Format-Pages {
    param(
        [System.Collections.Generic.List[string]]$lines,
        [string]$Title
    )
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine($Title)
    [void]$sb.AppendLine("软件名称：$SoftwareName")
    [void]$sb.AppendLine("版本号：V$Version")
    [void]$sb.AppendLine("编程语言：Dart (Flutter)")
    [void]$sb.AppendLine("生成日期：$(Get-Date -Format 'yyyy-MM-dd')")
    [void]$sb.AppendLine("")

    $pageNum = 1
    for ($i = 0; $i -lt $lines.Count; $i += $LinesPerPage) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("--- 第 $pageNum 页 ---")
        $end = [Math]::Min($i + $LinesPerPage - 1, $lines.Count - 1)
        for ($j = $i; $j -le $end; $j++) {
            [void]$sb.AppendLine($lines[$j])
        }
        $pageNum++
    }
    return $sb.ToString()
}

$front = $allLines.GetRange(0, [Math]::Min($need, $total))
$backStart = [Math]::Max(0, $total - $need)
$back = $allLines.GetRange($backStart, $total - $backStart)

$frontPath = Join-Path $outDir "源程序-前30页.txt"
$backPath = Join-Path $outDir "源程序-后30页.txt"

$frontTitle = "$SoftwareName V$Version - 源程序(前30页)"
$backTitle = "$SoftwareName V$Version - 源程序(后30页)"

[System.IO.File]::WriteAllText($frontPath, (Format-Pages $front $frontTitle), $utf8)
[System.IO.File]::WriteAllText($backPath, (Format-Pages $back $backTitle), $utf8)

Write-Host "Written: $frontPath"
Write-Host "Written: $backPath"
