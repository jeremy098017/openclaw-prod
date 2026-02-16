# ================================
# Base: 使用最新的 Playwright (支援 Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

# 環境變數設定
ENV NODE_ENV=production
ENV TZ=Asia/Taipei

WORKDIR /app

# 安裝必要工具：tini、curl、socat
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    socat \
    && rm -rf /var/lib/apt/lists/*

# 全域安裝 OpenClaw
RUN npm install -g openclaw

# 確保設定檔要存放的目錄存在
RUN mkdir -p /root/.openclaw

# 暴露 8080 Port 給 Zeabur
EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 最終啟動指令：
# 1. 寫入 JSON：mode 設回 local，並加入 trustedProxies 陣列來破解配對要求
# 2. 啟動 socat 轉接 8080 -> 18789
# 3. 啟動龍蝦
# ================================
CMD sh -c "echo '{\"gateway\":{\"mode\":\"local\",\"auth\":{\"token\":\"pmad1Wurp\"},\"trustedProxies\":[\"0.0.0.0/0\"]}}' > /root/.openclaw/openclaw.json && \
           socat TCP-LISTEN:8080,fork,reuseaddr TCP:127.0.0.1:18789 & \
           exec openclaw gateway run"