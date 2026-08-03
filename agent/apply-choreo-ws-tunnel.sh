#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path
import re

# ---------------------------------------------------------------------------
# connection_config.go — WS/WSS dialer on connectionConfigTuple
# ---------------------------------------------------------------------------
conn_cfg = Path('cmd/agent/connection_config.go')
text = conn_cfg.read_text()

# Expand imports for websocket dialer + keepalive.
# Inject path-by-path so upstream CodeQL/logging tweaks (e.g. extra "log")
# do not break the exact-block match used by older scripts.
def ensure_go_imports(src: str, paths: list[str]) -> str:
    """Insert any missing import paths into the first import (...) block.

    Stdlib paths (no dot in first path segment) go with other stdlib imports;
    third-party paths go after the blank line that separates them. If the
    import block is missing entirely, raise so the failure is explicit.
    """
    m = re.search(r'(?ms)^import \(\n(.*?)^\)\n', src)
    if not m:
        raise SystemExit('cannot find connection_config.go import block')

    body = m.group(1)
    existing = set(re.findall(r'"([^"]+)"', body))
    missing = [p for p in paths if p not in existing]
    if not missing:
        return src

    stdlib = []
    third = []
    for p in missing:
        # stdlib: single segment or no domain-looking first segment
        first = p.split('/')[0]
        if '.' not in first:
            stdlib.append(p)
        else:
            third.append(p)

    lines = body.splitlines(keepends=True)
    # Drop trailing blank lines inside the block; we'll re-add separators.
    while lines and lines[-1].strip() == '':
        lines.pop()

    # Partition existing lines into stdlib / blank / third-party.
    std_lines, third_lines = [], []
    seen_blank = False
    for line in lines:
        if line.strip() == '':
            seen_blank = True
            continue
        if not seen_blank and '"' in line:
            # Heuristic: before first blank = stdlib group (may already mix on
            # some files; still append new stdlib there).
            path_m = re.search(r'"([^"]+)"', line)
            if path_m and '.' not in path_m.group(1).split('/')[0]:
                std_lines.append(line)
            else:
                # Already mixed / third-party appeared before blank.
                third_lines.append(line)
                seen_blank = True
        else:
            third_lines.append(line)

    for p in sorted(stdlib):
        std_lines.append(f'\t"{p}"\n')
    for p in sorted(third):
        third_lines.append(f'\t"{p}"\n')

    # Stable-ish sort within each group by the quoted path.
    def sort_key(line: str) -> str:
        pm = re.search(r'"([^"]+)"', line)
        return pm.group(1) if pm else line

    std_lines = sorted(set(std_lines), key=sort_key)
    third_lines = sorted(set(third_lines), key=sort_key)

    new_body = ''.join(std_lines)
    if std_lines and third_lines:
        new_body += '\n'
    new_body += ''.join(third_lines)

    return src[: m.start(1)] + new_body + src[m.end(1) :]


text = ensure_go_imports(
    text,
    [
        'context',
        'net',
        'strings',
        'time',
        'github.com/coder/websocket',
        'google.golang.org/grpc/keepalive',
    ],
)

# Inject newClient() helper that supports ws:// / wss:// transport + keepalive.
helper = '''
func (c connectionConfigTuple) newClient() (*grpc.ClientConn, error) {
	if strings.HasPrefix(c.Server, "ws://") || strings.HasPrefix(c.Server, "wss://") {
		return grpc.NewClient(
			"passthrough:///nezha-ws-tunnel",
			grpc.WithTransportCredentials(insecure.NewCredentials()),
			// Detect dead tunnels quickly; Cloudflare/Choreo may drop idle WS
			// without a clean close the agent can observe.
			grpc.WithKeepaliveParams(keepalive.ClientParameters{
				Time:                20 * time.Second,
				Timeout:             10 * time.Second,
				PermitWithoutStream: true,
			}),
			grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
				wsConn, _, err := websocket.Dial(ctx, c.Server, &websocket.DialOptions{
					CompressionMode: websocket.CompressionDisabled,
				})
				if err != nil {
					return nil, err
				}
				// WebSocket ping unblocks half-open connections so the outer
				// reconnect loop can run without a process restart.
				go keepWebSocketAlive(wsConn)
				return websocket.NetConn(context.Background(), wsConn, websocket.MessageBinary), nil
			}),
			grpc.WithPerRPCCredentials(c.Auth),
		)
	}
	return grpc.NewClient(c.Server, c.dialOptions()...)
}

func keepWebSocketAlive(wsConn *websocket.Conn) {
	ticker := time.NewTicker(25 * time.Second)
	defer ticker.Stop()
	for range ticker.C {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		err := wsConn.Ping(ctx)
		cancel()
		if err != nil {
			_ = wsConn.Close(websocket.StatusGoingAway, "ping failed")
			return
		}
	}
}

'''

