---
title: 222 端口数据自动发布脚本使用说明
permalink: /update_serverports_222_usage.html
---
<p><a href="/">返回 Docker 容器查询</a></p>

# 222 端口数据自动发布脚本使用说明

脚本位置：

```text
/Users/kai/code/组内服务器/update_serverports_222.sh
```

该脚本用于从校园网直连 `172.29.7.222`，恢复停止中的主要用户容器，重新生成 `contain_222.json`，并将文件下载到本机 Git 仓库。默认模式会创建本地 commit 并 push；`--row` 模式同样会暂存文件并创建本地 commit，但会在 `git push` 到远程仓库之前停止。

## 执行后会发生什么

脚本会按顺序执行以下操作：

1. 检查本机是否安装 `ssh`、`scp`、`git`、`gh` 等命令。
2. 检查 GitHub CLI 是否已经登录。
3. 本机仓库不存在时，克隆 `ServerPorts/ServerPorts.github.io`。
4. 检查本机仓库必须位于指定分支，且没有未提交改动。
5. 使用 `git pull --ff-only` 同步远程最新内容。
6. 从当前校园网直接 SSH 到 `bmax@172.29.7.222`。
7. 检查 12 个主要用户容器，只对停止中的容器执行 `docker start`。
8. 确认这些容器全部处于运行状态，并显示当前端口映射。
9. 在 222 上运行 `generate_ports_data_for_222.sh`，生成 `contain_222.json`。
10. 检查 JSON 记录数与 `docker ps -a` 容器数一致。
11. 通过 SCP 将 `contain_222.json` 下载到本机仓库。
12. 校验下载文件的基本结构，只暂存 `contain_222.json`。
13. 数据发生变化时创建本地 commit。
14. `--row` 模式在这里停止并打印本地项目、JSON 文件和 commit 信息；默认模式继续正常 push 到远程 `main`。
15. 数据没有变化时直接退出，不创建空提交或 push。

## 重要行为

- 脚本不会重启 Docker daemon。
- 脚本不会重启已经运行的用户容器。
- 脚本只恢复停止中的指定用户容器。
- 脚本不会修改或暂存 221 使用的 `containers.json`。
- 脚本不会 force push。
- 本地仓库存在未提交改动时，脚本会停止执行。
- `git pull --ff-only` 无法快进时，脚本会停止执行，不会自动创建 merge commit。
- `--row` 模式仍会执行 `git add` 和本地 commit，只是不执行 `git push`。
- `--row` 完成后，本地分支通常会显示相对 `origin/main` 为 `ahead 1`，可先检查本地提交再决定是否手动推送。

## 前置条件

### 网络

本机需要处于能够直接访问以下地址的校园网环境：

```text
172.29.7.222:22
```

脚本不再使用 Windows 跳板或 ProxyJump。

可以提前测试：

```bash
nc -vz -w 5 172.29.7.222 22
```

### 本机命令

需要安装：

```text
bash
ssh
scp
git
gh
grep
mv
mkdir
```

### GitHub CLI 登录

检查登录状态：

```bash
gh auth token --hostname github.com >/dev/null && echo "GitHub CLI 已登录"
```

如果尚未登录：

```bash
gh auth login
```

登录账号需要对以下仓库拥有写权限：

```text
ServerPorts/ServerPorts.github.io
```

### SSH 登录

需要能够登录：

```text
bmax@172.29.7.222
```

密码认证时，脚本运行过程中会交互提示输入服务器密码。密码不会写入脚本或本说明文件。

### 222 上的生成脚本

服务器上必须存在：

```text
/home/bmax/ServerPorts.github.io/generate_ports_data_for_222.sh
```

它应生成：

```text
/home/bmax/ServerPorts.github.io/contain_222.json
```

## 基本用法

进入项目目录：

```bash
cd "/Users/kai/code/组内服务器"
```

查看帮助：

```bash
./update_serverports_222.sh --help
```

执行完整恢复和发布流程：

```bash
./update_serverports_222.sh
```

执行到本地 commit 后停止、不推送远程仓库：

```bash
./update_serverports_222.sh --row
```

`--row` 完成后会打印：

```text
row 模式完成：已创建本地 commit，并在 git push 前停止。
本地项目位置: /实际的本地仓库绝对路径
JSON 文件位置: /实际的本地仓库绝对路径/contain_222.json
本地 commit: <短 SHA>
后续推送: 在该项目中执行 git push origin main
```

检查本地提交：

```bash
git -C "/实际的本地仓库绝对路径" status --short --branch
git -C "/实际的本地仓库绝对路径" show --stat --oneline HEAD
```

确认无误后手动推送：

```bash
git -C "/实际的本地仓库绝对路径" push origin main
```

执行过程中可能会提示输入 222 的 SSH 密码。

## 默认配置

| 配置 | 默认值 |
|------|--------|
| GitHub 仓库 | `ServerPorts/ServerPorts.github.io` |
| 本机仓库目录 | `~/ServerPorts.github.io` |
| Git 分支 | `main` |
| SSH 目标 | `bmax@172.29.7.222` |
| 服务器工作目录 | `/home/bmax/ServerPorts.github.io` |
| 服务器生成脚本 | `generate_ports_data_for_222.sh` |
| 下载和提交文件 | `contain_222.json` |

## 可选环境变量

### 指定本机仓库目录

```bash
SERVERPORTS_REPO_DIR="/tmp/ServerPorts.github.io-research" \
  ./update_serverports_222.sh
```

### 指定推送分支

```bash
SERVERPORTS_BRANCH="main" \
  ./update_serverports_222.sh
```

### 指定 SSH 目标

