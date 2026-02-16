# ================================
# Base: 使用最新的 Playwright (Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

ENV NODE_ENV=production
ENV TZ=Asia/Taipei
ENV OPENCLAW_LOG_LEVEL=info

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw
RUN useradd -m -u 10001 openclaw

# 預先建好資料夾並給予權限
RUN mkdir -p /home/openclaw/.openclaw && chown -R openclaw:openclaw /home/openclaw /app

COPY --chown=openclaw:openclaw . .

USER openclaw

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fs http://127.0.0.1:18789/ || exit 1

EXPOSE 18789
ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 終極絕殺：用 OpenClaw 內建指令寫入設定，接著馬上啟動！
# ================================
CMD sh -c "openclaw config set gateway.mode local && exec openclaw gateway run"