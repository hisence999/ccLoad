$ErrorActionPreference = "Stop"

param(
    [switch]$PushOrigin,
    [string]$BaseBranch = "master"
)

function Assert-CleanWorktree {
    $status = git status --porcelain
    if ($status) {
        Write-Error "工作区不干净，请先提交或暂存改动后再同步上游。"
    }
}

function Assert-RemoteExists([string]$name) {
    $remote = git remote
    if (-not ($remote -split "`n" | Where-Object { $_ -eq $name })) {
        Write-Error "缺少远程 '$name'。"
    }
}

Assert-RemoteExists "origin"
Assert-RemoteExists "upstream"
Assert-CleanWorktree

Write-Host "==> 获取 upstream 最新提交"
git fetch upstream --prune

Write-Host "==> 切换到 $BaseBranch"
git switch $BaseBranch

Write-Host "==> 变基到 upstream/$BaseBranch"
git rebase "upstream/$BaseBranch"

if ($PushOrigin) {
    Write-Host "==> 推送同步后的 $BaseBranch 到 origin"
    git push origin $BaseBranch
} else {
    Write-Host "已完成本地同步。需要时可执行: git push origin $BaseBranch"
}

