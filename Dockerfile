# ================================
# Base: 使用最新的 Playwright (支援 Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

ENV NODE_ENV=production
ENV TZ=Asia/Taipei

WORKDIR /app

# 安裝守護行程與網路測試工具
RUN apt-get update && apt-get install -y --no-install-recommends tini curl && rm -rf /var/lib/apt/lists/*

# 全域安裝 OpenClaw 與隱形斗篷套件
RUN npm install -g openclaw
RUN npm install http-proxy

# 建立升級版隱形斗篷轉接器 (proxy.js)
# 這次直接在最源頭刪除 Header，確保 HTTP 和 WebSocket 都無法洩漏 IP
RUN cat <<'EOF' > proxy.js
const http = require('http');
const httpProxy = require('http-proxy');

const proxy = httpProxy.createProxyServer({ target: 'http://127.0.0.1:18789', ws: true });
proxy.on('error', (err) => console.error('Proxy error:', err.message));

// 清除 IP 標籤的函數
const cleanHeaders = (req) => {
  delete req.headers['x-forwarded-for'];
  delete req.headers['x-forwarded-proto'];
  delete req.headers['x-forwarded-host'];
  delete req.headers['x-real-ip'];
};

// 處理一般網頁載入 (HTTP)
const server = http.createServer((req, res) => {
  cleanHeaders(req);
  proxy.web(req, res);
});

// 處理即時連線 (WebSocket) - 這是之前漏掉的關鍵！
server.on('upgrade', (req, socket, head) => {
  cleanHeaders(req);
  proxy.ws(req, socket, head);
});

server.listen(8080, '0.0.0.0', () => console.log('Proxy listening on 8080'));
EOF

# 確保設定檔目錄存在
RUN mkdir -p /root/.openclaw

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 啟動指令：
# unset PORT 防止 Zeabur 變數干擾
# ================================
CMD sh -c "openclaw config set gateway.mode local && \
           openclaw config set gateway.auth.token pmad1Wurp && \
           node proxy.js & \
           unset PORT && exec openclaw gateway run"