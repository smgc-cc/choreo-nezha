# Nezha Dashboard - Choreo 部署版本

这是 Nezha 监控面板的 Choreo 平台适配版本。目标是在 Choreo 的限制下尽量少改上游：

- Dashboard 直接基于 `ghcr.io/nezhahq/nezha:latest`
- 运行时可写数据全部放到 `/tmp`
- 通过 R2/S3 或 WebDAV 定时备份 `/tmp` 数据
- REST 与 WebSocket 拆分到不同端口，符合 Choreo endpoint 限制
- 外部 Agent 通过 gRPC-over-WebSocket 接入
- 容器内可选内置一个上游原版 `nezha-agent`

两套边缘方案：

1. **模式一（推荐）**：Cloudflare Snippet + 原生 WS 穿透
2. **模式二（备选）**：全流量 Cloudflare Worker

## 主要特性

- 支持 Choreo 只读文件系统：`/dashboard/data -> /tmp`
- 支持 R2/S3 或 WebDAV 备份后端
- 容器启动时自动恢复最新备份
- 每 2 小时自动备份，默认保留 7 天
- 备份 SQLite、`config.yaml`、VictoriaMetrics TSDB、GeoIP 数据库
- Dashboard REST endpoint 与 WebSocket endpoint 分端口暴露
- Cloudflare Snippet 处理 Choreo Public URL 路径前缀（模式一）
- `/grpc-tunnel` 支持外部 patched Agent 通过 WebSocket 上报
- 可选启动内置 `nezha-agent`，直接连接本机 `127.0.0.1:8008`

---

## 模式一：Snippet（推荐）

### 架构

```text
nezha.example.com（本 zone 橙云 + Choreo 自定义域）
├── HTTP  → Snippet → CHOREO_ORIGIN + /default/nezha/v1.0/...
└── WebSocket
      注入补路径前缀（WS_PUBLIC_HOST 为空 = 同源）
      wss://nezha.example.com/default/nezha/nezha_ws/v1.0/...
      → 原生穿透 → Choreo WS → Caddy :8009
           ├─ /grpc-tunnel → grpc-ws-tunnel :8010 → Nezha :8008
           └─ 其他 WS      → Nezha Dashboard :8008

外部 patched Agent
  server: wss://nezha.example.com/default/nezha/nezha_ws/v1.0/grpc-tunnel

内置 Agent（可选）
  -> /dashboard/nezha-agent -> 127.0.0.1:8008
```

同源时 `nz-jwt` 为 **host-only**，终端等需登录态的 WS 可直接带 cookie，**不必**再设 `Domain=.host` / `SameSite=None`。

### 前提

| 项 | 说明 |
|---|---|
| DNS | 域名在 **本 Cloudflare zone** 橙云 |
| Choreo | 自定义域名绑到组件（一服务通常一个自定义域） |
| Network | **WebSockets = On** |
| SSL 回源 | 源站为 `*.choreoapis.dev` 时建议 **Full**（非 Full Strict） |

### Snippet

文件：`worker/_snippet.js`

```javascript
const CHOREO_ORIGIN = "xxxxx-dev.e1-us-east-azure.choreoapis.dev";
const HTTP_PATH_PREFIX = "/default/nezha/v1.0";
const WS_PATH_PREFIX = "/default/nezha/nezha_ws/v1.0";
// 单域名：留空 = WebSocket 与页面同 host（推荐）
const WS_PUBLIC_HOST = "";
// 一般保持空（host-only cookie）
const COOKIE_DOMAIN = "";
```

匹配：你的面板域名（如 `nezha.example.com`）。

要点：

- HTTP：`toChoreoHttpPath` 补 REST 前缀；误带 `nezha_ws` 时改写成 REST
- `WS_PUBLIC_HOST === ""` 时注入只补路径前缀，不改 host
- HTML：注入 monkey-patch `window.WebSocket`；`Cache-Control: no-store`
- 仍会把上游 agent 安装脚本 URL 改成本仓库 `agent/install.sh`
- **不要**再对同一域名挂全流量 Worker

### Caddy（容器 8009）

文件：`script/Caddyfile`

- 剥网关前缀 `/default/nezha/nezha_ws/v1.0`（若仍在 path 上）
- `/grpc-tunnel` → `127.0.0.1:8010`（grpc-ws-tunnel）
- 其他 → `127.0.0.1:8008`（Dashboard WS）

