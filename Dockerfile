# ================================
# Base: 使用最新的 Playwright (支援 Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

# 環境變數設定
ENV NODE_ENV=production
ENV TZ=Asia/Taipei

WORKDIR /app

# 安裝必要工具：tini (守護行程)、curl (測試用)、socat (轉接 Port 救星)
RUN apt-get update && apt-get install -y --no-install-recommends \
    tini \
    curl \
    socat \
    && rm -rf /var/lib/apt/lists/*

# 全域安裝 OpenClaw
RUN npm install -g openclaw

# 確保設定檔要存放的目錄存在 (使用 root 權限避免權限阻擋)
RUN mkdir -p /root/.openclaw

# 暴露 Zeabur 預設對外溝通的 8080 Port
EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 終極啟動指令 (三合一)：
# 1. 寫入 JSON 設定：強制切換為 public 模式 (免除 Pairing) 並綁定密碼
# 2. 啟動 socat：把 Zeabur 敲門的 8080 流量，無縫轉接給龍蝦的 18789 (解決 502 錯誤)
# 3. 啟動 OpenClaw 網關
# ================================
CMD sh -c "echo '{\"gateway\":{\"mode\":\"public\",\"auth\":{\"token\":\"pmad1Wurp\"}}}' > /root/.openclaw/openclaw.json && \
           socat TCP-LISTEN:8080,fork,reuseaddr TCP:127.0.0.1:18789 & \
           openclaw gateway run"