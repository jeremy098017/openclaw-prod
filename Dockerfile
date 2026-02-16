# ================================
# Base: 使用最新的 Playwright (內含 Node.js 22+)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

# ================================
# 基本環境設定
# ================================
ENV NODE_ENV=production
ENV OPENCLAW_LOG_LEVEL=info
ENV TZ=Asia/Taipei
ENV PYTHONUNBUFFERED=1 

WORKDIR /app

# ================================
# 安裝必要工具 (Playwright 鏡像已有 Node 22，補上 tini 即可)
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
# 複製應用程式
# ================================
COPY --chown=openclaw:openclaw . .

# ================================
# Healthcheck
# ================================
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fs http://127.0.0.1:18789/ || exit 1

EXPOSE 18789

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["openclaw", "gateway", "run"]