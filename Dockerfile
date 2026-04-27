# ==========================================
# 基于上游 Nezha 镜像进行 Choreo 适配
# ==========================================
FROM ghcr.io/nezhahq/nezha:latest AS upstream

# ==========================================
# 构建 gRPC-over-WebSocket 隧道
# ==========================================
FROM golang:1.26-alpine AS tunnel-builder

WORKDIR /src
COPY agent/grpc-ws-tunnel.go ./grpc-ws-tunnel.go
RUN go mod init choreo-grpc-ws-tunnel \
    && go get github.com/coder/websocket@latest \
    && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o grpc-ws-tunnel ./grpc-ws-tunnel.go

# ==========================================
# 构建内置 Nezha Agent
# ==========================================
FROM golang:1.26-alpine AS agent-builder

WORKDIR /src
RUN apk add --no-cache git
RUN git clone https://github.com/nezhahq/agent.git . \
    && git fetch --tags \
    && LATEST_TAG=$(git describe --tags --abbrev=0) \
    && git checkout "$LATEST_TAG" \
    && VERSION="${LATEST_TAG#v}" \
    && go mod download \
    && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w -X github.com/nezhahq/agent/pkg/monitor.Version=${VERSION} -X main.arch=$(go env GOARCH)" -o nezha-agent ./cmd/agent

# ==========================================
# 最终镜像：添加 Choreo 所需的工具和配置
# 使用 Alpine 以便安装额外工具（上游用 busybox 太精简）
# ==========================================
FROM alpine:3.21

USER root

# 升级基础包修复漏洞
RUN apk upgrade --no-cache libcrypto3 libssl3

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    aws-cli \
    tar \
    gzip \
    sqlite \
    curl \
    caddy \
    busybox \
    && rm -rf /var/cache/apk/*

# 安装 supercronic (容器友好的 cron)
RUN curl -fsSL "https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-amd64" -o /usr/local/bin/supercronic \
    && chmod +x /usr/local/bin/supercronic

WORKDIR /dashboard

# 从上游镜像复制所有必要文件
COPY --from=upstream /dashboard/app /dashboard/app
COPY --from=upstream /etc/ssl/certs /etc/ssl/certs
COPY --from=upstream /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=tunnel-builder /src/grpc-ws-tunnel /dashboard/grpc-ws-tunnel
COPY --from=agent-builder /src/nezha-agent /dashboard/nezha-agent

# --- 关键修复：解决只读文件系统 ---
# 删除原有的 data 目录，建立软链接指向 /tmp
RUN rm -rf /dashboard/data && ln -s /tmp /dashboard/data

# 设置环境变量
ENV TZ=Asia/Shanghai
ENV GIN_MODE=release

# 复制 Choreo 适配脚本
COPY script/backup.sh /dashboard/backup.sh
COPY script/entrypoint.sh /dashboard/entrypoint.sh
COPY script/crontab /dashboard/crontab
COPY script/Caddyfile /dashboard/Caddyfile
RUN chmod +x /dashboard/*.sh /dashboard/grpc-ws-tunnel /dashboard/nezha-agent

# 切换到 Choreo 指定用户 (10000-20000 范围)
USER 10014

EXPOSE 8008 8009

CMD ["/dashboard/entrypoint.sh"]