if 'func keepWebSocketAlive(' not in text:
    # Replace older newClient without keepalive if present.
    if 'func (c connectionConfigTuple) newClient()' in text:
        text = re.sub(
            r'\nfunc \(c connectionConfigTuple\) newClient\(\) \(\*grpc\.ClientConn, error\) \{.*?\n\}\n',
            '\n',
            text,
            count=1,
            flags=re.S,
        )
    anchor = 'func (c connectionConfigTuple) dialOptions() []grpc.DialOption {\n'
    if anchor not in text:
        raise SystemExit('cannot find dialOptions method anchor in connection_config.go')
    text = text.replace(anchor, helper + anchor, 1)
elif 'grpc.WithKeepaliveParams' not in text or 'keepWebSocketAlive' not in text:
    # Force re-inject if incomplete.
    text = re.sub(
        r'\nfunc \(c connectionConfigTuple\) newClient\(\) \(\*grpc\.ClientConn, error\) \{.*?\n\}\n(?:\nfunc keepWebSocketAlive\(.*?\n\}\n)?',
        '\n',
        text,
        count=1,
        flags=re.S,
    )
    anchor = 'func (c connectionConfigTuple) dialOptions() []grpc.DialOption {\n'
    if anchor not in text:
        raise SystemExit('cannot find dialOptions method anchor after cleanup')
    text = text.replace(anchor, helper + anchor, 1)

conn_cfg.write_text(text)

# ---------------------------------------------------------------------------
# main.go — call newClient() instead of grpc.NewClient(...dialOptions()...)
# ---------------------------------------------------------------------------
main = Path('cmd/agent/main.go')
text = main.read_text()

old_newclient = 'conn, err = grpc.NewClient(connectionConfig.Server, connectionConfig.dialOptions()...)'
new_newclient = 'conn, err = connectionConfig.newClient()'
if new_newclient not in text:
    if old_newclient not in text:
        matches = [line for line in text.splitlines() if 'grpc.NewClient' in line]
        raise SystemExit(
            'cannot find grpc.NewClient connection call to replace. candidates: ' + repr(matches[:5])
        )
    text = text.replace(old_newclient, new_newclient, 1)

# Faster reconnect on Choreo/Cloudflare tunnel drops (upstream default is 10s).
# Keep a small pause so we don't tight-loop hammer the endpoint on hard outages.
old_delay = 'delayWhenError = time.Second * 10 // Agent 重连间隔'
new_delay = 'delayWhenError = time.Second * 2 // Agent 重连间隔（Choreo WS 隧道缩短）'
if new_delay not in text:
    if old_delay not in text:
        # tolerate already-custom values that still look like the constant
        if 'delayWhenError = time.Second *' not in text:
            raise SystemExit('cannot find delayWhenError constant in main.go')
    else:
        text = text.replace(old_delay, new_delay, 1)

# Self-update: prefer custom UpdateRepo (default smgc-cc/choreo-nezha).
old_update = '''\tprintf("检查更新: %v", v)\n\tvar latest *selfupdate.Release\n\tswitch {\n'''
new_update = '''\tprintf("检查更新: %v", v)\n\tvar latest *selfupdate.Release\n\tupdateRepo := strings.TrimSpace(config.updateRepo)\n\tif updateRepo == "" {\n\t\tupdateRepo = "smgc-cc/choreo-nezha"\n\t}\n\tswitch {\n\tcase updateRepo != "":\n\t\tupdater, erru := selfupdate.NewUpdater(selfupdate.Config{\n\t\t\tBinaryName: binaryName,\n\t\t})\n\t\tif erru != nil {\n\t\t\tprintf("更新失败: %v", erru)\n\t\t\treturn\n\t\t}\n\t\tlatest, err = updater.UpdateSelf(v, updateRepo)\n'''
if 'updateRepo := strings.TrimSpace(config.updateRepo)' not in text:
    if old_update not in text:
        raise SystemExit('cannot find self-update switch anchor in main.go')
    text = text.replace(old_update, new_update, 1)

