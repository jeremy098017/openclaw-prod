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

# 確保設定檔目錄存在
RUN mkdir -p /root/.openclaw

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 終極啟動指令 (還原至最穩定狀態)
# ================================
CMD sh -c "echo '{\"gateway\":{\"port\":8080,\"mode\":\"local\",\"bind\":\"lan\",\"controlUi\":{\"dangerouslyDisableDeviceAuth\":true,\"allowInsecureAuth\":true},\"auth\":{\"mode\":\"token\",\"token\":\"pmad1Wurp\"}},\"models\":{\"providers\":{\"google\":{\"models\":[{\"api\":\"google-generative-ai\",\"id\":\"gemini-2.5-flash\",\"model\":\"gemini-2.5-flash\"}]}}}}' > /root/.openclaw/openclaw.json && \
           unset PORT && exec openclaw gateway run"