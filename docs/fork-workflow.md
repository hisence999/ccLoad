# Fork 同步与本地开发工作流

适用场景：

- 这个仓库是你自己的 fork：`origin = hisence999/ccLoad`
- 原始仓库是：`upstream = caidaoli/ccLoad`
- 你希望及时同步上游修复，同时保留自己的开发分支和实验环境

---

## 当前约定

已配置好的远程：

- `origin`: `https://github.com/hisence999/ccLoad`
- `upstream`: `https://github.com/caidaoli/ccLoad.git`

已配置好的本地 Git 偏好：

- `pull.rebase=true`
- `rebase.autoStash=true`
- `branch.autoSetupRebase=always`
- `remote.pushDefault=origin`

目标效果：

- 本地 `master` 尽量贴近上游 `upstream/master`
- 个人开发一律在功能分支上做
- 对外同步上游修复时，先更新本地 `master`，再从 `master` 拉开发分支

---

## 一次性本地开发环境

### 1. 准备环境文件

推荐从下面两个模板任选一个开始：

- 通用模板：`.env.example`
- 本地开发模板：`.env.dev.example`

建议：

```powershell
Copy-Item .env.dev.example .env.local
```

然后把你真正运行时需要的环境变量写进去。这个仓库已经忽略了：

- `.env`
- `.env.local`
- `.env.*.local`

所以本地调试配置不会误提交。

### 2. 本地开发命令

```powershell
make build
make dev
make web-test
go test -tags sonic ./internal/... -v
go test -tags sonic -race ./internal/...
golangci-lint run ./...
```

注意：

- 必须带 `-tags sonic`
- 真正生效的系统配置很多在 Web 管理界面里，不全在 `.env`

---

## 推荐分支模型

### 分支职责

- `master`: 你的 fork 主线，尽量跟上游保持同步
- `codex/<topic>`: 日常开发分支
- 如果你自己手工命名，也建议继续沿用 `codex/` 前缀

### 为什么这样做

- 上游修复 PR 合并后，你可以快速把 `master` rebase 到 `upstream/master`
- 你自己的功能开发不会污染同步主线
- 后续要回馈 PR 给原仓库，也更容易整理提交

---

## 日常工作流

### A. 同步上游修复

工作区干净时执行：

```powershell
.\scripts\sync-upstream.ps1
```

如果你想同步后顺手推到自己的 GitHub fork：

```powershell
.\scripts\sync-upstream.ps1 -PushOrigin
```

这个脚本会做：

1. 检查工作区是否干净
2. `git fetch upstream --prune`
3. 切到 `master`
4. `git rebase upstream/master`
5. 可选推送到 `origin/master`

### B. 开新功能分支

```powershell
.\scripts\start-feature.ps1 -Name "improve-channel-sync" -SyncUpstreamFirst
```

这个脚本会做：

1. 先把本地 `master` 同步到上游
2. 从 `master` 创建新分支
3. 自动补 `codex/` 前缀

例如会创建：

```text
codex/improve-channel-sync
```

### C. 开发完成后推送

```powershell
git push -u origin HEAD
```

后续继续推送：

```powershell
git push
```

### D. 上游更新后，让你的功能分支跟进

先同步主线：

```powershell
.\scripts\sync-upstream.ps1
```

再切回你的功能分支：

```powershell
git switch codex/improve-channel-sync
git rebase master
```

这样能保持提交历史比较干净。

---

## 两种同步策略

### 策略 1：你的 `master` 紧跟上游

适合：

- 你希望 fork 主线尽量干净
- 你自己的改动主要都放功能分支

做法：

- `master` 只做上游同步
- 所有个人开发都从功能分支发散

这是我更推荐的方式。

### 策略 2：你的 `master` 带自定义提交

适合：

- 你已经长期在 `master` 上做私有改动

缺点：

- 每次同步上游更容易冲突
- 后续给原仓库提 PR 需要额外整理提交

如果要走这条路，建议尽快把仍在 `master` 上的长期改动迁出到 `codex/*` 分支。

---

## 提交与回馈上游建议

### 如果只是同步上游修复

- 尽量不要修改同步提交内容
- 保持 `master` 干净

### 如果你要把自己的修复回馈给原仓库

推荐流程：

1. 从最新 `master` 开分支
2. 在分支上做最小必要改动
3. 本地通过测试
4. 推到 `origin`
5. 从你的 fork 向 `caidaoli/ccLoad` 发 PR

---

## 你的 Docker 镜像工作流

仓库已经配置了 GitHub Actions：

- 工作流文件：`.github/workflows/docker.yml`
- 目标仓库：`ghcr.io/<你的 GitHub 用户名>/<仓库名>`

对于你当前这个 fork，镜像名会是：

```text
ghcr.io/hisence999/ccload
```

### 自动打标签规则

#### 推送到 `master`

会自动生成：

- `ghcr.io/hisence999/ccload:latest`
- `ghcr.io/hisence999/ccload:master`
- `ghcr.io/hisence999/ccload:sha-<短提交>`

#### 推送到功能分支

例如推送到 `codex/improve-channel-sync`，会生成：

- `ghcr.io/hisence999/ccload:codex-improve-channel-sync`
- `ghcr.io/hisence999/ccload:sha-<短提交>`

不会污染 `latest`。

#### 推送 `v*` tag

例如 `v1.2.3`：

- `ghcr.io/hisence999/ccload:v1.2.3`
- `ghcr.io/hisence999/ccload:1.2`
- `ghcr.io/hisence999/ccload:1`
- 以及标准 `sha-*` 标签

### 手动触发

在 GitHub Actions 页面手动运行 `Build and Push Docker Image` 时，还可以额外指定一个自定义 tag。

---

## 启用 GHCR 推送需要确认的设置

默认工作流使用 GitHub 自带的 `GITHUB_TOKEN` 推送 GHCR，一般不需要你额外配置 PAT。

你只需要确认 fork 仓库设置里这两项是允许的：

1. `Settings -> Actions -> General`
2. Workflow permissions 选择 `Read and write permissions`

如果没开，工作流可能能构建但推不上 GHCR。

### 首次推送后

去 GitHub 个人主页的：

- `Packages`

里可以看到生成的容器镜像，并可设置为 public 或 private。

如果你希望任何人都能直接 `docker pull`，把这个 package 设成 public。

---

## 常用命令速查

查看远程：

```powershell
git remote -v
```

抓取上游：

```powershell
git fetch upstream --prune
```

把本地 `master` 对齐上游：

```powershell
git switch master
git rebase upstream/master
```

从主线开新分支：

```powershell
git switch master
git switch -c codex/your-topic
```

让当前功能分支跟进最新主线：

```powershell
git rebase master
```

---

## 注意事项

- 同步上游前，先保证工作区干净。
- 不要长期在 `master` 上直接开发。
- 如果以后原仓库默认分支从 `master` 改成 `main`，把脚本里的 `BaseBranch` 改成 `main` 即可。
- 如果你需要同时维护“稳定版”和“实验版”，建议新建长期分支，例如 `release/local-stable`，不要让 `master` 承担两种职责。
