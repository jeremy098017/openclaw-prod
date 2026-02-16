# ================================
# Base: 使用最新的 Playwright (Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

ENV NODE_ENV=production
ENV TZ=Asia/Taipei
# 關鍵：強制指定 OpenClaw 讀取 /app/config.toml
ENV OPENCLAW_CONFIG=/app/config.toml

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw
RUN useradd -m -u 10001 openclaw

# 把你剛建好的 config.toml 跟其他檔案一起複製進去
COPY --chown=openclaw:openclaw . .

USER openclaw

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fs http://127.0.0.1:18789/ || exit 1

EXPOSE 18789
ENTRYPOINT ["/usr/bin/tini", "--"]

# 最單純的啟動指令
CMD ["openclaw", "gateway", "run"]