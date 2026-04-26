# ==========================================
# 基于上游 Nezha 镜像进行 Choreo 适配
# ==========================================
FROM ghcr.io/nezhahq/nezha:latest AS upstream

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

# --- 关键修复：解决只读文件系统 ---
# 删除原有的 data 目录，建立软链接指向 /tmp
RUN rm -rf /dashboard/data && ln -s /tmp /dashboard/data

# 设置环境变量
ENV TZ=Asia/Shanghai
ENV GIN_MODE=release

# 复制 Choreo 适配脚本
COPY backup.sh /dashboard/backup.sh
COPY entrypoint.sh /dashboard/entrypoint.sh
COPY crontab /dashboard/crontab
RUN chmod +x /dashboard/*.sh

# 切换到 Choreo 指定用户 (10000-20000 范围)
USER 10014

EXPOSE 8008

CMD ["/dashboard/entrypoint.sh"]
