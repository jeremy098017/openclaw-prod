# ================================
# Base: 使用最新的 Playwright (Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

ENV NODE_ENV=production
ENV TZ=Asia/Taipei

WORKDIR /app

# 安裝必要工具：加上 socat (強大的網路轉接工具)
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    socat \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw

# 建立與設定使用者
RUN useradd -m -u 10001 openclaw && \
    mkdir -p /home/openclaw/.openclaw && \
    chown -R openclaw:openclaw /home/openclaw /app

COPY --chown=openclaw:openclaw . .

# 暴露 Zeabur 預設的 8080
EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 終極絕招：Socat 轉接 + 龍蝦啟動
# 1. 用 OpenClaw 內建指令確保 mode 為 local (Port 維持預設 18789)
# 2. 同時啟動 socat，把 8080 轉給 127.0.0.1:18789
# 3. 啟動龍蝦
# ================================
CMD sh -c "openclaw config set gateway.mode local && \
    socat TCP-LISTEN:8080,fork,reuseaddr TCP:127.0.0.1:18789 & \
    exec openclaw gateway run"