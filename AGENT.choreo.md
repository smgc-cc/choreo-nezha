# Choreo Nezha Agent 自动构建

本目录的 agent 改造不直接维护上游源码，而是在 GitHub Actions 中：

1. 拉取 `nezhahq/agent` 的最新 release tag（或手动指定 ref）。
2. 运行 `agent/apply-choreo-ws-tunnel.sh` 做最小改造。
3. 补充 `github.com/coder/websocket` 依赖并 `go mod tidy`。
4. 用 GoReleaser 构建并发布到当前仓库：`smgc-cc/choreo-nezha`。

这个目录仍保留 `agent/choreo-ws-tunnel.patch` 作为人工审阅参考；CI 实际使用脚本应用改造，避免 unified diff 因上游微小行号变化失效。

## 改造内容

Patch 做这些事：

- `server` 支持 `ws://` / `wss://`：agent 仍使用原生 gRPC API，但底层 transport 走 WebSocket `net.Conn`。
- **防半开连接**：WS 层定时 `Ping`（约 25s）+ gRPC client keepalive（20s/10s）。Cloudflare / Choreo 静默掐断空闲 WS 时，能让 stream 出错并进入上游自带的重连循环，避免「掉线后卡死、只能重启 agent」。
- **更快重连**：`delayWhenError` 从上游默认 `10s` 改为 `2s`（断线感知后约 2 秒开始 `Try to reconnect`）。
- 自动更新默认改为检查 `smgc-cc/choreo-nezha` release，避免自定义 agent 被官方 release 覆盖。

服务端 `agent/grpc-ws-tunnel.go` 同样对入站隧道做 WS ping，并在单向 `io.Copy` 结束后关闭两端。

针对上游 `v2.3.0+` 的连接/配置重构，脚本改动点是：

| 文件 | 改动 |
|---|---|
| `cmd/agent/connection_config.go` | 新增 `newClient()`：`ws://`/`wss://` 走 websocket dialer + keepalive + ping；其余走原 `dialOptions()` |
| `cmd/agent/main.go` | `grpc.NewClient(...dialOptions()...)` → `connectionConfig.newClient()`；`delayWhenError` `10s→2s`；`doSelfUpdate` 优先 `update_repo` |
| `cmd/agent/runtime_config_consumers.go` | `updateConfigTuple` 增加 `updateRepo` 字段 |
| `model/config.go` | `AgentConfig` 增加 `UpdateRepo`（`NZ_UPDATE_REPO` / `update_repo`） |

## 模式一（推荐）：长路径 + Snippet（无 Worker）

面板域名与 Choreo 自定义域为 **同一主机**，WS 原生穿透：

```yaml
# https 域名 + Choreo WS 前缀 + /grpc-tunnel（写 wss://）
server: wss://nezha.example.com/default/nezha/nezha_ws/v1.0/grpc-tunnel
client_secret: your-client-secret
# server 使用 wss:// 时，TLS 只作用在 WebSocket URL 本身；gRPC 内层 insecure
tls: false
# 可选；patch 默认就是 smgc-cc/choreo-nezha
update_repo: smgc-cc/choreo-nezha
```

环境变量：

```bash
NZ_SERVER=wss://nezha.example.com/default/nezha/nezha_ws/v1.0/grpc-tunnel
NZ_CLIENT_SECRET=your-client-secret
NZ_TLS=false
NZ_UPDATE_REPO=smgc-cc/choreo-nezha
```

| 流量 | 请求 | 边缘 |
|---|---|---|
| Agent WS | `wss://.../default/nezha/nezha_ws/v1.0/grpc-tunnel` | 原生穿透 → Choreo WS → Caddy → grpc-ws-tunnel |
| 浏览器 WS | 注入补同一 `nezha_ws` 前缀 | 同上（不经 Worker） |
| 浏览器 HTTP | Snippet 补 REST 前缀 | Snippet |

要求：Snippet 匹配该域名；Choreo 已绑自定义域；Cloudflare **WebSockets = On**。

### 一键安装示例

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
HOST=nezha.example.com
PREFIX=/default/nezha/nezha_ws/v1.0

curl --http1.1 -sS -D- -o /dev/null -m 12 \
  -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  "https://${HOST}${PREFIX}/grpc-tunnel" | head -15
```

期望：`101` 或业务侧关闭（非 530 HTML / 525）。

## 模式二：全流量 Worker

Worker 按协议补 REST / WS 前缀时，可用短路径：

```yaml
server: wss://nezha.example.com/grpc-tunnel
tls: false
```

## 不要

| 写法 | 原因 |
|---|---|
| 模式一写 `wss://host/grpc-tunnel`（无 `nezha_ws` 前缀） | 穿透后进不了 Choreo WS endpoint |
| 官方 agent + 原生 gRPC `host:8008` | Choreo 无 Public gRPC |
| `-e` / `server` 写成 `https://` 却期望 gRPC-WS | Nezha patched agent 认 `ws://` / `wss://` |

## 手动触发构建

在 GitHub Actions 运行 `Build Choreo Nezha Agent`：

- `upstream_ref` 留空：使用上游最新 release tag。
- `upstream_ref` 指定如 `v1.13.0`：构建指定上游版本。
- `choreo_suffix` 默认 `choreo.1`，最终 release tag 形如 `v1.13.0-choreo.1`。

## 注意

- Choreo 服务端需要 Public **WS** endpoint；容器内 `/grpc-tunnel` → `grpc-ws-tunnel` → `127.0.0.1:8008`。
- **模式一不需要 Cloudflare Worker**；Worker 只在模式二做路径代理，不解析 gRPC。
- 内置 Agent 仍直连 `127.0.0.1:8008`，不走 `/grpc-tunnel`。

完整部署见 [README.choreo.md](./README.choreo.md)。
