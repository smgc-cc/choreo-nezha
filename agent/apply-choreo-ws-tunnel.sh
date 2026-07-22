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

# Expand imports for websocket dialer.
if '"github.com/coder/websocket"' not in text:
    old_import = '''import (
	"crypto/tls"

	"github.com/nezhahq/agent/model"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
)'''
    new_import = '''import (
	"context"
	"crypto/tls"
	"net"
	"strings"

	"github.com/coder/websocket"
	"github.com/nezhahq/agent/model"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
)'''
    if old_import not in text:
        raise SystemExit('cannot find connection_config.go import block')
    text = text.replace(old_import, new_import, 1)

# Inject newClient() helper that supports ws:// / wss:// transport.
helper = '''
func (c connectionConfigTuple) newClient() (*grpc.ClientConn, error) {
	if strings.HasPrefix(c.Server, "ws://") || strings.HasPrefix(c.Server, "wss://") {
		return grpc.NewClient(
			"passthrough:///nezha-ws-tunnel",
			grpc.WithTransportCredentials(insecure.NewCredentials()),
			grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
				wsConn, _, err := websocket.Dial(ctx, c.Server, &websocket.DialOptions{
					CompressionMode: websocket.CompressionDisabled,
				})
				if err != nil {
					return nil, err
				}
				return websocket.NetConn(context.Background(), wsConn, websocket.MessageBinary), nil
			}),
			grpc.WithPerRPCCredentials(c.Auth),
		)
	}
	return grpc.NewClient(c.Server, c.dialOptions()...)
}

'''
if 'func (c connectionConfigTuple) newClient()' not in text:
    anchor = 'func (c connectionConfigTuple) dialOptions() []grpc.DialOption {\n'
    if anchor not in text:
        raise SystemExit('cannot find dialOptions method anchor in connection_config.go')
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
grep -q 'conn, err = connectionConfig.newClient()' cmd/agent/main.go
grep -q 'updateRepo := strings.TrimSpace(config.updateRepo)' cmd/agent/main.go
grep -q 'UpdateSelf(v, updateRepo)' cmd/agent/main.go
grep -q 'updateRepo' cmd/agent/runtime_config_consumers.go
grep -q 'UpdateRepo' model/config.go

echo "apply-choreo-ws-tunnel.sh: all checks passed"
