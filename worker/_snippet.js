/**
 * Cloudflare Snippet for Nezha on Choreo（模式一，推荐）
 *
 * 默认：单域名。面板域名 = Choreo 自定义域 = Agent 域名。
 * WebSocket 不进 Snippet、不经 Worker：注入补 WS 路径前缀后原生穿透。
 *
 * 架构:
 * - HTTP → Snippet → CHOREO_ORIGIN + REST 前缀
 * - WS   → 不进 Snippet；注入补 WS 路径前缀；WS_PUBLIC_HOST 空则同源
 * - Agent（patched）:
 *     server: wss://面板域名/default/nezha/nezha_ws/v1.0/grpc-tunnel
 *     WSS 原生穿透 → Choreo WS → Caddy → grpc-ws-tunnel → Nezha
 *
 * 多域名（面板入口 ≠ Choreo 绑定域）:
 * - WS_PUBLIC_HOST = Choreo 已绑定域名
 * - 跨注册域无法共享 cookie → 仅终端/文件页注入 JWT
 * - 浏览器 WS 使用 Nezha 原生 query: token（TokenLookup 已支持，无需 Caddy 转 Cookie）
 *
 * Cookie:
 * - 单域名默认 host-only，终端等需登录态的 WS 同源即可带 nz-jwt
 * - 同父域跨子域可设 COOKIE_DOMAIN；跨注册域请用 query: token
 * - 反代后上游常看不到 HTTPS，给 cookie 补 Secure
 * - 注意：失效 nz-jwt 在可选鉴权接口上可能触发 Nezha WAF 封锁页（Blocked HTML），
 *   前端会 Oops。清站点 cookie 后重新登录即可；必要时在后台解封 IP
 *
 * 备选：全流量 Worker → _worker_standalone.js
 */

// ============ 配置区域 ============

const CHOREO_ORIGIN = "uuid-dev.e1-us-east-azure.choreoapis.dev";
const HTTP_PATH_PREFIX = "/default/nezha/v1.0";
const WS_PATH_PREFIX = "/default/nezha/nezha_ws/v1.0";
// 单域名：留空 = WebSocket 与页面同 host（推荐）
// 多域名特例：填 Choreo 已绑定的域名，例如 "nezha.snippet.com"
const WS_PUBLIC_HOST = "";
// 一般保持空（host-only）。同父域跨子域时可填 ".example.com"
// 跨注册域（如 nezha.example.com ↔ nezha.snippet.com）填了也无效，靠 query: token
const COOKIE_DOMAIN = "";
// 注入到 HTML 的 JWT 最大长度（异常 cookie 直接丢弃）
const JWT_MAX_LEN = 4096;

// Dashboard 前端复制的 agent 安装命令来自上游构建产物，无法用 install_host 配置脚本 URL。
// 这里在 Snippet 层把上游脚本 URL 改成 patched Choreo agent 安装脚本。
const AGENT_INSTALL_SCRIPT_URL =
  "https://raw.githubusercontent.com/smgc-cc/choreo-nezha/main/agent/install.sh";