main.write_text(text)

# ---------------------------------------------------------------------------
# runtime_config_consumers.go — plumb UpdateRepo into updateConfigTuple
# ---------------------------------------------------------------------------
consumers = Path('cmd/agent/runtime_config_consumers.go')
text = consumers.read_text()

if 'updateRepo' not in text:
    old_tuple = '''type updateConfigTuple struct {
	useAtomGitToUpgrade bool
	useGiteeToUpgrade   bool
}'''
    new_tuple = '''type updateConfigTuple struct {
	useAtomGitToUpgrade bool
	useGiteeToUpgrade   bool
	updateRepo          string
}'''
    if old_tuple not in text:
        raise SystemExit('cannot find updateConfigTuple struct in runtime_config_consumers.go')
    text = text.replace(old_tuple, new_tuple, 1)

    old_from = '''func updateConfigTupleFrom(config *model.AgentConfig) updateConfigTuple {
	return updateConfigTuple{
		useAtomGitToUpgrade: config.UseAtomGitToUpgrade,
		useGiteeToUpgrade:   config.UseGiteeToUpgrade,
	}
}'''
    new_from = '''func updateConfigTupleFrom(config *model.AgentConfig) updateConfigTuple {
	return updateConfigTuple{
		useAtomGitToUpgrade: config.UseAtomGitToUpgrade,
		useGiteeToUpgrade:   config.UseGiteeToUpgrade,
		updateRepo:          config.UpdateRepo,
	}
}'''
    if old_from not in text:
        raise SystemExit('cannot find updateConfigTupleFrom in runtime_config_consumers.go')
    text = text.replace(old_from, new_from, 1)

consumers.write_text(text)

# ---------------------------------------------------------------------------
# model/config.go — UpdateRepo field
# ---------------------------------------------------------------------------
config = Path('model/config.go')
text = config.read_text()
if 'UpdateRepo' not in text:
    needle = '''\tUseAtomGitToUpgrade         bool            `koanf:"use_atomgit_to_upgrade" json:"use_atomgit_to_upgrade"`   // 强制从AtomGit获取更新\n'''
    if needle not in text:
        raise SystemExit('cannot find UseAtomGitToUpgrade config anchor')
    text = text.replace(
        needle,
        '''\tUseAtomGitToUpgrade         bool            `koanf:"use_atomgit_to_upgrade" json:"use_atomgit_to_upgrade"`   // 强制从AtomGit获取更新\n\tUpdateRepo                  string          `koanf:"update_repo" json:"update_repo,omitempty"`               // 自定义 GitHub 更新仓库\n''',
        1,
    )
config.write_text(text)

print('Choreo agent patch applied successfully')
PY

gofmt -w \
  cmd/agent/connection_config.go \
  cmd/agent/main.go \
  cmd/agent/runtime_config_consumers.go \
  model/config.go

# Sanity checks
grep -q 'func (c connectionConfigTuple) newClient()' cmd/agent/connection_config.go
grep -q 'websocket.Dial(ctx, c.Server' cmd/agent/connection_config.go
grep -q 'keepWebSocketAlive' cmd/agent/connection_config.go
grep -q 'grpc.WithKeepaliveParams' cmd/agent/connection_config.go
grep -q 'conn, err = connectionConfig.newClient()' cmd/agent/main.go
grep -q 'delayWhenError = time.Second \* 2' cmd/agent/main.go
grep -q 'updateRepo := strings.TrimSpace(config.updateRepo)' cmd/agent/main.go
grep -q 'UpdateSelf(v, updateRepo)' cmd/agent/main.go
grep -q 'updateRepo' cmd/agent/runtime_config_consumers.go
grep -q 'UpdateRepo' model/config.go

echo "apply-choreo-ws-tunnel.sh: all checks passed"
