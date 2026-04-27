# Choreo Nezha Agent 自动构建

本目录的 agent 改造不直接维护上游源码，而是在 GitHub Actions 中：

1. 拉取 `nezhahq/agent` 的最新 release tag（或手动指定 ref）。
2. 运行 `agent/apply-choreo-ws-tunnel.sh` 做最小改造。
3. 补充 `github.com/coder/websocket` 依赖并 `go mod tidy`。
4. 用 GoReleaser 构建并发布到当前仓库：`smgc-cc/choreo-nezha`。

这个目录仍保留 `agent/choreo-ws-tunnel.patch` 作为人工审阅参考；CI 实际使用脚本应用改造，避免 unified diff 因上游微小行号变化失效。

## 改造内容

Patch 做两件事：

- `server` 支持 `ws://` / `wss://`：agent 仍使用原生 gRPC API，但底层 transport 走 WebSocket `net.Conn`。
- 自动更新默认改为检查 `smgc-cc/choreo-nezha` release，避免自定义 agent 被官方 release 覆盖。

## Agent 配置示例

```yaml
server: wss://nezha.example.com/grpc-tunnel
client_secret: your-client-secret
# server 使用 wss:// 时，TLS 配置只作用在 WebSocket URL 本身；gRPC 内层使用 insecure transport。
tls: false
# 可选；patch 默认就是 smgc-cc/choreo-nezha。
update_repo: smgc-cc/choreo-nezha
```

也可以用环境变量：

```bash
NZ_SERVER=wss://nezha.example.com/grpc-tunnel
NZ_CLIENT_SECRET=your-client-secret
NZ_TLS=false
NZ_UPDATE_REPO=smgc-cc/choreo-nezha
```

## 手动触发构建

在 GitHub Actions 运行 `Build Choreo Nezha Agent`：

- `upstream_ref` 留空：使用上游最新 release tag。
- `upstream_ref` 指定如 `v1.13.0`：构建指定上游版本。
- `choreo_suffix` 默认 `choreo.1`，最终 release tag 形如 `v1.13.0-choreo.1`。

## 注意

Choreo 服务端仍需要一个 Public WS endpoint，并在容器内把 `/grpc-tunnel` WebSocket 隧道转发到 Nezha 原生 `127.0.0.1:8008`。Cloudflare Worker 只做 WS 代理，不解析 gRPC。
