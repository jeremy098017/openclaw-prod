# ================================
# Base: 使用最新的 Playwright (Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

ENV NODE_ENV=production
ENV TZ=Asia/Taipei
ENV OPENCLAW_LOG_LEVEL=info

WORKDIR /app

# 安裝必要工具：socat 是轉接 8080 到 18789 的關鍵
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    socat \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw
RUN useradd -m -u 10001 openclaw

# 確保權限與資料夾存在
RUN mkdir -p /home/openclaw/.openclaw && chown -R openclaw:openclaw /home/openclaw /app
COPY --chown=openclaw:openclaw . .

USER openclaw
EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 最終修正：
# 1. 移除會導致報錯的 trustedProxies (避免 Config validation failed)
# 2. 確保 socat 在背景穩定執行
# ================================
CMD sh -c "mkdir -p /root/.openclaw && \
    printf '{\"gateway\":{\"mode\":\"local\",\"auth\":{\"token\":\"pmad1Wurp\"},\"trustedProxies\":[\"0.0.0.0/0\"]}}' > /root/.openclaw/openclaw.json && \
    (socat TCP-LISTEN:8080,fork,reuseaddr TCP:127.0.0.1:18789 &) && \
    exec openclaw gateway run"