### Agent

见 [AGENT.choreo.md](./AGENT.choreo.md)。

```yaml
server: wss://nezha.example.com/default/nezha/nezha_ws/v1.0/grpc-tunnel
client_secret: YOUR_SECRET
tls: false
```

一键安装：

```bash
curl -L https://raw.githubusercontent.com/smgc-cc/choreo-nezha/main/agent/install.sh -o agent.sh \
  && chmod +x agent.sh \
  && env \
    NZ_SERVER=wss://nezha.example.com/default/nezha/nezha_ws/v1.0/grpc-tunnel \
    NZ_TLS=false \
    NZ_CLIENT_SECRET=$2 \
    NZ_UUID=$uuid \
    ./agent.sh
```

### 验证

```bash
# 注入（应看到 WebSocket 脚本与 nezha_ws 前缀）
curl -sS "https://nezha.example.com/" | grep -oE "window.WebSocket|nezha_ws" | head -5

# HTTP
curl -sS "https://nezha.example.com/api/v1/server" | head -c 200; echo

# Agent 隧道（期望 101 或业务关闭，不要 530 HTML）
curl --http1.1 -sS -D- -o /dev/null -m 12 \
  -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  "https://nezha.example.com/default/nezha/nezha_ws/v1.0/grpc-tunnel" | head -12
```

浏览器 DevTools → WS：路径应带 `/default/nezha/nezha_ws/v1.0/...`。

---

## 模式二：全流量 Worker（备选）

文件：`worker/_worker_standalone.js`

```text
nezha.example.com（Worker 自定义域）
├── HTTP → Worker → Choreo REST 前缀
└── WS   → Worker → Choreo WS 前缀 → Caddy
```

### 何时用

- 没有 Snippet
- 可接受 Workers **日请求额度**（页面、静态资源也计次）

### 部署

1. Create Worker，粘贴 `_worker_standalone.js`，改 `CHOREO_ORIGIN` / 前缀
2. 绑定自定义域名

### Agent

短路径即可（Worker 补 WS 前缀）：

```yaml
server: wss://nezha.example.com/grpc-tunnel
tls: false
```

生产更推荐模式一（HTTP 走 Snippet，WS 穿透不计 Worker 请求）。

---

## Choreo 组件

### 1. 创建 Service Component

构建配置：

```text
Build Preset: Docker
Dockerfile Path: Dockerfile
Component Directory: /
```

### 2. Endpoint

仓库已包含 `.choreo/component.yaml`：

| endpoint | 端口 | 类型 | 用途 |
|---|---:|---|---|
| `nezha` | `8008` | `REST` | Dashboard HTTP 页面和 API |
| `nezha_ws` | `8009` | `WS` | 前端 WebSocket 和 `/grpc-tunnel` |

不要增加 Public `GRPC` endpoint。Choreo 的 `GRPC` endpoint 只能是 `Project` visibility，不能作为公网 Agent 入口。

> Choreo 不支持同一个 Public endpoint 同时承载 REST、WebSocket、gRPC。Nezha 自身虽然在 8008 支持 HTTP/WS/gRPC 多路复用，但在 Choreo 上必须拆分。

### 3. 环境变量（最小推荐）

```bash
NZ_AGENTSECRETKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
NEZHA_ENABLE_LOCAL_AGENT=true
NEZHA_LOCAL_AGENT_UUID=11111111-1111-1111-1111-111111111111
```

R2：

```bash
BACKUP_BACKEND=r2
R2_ACCESS_KEY_ID=your_r2_access_key_id
R2_SECRET_ACCESS_KEY=your_r2_secret_access_key
R2_ENDPOINT_URL=https://your-account-id.r2.cloudflarestorage.com
R2_BUCKET_NAME=nezha-backup
```

WebDAV：

```bash
BACKUP_BACKEND=webdav
WEBDAV_URL=https://dav.example.com/remote.php/dav/files/your-user/nezha/backups
WEBDAV_USERNAME=your-user
WEBDAV_PASSWORD=your-app-password
```

### 4. 部署

1. Choreo **Build Latest** → 部署
2. 记录 Public URL，例如：

```text
https://xxxx-dev.e1-us-east-azure.choreoapis.dev/default/nezha/v1.0
```

