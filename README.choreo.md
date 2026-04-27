# Nezha Dashboard - Choreo 部署版本

这是 Nezha 监控面板的 Choreo 平台适配版本。目标是在 Choreo 的限制下尽量少改上游：

- Dashboard 直接基于 `ghcr.io/nezhahq/nezha:latest`
- 运行时可写数据全部放到 `/tmp`
- 通过 R2/S3 或 WebDAV 定时备份 `/tmp` 数据
- REST 与 WebSocket 拆分到不同端口，符合 Choreo endpoint 限制
- 外部 Agent 通过 gRPC-over-WebSocket 接入
- 容器内可选内置一个上游原版 `nezha-agent`

## 主要特性

- 支持 Choreo 只读文件系统：`/dashboard/data -> /tmp`
- 支持 R2/S3 或 WebDAV 备份后端
- 容器启动时自动恢复最新备份
- 每 2 小时自动备份，默认保留 7 天
- 备份 SQLite、`config.yaml`、VictoriaMetrics TSDB、GeoIP 数据库
- Dashboard REST endpoint 与 WebSocket endpoint 分端口暴露
- Cloudflare Worker 处理 Choreo Public URL 路径前缀
- `/grpc-tunnel` 支持外部 patched Agent 通过 WebSocket 上报
- 可选启动内置 `nezha-agent`，直接连接本机 `127.0.0.1:8008`

## 当前架构

```text
浏览器 HTTP
  -> Cloudflare Worker
  -> Choreo REST endpoint :8008
  -> Nezha Dashboard

浏览器 WebSocket
  -> Cloudflare Worker
  -> Choreo WS endpoint :8009
  -> Caddy
  -> Nezha Dashboard :8008

外部 Agent
  -> patched choreo-agent
  -> wss://你的域名/grpc-tunnel
  -> Cloudflare Worker
  -> Choreo WS endpoint :8009
  -> Caddy
  -> grpc-ws-tunnel :8010
  -> Nezha Dashboard :8008

内置 Agent（可选）
  -> /dashboard/nezha-agent
  -> 127.0.0.1:8008
```

Choreo endpoint 配置见 `.choreo/component.yaml`：

```yaml
endpoints:
  - name: nezha
    port: 8008
    type: REST
    networkVisibilities:
      - Public

  - name: nezha_ws
    port: 8009
    type: WS
    networkVisibilities:
      - Public
```

> Choreo 不支持同一个 Public endpoint 同时承载 REST、WebSocket、gRPC。Nezha 自身虽然在 8008 支持 HTTP/WS/gRPC 多路复用，但在 Choreo 上必须拆分。

## 文件结构

```text
choreo-nezha/
├── Dockerfile                 # Choreo 专用 Dockerfile
├── worker/
│   └── cloudflare-worker.js          # Cloudflare Worker 代理脚本
├── .choreo/
│   └── component.yaml                # Choreo endpoint 配置
├── script/
│   ├── backup.sh                     # R2/WebDAV 备份与恢复
│   ├── entrypoint.sh                 # 容器启动脚本
│   ├── crontab                       # 定时备份任务
│   ├── Caddyfile                     # WS 分流代理
├── agent/
│   └── apply-choreo-ws-tunnel.sh     # patched 外部 Agent 自动构建脚本
│   └── grpc-ws-tunnel.go             # gRPC-over-WebSocket 隧道
│   └── install.sh                    # agent 一键安装脚本
├── AGENT_CHOREO.md                   # 外部 patched Agent 说明
└── README.choreo.md                  # 本文档
```

## 部署到 Choreo

### 1. 创建 Service Component

在 Choreo Console 创建 Service Component，并连接本仓库。

构建配置：

```text
Build Preset: Docker
Dockerfile Path: Dockerfile
Component Directory: /
```

### 2. 配置 endpoint

仓库已包含 `.choreo/component.yaml`。需要保留两个 Public endpoint：

| endpoint | 端口 | 类型 | 用途 |
|---|---:|---|---|
| `nezha` | `8008` | `REST` | Dashboard HTTP 页面和 API |
| `nezha_ws` | `8009` | `WS` | 前端 WebSocket 和 `/grpc-tunnel` |

不要增加 Public `GRPC` endpoint。Choreo 的 `GRPC` endpoint 只能是 `Project` visibility，不能作为公网 Agent 入口。

