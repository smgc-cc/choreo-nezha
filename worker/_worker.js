/**
 * Cloudflare Worker for Nezha on Choreo (混合模式 - WebSocket 部分)
 *
 * 主要处理 WebSocket 代理（前端实时数据 + Agent gRPC tunnel）。
 * 配合 _snippet.js (Cloudflare Snippet) 使用：
 * - Snippet 处理主站 HTTP 流量并注入脚本将 WS 重定向到本 Worker
 * - Worker 处理 WebSocket 连接
 * - 非 WS 的 HTTP 访问返回 426（防止暴露）
 *
 * 架构:
 * - Choreo REST 端点 (8008) → Nezha Dashboard
 * - Choreo WS 端点 (8009) → Caddy
 *   - /grpc-tunnel → grpc-ws-tunnel → Nezha gRPC
 *   - 其他 WS → Nezha Dashboard WebSocket
 *
 * 部署步骤:
 * 1. 在 Cloudflare Dashboard → Workers & Pages → Create Worker
 * 2. 粘贴此代码并部署
 * 3. 修改下方的 CHOREO_ORIGIN 和 WS_PATH_PREFIX
 * 4. 在 Worker Settings → Triggers 中绑定 ws.{host} 自定义域名
 * 5. 确保 ws.{host} DNS 记录开启 Cloudflare 代理（橙色云朵）
 */

// ============ 配置区域 ============
// 请根据你的 Choreo 部署修改以下配置

const CHOREO_ORIGIN = "uuid-dev.e1-us-east-azure.choreoapis.dev";
const WS_PATH_PREFIX = "/default/nezha/nezha_ws/v1.0";

// ============ 代码区域 ============

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname;

    // WebSocket → 代理到 Choreo WS 端点
    const upgradeHeader = request.headers.get("Upgrade");
    if (upgradeHeader && upgradeHeader.toLowerCase() === "websocket") {
      return handleWebSocket(request, path, url.search);
    }

    // 其他 HTTP → 426 拒绝（防暴露）
    return new Response(null, { status: 426, headers: { "Upgrade": "websocket" } });
  },
};

/**
 * WebSocket 代理
 */
async function handleWebSocket(request, path, search) {
  const upstreamUrl = `https://${CHOREO_ORIGIN}${WS_PATH_PREFIX}${path}${search}`;

  console.log(`[Worker WS] Proxying to: ${upstreamUrl}`);

  try {
    const upstreamRequest = new Request(upstreamUrl, request);
    upstreamRequest.headers.set("Host", CHOREO_ORIGIN);
    upstreamRequest.headers.delete("Origin");

    const response = await fetch(upstreamRequest);

    if (response.status >= 400) {
      const body = await response.text();
      console.log(`[Worker WS] Error response: ${body.substring(0, 500)}`);
      return new Response(body, {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers,
      });
    }

    console.log(`[Worker WS] Connected: ${response.status}`);
    return response;
  } catch (error) {
    console.log(`[Worker WS] Error: ${error.message}`);
    return new Response(`WebSocket proxy error: ${error.message}`, { status: 502 });
  }
}
