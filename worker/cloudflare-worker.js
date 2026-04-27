/**
 * Cloudflare Worker for Nezha on Choreo
 *
 * 用于将 Nezha 部署到 Choreo 时，通过 Cloudflare Worker 实现路由代理。
 * 解决 Choreo 强制添加路径前缀的问题。
 *
 * 架构:
 * - Nezha Dashboard 运行在 8008 端口
 * - Choreo REST 端点 (8008) → Nezha Dashboard
 * - Choreo WS 端点 (8009) → Caddy
 *   - /grpc-tunnel → grpc-ws-tunnel → Nezha gRPC
 *   - 其他 WS → Nezha Dashboard WebSocket
 * - Cloudflare Worker → 去除 Choreo 路径前缀 → Choreo 端点
 *
 * 部署步骤:
 * 1. 在 Cloudflare Dashboard → Workers & Pages → Create Worker
 * 2. 粘贴此代码并部署
 * 3. 修改下方的 CHOREO_ORIGIN 和 HTTP_PATH_PREFIX
 * 4. 在 Worker Settings → Triggers 中绑定自定义域名
 * 5. 确保域名 DNS 记录开启 Cloudflare 代理（橙色云朵）
 *
 * 注意: 必须绑定自定义域名才能正常工作
 */

// ============ 配置区域 ============
// 请根据你的 Choreo 部署修改以下配置

const CHOREO_ORIGIN = "uuid-dev.e1-us-east-azure.choreoapis.dev";
const HTTP_PATH_PREFIX = "/default/nezha/v1.0";
// 前端 WebSocket 和自定义 agent 的 /grpc-tunnel 都走这个 Choreo WS endpoint。
const WS_PATH_PREFIX = "/default/nezha/nezha_ws/v1.0";

// ============ 代码区域 ============

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // 调试端点
    if (path === '/debug-worker') {
      return new Response('Nezha Worker is active! v1.0', { status: 200 });
    }

    // 请求回显调试端点
    if (path === '/debug-request') {
      const debugInfo = {
        method: request.method,
        url: request.url,
        path: path,
        search: url.search,
        headers: Object.fromEntries(request.headers.entries()),
      };
      return new Response(JSON.stringify(debugInfo, null, 2), {
        status: 200,
        headers: { "Content-Type": "application/json" }
      });
    }

    // 处理 CORS 预检请求
    if (request.method === "OPTIONS") {
      return handleCORS();
    }

    // 检查是否是 WebSocket 升级请求
    const upgradeHeader = request.headers.get("Upgrade");
    const isWebSocketUpgrade = upgradeHeader && upgradeHeader.toLowerCase() === "websocket";

    // 检查是否是 gRPC 请求（仅用于日志；公网 agent 使用 /grpc-tunnel WebSocket，不走原生 Public GRPC）
    const contentType = request.headers.get("Content-Type") || "";
    const isGRPC = contentType.includes("application/grpc");

    console.log(`[Request] ${request.method} ${path} | WS: ${isWebSocketUpgrade} | gRPC: ${isGRPC}`);

    // WebSocket 请求需要特殊处理
    if (isWebSocketUpgrade) {
      return handleWebSocket(request, url);
    }

    // 代理其他请求到 Choreo
    return handleProxy(request, url, isGRPC);
  },
};

/**
 * 处理 CORS 预检请求
 */
function handleCORS() {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "*",
      "Access-Control-Max-Age": "86400",
    },
  });
}

/**
 * 处理 WebSocket 连接
 */
async function handleWebSocket(request, url) {
  const path = url.pathname;

  // 构建上游 WebSocket URL：走 Choreo 独立 WS endpoint
  const upstreamUrl = `https://${CHOREO_ORIGIN}${WS_PATH_PREFIX}${path}${url.search}`;

  console.log(`[WebSocket] Proxying to: ${upstreamUrl}`);

  const headers = cloneHeaders(request.headers, CHOREO_ORIGIN);

  const upstreamRequest = new Request(upstreamUrl, {
    method: request.method,
    headers: headers,
  });

  try {
    const response = await fetch(upstreamRequest);
    console.log(`[WebSocket] Response status: ${response.status}`);

    // 如果是错误响应，记录详情
    if (response.status >= 400) {
      const responseBody = await response.text();
      console.log(`[WebSocket] Error response: ${responseBody.substring(0, 500)}`);
      return new Response(responseBody, {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers,
      });
    }

    return response;
  } catch (error) {
    console.log(`[WebSocket] Error: ${error.message}`);
    return new Response(`WebSocket proxy error: ${error.message}`, { status: 502 });
  }
}

