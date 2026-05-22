$ErrorActionPreference = "Stop"

param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [string]$BaseBranch = "master",
    [switch]$SyncUpstreamFirst
)

function Normalize-BranchName([string]$raw) {
    $value = $raw.Trim().ToLowerInvariant()
    $value = $value -replace "[^a-z0-9/_-]", "-"
    $value = $value -replace "-{2,}", "-"
    $value = $value.Trim("-")
    if (-not $value) {
        throw "分支名不能为空。"
    }
    return $value
}

if ($SyncUpstreamFirst) {
    & "$PSScriptRoot\sync-upstream.ps1" -BaseBranch $BaseBranch
}

$branchName = Normalize-BranchName $Name
if (-not $branchName.StartsWith("codex/")) {
    $branchName = "codex/$branchName"
}

Write-Host "==> 切换到 $BaseBranch"
git switch $BaseBranch

Write-Host "==> 创建并切换到 $branchName"
git switch -c $branchName

Write-Host "新开发分支已就绪: $branchName"

