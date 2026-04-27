#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

main = Path('cmd/agent/main.go')
text = main.read_text()

text = text.replace(
'''\t"github.com/blang/semver"\n''',
'''\t"github.com/blang/semver"\n\t"github.com/coder/websocket"\n''',
1,
)

old_conn = '''\t\tfor {\n\t\t\tvar securityOption grpc.DialOption\n\t\t\tif agentConfig.TLS {\n\t\t\t\tif agentConfig.InsecureTLS {\n\t\t\t\t\tsecurityOption = grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{MinVersion: tls.VersionTLS12, InsecureSkipVerify: true}))\n\t\t\t\t} else {\n\t\t\t\t\tsecurityOption = grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{MinVersion: tls.VersionTLS12}))\n\t\t\t\t}\n\t\t\t} else {\n\t\t\t\tsecurityOption = grpc.WithTransportCredentials(insecure.NewCredentials())\n\t\t\t}\n\t\t\tconn, err = grpc.NewClient(agentConfig.Server, securityOption, grpc.WithPerRPCCredentials(&auth))\n'''
new_conn = '''\t\tfor {\n\t\t\tconn, err = newGRPCConn(&auth)\n'''
text = text.replace(old_conn, new_conn, 1)

marker = '''func runService(action string, path string) {\n'''
helper = '''func newGRPCConn(auth *model.AuthHandler) (*grpc.ClientConn, error) {\n\tif strings.HasPrefix(agentConfig.Server, "ws://") || strings.HasPrefix(agentConfig.Server, "wss://") {\n\t\treturn grpc.NewClient(\n\t\t\t"passthrough:///nezha-ws-tunnel",\n\t\t\tgrpc.WithTransportCredentials(insecure.NewCredentials()),\n\t\t\tgrpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {\n\t\t\t\twsConn, _, err := websocket.Dial(ctx, agentConfig.Server, &websocket.DialOptions{\n\t\t\t\t\tCompressionMode: websocket.CompressionDisabled,\n\t\t\t\t})\n\t\t\t\tif err != nil {\n\t\t\t\t\treturn nil, err\n\t\t\t\t}\n\t\t\t\treturn websocket.NetConn(context.Background(), wsConn, websocket.MessageBinary), nil\n\t\t\t}),\n\t\t\tgrpc.WithPerRPCCredentials(auth),\n\t\t)\n\t}\n\n\tvar securityOption grpc.DialOption\n\tif agentConfig.TLS {\n\t\tif agentConfig.InsecureTLS {\n\t\t\tsecurityOption = grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{MinVersion: tls.VersionTLS12, InsecureSkipVerify: true}))\n\t\t} else {\n\t\t\tsecurityOption = grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{MinVersion: tls.VersionTLS12}))\n\t\t}\n\t} else {\n\t\tsecurityOption = grpc.WithTransportCredentials(insecure.NewCredentials())\n\t}\n\treturn grpc.NewClient(agentConfig.Server, securityOption, grpc.WithPerRPCCredentials(auth))\n}\n\n'''
text = text.replace(marker, helper + marker, 1)

old_update = '''\tprintf("检查更新: %v", v)\n\tvar latest *selfupdate.Release\n\tswitch {\n'''
new_update = '''\tprintf("检查更新: %v", v)\n\tvar latest *selfupdate.Release\n\tupdateRepo := strings.TrimSpace(agentConfig.UpdateRepo)\n\tif updateRepo == "" {\n\t\tupdateRepo = "smgc-cc/choreo-nezha"\n\t}\n\tswitch {\n\tcase updateRepo != "":\n\t\tupdater, erru := selfupdate.NewUpdater(selfupdate.Config{\n\t\t\tBinaryName: binaryName,\n\t\t})\n\t\tif erru != nil {\n\t\t\tprintf("更新失败: %v", erru)\n\t\t\treturn\n\t\t}\n\t\tlatest, err = updater.UpdateSelf(v, updateRepo)\n'''
text = text.replace(old_update, new_update, 1)
main.write_text(text)

config = Path('model/config.go')
text = config.read_text()
text = text.replace(
'''\tUseAtomGitToUpgrade         bool            `koanf:"use_atomgit_to_upgrade" json:"use_atomgit_to_upgrade"`   // 强制从AtomGit获取更新\n''',
'''\tUseAtomGitToUpgrade         bool            `koanf:"use_atomgit_to_upgrade" json:"use_atomgit_to_upgrade"`   // 强制从AtomGit获取更新\n\tUpdateRepo                  string          `koanf:"update_repo" json:"update_repo,omitempty"`               // 自定义 GitHub 更新仓库\n''',
1,
)
config.write_text(text)
PY

gofmt -w cmd/agent/main.go model/config.go
