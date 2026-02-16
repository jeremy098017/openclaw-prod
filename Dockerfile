# ================================
# Base: 使用最新的 Playwright (支援 Node 22)
# ================================
FROM mcr.microsoft.com/playwright:v1.50.0-noble

ENV NODE_ENV=production
ENV TZ=Asia/Taipei

WORKDIR /app

# 安裝守護行程與網路測試工具
RUN apt-get update && apt-get install -y --no-install-recommends tini curl && rm -rf /var/lib/apt/lists/*

# 全域安裝 OpenClaw 與 http-proxy (隱形斗篷套件)
RUN npm install -g openclaw
RUN npm install http-proxy

# 建立隱形斗篷轉接器 (proxy.js)
RUN cat <<'EOF' > proxy.js
const http = require('http');
const httpProxy = require('http-proxy');

// 建立轉接器，將流量導向龍蝦的 18789
const proxy = httpProxy.createProxyServer({ target: 'http://127.0.0.1:18789', ws: true });

// 關鍵：在轉發前，拔掉所有透露真實 IP 的標籤
proxy.on('proxyReq', (proxyReq) => {
  proxyReq.removeHeader('x-forwarded-for');
  proxyReq.removeHeader('x-forwarded-proto');
  proxyReq.removeHeader('x-forwarded-host');
});
proxy.on('error', (err) => console.error('Proxy error:', err));

// 啟動伺服器監聽 8080，幫 Zeabur 開門
const server = http.createServer((req, res) => proxy.web(req, res));
server.on('upgrade', (req, socket, head) => proxy.ws(req, socket, head));
server.listen(8080, '0.0.0.0', () => console.log('Proxy listening on 8080'));
EOF

# 確保設定檔目錄存在
RUN mkdir -p /root/.openclaw

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

# ================================
# 啟動指令：
# 1. 寫入密碼 Token
# 2. 啟動隱形斗篷 (node proxy.js)
# 3. 啟動龍蝦
# ================================
CMD sh -c "openclaw config set gateway.mode local && \
           openclaw config set gateway.auth.token pmad1Wurp && \
           node proxy.js & \
           env PORT= exec openclaw gateway run"