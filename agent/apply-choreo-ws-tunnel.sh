#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

main = Path('cmd/agent/main.go')
text = main.read_text()

if '"github.com/coder/websocket"' not in text:
    needle = '''\t"github.com/blang/semver"\n'''
    if needle not in text:
        raise SystemExit('cannot find semver import anchor')
    text = text.replace(
        needle,
        '''\t"github.com/blang/semver"\n\t"github.com/coder/websocket"\n''',
        1,
    )

old_conn = '''\t\t\tconn, err = grpc.NewClient(agentConfig.Server, securityOption, grpc.WithPerRPCCredentials(&auth))'''
new_conn = '''\t\t\tconn, err = newGRPCConn(securityOption, &auth)'''
if old_conn not in text:
    raise SystemExit('cannot find grpc.NewClient connection line to replace')
text = text.replace(old_conn, new_conn, 1)

marker = '''func runService(action string, path string) {\n'''
if marker not in text:
    raise SystemExit('cannot find runService marker')
helper = '''func newGRPCConn(securityOption grpc.DialOption, auth *model.AuthHandler) (*grpc.ClientConn, error) {\n\tif strings.HasPrefix(agentConfig.Server, "ws://") || strings.HasPrefix(agentConfig.Server, "wss://") {\n\t\treturn grpc.NewClient(\n\t\t\t"passthrough:///nezha-ws-tunnel",\n\t\t\tgrpc.WithTransportCredentials(insecure.NewCredentials()),\n\t\t\tgrpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {\n\t\t\t\twsConn, _, err := websocket.Dial(ctx, agentConfig.Server, &websocket.DialOptions{\n\t\t\t\t\tCompressionMode: websocket.CompressionDisabled,\n\t\t\t\t})\n\t\t\t\tif err != nil {\n\t\t\t\t\treturn nil, err\n\t\t\t\t}\n\t\t\t\treturn websocket.NetConn(context.Background(), wsConn, websocket.MessageBinary), nil\n\t\t\t}),\n\t\t\tgrpc.WithPerRPCCredentials(auth),\n\t\t)\n\t}\n\n\treturn grpc.NewClient(agentConfig.Server, securityOption, grpc.WithPerRPCCredentials(auth))\n}\n\n'''
if 'func newGRPCConn(' not in text:
    text = text.replace(marker, helper + marker, 1)

old_update = '''\tprintf("检查更新: %v", v)\n\tvar latest *selfupdate.Release\n\tswitch {\n'''
new_update = '''\tprintf("检查更新: %v", v)\n\tvar latest *selfupdate.Release\n\tupdateRepo := strings.TrimSpace(agentConfig.UpdateRepo)\n\tif updateRepo == "" {\n\t\tupdateRepo = "smgc-cc/choreo-nezha"\n\t}\n\tswitch {\n\tcase updateRepo != "":\n\t\tupdater, erru := selfupdate.NewUpdater(selfupdate.Config{\n\t\t\tBinaryName: binaryName,\n\t\t})\n\t\tif erru != nil {\n\t\t\tprintf("更新失败: %v", erru)\n\t\t\treturn\n\t\t}\n\t\tlatest, err = updater.UpdateSelf(v, updateRepo)\n'''
if 'updateRepo := strings.TrimSpace(agentConfig.UpdateRepo)' not in text:
    if old_update not in text:
        raise SystemExit('cannot find self-update switch anchor')
    text = text.replace(old_update, new_update, 1)

main.write_text(text)

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
PY

gofmt -w cmd/agent/main.go model/config.go

grep -q 'conn, err = newGRPCConn(securityOption, &auth)' cmd/agent/main.go
grep -q 'websocket.Dial(ctx, agentConfig.Server' cmd/agent/main.go
grep -q 'UpdateSelf(v, updateRepo)' cmd/agent/main.go
grep -q 'UpdateRepo' model/config.go
