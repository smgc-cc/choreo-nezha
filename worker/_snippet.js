/**
 * Cloudflare Snippet for Nezha on Choreo (混合模式 - HTTP 部分)
 *
 * 处理所有 HTTP 流量（页面、API、静态资源），WebSocket 交给 Worker 处理。
 * Snippet 在返回 HTML 时注入脚本，将前端 WebSocket 连接重定向到 ws.{当前域名}，
 * 该子域名绑定到 Worker 的 Custom Domain。
 *
 * 架构:
 * - HTTP (页面/API/资源) → Snippet → Choreo HTTP 端点 [免费无限额度]
 * - WS (前端实时数据)    → ws.{host} (Worker Custom Domain) → Choreo WS 端点
 * - Agent gRPC tunnel   → ws.{host} /grpc-tunnel → Choreo WS 端点
 *
 * Cookie 处理:
 * - 上游 Set-Cookie 的 nz-jwt 没有 Domain 属性（只对当前 host 生效）
 * - Snippet 给它加上 Domain=.{host}，使 cookie 对 ws.{host} 子域名也生效
 * - 这样终端等需要登录态的 WS 功能可以正常鉴权
 * - 后端在反代链后面只看到 HTTP，不会设 Secure 标志；Snippet 给所有 cookie
 *   补上 Secure（Chrome 要求 SameSite=None 必须搭配 Secure，否则静默丢弃）
 *
 * 配套:
 * - _worker.js: 部署为 Worker，添加 Custom Domain: ws.{host}
 * - _snippet.js: 部署为 Snippet
 *
 * 部署步骤:
 * 1. 在 Cloudflare Dashboard → Rules → Snippets → Create Snippet
 * 2. 粘贴此代码并部署，关联到主域名
 * 3. 修改下方的 CHOREO_ORIGIN 和 HTTP_PATH_PREFIX
 * 4. 配合 _worker.js 部署 Worker 并绑定 ws.{host} Custom Domain
 */

// ============ 配置区域 ============
// 请根据你的 Choreo 部署修改以下配置

const CHOREO_ORIGIN = "uuid-dev.e1-us-east-azure.choreoapis.dev";
const HTTP_PATH_PREFIX = "/default/nezha/v1.0";