3. 绑定自定义域到组件
4. 按上文部署 Snippet（模式一）或 Worker（模式二）

---

## 文件结构

```text
choreo-nezha/
├── Dockerfile
├── worker/
│   ├── _snippet.js                   # 模式一 Snippet（推荐）
│   └── _worker_standalone.js         # 模式二 全流量 Worker
├── .choreo/
│   └── component.yaml
├── script/
│   ├── backup.sh
│   ├── entrypoint.sh
│   ├── crontab
│   └── Caddyfile                     # WS 前缀剥离 + /grpc-tunnel 分流
├── agent/
│   ├── apply-choreo-ws-tunnel.sh
│   ├── grpc-ws-tunnel.go
│   └── install.sh
├── AGENT.choreo.md
└── README.choreo.md
```

---

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

---

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

---

## 内置 Agent

Dockerfile 会从 `https://github.com/nezhahq/agent` 拉取最新 tag，构建上游原版 `nezha-agent`。

启用：

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

- 内置 Agent 不走边缘、不走 `/grpc-tunnel`
- 内置 Agent 不需要 patched WebSocket agent
- `NEZHA_LOCAL_AGENT_UUID` 建议固定，否则 `/tmp` 丢失后可能注册成新机器

---

## 外部 Agent

由于 Choreo 不支持 Public gRPC endpoint，外部 Agent 需要使用 **patched** 版本，通过 WebSocket 连接。

| 模式 | `server` |
|---|---|
| 模式一 Snippet | `wss://nezha.example.com/default/nezha/nezha_ws/v1.0/grpc-tunnel` |
| 模式二 Worker | `wss://nezha.example.com/grpc-tunnel` |

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

更多说明见 [AGENT.choreo.md](./AGENT.choreo.md)。

---

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

---

## 故障排查

| 现象 | 处理 |
|---|---|
| 页面 404 | Snippet/Worker 的 `HTTP_PATH_PREFIX` 与 Choreo REST 路径不一致 |
| 无 WebSocket 注入 | Snippet 未匹配域名 / 未部署 |
| WS 无 `nezha_ws` 前缀 | 注入未生效；或模式二应用了短路径但走的是穿透 |
| 模式一 Agent 连不上 | `server` 是否带 `/default/nezha/nezha_ws/v1.0/grpc-tunnel` |
| WS 530 HTML | 域名未橙云 / 未绑 Choreo 自定义域 / WebSockets 未开 |
| Dashboard Oops / Blocked | 清 `status.sfun.cc` 的 cookie 后重登；仍 Blocked 则解 WAF IP |
| 终端立刻 Session completed | 多域名：Snippet 注入 `?token=`；确认会话有效且 RealIP 稳定 |
| 终端鉴权失败 | 是否同源；同父域可 `COOKIE_DOMAIN`；跨注册域用原生 `?token=` |
| 外部 Agent 525 / text/plain | 打到了 CF/Choreo 错误页；确认 patched agent + `wss://.../grpc-tunnel` |
| 内置 Agent 没出现 | `NEZHA_ENABLE_LOCAL_AGENT=true` 且 secret/uuid 已设 |
| 备份未执行 | `cat /tmp/backup.log` 与 `BACKUP_BACKEND` 相关变量 |
| 恢复后 Agent secret 不一致 | entrypoint 会 `sync_agent_secret_key`；确认环境变量未变 |
| Worker 额度打满 | 改回模式一 |

### 页面 404

确认 Snippet/Worker 中：

```js
const HTTP_PATH_PREFIX = "/default/nezha/v1.0";
```

与 Choreo REST Public URL 的路径一致。

### WebSocket 连接失败

**模式一:**

1. Snippet 已部署且匹配面板域名
2. 浏览器 WS URL 含 `/default/nezha/nezha_ws/v1.0`
3. Cloudflare WebSockets On；域名橙云；Choreo 已绑自定义域
4. 容器 Caddy 能剥前缀并转发

**模式二:**

```js
const WS_PATH_PREFIX = "/default/nezha/nezha_ws/v1.0";
```

并确认 `.choreo/component.yaml` 中 `nezha_ws` 为 `type: WS` / `port: 8009`。

### 外部 Agent 报 525 或 content-type text/plain

说明 Agent 打到了 Cloudflare/Choreo 错误页面，不是隧道。