### 3. 配置环境变量

最小推荐配置：

```bash
NZ_AGENTSECRETKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
NEZHA_ENABLE_LOCAL_AGENT=true
NEZHA_LOCAL_AGENT_UUID=11111111-1111-1111-1111-111111111111
```

如果使用 R2：

```bash
BACKUP_BACKEND=r2
R2_ACCESS_KEY_ID=your_r2_access_key_id
R2_SECRET_ACCESS_KEY=your_r2_secret_access_key
R2_ENDPOINT_URL=https://your-account-id.r2.cloudflarestorage.com
R2_BUCKET_NAME=nezha-backup
```

如果使用 WebDAV：

```bash
BACKUP_BACKEND=webdav
WEBDAV_URL=https://dav.example.com/remote.php/dav/files/your-user/nezha/backups
WEBDAV_USERNAME=your-user
WEBDAV_PASSWORD=your-app-password
```

### 4. 部署

1. 在 Choreo 点击 **Build Latest**
2. 构建成功后部署到 Development 或 Production 环境
3. 记录 Choreo 生成的 Public URL，例如：

```text
https://xxxx-dev.e1-us-east-azure.choreoapis.dev/default/nezha/v1.0
```

### 5. 部署 Cloudflare Worker

Choreo Public URL 会强制带路径前缀，例如 `/default/nezha/v1.0`。Nezha Dashboard 期望从 `/` 提供页面，因此需要 Worker 去掉/补齐路径前缀。

使用仓库里的 `cloudflare-worker.js`，修改顶部配置：

```js
const CHOREO_ORIGIN = "xxxx-dev.e1-us-east-azure.choreoapis.dev";
const HTTP_PATH_PREFIX = "/default/nezha/v1.0";
const WS_PATH_PREFIX = "/default/nezha/nezha_ws/v1.0";
```

然后在 Cloudflare Worker 绑定自定义域名，例如：

```text
https://nezha.example.com
```

浏览器访问和外部 Agent 都建议使用这个自定义域名。

## 环境变量说明

### choreo-nezha 封装变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `NEZHA_LISTEN_PORT` | `8008` | Dashboard 监听端口，不建议改 |
| `NEZHA_LISTEN_HOST` | `0.0.0.0` | Dashboard 监听地址 |
| `NEZHA_ENABLE_LOCAL_AGENT` | `false` | 是否启动内置 Agent |
| `NEZHA_LOCAL_AGENT_SECRET` | `${NZ_AGENTSECRETKEY}` | 内置 Agent 使用的 client secret |
| `NEZHA_LOCAL_AGENT_UUID` | 空 | 内置 Agent UUID，强烈建议固定 |
| `BACKUP_BACKEND` | `r2` | 备份后端：`r2`、`webdav`、`none` |

推荐固定：

```bash
NZ_AGENTSECRETKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
NEZHA_ENABLE_LOCAL_AGENT=true
NEZHA_LOCAL_AGENT_UUID=11111111-1111-1111-1111-111111111111
```

`NEZHA_LOCAL_AGENT_SECRET` 一般不需要设置，默认复用 `NZ_AGENTSECRETKEY`。

### Dashboard 原生变量

Dashboard 会读取 `NZ_` 前缀环境变量。常用项：

| 变量 | 说明 |
|---|---|
| `NZ_AGENTSECRETKEY` | Agent 认证 secret，建议固定 |
| `NZ_JWTSECRETKEY` | JWT secret，可选 |
| `NZ_LISTENPORT` | Dashboard 原生监听端口配置 |
| `NZ_LISTENHOST` | Dashboard 原生监听地址配置 |
| `NZ_LANGUAGE` | 语言 |
| `NZ_SITENAME` | 站点名 |
| `NZ_FORCEAUTH` | 是否强制登录 |
| `NZ_TSDB_DATAPATH` | TSDB 数据路径 |
| `NZ_TSDB_RETENTIONDAYS` | TSDB 保留天数 |
| `NZ_TSDB_MAXMEMORYMB` | TSDB 内存限制 |

当前 `entrypoint.sh` 会生成 `/tmp/config.yaml`，其中已设置：

```yaml
debug: false
listen_host: 0.0.0.0
listen_port: 8008
location: Asia/Shanghai
language: zh-CN
tsdb:
  data_path: /tmp/tsdb
  retention_days: 30
  max_memory_mb: 256
```

