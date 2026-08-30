# LiveKit 私有化部署包

生产环境复制 `.env.example` 为 `.env`；本机局域网联调复制 `.env.local.example` 为 `.env`。为每个环境填写独立的 key、secret 与 LiveKit 域名后执行：

```bash
docker compose --env-file .env up -d
```

Mac 局域网联调优先执行 `./start-local.sh`。脚本每次启动都会从当前默认网络接口识别 LAN IPv4，并通过进程环境覆盖 `.env` 中可能已经过期的 `LIVEKIT_NODE_IP`，因此 Wi-Fi DHCP 地址变化后无需手工改文件。`MacBook-Pro-3.local` 仅用于稳定解析信令地址；WebRTC ICE 候选仍必须发布实际可路由 IP。

`application-local.yaml` 会可选加载仓库根目录的 `deploy/livekit/.env`，因此 IDEA 从仓库根目录启动后端时不需要再复制一套 LiveKit 环境变量。其他工作目录可通过 `IM_CALL_CONFIG_FILE` 指定绝对路径；生产不依赖该文件，直接注入 `IM_CALL_LIVEKIT_*`。

如 macOS 未主动发布本机 `.local` 记录，可加载仓库内的 Bonjour LaunchAgent：

```bash
launchctl bootstrap "gui/$(id -u)" "$(pwd)/macos/com.shengyu.local-api-bonjour.plist"
launchctl enable "gui/$(id -u)/com.shengyu.local-api-bonjour"
```

该服务通过 mDNS 发布当前 Mac 的 LAN 地址，DHCP 换 IP 时由 mDNSResponder 自动更新。若使用 Clash Verge TUN，还必须在订阅的持久化增强规则中将 `224.0.0.251/32` 和 `ff02::fb/128` 置于订阅的 `224.0.0.0/4,REJECT` 之前并设为 `DIRECT`，同时将 `*.local` 加入 `dns.fake-ip-filter`。这些规则只放行 Bonjour 组播，不改变外网代理。

启动后可单独执行 `./verify-network.sh`，检查 HTTP 信令、RTC TCP、容器状态以及是否错误发布了 Docker `172.x` bridge 地址。

本 Compose 是单节点 P0 部署。TURN 使用 LiveKit 内嵌实现，鉴权会自动绑定已建立的 LiveKit 信令连接，客户端无需、也不会收到长期 TURN 凭证。

`LIVEKIT_NODE_IP` 必须是客户端可路由的宿主机地址：本机 Wi-Fi 联调填 Mac 的 LAN IPv4；客户生产环境填该 LiveKit 节点公网 IPv4。Docker bridge 地址（例如 `172.x.x.x`）不能填写。局域网调试保持 `LIVEKIT_USE_EXTERNAL_IP=false`；公网部署可改为 `true` 让 LiveKit 通过 STUN 发现地址，或保留 `false` 并显式配置 `LIVEKIT_NODE_IP`。

生产环境必须在启动前完成：DNS、TLS/WSS 反向代理、UDP RTC mux 7882、TCP RTC 7881、UDP TURN 3478 与 relay 41000-41040，以及 TURN/TLS 443 或 5349 的网络验证。不得以 `.local`、开发机 IP 或示例地址上线。生产 TURN/TLS 必须在 LiveKit 配置中提供受信任证书，再启用 `turn.tls_port`。本目录不把开发密钥打包进镜像，客户密钥只从 `.env` 或正式密钥管理系统注入。
