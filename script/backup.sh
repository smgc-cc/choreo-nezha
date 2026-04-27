#!/bin/sh

# 设置默认值
BACKUP_BACKEND=$(printf '%s' "${BACKUP_BACKEND:-r2}" | tr '[:upper:]' '[:lower:]')

R2_ACCESS_KEY_ID=${R2_ACCESS_KEY_ID:-""}
R2_SECRET_ACCESS_KEY=${R2_SECRET_ACCESS_KEY:-""}
R2_ENDPOINT_URL=${R2_ENDPOINT_URL:-""}
R2_BUCKET_NAME=${R2_BUCKET_NAME:-""}

WEBDAV_URL=${WEBDAV_URL:-""}
WEBDAV_USERNAME=${WEBDAV_USERNAME:-${WEBDAV_USER:-""}}
WEBDAV_PASSWORD=${WEBDAV_PASSWORD:-${WEBDAV_PASS:-""}}

# 关键：定义运行时数据目录，Choreo 下必须是 /tmp
RUNTIME_DATA_DIR="/tmp"
# 数据库文件名
DB_FILE_NAME="sqlite.db"
# VictoriaMetrics 数据目录
TSDB_DIR_NAME="tsdb"
# 备份文件前缀
BACKUP_PREFIX="nezha_backup_"

check_backend() {
    case "$BACKUP_BACKEND" in
        r2)
            if [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ] || [ -z "$R2_ENDPOINT_URL" ] || [ -z "$R2_BUCKET_NAME" ]; then
                echo "Warning: R2 environment variables are not set, skipping backup/restore"
                exit 0
            fi
            export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
            export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
            export AWS_DEFAULT_REGION="auto"
            export AWS_ENDPOINT_URL="$R2_ENDPOINT_URL"
            export BUCKET_NAME="$R2_BUCKET_NAME"
            ;;
        webdav)
            if [ -z "$WEBDAV_URL" ] || [ -z "$WEBDAV_USERNAME" ] || [ -z "$WEBDAV_PASSWORD" ]; then
                echo "Warning: WebDAV environment variables are not set, skipping backup/restore"
                exit 0
            fi
            WEBDAV_URL=${WEBDAV_URL%/}
            ;;
        none|off|disabled)
            echo "Backup backend disabled, skipping backup/restore"
            exit 0
            ;;
        *)
            echo "Error: unsupported BACKUP_BACKEND: $BACKUP_BACKEND. Use r2 or webdav."
            exit 1
            ;;
    esac
}

list_backups() {
    case "$BACKUP_BACKEND" in
        r2)
            aws s3 ls "s3://${BUCKET_NAME}/backups/${BACKUP_PREFIX}" | awk '{print $NF}'
            ;;
        webdav)
            curl -fsS -u "${WEBDAV_USERNAME}:${WEBDAV_PASSWORD}" \
                -X PROPFIND \
                -H "Depth: 1" \
                "$WEBDAV_URL/" \
                | tr '<' '\n' \
                | sed -n "s|.*href>\([^<]*${BACKUP_PREFIX}[^<]*\.tar\.gz\).*|\1|p" \
                | while read -r href; do
                    basename "$href" | sed 's/%5F/_/g; s/%2E/./g; s/%2D/-/g'
                done
            ;;
    esac
}

download_backup() {
    backup_file="$1"
    case "$BACKUP_BACKEND" in
        r2)
            aws s3 cp "s3://${BUCKET_NAME}/backups/${backup_file}" "/tmp/${backup_file}"
            ;;
        webdav)
            curl -fsS -u "${WEBDAV_USERNAME}:${WEBDAV_PASSWORD}" \
                -o "/tmp/${backup_file}" \
                "$WEBDAV_URL/${backup_file}"
            ;;
    esac
}

upload_backup() {
    local_file="$1"
    backup_file="$2"
    case "$BACKUP_BACKEND" in
        r2)
            aws s3 cp "$local_file" "s3://${BUCKET_NAME}/backups/${backup_file}"
            ;;
        webdav)
            curl -fsS -u "${WEBDAV_USERNAME}:${WEBDAV_PASSWORD}" \
                -X MKCOL \
                "$WEBDAV_URL/" >/dev/null 2>&1 || true
            curl -fsS -u "${WEBDAV_USERNAME}:${WEBDAV_PASSWORD}" \
                -T "$local_file" \
                "$WEBDAV_URL/${backup_file}"
            ;;
    esac
}

delete_backup() {
    backup_file="$1"
    case "$BACKUP_BACKEND" in
        r2)
            aws s3 rm "s3://${BUCKET_NAME}/backups/${backup_file}"
            ;;
        webdav)
            curl -fsS -u "${WEBDAV_USERNAME}:${WEBDAV_PASSWORD}" \
                -X DELETE \
                "$WEBDAV_URL/${backup_file}"
            ;;
    esac
}