const UPSTREAM_AGENT_INSTALL_PATTERNS = [
  /https:\/\/raw\.githubusercontent\.com\/nezhahq\/scripts\/[^\s'"`<>]+\/(?:agent\/)?install(?:_en)?\.sh/g,
  /https:\/\/gitee\.com\/naibahq\/scripts\/raw\/[^\s'"`<>]+\/(?:agent\/)?install\.sh/g,
  /https:\/\/cdn\.jsdelivr\.net\/gh\/nezhahq\/scripts@[^\s'"`<>]+\/(?:agent\/)?install(?:_en)?\.sh/g,
  /https:\/\/fastly\.jsdelivr\.net\/gh\/nezhahq\/scripts@[^\s'"`<>]+\/(?:agent\/)?install(?:_en)?\.sh/g,
  /https:\/\/testingcf\..jsdelivr\.net\/gh\/nezhahq\/scripts@[^\s'"`<>]+\/(?:agent\/)?install(?:_en)?\.sh/g,
];

// ============ 注入脚本 ============

/**
 * @param {string} jwtToken 仅多域名 + 终端/文件页时非空；其它页为 ""
 */
function buildWsInjectScript(jwtToken) {
  return `<script>
(function(){
  var P=${JSON.stringify(WS_PATH_PREFIX)};
  var H=${JSON.stringify(WS_PUBLIC_HOST)};
  var T=${JSON.stringify(jwtToken || "")};
  var O=window.WebSocket;
  window.WebSocket=function(u,p){
    var o=new URL(u,location.href);
    // 同源、显式 WS 公共域、或旧 ws. 子域 → 统一改写到目标 host + 补路径前缀
    if(o.host===location.host||(H&&o.host===H)||o.host===("ws."+location.host)){
      o.host=H||location.host;
      if(P&&o.pathname.indexOf(P)!==0){
        o.pathname=P.replace(/\\/$/,"")+o.pathname;
      }
      // 跨域 WS 带不上 nz-jwt cookie。
      // Nezha TokenLookup = "header: Authorization, query: token, cookie: nz-jwt"
      // 终端/文件 WS 用原生 query: token
      if(T&&H&&H!==location.host&&!o.searchParams.get("token")){
        if(o.pathname.indexOf("/api/v1/ws/terminal/")!==-1||o.pathname.indexOf("/api/v1/ws/file/")!==-1){
          o.searchParams.set("token",T);
        }
      }
    }
    return p!==void 0?new O(o.href,p):new O(o.href);
  };
  window.WebSocket.prototype=O.prototype;
  for(var k in{CONNECTING:0,OPEN:1,CLOSING:2,CLOSED:3})window.WebSocket[k]=O[k];
})();
</script>`;
}

function readRequestCookie(request, name) {
  const raw = request.headers.get("Cookie") || "";
  for (const part of raw.split(";")) {
    const i = part.indexOf("=");
    if (i === -1) continue;
    if (part.slice(0, i).trim() === name) return part.slice(i + 1).trim();
  }
  return "";
}

/** JWT / base64url 形态；过长或怪异字符不注入 */
function sanitizeJwt(token) {
  if (!token) return "";
  if (token.length > JWT_MAX_LEN) return "";
  if (!/^[A-Za-z0-9._~\-+/=]+$/.test(token)) return "";
  return token;
}

/**
 * 仅多域名且终端/文件管理页注入 JWT（全页 window.open，可命中）。
 * 不要在 /dashboard/login 或普通后台页注入，避免 HTML 泄露面扩大。
 */
function shouldInjectJwt(path) {
  if (!(WS_PUBLIC_HOST || "").trim()) return false;
  if (!path) return false;
  let p = path;
  if (p.length > 1 && p.endsWith("/")) p = p.slice(0, -1);
  if (p === "/dashboard/terminal" || p.startsWith("/dashboard/terminal/")) return true;
  if (p === "/dashboard/file" || p.startsWith("/dashboard/file/")) return true;
  // 部分构建可能用其它文件管理路径
  if (p === "/dashboard/fm" || p.startsWith("/dashboard/fm/")) return true;
  return false;
}

/**
 * 把浏览器 pathname 归一成 Choreo REST 上游路径。
 *
 * 1) 已带 HTTP 前缀 → 原样（防双重前缀）
 * 2) 误带 WS 前缀 → 换成 HTTP 前缀 + 剩余 path
 * 3) 裸 /... → 加 HTTP 前缀
 */
function toChoreoHttpPath(path) {
  const http = (HTTP_PATH_PREFIX || "").replace(/\/+$/, "") || "";
  const ws = (WS_PATH_PREFIX || "").replace(/\/+$/, "") || "";
  let p = path || "/";
  if (!p.startsWith("/")) p = "/" + p;

  if (http && (p === http || p.startsWith(http + "/"))) {
    return p;
  }
  if (ws && (p === ws || p.startsWith(ws + "/"))) {
    const rest = p.slice(ws.length) || "/";
    return http + (rest.startsWith("/") ? rest : "/" + rest);
  }
  return http + p;
}

// ============ 主处理 ============

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const requestHost = url.hostname;

    if (path === "/debug-worker" || path === "/debug-snippet") {
      return new Response("Nezha Snippet is active! (snippet-only / no worker for WS)", {
        status: 200,
      });
    }

    if (path === "/debug-request") {
      const debugInfo = {
        method: request.method,
        url: request.url,
        path,
        search: url.search,
        headers: Object.fromEntries(request.headers.entries()),
      };
      return new Response(JSON.stringify(debugInfo, null, 2), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

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
    if (method === "HEAD" && isSPARoute(path)) method = "GET";

    const upstreamPath = toChoreoHttpPath(path);
    const upstreamUrl = `https://${CHOREO_ORIGIN}${upstreamPath}${url.search}`;

    const headers = new Headers();
    for (const [key, value] of request.headers.entries()) {
      const lk = key.toLowerCase();
      if (lk !== "host" && lk !== "origin") headers.set(key, value);
    }
    headers.set("Host", CHOREO_ORIGIN);
    headers.set("Accept-Encoding", "identity");

    let body = null;
    if (method !== "GET" && method !== "HEAD") {
      try {
        body = await request.arrayBuffer();
      } catch (e) {
        body = request.body;
      }
    }

    try {
      let response = await fetch(upstreamUrl, {
        method,
        headers,
        body,
        redirect: "manual",
      });

      let redirects = 0;
      while (response.status >= 300 && response.status < 400 && redirects < 5) {
        const location = response.headers.get("Location");
        if (!location) break;

        let redirectUrl;
        if (location.startsWith("/")) {
          redirectUrl = `https://${CHOREO_ORIGIN}${toChoreoHttpPath(location)}`;
        } else if (location.startsWith("http")) {
          redirectUrl = location;
        } else {
          redirectUrl = new URL(location, upstreamUrl).href;
        }

        response = await fetch(redirectUrl, {
          method,
          headers,
          body,
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

      rewriteCookieDomain(response, newHeaders, requestHost);

      if (isHTML) {
        let jwtForInject = "";
        if (shouldInjectJwt(path)) {
          jwtForInject = sanitizeJwt(readRequestCookie(request, "nz-jwt"));
        }

        let html = await response.text();
        html = html.replace(/<head([^>]*)>/i, `<head$1>${buildWsInjectScript(jwtForInject)}`);

        if (shouldRewriteAgentInstallCommand(path, contentType)) {
          html = rewriteAgentInstallCommand(html);
        }

        newHeaders.delete("Content-Length");
        newHeaders.delete("Content-Encoding");
        newHeaders.set("Content-Type", "text/html; charset=utf-8");
        applyNoStore(newHeaders);

        return new Response(html, {
          status: response.status,
          statusText: response.statusText,
          headers: newHeaders,
        });
      }

      if (shouldRewriteAgentInstallCommand(path, contentType)) {
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

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: newHeaders,
      });
    } catch (error) {
      return new Response(
        JSON.stringify({
          status: "error",
          message: `Proxy error: ${error.message}`,
        }),
        {
          status: 502,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Cache-Control": "no-store",
          },
        }
      );
    }
  },
};

function applyNoStore(headers) {
  headers.set("Cache-Control", "no-store, no-cache, must-revalidate, private");
  headers.set("Pragma", "no-cache");
  headers.set("Expires", "0");
}

/**
 * 解析是否需要给 cookie 扩 Domain（仅同父域跨 host WS 时）。
 * 单域名 / 跨注册域 → 返回 null。
 */
function resolveCookieDomain(requestHost, wsPublicHost) {
  const forced = (COOKIE_DOMAIN || "").trim();
  if (forced) return forced.startsWith(".") ? forced : `.${forced}`;

  const host = (requestHost || "").toLowerCase();
  const wsHost = (wsPublicHost || "").toLowerCase();
  if (!host) return null;
  if (!wsHost || wsHost === host) return null;
  if (wsHost.endsWith("." + host)) return "." + host;
  return null;
}

/**
 * 改写 Set-Cookie：
 * - 始终尽量补 Secure（反代后上游常是 HTTP）
 * - 仅同父域跨 host 时给 nz-jwt 加 Domain + SameSite=None
 */
function rewriteCookieDomain(response, newHeaders, host) {
  const cookies = response.headers.getAll
    ? response.headers.getAll("Set-Cookie")
    : [response.headers.get("Set-Cookie")].filter(Boolean);

  if (!cookies.length) return;

  const domain = resolveCookieDomain(host, WS_PUBLIC_HOST);
  newHeaders.delete("Set-Cookie");

  for (const cookie of cookies) {
    let rewritten = cookie;
    if (!/;\s*Secure/i.test(rewritten)) {
      rewritten += "; Secure";
    }

    if (domain && cookie.includes("nz-jwt")) {
      rewritten = rewritten
        .replace(/;\s*SameSite=\w+/i, "; SameSite=None")
        .replace(/;\s*Domain=[^;]*/i, "");
      if (!/;\s*SameSite=/i.test(rewritten)) {
        rewritten += "; SameSite=None";
      }
      rewritten += `; Domain=${domain}`;
    }

    newHeaders.append("Set-Cookie", rewritten);
  }
}

function shouldRewriteAgentInstallCommand(path, contentType) {
  const isTextResponse =
    /text\/html|application\/javascript|text\/javascript|application\/json|text\/plain/i.test(
      contentType
    );
  return (
    isTextResponse &&
    (path.startsWith("/dashboard/") || path === "/dashboard" || path === "/api/v1/setting")
  );
}

function rewriteAgentInstallCommand(body) {
  return UPSTREAM_AGENT_INSTALL_PATTERNS.reduce(
    (text, pattern) => text.replace(pattern, AGENT_INSTALL_SCRIPT_URL),
    body
  );
}

function isSPARoute(path) {
  if (path.startsWith("/api/")) return false;
  if (/\.(js|css|png|jpg|jpeg|gif|svg|ico|woff2?|ttf|eot|map|json|webp|avif)$/i.test(path))
    return false;
  if (path === "/favicon.ico" || path === "/manifest.json") return false;
  return true;
}
