#Requires -Version 5.1
<#
.SYNOPSIS
  初始化 Git 仓库并推送到 GitHub。

.PARAMETER RepoUrl
  已有仓库地址，如 https://github.com/你的用户名/LPRobot-Flutter.git

.PARAMETER RepoName
  在 GitHub 上新建仓库的名称（未提供 RepoUrl 时使用），默认 LPRobot-Flutter。

.PARAMETER Private
  新建私有仓库（默认公开）。

.PARAMETER SkipCommit
  跳过 git add / commit（已有提交时使用）。

.EXAMPLE
  .\scripts\setup\github-push.ps1
  .\scripts\setup\github-push.ps1 -RepoUrl https://github.com/you/LPRobot-Flutter.git
  .\scripts\setup\github-push.ps1 -RepoName LPRobot-Flutter -Private
#>
param(
    [string]$RepoUrl = '',
    [string]$RepoName = 'LPRobot-Flutter',
    [switch]$Private,
    [switch]$SkipCommit
)

$ErrorActionPreference = 'Stop'

# 刷新 PATH（winget 安装 gh 后当前终端可能尚未生效）
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
    [Environment]::GetEnvironmentVariable('Path', 'User')
$ghExe = 'gh'
foreach ($candidate in @(
        (Join-Path ${env:ProgramFiles} 'GitHub CLI\gh.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'GitHub CLI\gh.exe')
    )) {
    if (Test-Path $candidate) { $ghExe = $candidate; break }
}

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not (Test-Path (Join-Path $ProjectRoot 'pubspec.yaml'))) {
    throw "找不到 pubspec.yaml: $ProjectRoot"
}
Set-Location $ProjectRoot

function Write-Step([string]$Message) {
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-GhAvailable {
    return (Test-Path $ghExe) -or [bool](Get-Command gh -ErrorAction SilentlyContinue)
}

function Invoke-Gh {
    param([string[]]$GhArgs)
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        if (Test-Path $ghExe) {
            & $ghExe @GhArgs 2>&1 | Out-Null
        } else {
            & gh @GhArgs 2>&1 | Out-Null
        }
    } finally {
        $ErrorActionPreference = $oldEap
    }
    return $LASTEXITCODE
}

function Ensure-Gh {
    if (-not (Test-GhAvailable)) {
        if ($RepoUrl) {
            Write-Host '  [注意] 未安装 gh，将仅用 git 推送到 -RepoUrl' -ForegroundColor Yellow
            return
        }
        throw '未找到 gh。请先安装: winget install GitHub.cli'
    }
    $authCode = Invoke-Gh @('auth', 'status')
    if ($authCode -ne 0) {
        if ($RepoUrl) {
            Write-Host '  [注意] gh 未登录，将使用 git 推送（可能弹出 GitHub 凭据窗口）' -ForegroundColor Yellow
            return
        }
        Write-Host '请先在浏览器完成 GitHub 登录（设备码授权）...' -ForegroundColor Yellow
        $loginCode = Invoke-Gh @('auth', 'login', '-h', 'github.com', '-p', 'https', '-w')
        if ($loginCode -ne 0) { throw 'GitHub 登录失败或已取消' }
    }
    & $ghExe auth status 2>&1 | Out-Host
}

function Ensure-GitUser {
    $name = git config user.name 2>$null
    $email = git config user.email 2>$null
    if ($name -and $email) { return }

    $ghLoggedIn = $false
    if (Test-GhAvailable) {
        $ghLoggedIn = ((Invoke-Gh @('auth', 'status')) -eq 0)
    }
    if ($ghLoggedIn) {
        $login = Invoke-Gh @('api', 'user', '-q', '.login')
        $display = Invoke-Gh @('api', 'user', '-q', '.name')
        if (-not $display) { $display = $login }
        git config user.name $display
        git config user.email "$login@users.noreply.github.com"
        Write-Host "  Git 提交身份: $display <$login@users.noreply.github.com>"
        return
    }

    $login = 'cxz1010839135'
    if ($RepoUrl -match 'github\.com[:/]([^/]+)/') {
        $login = $Matches[1]
    }
    git config user.name $login
    git config user.email "$login@users.noreply.github.com"
    Write-Host "  Git 提交身份: $login <$login@users.noreply.github.com>"
}

function Initialize-Repo {
    if (-not (Test-Path (Join-Path $ProjectRoot '.git'))) {
        Write-Step '初始化 Git 仓库'
        git init -b main
    } else {
        Write-Host '  [OK] 已是 Git 仓库'
    }
}

function New-LocalCommit {
    if ($SkipCommit) {
        Write-Host '  [跳过] -SkipCommit'
        return
    }

    Write-Step '提交本地更改'
    git add -A
    $status = git status --porcelain
    if (-not $status) {
        $count = (git rev-list --count HEAD 2>$null)
        if ($count -and [int]$count -gt 0) {
            Write-Host '  [OK] 工作区干净，沿用已有提交'
            return
        }
        throw '没有可提交的文件'
    }

    $msg = @'
Initial commit: LPRobot Flutter 上位机

- Blockly 可视化编程预览
- Windows / Android 打包脚本
- 开发环境配置脚本
'@
    git commit -m $msg
}

function Connect-RemoteAndPush {
    param([string]$Url)

    Write-Step "绑定远程: $Url"
    $existing = git remote get-url origin 2>$null
    if ($existing) {
        if ($existing -ne $Url) {
            git remote set-url origin $Url
        }
    } else {
        git remote add origin $Url
    }

    Write-Step '推送到 GitHub (main)'
    git push -u origin main
}

function New-GithubRepoAndPush {
    Write-Step "在 GitHub 创建仓库: $RepoName"
    $visibility = if ($Private) { '--private' } else { '--public' }
    $createCode = Invoke-Gh @('repo', 'create', $RepoName, $visibility, '--source', '.', '--remote', 'origin', '--push')
    if ($createCode -ne 0) {
        throw 'gh repo create 失败（仓库名可能已存在，请用 -RepoUrl 指定已有仓库）'
    }
}

# -- 主流程 --
Write-Host 'LPRobot Flutter -> GitHub' -ForegroundColor White
Write-Host "工程: $ProjectRoot"

Ensure-Gh
Initialize-Repo
Ensure-GitUser
New-LocalCommit

if ($RepoUrl) {
    $url = $RepoUrl.TrimEnd('/')
    if ($url -notmatch '\.git$') { $url += '.git' }
    Connect-RemoteAndPush -Url $url
} elseif (git remote get-url origin 2>$null) {
    Write-Step '使用已有 origin 远程'
    git push -u origin main
} else {
    New-GithubRepoAndPush
}

Write-Host ''
Write-Host '========================================================' -ForegroundColor Green
Write-Host ' 已推送到 GitHub' -ForegroundColor Green
Write-Host '========================================================' -ForegroundColor Green
$viewUrl = Invoke-Gh @('repo', 'view', '--json', 'url', '-q', '.url') 2>$null
if ($viewUrl) {
    Write-Host "  $viewUrl"
}