# 恢复功能
restore_backup() {
    check_backend

    echo "Checking for latest backup via ${BACKUP_BACKEND}..."
    LATEST_BACKUP=$(list_backups | sort | tail -n 1)

    if [ -n "$LATEST_BACKUP" ]; then
        echo "Found backup: ${LATEST_BACKUP}"

        if download_backup "$LATEST_BACKUP"; then
            echo "Backup downloaded. Restoring to ${RUNTIME_DATA_DIR}..."

            RESTORE_TEMP="/tmp/restore_temp"
            mkdir -p "$RESTORE_TEMP"

            if tar -xzf "/tmp/${LATEST_BACKUP}" -C "$RESTORE_TEMP"; then
                # 恢复 SQLite 数据库
                if [ -f "${RESTORE_TEMP}/data/${DB_FILE_NAME}" ]; then
                    cp -f "${RESTORE_TEMP}/data/${DB_FILE_NAME}" "${RUNTIME_DATA_DIR}/${DB_FILE_NAME}"
                    echo "Restored database: ${DB_FILE_NAME}"
                fi

                # 恢复 config.yaml
                if [ -f "${RESTORE_TEMP}/data/config.yaml" ]; then
                    cp -f "${RESTORE_TEMP}/data/config.yaml" "${RUNTIME_DATA_DIR}/config.yaml"
                    echo "Restored config: config.yaml"
                fi

                # 恢复 VictoriaMetrics TSDB 数据
                if [ -d "${RESTORE_TEMP}/data/${TSDB_DIR_NAME}" ]; then
                    rm -rf "${RUNTIME_DATA_DIR}/${TSDB_DIR_NAME}"
                    cp -af "${RESTORE_TEMP}/data/${TSDB_DIR_NAME}" "${RUNTIME_DATA_DIR}/"
                    echo "Restored TSDB data"
                fi

                # 恢复 GeoIP 数据库（如果有）
                if [ -f "${RESTORE_TEMP}/data/geoip.db" ]; then
                    cp -f "${RESTORE_TEMP}/data/geoip.db" "${RUNTIME_DATA_DIR}/geoip.db"
                    echo "Restored GeoIP database"
                fi

                rm -rf "$RESTORE_TEMP"
                rm "/tmp/${LATEST_BACKUP}"
                echo "Backup restored successfully to ${RUNTIME_DATA_DIR}"
            else
                echo "Error: Backup archive is corrupted!"
                rm -rf "$RESTORE_TEMP"
                exit 1
            fi
        fi
    else
        echo "No backup found via ${BACKUP_BACKEND}, starting fresh."
    fi
}

# 备份功能
create_backup() {
    check_backend

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="${BACKUP_PREFIX}${TIMESTAMP}.tar.gz"
    BACKUP_DIR="/tmp/nezha_backup_dir_${TIMESTAMP}"

    mkdir -p "${BACKUP_DIR}/data"

    # 1. 备份 SQLite 数据库
    echo "Backing up SQLite database from ${RUNTIME_DATA_DIR}..."
    if [ -f "${RUNTIME_DATA_DIR}/${DB_FILE_NAME}" ]; then
        if ! sqlite3 "${RUNTIME_DATA_DIR}/${DB_FILE_NAME}" "VACUUM INTO '${BACKUP_DIR}/data/${DB_FILE_NAME}'"; then
            echo "Error: SQLite vacuum failed!"
            rm -rf "$BACKUP_DIR"
            return 1
        fi
        echo "Database backed up successfully"
    else
        echo "Warning: No database file found to backup."
    fi

    # 2. 备份配置文件
    if [ -f "${RUNTIME_DATA_DIR}/config.yaml" ]; then
        cp -f "${RUNTIME_DATA_DIR}/config.yaml" "${BACKUP_DIR}/data/"
        echo "Config file backed up"
    fi

    # 3. 备份 VictoriaMetrics TSDB 数据
    if [ -d "${RUNTIME_DATA_DIR}/${TSDB_DIR_NAME}" ]; then
        cp -a "${RUNTIME_DATA_DIR}/${TSDB_DIR_NAME}" "${BACKUP_DIR}/data/"
        echo "TSDB data backed up"
    fi

    # 4. 备份 GeoIP 数据库（如果有）
    if [ -f "${RUNTIME_DATA_DIR}/geoip.db" ]; then
        cp -f "${RUNTIME_DATA_DIR}/geoip.db" "${BACKUP_DIR}/data/"
        echo "GeoIP database backed up"
    fi

    # 5. 压缩并上传
    echo "Compressing backup..."
    tar -czf "/tmp/${BACKUP_FILE}" -C "$BACKUP_DIR" .

    echo "Uploading to ${BACKUP_BACKEND}..."
    if upload_backup "/tmp/${BACKUP_FILE}" "$BACKUP_FILE"; then
        echo "Upload successful: ${BACKUP_FILE}"
    else
        echo "Error: Upload failed!"
    fi

    # 清理
    rm -rf "$BACKUP_DIR" "/tmp/${BACKUP_FILE}"

    # 6. 清理旧备份 (保留7天)
    echo "Cleaning up old backups..."
    OLD_DATE=$(date -d "@$(($(date +%s) - 7*86400))" +%Y%m%d 2>/dev/null || date -v-7d +%Y%m%d)
    list_backups | while read -r filename; do
        file_date=$(printf '%s' "$filename" | sed -n 's/.*\([0-9]\{8\}\).*/\1/p')
        if [ -n "$file_date" ] && [ "$file_date" -lt "$OLD_DATE" ]; then
            echo "Deleting old backup: $filename"
            delete_backup "$filename"
        fi
    done

    echo "Backup completed successfully"
}

case "$1" in
    "restore") restore_backup ;;
    "backup") create_backup ;;
    *) echo "Usage: $0 {backup|restore}"; exit 1 ;;
esac
