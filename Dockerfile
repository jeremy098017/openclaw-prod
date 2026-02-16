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

# 建立完美版隱形斗篷轉接器 (proxy.js)
RUN cat <<'EOF' > proxy.js
const http = require('http');
const httpProxy = require('http-proxy');

const proxy = httpProxy.createProxyServer({ target: 'http://127.0.0.1:18789', ws: true });
proxy.on('error', (err) => console.error('Proxy error:', err.message));

// 終極偽裝函數
const cleanHeaders = (req) => {
  delete req.headers['x-forwarded-for'];
  delete req.headers['x-forwarded-proto'];
  delete req.headers['x-forwarded-host'];
  delete req.headers['x-real-ip'];
  req.headers['host'] = '127.0.0.1:18789';
  req.headers['origin'] = 'http://127.0.0.1:18789';
};

const server = http.createServer((req, res) => {
  cleanHeaders(req);
  proxy.web(req, res);
});

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
# 1. 刪除舊的設定檔 (清除之前的密碼記憶)
# 2. 重新設定為 local 模式 (不再設定 token)
# ================================
CMD sh -c "rm -f /root/.openclaw/openclaw.json && \
           openclaw config set gateway.mode local && \
           node proxy.js & \
           unset PORT && exec openclaw gateway run"