并且在启动和恢复备份后同步：

```yaml
agent_secret_key: ${NZ_AGENTSECRETKEY}
```

这样可以避免 R2/WebDAV 恢复出的旧 `config.yaml` 覆盖当前环境变量中的 `NZ_AGENTSECRETKEY`。

## 备份与恢复

备份脚本：

```text
/dashboard/backup.sh
```

定时任务：

```cron
0 */2 * * * /dashboard/backup.sh backup >> /tmp/backup.log 2>&1
```

### 备份内容

```text
/tmp/sqlite.db
/tmp/config.yaml
/tmp/tsdb/
/tmp/geoip.db
```

SQLite 使用 `VACUUM INTO` 做在线备份。

### R2 模式

```bash
BACKUP_BACKEND=r2
R2_ACCESS_KEY_ID=xxx
R2_SECRET_ACCESS_KEY=xxx
R2_ENDPOINT_URL=https://xxx.r2.cloudflarestorage.com
R2_BUCKET_NAME=nezha-backup
```

备份路径：

```text
s3://$R2_BUCKET_NAME/backups/nezha_backup_YYYYMMDD_HHMMSS.tar.gz
```

### WebDAV 模式

```bash
BACKUP_BACKEND=webdav
WEBDAV_URL=https://dav.example.com/remote.php/dav/files/your-user/nezha/backups
WEBDAV_USERNAME=your-user
WEBDAV_PASSWORD=your-app-password
```

也支持别名：

```bash
WEBDAV_USER=your-user
WEBDAV_PASS=your-app-password
```

备份路径：

```text
$WEBDAV_URL/nezha_backup_YYYYMMDD_HHMMSS.tar.gz
```

`WEBDAV_URL` 应该直接指向存放备份文件的目录。脚本会尝试 `MKCOL`，目录已存在时不会中断。

### 禁用备份

```bash
BACKUP_BACKEND=none
```

也支持：

```bash
BACKUP_BACKEND=off
BACKUP_BACKEND=disabled
```

### 手动备份/恢复

进入容器后执行：

```bash
/dashboard/backup.sh backup
/dashboard/backup.sh restore
```

查看日志：

```bash
cat /tmp/backup.log
```

## 内置 Agent

`Dockerfile.choreo` 会从 `https://github.com/nezhahq/agent` 拉取最新 tag，构建上游原版 `nezha-agent`，并注入上游版本号：

```dockerfile
-X github.com/nezhahq/agent/pkg/monitor.Version=${VERSION}
-X main.arch=$(go env GOARCH)
```

启用内置 Agent：

```bash
NZ_AGENTSECRETKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
NEZHA_ENABLE_LOCAL_AGENT=true
NEZHA_LOCAL_AGENT_UUID=11111111-1111-1111-1111-111111111111
```

内置 Agent 运行配置由 entrypoint 自动生成：

```yaml
server: 127.0.0.1:8008
client_secret: ${NZ_AGENTSECRETKEY}
tls: false
disable_auto_update: true
disable_force_update: true
disable_command_execute: true
disable_nat: true
uuid: ${NEZHA_LOCAL_AGENT_UUID}
```

注意：

- 内置 Agent 不走 Worker、不走 `/grpc-tunnel`
- 内置 Agent 不需要 patched WebSocket agent
- `NEZHA_LOCAL_AGENT_UUID` 建议固定，否则 `/tmp` 丢失后可能注册成新机器

## 外部 Agent

由于 Choreo 不支持 Public gRPC endpoint，外部 Agent 需要使用 patched 版本，通过 WebSocket 连接：

```yaml
server: wss://nezha.example.com/grpc-tunnel
client_secret: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
tls: false
update_repo: smgc-cc/choreo-nezha
```

一键安装脚本

```bash
curl -L https://raw.githubusercontent.com/smgc-cc/choreo-nezha/main/agent/install.sh -o agent.sh && chmod +x agent.sh && env NZ_SERVER=wss://nezha.example.com/grpc-tunnel NZ_TLS=false NZ_CLIENT_SECRET=$2 NZ_UUID=$uuid ./agent.sh
```

### 关于 `NZ_AGENTSECRETKEY` 和 `NZ_CLIENT_SECRET`

Nezha v2 中存在两类 Agent secret：