```bash
SERVERPORTS_TARGET_HOST="bmax@172.29.7.222" \
  ./update_serverports_222.sh
```

### 指定服务器目录或生成脚本

```bash
SERVERPORTS_REMOTE_DIR="/home/bmax/ServerPorts.github.io" \
SERVERPORTS_REMOTE_SCRIPT="generate_ports_data_for_222.sh" \
  ./update_serverports_222.sh
```

## 脚本管理的用户容器

当前脚本会检查以下容器：

```text
zhaoshaofan_261019
chenjinming_260930
hongruiqi_260930
cangshihong_251002
liwenjin_260913
sunyu_260121
caiyitian_251104
qianzijuan_251027
liushangqing_250929
wangyu_250801
zhuangyuan_250730
huanglanxin_250710
```

新增、删除或重命名用户容器后，需要同步修改脚本中的 `USER_CONTAINERS` 数组。

## 成功输出

脚本会显示：

- 被恢复的容器名称。
- 当前运行容器和端口映射。
- JSON 生成结果和记录数量。
- 文件下载过程。
- 本地 Git commit 结果。
- 默认模式下的 push 结果，或 `--row` 模式下的本地路径和未推送状态。

默认模式成功结束时输出类似：

```text
完成: 18 条容器记录，commit 1631e9c 已推送到 main。
```

`--row` 模式成功结束时输出类似：

```text
row 模式完成：已创建本地 commit，并在 git push 前停止。
本地项目位置: /Users/kai/ServerPorts.github.io
JSON 文件位置: /Users/kai/ServerPorts.github.io/contain_222.json
本地 commit: 1631e9c
后续推送: 在该项目中执行 git push origin main
## main...origin/main [ahead 1]
```

实际路径、记录数和 commit SHA 会随本机配置及服务器状态变化。

## 执行后验证

检查本地仓库：

```bash
git -C "$HOME/ServerPorts.github.io" status --short --branch
git -C "$HOME/ServerPorts.github.io" log -1 --oneline
```

默认模式完成后，本地应与远程同步且没有未提交改动。`--row` 模式完成后也应没有未提交改动，但分支通常显示 `[ahead 1]`，表示本地 commit 尚未 push。

检查远程 JSON 的生成时间：

```bash
gh api \
  -H "Accept: application/vnd.github.raw+json" \
  "repos/ServerPorts/ServerPorts.github.io/contents/contain_222.json?ref=main" \
  | grep -F '"generated":'
```

确认 221 文件没有被本次提交修改：

```bash
git -C "$HOME/ServerPorts.github.io" show --name-status --oneline HEAD
```

正常情况下应只显示：

```text
M	contain_222.json
```

## 常见错误

### 无法直接连接 222

可能输出 SSH 超时、连接拒绝或路由不可达。

先检查：

```bash
ping 172.29.7.222
nc -vz -w 5 172.29.7.222 22
```

确认本机当前连接校园网，并且没有把该地址错误地交给代理软件处理。

### GitHub CLI 未登录

错误类似：

```text
错误: 请先运行 gh auth login
```

处理：

```bash
gh auth login
```

### 本机仓库存在未提交改动

错误类似：

```text
错误: 本机仓库存在未提交改动，请先处理
```

检查：

```bash
git -C "$HOME/ServerPorts.github.io" status
```

不要直接删除或覆盖未知改动，应先确认改动来源。

### 本机分支不是 main

检查：

```bash
git -C "$HOME/ServerPorts.github.io" branch --show-current
```

确认没有未提交改动后，再切换到正确分支。

### `git pull --ff-only` 失败

这表示本地和远程历史发生分叉。不要 force push，也不要直接覆盖远程。

检查历史：

```bash
git -C "$HOME/ServerPorts.github.io" fetch origin main
git -C "$HOME/ServerPorts.github.io" log --graph --decorate --oneline --all -10
```

确认双方改动后，再决定使用 rebase 或 merge。

### 容器不存在

如果脚本中的容器名称已经失效，`docker inspect` 会失败，脚本将停止，不会继续生成或推送 JSON。

需要登录 222 检查：

```bash
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

然后更新脚本中的 `USER_CONTAINERS` 数组。

### 容器启动后立即退出

脚本会在生成 JSON 前再次检查容器状态。如果容器未保持运行，脚本会停止。

登录 222 检查：

```bash
docker ps -a
docker logs --tail 100 <容器名>
docker inspect <容器名>
```

### JSON 数量校验失败

错误表示：

```text
JSON 记录数 != docker ps -a 容器数
```

登录 222 后手动检查：

```bash
cd /home/bmax/ServerPorts.github.io
./generate_ports_data_for_222.sh
grep -c '"id":' contain_222.json
docker ps -a -q | wc -l
```

不要在数量不一致时强行提交。

### push 被拒绝

这通常表示脚本执行期间远程仓库出现了新提交。普通 push 会安全地拒绝，不会覆盖远程内容。

检查：

```bash
git -C "$HOME/ServerPorts.github.io" fetch origin main
git -C "$HOME/ServerPorts.github.io" log --graph --decorate --oneline --all -10
```

确认远程改动后，再手动合并或 rebase。禁止使用 force push。

## 安全注意事项

- 不要把服务器密码写入脚本、环境变量文件、Git 仓库或本文档。
- 不要使用 `git push --force`。
- 不要跳过 `git pull --ff-only` 和工作区干净检查。
- 不要把 `containers.json` 加入 222 的提交。
- 不要为了更新端口数据而重启 Docker daemon。
- 如果服务器上有正在运行的用户任务，脚本不会主动重启对应容器。