// Dashboard 前端复制的 agent 安装命令来自上游构建产物，无法用 install_host 配置脚本 URL。
// 这里在 Snippet 层把上游脚本 URL 改成 patched Choreo agent 安装脚本。
const AGENT_INSTALL_SCRIPT_URL = "https://raw.githubusercontent.com/smgc-cc/choreo-nezha/main/agent/install.sh";
const UPSTREAM_AGENT_INSTALL_PATTERNS = [
  /https:\/\/raw\.githubusercontent\.com\/nezhahq\/scripts\/[^\s'"`<>]+\/(?:agent\/)?install(?:_en)?\.sh/g,
  /https:\/\/gitee\.com\/naibahq\/scripts\/raw\/[^\s'"`<>]+\/(?:agent\/)?install\.sh/g,
  /https:\/\/cdn\.jsdelivr\.net\/gh\/nezhahq\/scripts@[^\s'"`<>]+\/(?:agent\/)?install(?:_en)?\.sh/g,
  /https:\/\/fastly\.jsdelivr\.net\/gh\/nezhahq\/scripts@[^\s'"`<>]+\/(?:agent\/)?install(?:_en)?\.sh/g,
  /https:\/\/testingcf\..jsdelivr\.net\/gh\/nezhahq\/scripts@[^\s'"`<>]+\/(?:agent\/)?install(?:_en)?\.sh/g,
];

// 注入到 HTML 的脚本: 根据当前访问域名自动推导 WS 域名 (ws. 前缀)
const WS_INJECT_SCRIPT = `<script>
(function(){
  var O=window.WebSocket;
  window.WebSocket=function(u,p){
    var o=new URL(u);
    o.host="ws."+location.host;
    return p!==void 0?new O(o+"",p):new O(o+"");
  };
  window.WebSocket.prototype=O.prototype;
  for(var k in{CONNECTING:0,OPEN:1,CLOSING:2,CLOSED:3})window.WebSocket[k]=O[k];
})();
</script>`;

// ============ 代码区域 ============

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const requestHost = url.hostname; // 当前访问域名，用于 cookie domain

    // 调试端点
    if (path === '/debug-worker') {
      return new Response('Nezha Snippet is active! (hybrid mode)', { status: 200 });
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

    let method = request.method;

    // Safari HEAD 预取 → 转为 GET（SPA 路由需要完整响应）
    if (method === 'HEAD' && isSPARoute(path)) {
      console.log(`[Snippet] Converting HEAD to GET for SPA route: ${path}`);
      method = 'GET';
    }

    const upstreamUrl = `https://${CHOREO_ORIGIN}${HTTP_PATH_PREFIX}${path}${url.search}`;

    console.log(`[Snippet] ${method} ${path} → ${upstreamUrl}`);

    // 克隆请求头，替换 Host
    const headers = new Headers();
    for (const [key, value] of request.headers.entries()) {
      if (key.toLowerCase() !== 'host') {
        headers.set(key, value);
      }
    }
    headers.set('Host', CHOREO_ORIGIN);
    headers.set('Accept-Encoding', 'identity');

    // 读取请求体
    let body = null;
    if (method !== "GET" && method !== "HEAD") {
      try {
        body = await request.arrayBuffer();
      } catch (e) {
        body = request.body;
      }
    }

    try {
      // 手动处理重定向: 上游的 301 会丢 Choreo 路径前缀
      let response = await fetch(upstreamUrl, {
        method: method,
        headers: headers,
        body: body,
        redirect: "manual",
      });

      // 处理重定向（最多跟 5 次）
      let redirects = 0;
      while (response.status >= 300 && response.status < 400 && redirects < 5) {
        const location = response.headers.get("Location");
        if (!location) break;

        let redirectUrl;
        if (location.startsWith("/")) {
          redirectUrl = `https://${CHOREO_ORIGIN}${HTTP_PATH_PREFIX}${location}`;
        } else if (location.startsWith("http")) {
          redirectUrl = location;
        } else {
          redirectUrl = new URL(location, upstreamUrl).href;
        }

        console.log(`[Snippet] Following redirect to: ${redirectUrl}`);

        response = await fetch(redirectUrl, {
          method: method,
          headers: headers,
          body: body,
          redirect: "manual",
        });
        redirects++;
      }

      const contentType = response.headers.get("Content-Type") || "";
      const isHTML = contentType.includes("text/html");

      const newHeaders = new Headers(response.headers);
      newHeaders.set("Access-Control-Allow-Origin", "*");
      newHeaders.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
      newHeaders.set("Access-Control-Allow-Headers", "*");

      // 改写 Set-Cookie: 给 nz-jwt 加 Domain=.{host}
      // 使 cookie 对 ws.{host} 子域名也生效（终端等 WS 功能需要登录态）
      rewriteCookieDomain(response, newHeaders, requestHost);

      // HTML 响应: 注入 WS 重定向脚本 + 替换 agent 安装脚本 URL
      if (isHTML) {
        let html = await response.text();

        // 注入 WS 重定向脚本（所有 HTML 页面都需要）
        html = html.replace(/<head([^>]*)>/i, `<head$1>${WS_INJECT_SCRIPT}`);

        // Dashboard 页面还需要替换 agent 安装脚本 URL
        if (shouldRewriteAgentInstallCommand(path, contentType)) {
          html = rewriteAgentInstallCommand(html);
        }

        newHeaders.delete("Content-Length");
        newHeaders.delete("Content-Encoding");
        newHeaders.set("Content-Type", "text/html; charset=utf-8");

        return new Response(html, {
          status: response.status,
          statusText: response.statusText,
          headers: newHeaders,
        });
      }

      // 非 HTML 文本响应（JSON 等）：替换 agent 安装脚本 URL
      if (!isHTML && shouldRewriteAgentInstallCommand(path, contentType)) {
        const responseText = await response.text();
        const rewrittenBody = rewriteAgentInstallCommand(responseText);
        newHeaders.delete("Content-Length");
        newHeaders.delete("Content-Encoding");
        return new Response(rewrittenBody, {
          status: response.status,
          statusText: response.statusText,
          headers: newHeaders,
        });
      }

      // 其他响应直接透传
      const responseBody = await response.arrayBuffer();

      return new Response(responseBody, {
        status: response.status,
        statusText: response.statusText,
        headers: newHeaders,
      });
    } catch (error) {
      console.log(`[Snippet] Error: ${error.message}`);
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
  },
};

/**
 * 改写 Set-Cookie 中 nz-jwt 的 Domain
 *
 * 上游返回: Set-Cookie: nz-jwt=xxx; Path=/; HttpOnly; Secure; SameSite=Lax
 * 改写为:   Set-Cookie: nz-jwt=xxx; Path=/; HttpOnly; Secure; SameSite=None; Domain=.{host}
 *
 * Domain=.{host} 使 cookie 对 ws.{host} 也生效
 * SameSite 从 Lax 改为 None（跨子域名 WS 需要）
 */
function rewriteCookieDomain(response, newHeaders, host) {
  const cookies = response.headers.getAll
    ? response.headers.getAll("Set-Cookie")
    : [response.headers.get("Set-Cookie")].filter(Boolean);

  if (!cookies.length) return;

  // 清除原有 Set-Cookie（newHeaders 从 response.headers 复制过来的）
  newHeaders.delete("Set-Cookie");

  for (const cookie of cookies) {
    if (cookie.includes("nz-jwt")) {
      // 加 Domain，SameSite 改为 None（跨子域 WS 需要 Secure + SameSite=None）
      // Chrome 要求 SameSite=None 必须搭配 Secure，否则 cookie 被静默丢弃
      let rewritten = cookie
        .replace(/;\s*SameSite=\w+/i, "; SameSite=None")
        .replace(/;\s*Domain=[^;]*/i, ""); // 先删掉已有的 Domain（如果有）
      if (!/;\s*Secure/i.test(rewritten)) {
        rewritten += "; Secure";
      }
      rewritten += `; Domain=.${host}`;
      newHeaders.append("Set-Cookie", rewritten);
    } else {
      // 其他 cookie（如 nz-csrf）：后端在反代后面看到 HTTP，不会加 Secure；
      // 浏览器在 HTTPS 页面上收到无 Secure 的 cookie 可能拒绝存储（Chrome 严格模式）
      let rewritten = cookie;
      if (!/;\s*Secure/i.test(rewritten)) {
        rewritten += "; Secure";
      }
      newHeaders.append("Set-Cookie", rewritten);
    }
  }
}

/**
 * 判断响应是否可能包含 Dashboard 复制的 agent 安装命令
 */
function shouldRewriteAgentInstallCommand(path, contentType) {
  const isTextResponse = /text\/html|application\/javascript|text\/javascript|application\/json|text\/plain/i.test(contentType);
  return isTextResponse && (path.startsWith('/dashboard/') || path === '/dashboard' || path === '/api/v1/setting');
}

/**
 * 替换上游 agent 安装脚本地址
 */
function rewriteAgentInstallCommand(body) {
  return UPSTREAM_AGENT_INSTALL_PATTERNS.reduce(
    (text, pattern) => text.replace(pattern, AGENT_INSTALL_SCRIPT_URL),
    body,
  );
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
