FROM mcr.microsoft.com/playwright:v1.50.0-noble

ENV NODE_ENV=production
ENV TZ=Asia/Taipei

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends tini curl && rm -rf /var/lib/apt/lists/*

# 全域安裝 OpenClaw
RUN npm install -g openclaw

# 建立設定檔目錄
RUN mkdir -p /root/.openclaw

# 直接將剛才建立的 json 複製進去 (這是最穩定的做法)
COPY openclaw.json /root/.openclaw/openclaw.json

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# 啟動指令現在變得很乾淨，不會再出錯了
CMD ["sh", "-c", "unset PORT && exec openclaw gateway run"]