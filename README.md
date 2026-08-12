# Nezha Dockerfile for Choreo

# Version

v2.3.3

# Releases

## What's Changed
* 服务器位于大陆时的一些问题及解决方案 by @guoyongchang in https://github.com/nezhahq/nezha/pull/14
* 自定义版权去除jq引用，添加wxpush示例 by @iLayPark in https://github.com/nezhahq/nezha/pull/45
* 添加标签功能，默认主题可根据标签分组 by @iLayPark in https://github.com/nezhahq/nezha/pull/53
* 调整状态卡片上下空白高度 by @iLayPark in https://github.com/nezhahq/nezha/pull/54
* 修复详情面板透明的bug by @iLayPark in https://github.com/nezhahq/nezha/pull/57
* 优化服务监控布局 by @iLayPark in https://github.com/nezhahq/nezha/pull/59
* Add new theme DayNight by @JackieSung4ev in https://github.com/nezhahq/nezha/pull/73
* 新主题添加流量统计 by @iLayPark in https://github.com/nezhahq/nezha/pull/75
* Responsive and UI update by @JackieSung4ev in https://github.com/nezhahq/nezha/pull/76
* Service page and Smooth transition update by @JackieSung4ev in https://github.com/nezhahq/nezha/pull/77
* Update service page javaScript file by @JackieSung4ev in https://github.com/nezhahq/nezha/pull/78
* Service page responsive update by @JackieSung4ev in https://github.com/nezhahq/nezha/pull/79
* Dev by @naiba in https://github.com/nezhahq/nezha/pull/80
* Dev by @naiba in https://github.com/nezhahq/nezha/pull/81
* 🚸 调整导航栏，太密 by @naiba in https://github.com/nezhahq/nezha/pull/82
* Progressbar restructure and UI design update by @JackieSung4ev in https://github.com/nezhahq/nezha/pull/86
* UI design update and JavaScript files formating by @JackieSung4ev in https://github.com/nezhahq/nezha/pull/87
* Add password page and UI design update by @JackieSung4ev in https://github.com/nezhahq/nezha/pull/88
* fix: correct minor typos in disk usage statistic by @Creling in https://github.com/nezhahq/nezha/pull/103
* 新增手动修改白天/黑夜模式 by @Bravoyk in https://github.com/nezhahq/nezha/pull/106
* 🌈  Modify the popup window  by @Bravoyk in https://github.com/nezhahq/nezha/pull/107
* 🌈 Change background color. by @Bravoyk in https://github.com/nezhahq/nezha/pull/108
* Nezha brand logo update by @JackieSung4ev in https://github.com/nezhahq/nezha/pull/113
* WebSocket增加Ping包 & Actions构建镜像时用户名转为小写 by @matchch in https://github.com/nezhahq/nezha/pull/118
* 加强了中国大陆安装时候的稳定性和安装速度 by @matchch in https://github.com/nezhahq/nezha/pull/119
* Actions推送到阿里云上海仓库 && 安装脚本修改 by @matchch in https://github.com/nezhahq/nezha/pull/120
* Improve HTTPS certificate checking logic. by @techotaku in https://github.com/nezhahq/nezha/pull/122
* 解决国内镜像下载Agent缓存问题 by @matchch in https://github.com/nezhahq/nezha/pull/123
* Update OpenWrt guide by @Es-dese in https://github.com/nezhahq/nezha/pull/127
* 借用jsdelivr获取版本号 by @matchch in https://github.com/nezhahq/nezha/pull/130
* 面板安装支持ARM和x86 by @matchch in https://github.com/nezhahq/nezha/pull/131
* 解决排除网卡不生效的bug by @acgpiano in https://github.com/nezhahq/nezha/pull/132
* 修复修改密钥后，agent连不上bug by @ch8o in https://github.com/nezhahq/nezha/pull/133
* Bump github.com/gin-gonic/gin from 1.6.3 to 1.7.0 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/134
* 支持输入错误时删除 by @CoiaPrant in https://github.com/nezhahq/nezha/pull/136
* 修复LXC容器的读取内存和Swap错误 by @CoiaPrant in https://github.com/nezhahq/nezha/pull/137
* 在修改服务器弹框，显示agent安装命令 by @cloverzrg in https://github.com/nezhahq/nezha/pull/138
* 修复脚本无法修改agent配置的问题 by @cloverzrg in https://github.com/nezhahq/nezha/pull/139
* agent 增加 SSL/TLS 选项 by @lemoeo in https://github.com/nezhahq/nezha/pull/141
* :sparkles: 反向代理 gRPC 端口（支持 Cloudflare CDN） by @lemoeo in https://github.com/nezhahq/nezha/pull/142
* 添加磁盘空间获取的Fallback方法,应对OVZ无法统计问题! by @nickfox-taterli in https://github.com/nezhahq/nezha/pull/143
* Agent支持IBM-S390X和RISCV64架构 by @matchch in https://github.com/nezhahq/nezha/pull/144
* Add OpenWRT_Nezha Project by @matchch in https://github.com/nezhahq/nezha/pull/145
* Add SS Func to accelerate connections count in some Linux by @matchch in https://github.com/nezhahq/nezha/pull/148
* Update footer.html by @CosmosZ-code in https://github.com/nezhahq/nezha/pull/146
* Update header.html by @CosmosZ-code in https://github.com/nezhahq/nezha/pull/147
* Add theme-mdui. by @MikoyChinese in https://github.com/nezhahq/nezha/pull/149
* Update realtime tooltip and fix some bugs. by @MikoyChinese in https://github.com/nezhahq/nezha/pull/150
* Fix viewpassword and Add Network Traffic Statistics in service page. by @MikoyChinese in https://github.com/nezhahq/nezha/pull/151
* 添加统计周期单位cycle_unit by @MikoyChinese in https://github.com/nezhahq/nezha/pull/153
* Round check next time format to second by @MikoyChinese in https://github.com/nezhahq/nezha/pull/154
* 修复管理后台页面新添加CoverIgnoreAll类型服务需要重启docker镜像的问题. by @MikoyChinese in https://github.com/nezhahq/nezha/pull/155
* fix some typo by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/156
* 增加代码注释 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/157
* optimize:移除两处冗余的代码 + refactor:优化代码组织结构 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/158
* feat: 通过传递客户端Cookie的方式使web终端功能兼容被Cloudflare Access保护的面板 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/159
* feat: 通知方式分组 支持将不同的报警｜监控｜计划任务的通知 发送到指定的通知分组 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/160
* optimise: 优化websocket数据包发送逻辑 加快首次访问时监控信息载入速度 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/161
* feat: 添加更多的占位符以支持基于服务器状态指标构造自定义的HTTP请求 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/162
* update: 增加TCP连接数与UDP连接数的占位符 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/163
* feat: 添加/修改通知方式时可选择不发送测试信息 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/164
* update: #SERVER.IP#仅返回一个IP(优先返回ipv4地址)｜ 新增获取ipv4与ipv6地址的占位符 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/165
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/166
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/167
* 新增win一键 (need PS 管理员权限) by @dysf888 in https://github.com/nezhahq/nezha/pull/170
* fix `tar: This does not look like a tar archive` by @hmsjy2017 in https://github.com/nezhahq/nezha/pull/169
* 提取文本到zh-CN.toml by @hhhkkk520 in https://github.com/nezhahq/nezha/pull/171
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/172
* 😉新增region判断 by @dysf888 in https://github.com/nezhahq/nezha/pull/173
* 提取全部主题文本到 zh-CN.toml by @hhhkkk520 in https://github.com/nezhahq/nezha/pull/175
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/176
* Translate the installation script by @matchch in https://github.com/nezhahq/nezha/pull/178
* 修改了一些文本和格式错误 by @hhhkkk520 in https://github.com/nezhahq/nezha/pull/179
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/180
* Update UserGuide_en.md by @MartijnLindeman in https://github.com/nezhahq/nezha/pull/181
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/182
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/183
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/184
* update: 使用 "ServerGroup" 标签在服务器相关页面 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/186
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/185
* fix: 恢复错误修改的Tag by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/187
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/188
* 重写英文文档，优化中文文档，修复了一些文本显示错误 by @hhhkkk520 in https://github.com/nezhahq/nezha/pull/189
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/190
* fix typo by @matchch in https://github.com/nezhahq/nezha/pull/193
* 国旗颜色不够鲜艳 by @iilemon in https://github.com/nezhahq/nezha/pull/195
* Update theme-mdui homepage and some url. by @MikoyChinese in https://github.com/nezhahq/nezha/pull/196
* Fix README && Update Script by @matchch in https://github.com/nezhahq/nezha/pull/199
* py洗干净了 by @dysf888 in https://github.com/nezhahq/nezha/pull/201
* Add SELinux Check by @matchch in https://github.com/nezhahq/nezha/pull/202
* Fix SELinux for more system by @matchch in https://github.com/nezhahq/nezha/pull/203
* Add tls support by @GreenTeodoro839 in https://github.com/nezhahq/nezha/pull/204
* Add update before fetch by @matchch in https://github.com/nezhahq/nezha/pull/205
* Custom DNS by @matchch in https://github.com/nezhahq/nezha/pull/207
* Update README.md by @hhhkkk520 in https://github.com/nezhahq/nezha/pull/208
* feat: API支持 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/206
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/209
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/210
* update: 服务器状态API增加上次汇报时间的unix时间戳 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/211
* 更新README、删除旧文档、更新英文文档链接 by @hhhkkk520 in https://github.com/nezhahq/nezha/pull/213
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/214
* 删除多余}  水pr=,= by @dysf888 in https://github.com/nezhahq/nezha/pull/215
* Add CGO for Mac by @matchch in https://github.com/nezhahq/nezha/pull/216
* JSdelivr -> Jihulab by @matchch in https://github.com/nezhahq/nezha/pull/217
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/218
* Fix 修改main.js的版本参数避免缓存问题 by @matchch in https://github.com/nezhahq/nezha/pull/220
* 修改面板配置时不直接修改 by @matchch in https://github.com/nezhahq/nezha/pull/221
* 默认主题增加流量剩余显示 by @liuyanxi975 in https://github.com/nezhahq/nezha/pull/219
* 改进剩余流量显示 by @liuyanxi975 in https://github.com/nezhahq/nezha/pull/223
* Add retry times limit for wget by @matchch in https://github.com/nezhahq/nezha/pull/222
* Add timeout limit for wget by @matchch in https://github.com/nezhahq/nezha/pull/225
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/224
* 流量剩余显示增加详细信息 by @liuyanxi975 in https://github.com/nezhahq/nezha/pull/227
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/229
* 一键脚本语言跟随面板语言 by @matchch in https://github.com/nezhahq/nezha/pull/230
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/231
* fix 未能创建 SSL/TLS 安全通道 by @dysf888 in https://github.com/nezhahq/nezha/pull/232
* limit ps version by @dysf888 in https://github.com/nezhahq/nezha/pull/233
* Change bytecdntp to staticfile by @matchch in https://github.com/nezhahq/nezha/pull/234
* Add FreeBSD Agent For Goreleaser by @matchch in https://github.com/nezhahq/nezha/pull/235
* update: 未获取到country code时继续查询下一个API by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/236
* 🎉 reduce docker image build time by @naiba in https://github.com/nezhahq/nezha/pull/238
* fixArchLinuxIcon by @KorenKrita in https://github.com/nezhahq/nezha/pull/240
* feat: 报警规则触发任务执行 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/241
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/242
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/243
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/244
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/245
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/246
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/247
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/248
* New Crowdin updates by @naiba in https://github.com/nezhahq/nezha/pull/249
* Improved translation of texts by @hhhkkk520 in https://github.com/nezhahq/nezha/pull/250
* feat(gitea):  oauth2 add gitea support by @ysicing in https://github.com/nezhahq/nezha/pull/251
* fix: Gitee login error by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/252
* fix: 更新导致创建日期归零 by @qcgzxw in https://github.com/nezhahq/nezha/pull/254
* 服务器备注支持换行显示 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/255
* fix: nameserver issue by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/256
* Update install.sh by @coreff in https://github.com/nezhahq/nezha/pull/258
* Update install_en.sh by @coreff in https://github.com/nezhahq/nezha/pull/259
* Master by @fscarmen in https://github.com/nezhahq/nezha/pull/260
* Better support for archlinux by @dysf888 in https://github.com/nezhahq/nezha/pull/263
* 更好的支持archlinux by @dysf888 in https://github.com/nezhahq/nezha/pull/262
* Fix fatal permission issue by @dysf888 in https://github.com/nezhahq/nezha/pull/265
* Fix fatal permission issue by @dysf888 in https://github.com/nezhahq/nezha/pull/264
* Update service.html by @yuanweize in https://github.com/nezhahq/nezha/pull/267
* fix: 部分环境下启动时间锁定在1970年的问题 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/268
* 修正 Arch 的安装错误 by @1ridic in https://github.com/nezhahq/nezha/pull/269
* Create zh-TW.toml by @rootmelo92118 in https://github.com/nezhahq/nezha/pull/271
* update: 使用jsdelivr替代jihulab by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/272
* Feat: Add jsdelivr purge step in workflow by @matchch in https://github.com/nezhahq/nezha/pull/273
* Update Readme by @cantoblanco in https://github.com/nezhahq/nezha/pull/276
* bump golang.org/x/net from 0.5.0 to 0.7.0 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/277
* 添加提醒方式页面placeholder少了两个逗号 by @colour93 in https://github.com/nezhahq/nezha/pull/278
* Fix: fix icmp ping & fix agent action build by @matchch in https://github.com/nezhahq/nezha/pull/279
* 效仿中文版shell给英文版shell增加中国IP判断 by @spiritLHLS in https://github.com/nezhahq/nezha/pull/280
* Update README.md by @cantoblanco in https://github.com/nezhahq/nezha/pull/281
* Adding an theme by @adminsama in https://github.com/nezhahq/nezha/pull/282
* Update es-ES.toml by @dysf888 in https://github.com/nezhahq/nezha/pull/287
* Update zh-TW.toml by @dysf888 in https://github.com/nezhahq/nezha/pull/286
* Update en-US.toml by @dysf888 in https://github.com/nezhahq/nezha/pull/285
* Update zh-CN.toml by @dysf888 in https://github.com/nezhahq/nezha/pull/283
* Update home.html by @dysf888 in https://github.com/nezhahq/nezha/pull/284
* Feat: 服务监控支持触发任务执行 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/288
* 新增文本的多语言翻译 by @cantoblanco in https://github.com/nezhahq/nezha/pull/289
* Bump github.com/gin-gonic/gin from 1.9.0 to 1.9.1 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/290
* 服务状态变更时清除静音缓存 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/291
* Update en-US.toml by @dysf888 in https://github.com/nezhahq/nezha/pull/292
* Bump golang.org/x/net from 0.14.0 to 0.17.0 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/293
* Feat: Add some parameters by @matchch in https://github.com/nezhahq/nezha/pull/294
* ✨ feat: add server-status theme by @unclezs in https://github.com/nezhahq/nezha/pull/295
* [agent] Alpine 系统增加 SSL/TLS加密 (--tls) 支持。 by @fscarmen in https://github.com/nezhahq/nezha/pull/297
* 优化中文语言文件 by @cantoblanco in https://github.com/nezhahq/nezha/pull/298
* 优化繁体中文、英语、西班牙语语言文件 by @cantoblanco in https://github.com/nezhahq/nezha/pull/299
* Fix: get.daocloud.io 503 by @matchch in https://github.com/nezhahq/nezha/pull/301
* Add standalone installation method & OpenRC support for nezha-agent by @uubulb in https://github.com/nezhahq/nezha/pull/300
* Fix various bugs in fresh installation by @uubulb in https://github.com/nezhahq/nezha/pull/302
* Exit after installing agent by @uubulb in https://github.com/nezhahq/nezha/pull/303
* Fix Coroutine Leaks and Proxy Handling in http.Client by @Mmx233 in https://github.com/nezhahq/nezha/pull/304
* fix: field name "VerifySSL" to "SkipVerifySSL" in Transport config by @Mmx233 in https://github.com/nezhahq/nezha/pull/305
* Fix select_version by @matchch in https://github.com/nezhahq/nezha/pull/306
* installer: fix docker compose command determination by @uubulb in https://github.com/nezhahq/nezha/pull/307
* Improve: use alpine as dockerfile base image by @Mmx233 in https://github.com/nezhahq/nezha/pull/309
* improve server-status theme  by @nap0o in https://github.com/nezhahq/nezha/pull/310
* 更新判断面板是否是通过docker安装的逻辑 by @spiritLHLS in https://github.com/nezhahq/nezha/pull/311
* Bump golang.org/x/crypto from 0.15.0 to 0.17.0 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/312
* add supervise daemon for alpine by @wwng2333 in https://github.com/nezhahq/nezha/pull/313
* replace daocloud with fgit by @dysf888 in https://github.com/nezhahq/nezha/pull/315
* feat: add network monitor hitory by @lvgj-stack in https://github.com/nezhahq/nezha/pull/316
* fix: add toggle to service by @lvgj-stack in https://github.com/nezhahq/nezha/pull/317
* fix: revert service html and block service in backend by @lvgj-stack in https://github.com/nezhahq/nezha/pull/318
* feat: add index on monitor history by @lvgj-stack in https://github.com/nezhahq/nezha/pull/320
* 对历史延迟图表进行了相关修复/美化工作 by @xykt in https://github.com/nezhahq/nezha/pull/321
* 增加了网络页面对 Neko Meui 主题的支持 by @HsukqiLee in https://github.com/nezhahq/nezha/pull/322
* Arch 修复 nezha-agent 主目录遗留问题 by @arkylin in https://github.com/nezhahq/nezha/pull/323
* 优化安装逻辑 by @1ridic in https://github.com/nezhahq/nezha/pull/325
* Add DDNS support by @DarcJC in https://github.com/nezhahq/nezha/pull/324
* 优化default和serverstatus主题模版 by @nap0o in https://github.com/nezhahq/nezha/pull/327
* fix bug by @nap0o in https://github.com/nezhahq/nezha/pull/328
* Fix DDNS bugs and split up ddns module by @DarcJC in https://github.com/nezhahq/nezha/pull/326
* angel-kanade模版增加主题切换功能 by @nap0o in https://github.com/nezhahq/nezha/pull/329
* 修复echarts不显示bug by @nap0o in https://github.com/nezhahq/nezha/pull/330
* 主题切换相关优化 by @nap0o in https://github.com/nezhahq/nezha/pull/331
* Bump google.golang.org/protobuf from 1.31.0 to 1.33.0 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/332
* 网络监控页面相关优化 by @HsukqiLee in https://github.com/nezhahq/nezha/pull/333
* 更正某些情况下三网延迟区间显示不正确的BUG by @xykt in https://github.com/nezhahq/nezha/pull/338
* ddns: Add ability to update IPv4 or IPv6 only by @uubulb in https://github.com/nezhahq/nezha/pull/342
* fix installer bugs & improve by @uubulb in https://github.com/nezhahq/nezha/pull/341
* Optimize translation by @zhucaidan in https://github.com/nezhahq/nezha/pull/343
* chore: fix some comments by @lvyaoting in https://github.com/nezhahq/nezha/pull/345
* ServerStatus主题首页增加服务器世界分布图功能 by @nap0o in https://github.com/nezhahq/nezha/pull/344
* 修复ServerStatus主题Bug by @nap0o in https://github.com/nezhahq/nezha/pull/346
* Update install.sh by @dreamingsleeping in https://github.com/nezhahq/nezha/pull/347
* Add DDNS Profiles, use publicsuffixlist domain parser by @uubulb in https://github.com/nezhahq/nezha/pull/350
* :sparkles: 支持cloudflare access OIDC认证 by @AkkiaS7 in https://github.com/nezhahq/nezha/pull/354
* chore: fix a typo by @uubulb in https://github.com/nezhahq/nezha/pull/355
* 修正拼写错误 by @nap0o in https://github.com/nezhahq/nezha/pull/356
* 删除多余空格 by @eya46 in https://github.com/nezhahq/nezha/pull/358
* Use agent's builtin support for services instead by @uubulb in https://github.com/nezhahq/nezha/pull/357
* Update GPG key for libsepol by @wellcoming in https://github.com/nezhahq/nezha/pull/360
* Add support for sensor temperature in host state by @funnyzak in https://github.com/nezhahq/nezha/pull/359
* ci: using time/tzdata package to provide zoneinfo by @uubulb in https://github.com/nezhahq/nezha/pull/365
* 优化default和server status主题 by @nap0o in https://github.com/nezhahq/nezha/pull/363
* 修复一些bug by @nap0o in https://github.com/nezhahq/nezha/pull/367
* chore: fix some typos by @uubulb in https://github.com/nezhahq/nezha/pull/370
* Add option to reduct temperature information by @uubulb in https://github.com/nezhahq/nezha/pull/369
* default和serverstatus主题温度展示相关 by @nap0o in https://github.com/nezhahq/nezha/pull/372
* Hide DDNS domain info for guests by @uubulb in https://github.com/nezhahq/nezha/pull/371
* feat: Add GPU inspection/monitoring support by @uubulb in https://github.com/nezhahq/nezha/pull/373
* Temporary fix for DDNSDomain leaks by @uubulb in https://github.com/nezhahq/nezha/pull/374
* 优化gpu前端展示代码 by @nap0o in https://github.com/nezhahq/nezha/pull/375
* Bump github.com/hashicorp/go-retryablehttp from 0.7.2 to 0.7.7 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/377
* refactor: make the installer script POSIX compliant by @uubulb in https://github.com/nezhahq/nezha/pull/376
* 优化server-status主题首页网络图表 by @nap0o in https://github.com/nezhahq/nezha/pull/378
* fix: EUID is a readonly variable on some shells by @uubulb in https://github.com/nezhahq/nezha/pull/379
* Update README.md  by @cantoblanco in https://github.com/nezhahq/nezha/pull/380
* 优化server-status主题服务页 by @nap0o in https://github.com/nezhahq/nezha/pull/382
* feat: notifications support for GPU & Temperature by @uubulb in https://github.com/nezhahq/nezha/pull/381
* fix: timestamp conversion by @uubulb in https://github.com/nezhahq/nezha/pull/383
* ddns: improve performance by @uubulb in https://github.com/nezhahq/nezha/pull/385
* ServerStatus主题优化 by @nap0o in https://github.com/nezhahq/nezha/pull/386
* 🐛 fixbug by @nap0o in https://github.com/nezhahq/nezha/pull/388
* 添加OIDC支持 by @IamTaoChen in https://github.com/nezhahq/nezha/pull/387
* installer: restore the China mirror of agent by @uubulb in https://github.com/nezhahq/nezha/pull/389
* ci: sync release to gitee by @uubulb in https://github.com/nezhahq/nezha/pull/390
* fix: concurrent write to single WebSocket connection by @uubulb in https://github.com/nezhahq/nezha/pull/392
* Update IP location service in install scripts by @Septrum101 in https://github.com/nezhahq/nezha/pull/391
* installer: use multiple geoip api to determine location by @uubulb in https://github.com/nezhahq/nezha/pull/393
* installer: improve region detection reliability using CDN APIs by @xrgzs in https://github.com/nezhahq/nezha/pull/394
* 🎉 通过自定义代码实现server-status主题深色模式半透明样式的前置准备 by @nap0o in https://github.com/nezhahq/nezha/pull/395
* api: add DisplayIndex info by @uubulb in https://github.com/nezhahq/nezha/pull/397
* feat: use embed geoip database by @uubulb in https://github.com/nezhahq/nezha/pull/396
* ci: only keep the latest release by @uubulb in https://github.com/nezhahq/nezha/pull/398
* chore: wrong name by @uubulb in https://github.com/nezhahq/nezha/pull/399
* chore: missing gpu info line break in theme-angel-kanade by @silver-ymz in https://github.com/nezhahq/nezha/pull/403
* installer: fix geo_check by @uubulb in https://github.com/nezhahq/nezha/pull/404
* ws: ignore all DDNS fields by @uubulb in https://github.com/nezhahq/nezha/pull/406
* server-status主题优化 by @nap0o in https://github.com/nezhahq/nezha/pull/405
* server-status主题重写network页面 by @nap0o in https://github.com/nezhahq/nezha/pull/407
* Add replacing fields to notification content in notification.go by @hiDandelion in https://github.com/nezhahq/nezha/pull/408
* improve & fix : 主题优化及bug修复 by @nap0o in https://github.com/nezhahq/nezha/pull/409
* ci增加重传机制 by @uubulb in https://github.com/nezhahq/nezha/pull/410
* feat: framed fm for webshell by @uubulb in https://github.com/nezhahq/nezha/pull/411
* fm: store file to OPFS temporarily by @uubulb in https://github.com/nezhahq/nezha/pull/413
* refactor: ddns by @uubulb in https://github.com/nezhahq/nezha/pull/414
* fix cpu core display by @uubulb in https://github.com/nezhahq/nezha/pull/415
* fix/fm: reset upload state after completion by @uubulb in https://github.com/nezhahq/nezha/pull/416
* [ci][docker]: use matrix to reduce build time & change base image to busybox by @uubulb in https://github.com/nezhahq/nezha/pull/417
* fix: docker image by @uubulb in https://github.com/nezhahq/nezha/pull/418
* fix dashboard install script by @uubulb in https://github.com/nezhahq/nezha/pull/419
* server-status和default主题：feat & improve & fix by @nap0o in https://github.com/nezhahq/nezha/pull/420
* Default主题fixbug by @nap0o in https://github.com/nezhahq/nezha/pull/421
* improve: status-server主题network页 by @nap0o in https://github.com/nezhahq/nezha/pull/422
* improve: use sync.Pool for buffer allocation by @uubulb in https://github.com/nezhahq/nezha/pull/423
* feat: status-server主题增加agent账单信息展示 by @nap0o in https://github.com/nezhahq/nezha/pull/424
* fix: 允许更新默认分组 by @lyj0309 in https://github.com/nezhahq/nezha/pull/426
* improve: status-server主题agent账单信息展示 by @nap0o in https://github.com/nezhahq/nezha/pull/425
* installer: fix docker-compose detection by @uubulb in https://github.com/nezhahq/nezha/pull/427
* installer: fix docker-compose detection logic by @uubulb in https://github.com/nezhahq/nezha/pull/428
* Update en-US.toml by @zhucaidan in https://github.com/nezhahq/nezha/pull/429
* chore: l10n: improve translation by @uubulb in https://github.com/nezhahq/nezha/pull/431
* improve: status-server主题日常优化 by @nap0o in https://github.com/nezhahq/nezha/pull/432
* feat: description file for custom theme; use gjson by @uubulb in https://github.com/nezhahq/nezha/pull/433
* fix dashboard custom theme, expose HideForGuest for api by @uubulb in https://github.com/nezhahq/nezha/pull/434
* ddns: store configuation in database by @uubulb in https://github.com/nezhahq/nezha/pull/435
* fix(ddns): add missing field WebhookRequestType by @uubulb in https://github.com/nezhahq/nezha/pull/436
* fix(ddns): handle second-level domain correctly by @uubulb in https://github.com/nezhahq/nezha/pull/438
* do not check description file for theme-custom by @uubulb in https://github.com/nezhahq/nezha/pull/437
* ddns: remove ipv6 nameservers, support custom nameservers by @uubulb in https://github.com/nezhahq/nezha/pull/439
* fix: add custom theme key by @uubulb in https://github.com/nezhahq/nezha/pull/440
* installer: fix some style issues by @uubulb in https://github.com/nezhahq/nezha/pull/441
* fix installer by @uubulb in https://github.com/nezhahq/nezha/pull/442
* dev: add a helper function by @uubulb in https://github.com/nezhahq/nezha/pull/443
* dev: add ddns create, edit and batch delete api by @uubulb in https://github.com/nezhahq/nezha/pull/444
* dev: add ddns list api by @uubulb in https://github.com/nezhahq/nezha/pull/445
* ddns: add listProviders api by @uubulb in https://github.com/nezhahq/nezha/pull/446
* installer: fix format by @uubulb in https://github.com/nezhahq/nezha/pull/448
* use plain error type for expected behaviors by @uubulb in https://github.com/nezhahq/nezha/pull/447
* installer: fix download service scripts by @uubulb in https://github.com/nezhahq/nezha/pull/449
* add path check for multiplexer by @uubulb in https://github.com/nezhahq/nezha/pull/451
* implement notification group by @uubulb in https://github.com/nezhahq/nezha/pull/450
* fix list apis by @uubulb in https://github.com/nezhahq/nezha/pull/453
* fix swaggo by @uubulb in https://github.com/nezhahq/nezha/pull/454
* update grpc-go & protobuf definition by @uubulb in https://github.com/nezhahq/nezha/pull/455
* add fm api by @uubulb in https://github.com/nezhahq/nezha/pull/456
* prevent writing response to websocket connections by @uubulb in https://github.com/nezhahq/nezha/pull/457
* add alert api by @uubulb in https://github.com/nezhahq/nezha/pull/458
* add cron, nat api & refactor alert rule by @uubulb in https://github.com/nezhahq/nezha/pull/459
* add setting api by @uubulb in https://github.com/nezhahq/nezha/pull/461
* add "network page" api by @uubulb in https://github.com/nezhahq/nezha/pull/460
* ddns: replace tencentcloud implemention by @uubulb in https://github.com/nezhahq/nezha/pull/462
* fix(cli): display version without initializing app by @Moraxyc in https://github.com/nezhahq/nezha/pull/463
* chore(deps): bump github.com/golang-jwt/jwt/v4 from 4.5.0 to 4.5.1 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/485
* Fix code scanning alert no. 23: Uncontrolled data used in path expression by @naiba in https://github.com/nezhahq/nezha/pull/486
* ci: fix arm64 path parsing by @uubulb in https://github.com/nezhahq/nezha/pull/487
* fix: use exec to properly handle container signals by @yanhao98 in https://github.com/nezhahq/nezha/pull/501
* Feature/v0 scripts by @matchch in https://github.com/nezhahq/nezha/pull/512
* fix(i18n): replace hyphen with underscore by @uubulb in https://github.com/nezhahq/nezha/pull/524
* fix server deletion api, add issue templates by @uubulb in https://github.com/nezhahq/nezha/pull/526
* fix: allocate memory for geoip struct of new server instance by @uubulb in https://github.com/nezhahq/nezha/pull/530
* chore: issue template typos by @uubulb in https://github.com/nezhahq/nezha/pull/529
* fix config default value by @uubulb in https://github.com/nezhahq/nezha/pull/538
* update ws & settings api by @uubulb in https://github.com/nezhahq/nezha/pull/547
* Update waf.go by @yumusb in https://github.com/nezhahq/nezha/pull/548
* feat: add listen_host by @Moraxyc in https://github.com/nezhahq/nezha/pull/550
* fix: allocate geoip on server creation by @uubulb in https://github.com/nezhahq/nezha/pull/554
* fix service api by @uubulb in https://github.com/nezhahq/nezha/pull/556
* UserTemplate GitHub -> Repository by @uubulb in https://github.com/nezhahq/nezha/pull/564
* chore: use cmp by @uubulb in https://github.com/nezhahq/nezha/pull/568
* mention weblate & add weblate badge by @uubulb in https://github.com/nezhahq/nezha/pull/569
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/570
* Refactor: Load UserTemplates from embedded yaml file by @Moraxyc in https://github.com/nezhahq/nezha/pull/575
* fix: custom_nameservers should be dns_servers by @uubulb in https://github.com/nezhahq/nezha/pull/581
* fix: add nil check for ReportSystemState by @uubulb in https://github.com/nezhahq/nezha/pull/583
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/580
* chore: update admin frontend screenshot by @uubulb in https://github.com/nezhahq/nezha/pull/893
* [WIP] feat: user roles by @uubulb in https://github.com/nezhahq/nezha/pull/852
* chore: update translation template by @uubulb in https://github.com/nezhahq/nezha/pull/900
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/901
* fix: batch-block online-user request method by @hamster1963 in https://github.com/nezhahq/nezha/pull/903
* feat: support id query for "list" apis by @uubulb in https://github.com/nezhahq/nezha/pull/908
* issue template 必须填写配置 by @uubulb in https://github.com/nezhahq/nezha/pull/913
* chore: simplify some steps, remove unused code by @uubulb in https://github.com/nezhahq/nezha/pull/912
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/916
* bug fixes by @uubulb in https://github.com/nezhahq/nezha/pull/918
* fix: return 404 when page not found by @quanljh in https://github.com/nezhahq/nezha/pull/927
* fix: oauth2 redirect url not consistent by @uubulb in https://github.com/nezhahq/nezha/pull/930
* fix: struct tag by @uubulb in https://github.com/nezhahq/nezha/pull/932
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/933
* fix windows ci by @uubulb in https://github.com/nezhahq/nezha/pull/934
* Fix default port by @lyj0309 in https://github.com/nezhahq/nezha/pull/935
* fix: update user cache after profile updates by @uubulb in https://github.com/nezhahq/nezha/pull/936
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/945
* fix: fix typo in database variable name by @igophper in https://github.com/nezhahq/nezha/pull/939
* feat(waf): return ip in string literal by @uubulb in https://github.com/nezhahq/nezha/pull/947
* small improvements by @uubulb in https://github.com/nezhahq/nezha/pull/958
* feat: new theme nezha-ascii by @hamster1963 in https://github.com/nezhahq/nezha/pull/960
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/962
* chore: setup dependabot by @uubulb in https://github.com/nezhahq/nezha/pull/972
* feat: option to force authorization for vistor routes by @uubulb in https://github.com/nezhahq/nezha/pull/971
* Revert "chore: setup dependabot" by @naiba in https://github.com/nezhahq/nezha/pull/978
* ddns: allow overriding domains per configuration by @uubulb in https://github.com/nezhahq/nezha/pull/979
* feat: edit server config online by @uubulb in https://github.com/nezhahq/nezha/pull/980
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/981
* feat: batch set server config by @uubulb in https://github.com/nezhahq/nezha/pull/983
* fix: notifier groups cache not initialized by @uubulb in https://github.com/nezhahq/nezha/pull/995
* refactor: simplify server & service manipulation by @uubulb in https://github.com/nezhahq/nezha/pull/993
* chore: add devcontainer config by @MemoryShadow in https://github.com/nezhahq/nezha/pull/1004
* fix: possible redirect url inconsistency by @uubulb in https://github.com/nezhahq/nezha/pull/1003
* fix: ConfigCache not copied affer server updates by @uubulb in https://github.com/nezhahq/nezha/pull/1008
* feat: update to go1.24 & support listening https by @uubulb in https://github.com/nezhahq/nezha/pull/1002
* ci: use go1.24 by @uubulb in https://github.com/nezhahq/nezha/pull/1012
* improve check for offline rules by @uubulb in https://github.com/nezhahq/nezha/pull/1013
* feat: add configurable JWT timeout setting by @MemoryShadow in https://github.com/nezhahq/nezha/pull/1014
* fix service by @uubulb in https://github.com/nezhahq/nezha/pull/1015
* fix: config fields not generated on first startup by @uubulb in https://github.com/nezhahq/nezha/pull/1016
* fix: oauth2 config not loaded by @uubulb in https://github.com/nezhahq/nezha/pull/1018
* fix: ignore the duration of out-of-bound rules by @uubulb in https://github.com/nezhahq/nezha/pull/1019
* generate agent_secret for old users by @uubulb in https://github.com/nezhahq/nezha/pull/1021
* chore(deps): bump golang.org/x/net from 0.35.0 to 0.36.0 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/1026
* hide install_host for guest by @uubulb in https://github.com/nezhahq/nezha/pull/1029
* ddns: retreive dns servers from context by @uubulb in https://github.com/nezhahq/nezha/pull/1034
* ddns: support provider hurricane electric by @uubulb in https://github.com/nezhahq/nezha/pull/1036
* improve transfer record logic by @uubulb in https://github.com/nezhahq/nezha/pull/1033
* fix packaging script by @uubulb in https://github.com/nezhahq/nezha/pull/1037
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/1040
* chore(deps): bump github.com/golang-jwt/jwt/v4 from 4.5.1 to 4.5.2 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/1041
* add tests for config & iostream by @uubulb in https://github.com/nezhahq/nezha/pull/1045
* fix search by id by @uubulb in https://github.com/nezhahq/nezha/pull/1047
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/1048
* Update README.md by @naiba in https://github.com/nezhahq/nezha/pull/1051
* update ddns on server update by @uubulb in https://github.com/nezhahq/nezha/pull/1050
* i18n: replace gettext implementation by @uubulb in https://github.com/nezhahq/nezha/pull/1056
* feat: separate real ip header of frontend/agent by @TomyJan in https://github.com/nezhahq/nezha/pull/1057
* chore(deps): bump golang.org/x/net from 0.37.0 to 0.38.0 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/1063
* chore: cleanup some code by @uubulb in https://github.com/nezhahq/nezha/pull/1069
* update dependencies by @uubulb in https://github.com/nezhahq/nezha/pull/1077
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/1049
* chore(deps): bump github.com/go-viper/mapstructure/v2 from 2.2.1 to 2.3.0 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/1097
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/1093
* chore(deps): bump github.com/go-viper/mapstructure/v2 from 2.3.0 to 2.4.0 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/1111
* fix: member-created services shouldn't be applied to admin resources by @uubulb in https://github.com/nezhahq/nezha/pull/1113
* fix: embed tzdata to correct container timezone by @honeok in https://github.com/nezhahq/nezha/pull/1126
* fix: use server ids in db query by @uubulb in https://github.com/nezhahq/nezha/pull/1146
* fix: add a default error message for waf page by @uubulb in https://github.com/nezhahq/nezha/pull/1145
* chore(deps): bump golang.org/x/crypto from 0.37.0 to 0.45.0 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/1138
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/1128
* feat(notification): add option to convert metric units in request body by @uubulb in https://github.com/nezhahq/nezha/pull/1156
* feat: tsdb by @naiba in https://github.com/nezhahq/nezha/pull/1162
* Translations update from Hosted Weblate by @weblate in https://github.com/nezhahq/nezha/pull/1168
* Filter hidden servers in guest server-group API by @NikoCat233 in https://github.com/nezhahq/nezha/pull/1172
* chore(deps): bump google.golang.org/grpc from 1.76.0 to 1.79.3 by @dependabot[bot] in https://github.com/nezhahq/nezha/pull/1177
* fix(OnUserDelete): only delete current iterated user from db by @uubulb in https://github.com/nezhahq/nezha/pull/1188
* Add Trendshift badge to README by @cantoblanco in https://github.com/nezhahq/nezha/pull/1224
* Fixes broken Star History chart by @Mubelotix in https://github.com/nezhahq/nezha/pull/1225
* fix: 修复空周期流量规则列表导致流量历史清理失效 by @railzen in https://github.com/nezhahq/nezha/pull/1226

