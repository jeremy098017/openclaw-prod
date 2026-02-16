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

RUN mkdir -p /home/openclaw/.openclaw && chown -R openclaw:openclaw /home/openclaw /app
COPY --chown=openclaw:openclaw . .

USER openclaw

# 修改健康檢查為 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fs http://127.0.0.1:8080/ || exit 1

# 暴露 8080
EXPOSE 8080
ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 同時修正 Port 為 8080 與 Host 為 0.0.0.0
# ================================
CMD sh -c "openclaw config set gateway.mode local && \
           openclaw config set gateway.port 8080 && \
           openclaw config set gateway.host 0.0.0.0 && \
           exec openclaw gateway run"