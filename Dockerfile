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
# 終極啟動指令 (包含 Gemini 與 LINE 設定)
# ================================
CMD sh -c "if [ ! -f /root/.openclaw/openclaw.json ]; then \
echo '{\
  \"agents\": {\
    \"defaults\": {\
      \"model\": { \"primary\": \"gemini\" },\
      \"models\": { \"google/gemini-2.5-flash\": { \"alias\": \"gemini\" } }\
    }\
  },\
  \"channels\": {\
    \"line\": {\
      \"enabled\": true,\
      \"channelSecret\": \"2f1a6ae1cc34a355f39027bedf8d7c4f\",\
      \"channelAccessToken\": \"iKDO1rKvL4VpiwIj8+yrQLnQ3stCF09lLznX39kGcbhl+OhNA2TRw8FIgIitfswi3qjpmvKnum5QCRwyGiDUCF88SaYwjmRLPEGfZDg5ztOynjfrHllE9/ODsj2P+D/dmItcPzPmGRgj5kZHtO/qRgdB04t89/1O/w1cDnyilFU=\",\
      \"debug\": true\
    }\
  },\
  \"gateway\": {\
    \"port\": 8080,\
    \"mode\": \"local\",\
    \"bind\": \"lan\",\
    \"controlUi\": { \"dangerouslyDisableDeviceAuth\": true, \"allowInsecureAuth\": true },\
    \"auth\": { \"mode\": \"token\", \"token\": \"pmad1Wurp\" }\
  }\
}' > /root/.openclaw/openclaw.json; fi && \
unset PORT && exec openclaw gateway run"