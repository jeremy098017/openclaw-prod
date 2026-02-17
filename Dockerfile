FROM mcr.microsoft.com/playwright:v1.50.0-noble

ENV NODE_ENV=production
ENV TZ=Asia/Taipei

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends tini curl && rm -rf /var/lib/apt/lists/*

# 全域安裝 OpenClaw
RUN npm install -g openclaw

# 將正確的設定檔先 COPY 到暫存目錄 /app
COPY openclaw.json /app/openclaw.json

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# 關鍵：啟動時先執行 cp，確保 /root/.openclaw 下的檔案永遠是最新的
CMD ["sh", "-c", "mkdir -p /root/.openclaw && cp /app/openclaw.json /root/.openclaw/openclaw.json && unset PORT && exec openclaw gateway run"]