| Secret | 来源 | 用途 |
|---|---|---|
| `NZ_AGENTSECRETKEY` | Dashboard 配置 `agent_secret_key` | 全局兼容 secret，适合给内置 Agent 使用 |
| `NZ_CLIENT_SECRET` | 当前登录用户的 `users.agent_secret` | Dashboard 页面复制安装命令时使用，适合外部 Agent |

所以即使设置了：

```bash
NZ_AGENTSECRETKEY=$1
```

Dashboard 页面复制出来的安装命令也可能是另一个值：

```bash
NZ_CLIENT_SECRET=$2
```

这是正常现象，不代表 `NZ_AGENTSECRETKEY` 没生效。

推荐使用方式：

- 内置 Agent：使用 `NZ_AGENTSECRETKEY`，因为从 0 启动时可以通过环境变量预先固定。
- 外部 Agent：优先使用 Dashboard 页面复制出来的 `NZ_CLIENT_SECRET`，它属于当前登录用户。

两个 secret 都会被 Dashboard 接受认证，但归属的用户不同。

更多说明见：

```text
AGENT_CHOREO.md
```

## 运行时数据路径

```text
/dashboard/data -> /tmp

/tmp/
├── sqlite.db
├── config.yaml
├── nezha-agent.yml
├── tsdb/
└── geoip.db
```

Choreo 容器重启或重新部署时 `/tmp` 可能丢失，因此必须依赖 R2/WebDAV 恢复。

## 故障排查

### 页面 404

通常是 Choreo 路径前缀问题。确认 Cloudflare Worker 中：

```js
const HTTP_PATH_PREFIX = "/default/nezha/v1.0";
```

与 Choreo REST Public URL 的路径一致。

### WebSocket 连接失败

确认：

```js
const WS_PATH_PREFIX = "/default/nezha/nezha_ws/v1.0";
```

并确认 `.choreo/component.yaml` 中 `nezha_ws` endpoint 是：

```yaml
type: WS
port: 8009
```

### 外部 Agent 报 525 或 content-type text/plain

说明 Agent 打到了 Cloudflare/Choreo 错误页面，不是 Nezha gRPC 服务。

外部 Agent 应使用 patched choreo-agent，并配置：

```yaml
server: wss://你的域名/grpc-tunnel
tls: false
```

不要使用原生 gRPC 地址连接 Choreo Public URL。

### 内置 Agent 没出现

检查环境变量：

```bash
NEZHA_ENABLE_LOCAL_AGENT=true
NZ_AGENTSECRETKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
NEZHA_LOCAL_AGENT_UUID=11111111-1111-1111-1111-111111111111
```

检查日志中是否有：

```text
Starting bundled Nezha Agent...
Connection to 127.0.0.1:8008 established
```

### 备份未执行

检查：

```bash
cat /tmp/backup.log
```

R2 模式检查：

```bash
echo $BACKUP_BACKEND
echo $R2_ENDPOINT_URL
echo $R2_BUCKET_NAME
```

WebDAV 模式检查：

```bash
echo $BACKUP_BACKEND
echo $WEBDAV_URL
echo $WEBDAV_USERNAME
```

### 恢复后 Agent secret 不一致

当前 entrypoint 会在 restore 后执行 `sync_agent_secret_key`，把 `/tmp/config.yaml` 中的 `agent_secret_key` 同步为 `NZ_AGENTSECRETKEY`。

如果仍异常，确认 Choreo 环境变量中 `NZ_AGENTSECRETKEY` 没有变化。

## 限制与注意事项

- `/tmp` 非持久化，最多可能丢失两次备份之间的数据
- TSDB 数据可能较大，WebDAV 上传可能比 R2 慢
- Public gRPC 在 Choreo 不可用，外部 Agent 必须走 `/grpc-tunnel`
- 内置 Agent 只代表 Choreo 容器本身，不代表外部服务器
- 建议固定 `NZ_AGENTSECRETKEY` 和 `NEZHA_LOCAL_AGENT_UUID`

## 相关文档

- `AGENT_CHOREO.md`：外部 patched Agent 自动构建与使用说明
- `.choreo/component.yaml`：Choreo endpoint 配置
- `worker/cloudflare-worker.js`：Cloudflare Worker 代理脚本
- `script/backup.sh`：R2/WebDAV 备份脚本