## New Contributors
* @guoyongchang made their first contribution in https://github.com/nezhahq/nezha/pull/14
* @iLayPark made their first contribution in https://github.com/nezhahq/nezha/pull/45
* @JackieSung4ev made their first contribution in https://github.com/nezhahq/nezha/pull/73
* @Creling made their first contribution in https://github.com/nezhahq/nezha/pull/103
* @Bravoyk made their first contribution in https://github.com/nezhahq/nezha/pull/106
* @techotaku made their first contribution in https://github.com/nezhahq/nezha/pull/122
* @Es-dese made their first contribution in https://github.com/nezhahq/nezha/pull/127
* @acgpiano made their first contribution in https://github.com/nezhahq/nezha/pull/132
* @ch8o made their first contribution in https://github.com/nezhahq/nezha/pull/133
* @CoiaPrant made their first contribution in https://github.com/nezhahq/nezha/pull/136
* @cloverzrg made their first contribution in https://github.com/nezhahq/nezha/pull/138
* @lemoeo made their first contribution in https://github.com/nezhahq/nezha/pull/141
* @nickfox-taterli made their first contribution in https://github.com/nezhahq/nezha/pull/143
* @CosmosZ-code made their first contribution in https://github.com/nezhahq/nezha/pull/146
* @MikoyChinese made their first contribution in https://github.com/nezhahq/nezha/pull/149
* @AkkiaS7 made their first contribution in https://github.com/nezhahq/nezha/pull/156
* @dysf888 made their first contribution in https://github.com/nezhahq/nezha/pull/170
* @hmsjy2017 made their first contribution in https://github.com/nezhahq/nezha/pull/169
* @hhhkkk520 made their first contribution in https://github.com/nezhahq/nezha/pull/171
* @MartijnLindeman made their first contribution in https://github.com/nezhahq/nezha/pull/181
* @iilemon made their first contribution in https://github.com/nezhahq/nezha/pull/195
* @GreenTeodoro839 made their first contribution in https://github.com/nezhahq/nezha/pull/204
* @liuyanxi975 made their first contribution in https://github.com/nezhahq/nezha/pull/219
* @KorenKrita made their first contribution in https://github.com/nezhahq/nezha/pull/240
* @ysicing made their first contribution in https://github.com/nezhahq/nezha/pull/251
* @qcgzxw made their first contribution in https://github.com/nezhahq/nezha/pull/254
* @coreff made their first contribution in https://github.com/nezhahq/nezha/pull/258
* @fscarmen made their first contribution in https://github.com/nezhahq/nezha/pull/260
* @yuanweize made their first contribution in https://github.com/nezhahq/nezha/pull/267
* @1ridic made their first contribution in https://github.com/nezhahq/nezha/pull/269
* @rootmelo92118 made their first contribution in https://github.com/nezhahq/nezha/pull/271
* @cantoblanco made their first contribution in https://github.com/nezhahq/nezha/pull/276
* @colour93 made their first contribution in https://github.com/nezhahq/nezha/pull/278
* @spiritLHLS made their first contribution in https://github.com/nezhahq/nezha/pull/280
* @adminsama made their first contribution in https://github.com/nezhahq/nezha/pull/282
* @unclezs made their first contribution in https://github.com/nezhahq/nezha/pull/295
* @Mmx233 made their first contribution in https://github.com/nezhahq/nezha/pull/304
* @wwng2333 made their first contribution in https://github.com/nezhahq/nezha/pull/313
* @lvgj-stack made their first contribution in https://github.com/nezhahq/nezha/pull/316
* @HsukqiLee made their first contribution in https://github.com/nezhahq/nezha/pull/322
* @arkylin made their first contribution in https://github.com/nezhahq/nezha/pull/323
* @DarcJC made their first contribution in https://github.com/nezhahq/nezha/pull/324
* @zhucaidan made their first contribution in https://github.com/nezhahq/nezha/pull/343
* @lvyaoting made their first contribution in https://github.com/nezhahq/nezha/pull/345
* @dreamingsleeping made their first contribution in https://github.com/nezhahq/nezha/pull/347
* @eya46 made their first contribution in https://github.com/nezhahq/nezha/pull/358
* @wellcoming made their first contribution in https://github.com/nezhahq/nezha/pull/360
* @funnyzak made their first contribution in https://github.com/nezhahq/nezha/pull/359
* @Septrum101 made their first contribution in https://github.com/nezhahq/nezha/pull/391
* @xrgzs made their first contribution in https://github.com/nezhahq/nezha/pull/394
* @silver-ymz made their first contribution in https://github.com/nezhahq/nezha/pull/403
* @hiDandelion made their first contribution in https://github.com/nezhahq/nezha/pull/408
* @lyj0309 made their first contribution in https://github.com/nezhahq/nezha/pull/426
* @Moraxyc made their first contribution in https://github.com/nezhahq/nezha/pull/463
* @yanhao98 made their first contribution in https://github.com/nezhahq/nezha/pull/501
* @yumusb made their first contribution in https://github.com/nezhahq/nezha/pull/548
* @weblate made their first contribution in https://github.com/nezhahq/nezha/pull/570
* @quanljh made their first contribution in https://github.com/nezhahq/nezha/pull/927
* @igophper made their first contribution in https://github.com/nezhahq/nezha/pull/939
* @MemoryShadow made their first contribution in https://github.com/nezhahq/nezha/pull/1004
* @TomyJan made their first contribution in https://github.com/nezhahq/nezha/pull/1057
* @honeok made their first contribution in https://github.com/nezhahq/nezha/pull/1126
* @NikoCat233 made their first contribution in https://github.com/nezhahq/nezha/pull/1172
* @Mubelotix made their first contribution in https://github.com/nezhahq/nezha/pull/1225
* @railzen made their first contribution in https://github.com/nezhahq/nezha/pull/1226

**Full Changelog**: https://github.com/nezhahq/nezha/compare/v2.3.2...v2.3.3
