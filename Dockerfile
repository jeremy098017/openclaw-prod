# ================================
# Base: 使用最新的 Playwright (支援 Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

ENV NODE_ENV=production
ENV TZ=Asia/Taipei

WORKDIR /app

# 安裝守護行程與網路測試工具 (不需要隱形斗篷和 socat 了！)
RUN apt-get update && apt-get install -y --no-install-recommends tini curl && rm -rf /var/lib/apt/lists/*

# 全域安裝 OpenClaw
RUN npm install -g openclaw

# 確保設定檔目錄存在
RUN mkdir -p /root/.openclaw

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 終極啟動指令：
# 1. 直接把 8080 Port 寫給龍蝦
# 2. 開放區域網路 (lan) 連線
# 3. 關閉煩人的 Device Auth (設備綁定)
# 4. 指定 Token 為 pmad1Wurp
# ================================
CMD sh -c "echo '{\"gateway\":{\"port\":8080,\"mode\":\"local\",\"bind\":\"lan\",\"controlUi\":{\"dangerouslyDisableDeviceAuth\":true,\"allowInsecureAuth\":true},\"auth\":{\"mode\":\"token\",\"token\":\"pmad1Wurp\"}}}' > /root/.openclaw/openclaw.json && \
           unset PORT && exec openclaw gateway run"