#!/bin/sh

# ==============================
# 环境变量配置与默认值
# ==============================
NEZHA_LISTEN_PORT=${NEZHA_LISTEN_PORT:-8008}
NEZHA_LISTEN_HOST=${NEZHA_LISTEN_HOST:-0.0.0.0}
NEZHA_ENABLE_LOCAL_AGENT=${NEZHA_ENABLE_LOCAL_AGENT:-false}
NEZHA_LOCAL_AGENT_SECRET=${NEZHA_LOCAL_AGENT_SECRET:-${NZ_AGENTSECRETKEY:-}}
NEZHA_LOCAL_AGENT_UUID=${NEZHA_LOCAL_AGENT_UUID:-}

# 数据库和配置文件路径（必须在 /tmp）
DB_FILE="/tmp/sqlite.db"
CONFIG_FILE="/tmp/config.yaml"
AGENT_CONFIG_FILE="/tmp/nezha-agent.yml"

sync_agent_secret_key() {
    if [ -z "${NZ_AGENTSECRETKEY:-}" ] || [ ! -f "$CONFIG_FILE" ]; then
        return
    fi

    grep -v '^agent_secret_key:' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" || true
    printf 'agent_secret_key: %s\n' "$NZ_AGENTSECRETKEY" >> "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
}

# ==============================
# 1. 初始化 /tmp 目录结构
# ==============================
echo "Initializing directory structure in /tmp..."
mkdir -p /tmp/tsdb /tmp/.config/caddy /tmp/.local/share/caddy

# ==============================
# 2. 创建默认配置文件（如果不存在）
# ==============================
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating default config file..."
    cat > "$CONFIG_FILE" <<EOF
debug: false
listen_host: ${NEZHA_LISTEN_HOST}
listen_port: ${NEZHA_LISTEN_PORT}
location: Asia/Shanghai
language: zh-CN
tsdb:
  data_path: /tmp/tsdb
  retention_days: 30
  max_memory_mb: 256
EOF
    sync_agent_secret_key
fi

# ==============================
# 3. 启动定时备份任务 (supercronic)
# ==============================
echo "Starting supercronic for scheduled backups..."
supercronic /dashboard/crontab &

# ==============================
# 4. 尝试恢复备份
# ==============================
echo "Restoring backup if available..."
/dashboard/backup.sh restore
sync_agent_secret_key

# ==============================
# 5. 启动 gRPC-over-WebSocket 隧道
# ==============================
echo "Starting gRPC-over-WebSocket tunnel on port 8010..."
/dashboard/grpc-ws-tunnel -listen :8010 -target 127.0.0.1:${NEZHA_LISTEN_PORT} -path /grpc-tunnel &

# ==============================
# 6. 启动 Caddy WebSocket 代理
# ==============================
echo "Starting Caddy WebSocket proxy on port 8009..."
HOME=/tmp XDG_CONFIG_HOME=/tmp/.config XDG_DATA_HOME=/tmp/.local/share caddy run --config /dashboard/Caddyfile --adapter caddyfile &

# ==============================
# 7. 启动内置 Nezha Agent（可选）
# ==============================
if [ "$NEZHA_ENABLE_LOCAL_AGENT" = "true" ]; then
    if [ -z "$NEZHA_LOCAL_AGENT_SECRET" ]; then
        echo "Warning: NEZHA_ENABLE_LOCAL_AGENT=true but neither NEZHA_LOCAL_AGENT_SECRET nor NZ_AGENTSECRETKEY is set, skipping local agent"
    else
        echo "Starting bundled Nezha Agent..."
        (
            count=0
            while ! nc -z 127.0.0.1 "${NEZHA_LISTEN_PORT}" 2>/dev/null && [ $count -lt 60 ]; do
                sleep 1
                count=$((count+1))
            done

            if ! nc -z 127.0.0.1 "${NEZHA_LISTEN_PORT}" 2>/dev/null; then
                echo "Error: Nezha Dashboard failed to start within 60s. Local agent skipped."
                exit 1
            fi

            cat > "$AGENT_CONFIG_FILE" <<EOF
server: 127.0.0.1:${NEZHA_LISTEN_PORT}
client_secret: ${NEZHA_LOCAL_AGENT_SECRET}
tls: false
disable_auto_update: true
disable_force_update: true
disable_command_execute: false
disable_nat: true
EOF
            if [ -n "$NEZHA_LOCAL_AGENT_UUID" ]; then
                cat >> "$AGENT_CONFIG_FILE" <<EOF
uuid: ${NEZHA_LOCAL_AGENT_UUID}
EOF
            fi

            exec /dashboard/nezha-agent -c "$AGENT_CONFIG_FILE"
        ) &
    fi
else
    echo "Bundled Nezha Agent disabled. Set NEZHA_ENABLE_LOCAL_AGENT=true to enable it."
fi

# ==============================
# 8. 启动主应用
# ==============================
echo "Starting Nezha Dashboard..."
echo "Database: $DB_FILE"
echo "Config: $CONFIG_FILE"
echo "Listen: ${NEZHA_LISTEN_HOST}:${NEZHA_LISTEN_PORT}"

# 使用上游镜像的二进制文件路径
exec /dashboard/app -c "$CONFIG_FILE" -db "$DB_FILE"
