#!/bin/sh

# ==============================
# 环境变量配置与默认值
# ==============================
NEZHA_LISTEN_PORT=${NEZHA_LISTEN_PORT:-8008}
NEZHA_LISTEN_HOST=${NEZHA_LISTEN_HOST:-0.0.0.0}

# 数据库和配置文件路径（必须在 /tmp）
DB_FILE="/tmp/sqlite.db"
CONFIG_FILE="/tmp/config.yaml"

# ==============================
# 1. 初始化 /tmp 目录结构
# ==============================
echo "Initializing directory structure in /tmp..."
mkdir -p /tmp/tsdb

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

# ==============================
# 5. 启动 Caddy WebSocket 代理
# ==============================
echo "Starting Caddy WebSocket proxy on port 8009..."
caddy run --config /dashboard/Caddyfile --adapter caddyfile &

# ==============================
# 6. 启动主应用
# ==============================
echo "Starting Nezha Dashboard..."
echo "Database: $DB_FILE"
echo "Config: $CONFIG_FILE"
echo "Listen: ${NEZHA_LISTEN_HOST}:${NEZHA_LISTEN_PORT}"

# 使用上游镜像的二进制文件路径
exec /dashboard/app -c "$CONFIG_FILE" -db "$DB_FILE"