/**
 * 判断是否是 SPA 路由（非 API 且非静态资源）
 */
function isSPARoute(path) {
  const isApiPath = path.startsWith('/api/');
  const isStaticAsset = /\.(js|css|png|jpg|jpeg|gif|svg|ico|woff2?|ttf|eot|map|json|webp|avif)$/i.test(path);
  const isSpecialPath = path === '/favicon.ico' || path === '/manifest.json';
  return !isApiPath && !isStaticAsset && !isSpecialPath;
}

/**
 * 代理请求到 Choreo
 */
async function handleProxy(request, url, isGRPC) {
  const path = url.pathname;
  let method = request.method;

  // Safari 等浏览器会对页面链接发起 HEAD 预取请求
  // 对于 SPA 路由的 HEAD 请求，转换为 GET 请求以获得正确响应
  if (method === 'HEAD' && isSPARoute(path)) {
    console.log(`[Proxy] Converting HEAD to GET for SPA route: ${path}`);
    method = 'GET';
  }

  // 构建上游 URL：添加 Choreo 路径前缀
  const upstreamUrl = `https://${CHOREO_ORIGIN}${HTTP_PATH_PREFIX}${path}${url.search}`;

  console.log(`[Proxy] ${method} ${path} → ${upstreamUrl}`);

  const headers = cloneHeaders(request.headers, CHOREO_ORIGIN);

  // 对于有请求体的请求，先读取为 ArrayBuffer
  let body = null;
  if (method !== "GET" && method !== "HEAD") {
    try {
      body = await request.arrayBuffer();
    } catch (e) {
      body = request.body;
    }
  }

  // 手动处理重定向，保持请求方法不变
  let upstreamRequest = new Request(upstreamUrl, {
    method: method,
    headers: headers,
    body: body,
    redirect: "manual",
  });

  try {
    let response = await fetch(upstreamRequest);
    console.log(`[Proxy] Response status: ${response.status}`);

    // 手动处理重定向
    let redirectCount = 0;
    const maxRedirects = 5;
    while (response.status >= 300 && response.status < 400 && redirectCount < maxRedirects) {
      const location = response.headers.get("Location");
      if (!location) break;

      let redirectUrl;
      if (location.startsWith("/")) {
        // 相对路径重定向，添加 Choreo 前缀
        redirectUrl = `https://${CHOREO_ORIGIN}${HTTP_PATH_PREFIX}${location}${url.search}`;
      } else if (location.startsWith("http")) {
        redirectUrl = location;
      } else {
        redirectUrl = new URL(location, upstreamUrl).href;
      }

      console.log(`[Proxy] Following redirect to: ${redirectUrl}`);

      upstreamRequest = new Request(redirectUrl, {
        method: method,
        headers: headers,
        body: body,
        redirect: "manual",
      });

      response = await fetch(upstreamRequest);
      redirectCount++;
    }

    // 读取完整响应体
    const responseBody = await response.arrayBuffer();

    const newHeaders = new Headers(response.headers);
    newHeaders.set("Access-Control-Allow-Origin", "*");
    newHeaders.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    newHeaders.set("Access-Control-Allow-Headers", "*");

    return new Response(responseBody, {
      status: response.status,
      statusText: response.statusText,
      headers: newHeaders,
    });
  } catch (error) {
    console.log(`[Proxy] Error: ${error.message}`);
    return new Response(JSON.stringify({
      status: "error",
      message: `Proxy error: ${error.message}`
    }), {
      status: 502,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      }
    });
  }
}

/**
 * 克隆请求头，替换 Host
 */
function cloneHeaders(originalHeaders, newHost) {
  const headers = new Headers();
  for (const [key, value] of originalHeaders.entries()) {
    if (key.toLowerCase() !== 'host') {
      headers.set(key, value);
    }
  }
  headers.set('Host', newHost);
  return headers;
}
