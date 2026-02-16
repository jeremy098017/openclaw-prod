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

# 確保權限
RUN mkdir -p /home/openclaw/.openclaw && chown -R openclaw:openclaw /home/openclaw /app
COPY --chown=openclaw:openclaw . .

USER openclaw
EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 終極修正：
# 1. 移除 HEALTHCHECK 指令（避免 Zeabur 誤判導致重啟）
# 2. 先設定 Config，再啟動轉接與龍蝦
# ================================
CMD sh -c "openclaw config set gateway.mode local && \
           openclaw config set gateway.auth.token pmad1Wurp && \
           openclaw config set gateway.trustedProxies true && \
           socat TCP-LISTEN:8080,fork,reuseaddr TCP:127.0.0.1:18789 & \
           exec openclaw gateway run"