# ================================
# Base: 使用最新的 Playwright (Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

# 環境變數
ENV NODE_ENV=production
ENV TZ=Asia/Taipei
ENV OPENCLAW_LOG_LEVEL=info

WORKDIR /app

# 安裝必要工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 安裝 OpenClaw
RUN npm install -g openclaw

# 建立使用者
RUN useradd -m -u 10001 openclaw

# 先複製檔案，避免蓋掉後面產生的設定檔
COPY --chown=openclaw:openclaw . .

# 產生符合 TOML 格式的設定檔，並確保權限正確
RUN mkdir -p /home/openclaw/.openclaw && \
    printf "[gateway]\nmode = \"local\"\nport = 18789\n" > /home/openclaw/.openclaw/config.toml && \
    chown -R openclaw:openclaw /home/openclaw

# 切換使用者
USER openclaw

# 健康檢查
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fs http://127.0.0.1:18789/ || exit 1

EXPOSE 18789

ENTRYPOINT ["/usr/bin/tini", "--"]

# 啟動指令：拿掉不支援的參數，回歸最簡潔的啟動方式
CMD ["openclaw", "gateway", "run", "--allow-unconfigured"]