# ================================
# Base: 使用最新的 Playwright (Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

# ================================
# 環境變數設定 (Zeabur 部署關鍵)
# ================================
ENV NODE_ENV=production
ENV TZ=Asia/Taipei
# 1. 解決 "Missing config"：強制設定模式
ENV OPENCLAW_GATEWAY_MODE=local
# 2. 告訴 OpenClaw 設定檔就在 /app 這裡（如果你有上傳的話）
ENV OPENCLAW_CONFIG_PATH=/app/config.toml
# 3. 確保日誌即時輸出
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# ================================
# 安裝 tini 與 curl
# ================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 安裝 OpenClaw
RUN npm install -g openclaw

# ================================
# 權限處理
# ================================
RUN useradd -m -u 10001 openclaw && \
    mkdir -p /home/openclaw/.openclaw && \
    chown -R openclaw:openclaw /home/openclaw /app

# 先切換使用者再 COPY，確保檔案權限正確
USER openclaw

# 複製專案檔案 (包含你的 config.toml, 如果有的話)
COPY --chown=openclaw:openclaw . .

# ================================
# 啟動設定
# ================================
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fs http://127.0.0.1:18789/ || exit 1

EXPOSE 18789

ENTRYPOINT ["/usr/bin/tini", "--"]

# 使用 --allow-unconfigured 作為雙重保險
CMD ["openclaw", "gateway", "run", "--allow-unconfigured"]