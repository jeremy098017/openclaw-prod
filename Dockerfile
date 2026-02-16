# ================================
# Base: 使用官方 Node.js 版 Playwright (直接內含 Node.js 與瀏覽器依賴)
# ================================
FROM mcr.microsoft.com/playwright:v1.42.0-jammy

# ================================
# 基本環境設定
# ================================
ENV NODE_ENV=production
ENV OPENCLAW_LOG_LEVEL=info
ENV TZ=Asia/Taipei
# 確保 Log 能即時顯示
ENV PYTHONUNBUFFERED=1 

WORKDIR /app

# ================================
# 安裝必要工具 (Playwright 鏡像已有 Node，補上 tini 即可)
# ================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    && rm -rf /var/lib/apt/lists/*

# ================================
# 安裝 OpenClaw CLI
# ================================
RUN npm install -g openclaw

# ================================
# 建立非 root 使用者
# ================================
RUN useradd -m -u 10001 openclaw && \
    mkdir -p /home/openclaw/.openclaw && \
    chown -R openclaw:openclaw /home/openclaw /app

USER openclaw

# ================================
# 複製應用程式 (如果本地有 config.toml 等)
# ================================
COPY --chown=openclaw:openclaw . .

# ================================
# Healthcheck
# ================================
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fs http://127.0.0.1:18789/ || exit 1

# 暴露 gateway port
EXPOSE 18789

# 使用 tini 啟動
ENTRYPOINT ["/usr/bin/tini", "--"]

# 啟動 OpenClaw Gateway
CMD ["openclaw", "gateway", "run"]