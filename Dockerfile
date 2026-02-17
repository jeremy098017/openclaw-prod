# ================================
# Base: 使用最新的 Playwright (支援 Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

ENV NODE_ENV=production
ENV TZ=Asia/Taipei

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends tini curl && rm -rf /var/lib/apt/lists/*

# 全域安裝 OpenClaw
RUN npm install -g openclaw

# 建立設定檔目錄並將檔案複製進去
RUN mkdir -p /root/.openclaw
COPY openclaw.json /root/.openclaw/openclaw.json

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# 啟動指令變得非常乾淨，不會再出錯了
CMD ["sh", "-c", "unset PORT && exec openclaw gateway run"]