```yaml
server: wss://你的域名/default/nezha/nezha_ws/v1.0/grpc-tunnel   # 模式一
# 或
server: wss://你的域名/grpc-tunnel                               # 模式二
tls: false
```

不要使用原生 gRPC 地址连接 Choreo Public URL。

---

## 限制与注意事项

- `/tmp` 非持久化，最多可能丢失两次备份之间的数据
- TSDB 数据可能较大，WebDAV 上传可能比 R2 慢
- Public gRPC 在 Choreo 不可用，外部 Agent 必须走 `/grpc-tunnel`（patched）
- 内置 Agent 只代表 Choreo 容器本身，不代表外部服务器
- 建议固定 `NZ_AGENTSECRETKEY` 和 `NEZHA_LOCAL_AGENT_UUID`
- 模式一 **不需要** Worker；模式二才部署 `_worker_standalone.js`

---

## 对比

| | 模式一 Snippet | 模式二 Worker |
|---|---|---|
| Agent `server` | **长** `wss://.../nezha_ws/v1.0/grpc-tunnel` | **短** `wss://.../grpc-tunnel` |
| 边缘费用 | HTTP≈免费；WS 穿透 | 全流量计 Workers |
| 终端 cookie | 同源 host-only | 同源 Cookie |
| 推荐 | **生产默认** | 无 Snippet / 图简单时 |

---

## 附录：Snippets 多域名特例（可选，非必须）

仅当 **面板入口域名** 与 **Choreo 绑定域名** 不是同一个时使用（例如品牌域经 SaaS、snippets 基建域在另一 zone）。

示例（与本仓库线上一致时可对照）：

| 角色 | 主机 |
|---|---|
| 浏览器入口（Snippet） | `nezha.example.com` |
| Choreo 绑定 + Agent + WS 穿透 | `nezha.snippet.com` |

Snippet：

```javascript
const WS_PUBLIC_HOST = "nezha.snippet.com"; // 浏览器 WS 改到基建域
const COOKIE_DOMAIN = ""; // 跨注册域无法共享 cookie，保持空
```

匹配规则加上 **入口域 + 基建域** 两个 host（基建域若也出 HTML，需同样挂 Snippet 或可只访问入口域）。

影响：

- 浏览器 WS 在基建域；**跨注册域 cookie 带不过去**
- 终端 / 文件管理 WS：Snippet 仅在 `/dashboard/terminal*` 等页注入，并用 Nezha 原生 `?token=`（`TokenLookup` 已支持）
- HTML 带 `Cache-Control: no-store`
- Agent 建议：  
  `server: wss://nezha.snippet.com/default/nezha/nezha_ws/v1.0/grpc-tunnel`
- 日常从入口域登录并打开终端；勿在未登录的基建域直接开终端页

故障对照：

| 现象 | 原因 |
|---|---|
| Dashboard **Oops / unexpected error** | 浏览器带着**失效** `nz-jwt` 请求 `/api/v1/setting` 等；Nezha `fallbackAuth` 会 `BlockIP` 并返回 **Blocked HTML**（`you were blocked by nezha WAF`），前端当 JSON 解析失败。处理：清站点 cookie 后重新登录；若仍 403 Blocked，在 WAF 封禁列表解封你的 IP，或等封锁窗口过期 |
| 打开终端立刻 Session completed | WS 到基建域无登录态：需多域名 Snippet 注入 `?token=`；或会话因 **IP 绑定**失败（JWT session 绑定登录时 RealIP） |
| 入口域裸 WS 530 | 正常：入口域未绑 Choreo，WS 必须走 `WS_PUBLIC_HOST` |
| Agent 在线但终端不行 | Agent 走 `/grpc-tunnel` 不依赖浏览器 cookie；终端 WS 要鉴权 |

**默认部署不必多域名。** 能单域名绑 Choreo 时，优先单域名（`WS_PUBLIC_HOST = ""`），无需 `?token=` query。

---

## 相关文档

- [AGENT.choreo.md](./AGENT.choreo.md)：外部 patched Agent 构建与使用
- `.choreo/component.yaml`：Choreo endpoint 配置
- `worker/_snippet.js`：模式一 Snippet（推荐）
- `worker/_worker_standalone.js`：模式二全流量 Worker
- `script/Caddyfile`：WS 前缀剥离与 `/grpc-tunnel` 分流
- `script/backup.sh`：R2/WebDAV 备份脚本
