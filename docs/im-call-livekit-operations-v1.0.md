# LiveKit 通话客户交付与运维基线

本文件与 `im-call-livekit-rebuild-task-spec-v2.0.md` 共同构成通话交付基线。开发联调使用 `deploy/livekit/docker-compose.yml`；生产 Kubernetes 使用 LiveKit 官方 Helm chart 与 `deploy/livekit/values-production.example.yaml`，不得把示例密钥直接上线。

## 1. 组件与端口

| 组件 | 端口 | 协议 | 用途 |
|---|---:|---|---|
| LiveKit API/Signal | 7880（生产由 443 代理） | TCP/WSS | SDK 信令、房间 API |
| LiveKit RTC fallback | 7881 | TCP | UDP 不可用时的媒体回退 |
| LiveKit media | 50000-50100 | UDP | 音视频媒体 |
| Embedded TURN | 3478、49160-49200 | UDP | NAT 中继和 relay |
| TURN/TLS | 5349 或 443 | TCP/TLS | 严格网络兜底 |
| Redis | 6379（仅内网） | TCP | 多节点房间协调 |

LiveKit 节点必须直接获得可路由 IP。Kubernetes 生产节点使用 `hostNetwork`，不部署到 serverless/private NAT 集群；Docker Desktop 联调用 `start-local.sh` 自动识别当前 LAN IPv4，`.local` 只用于信令域名解析。

## 2. 环境变量与密钥

后端只读取 `IM_CALL_LIVEKIT_URL/API_KEY/API_SECRET/ALLOW_INSECURE/TOKEN_EXPIRE_SECONDS`。LiveKit 容器与后端共用 `IM_CALL_LIVEKIT_API_KEY/API_SECRET`，避免两份密钥漂移；容器额外读取 `LIVEKIT_DOMAIN/NODE_IP/USE_EXTERNAL_IP/WEBHOOK_URL`和 Redis 密码。API secret、Redis 密码、APNs/FCM 凭据不得进入 Flutter、Git、日志、outbox payload 或数据库通话记录。

每个客户使用独立 key/secret。轮换时先在 LiveKit 同时加入新旧 key，发布后端新 key，等待旧 Token 最大 TTL（当前 10 分钟）后删除旧 key；Redis 与 TLS 密钥按客户变更窗口滚动更新。

## 3. 部署、升级与回滚

开发：复制 `.env.example`，执行 `deploy/livekit/start-local.sh`。生产：创建 Redis、TLS Secret 和正式 DNS，开放端口，执行官方 Helm `install/upgrade`。升级采用固定镜像版本、逐节点滚动和预发布租户验收。

回滚只回滚本次 LiveKit 版本/应用版本和数据库新增代码，不恢复 Janus。数据库新增列/outbox 表保留以保证历史记录可读；活跃通话在发布窗口前主动结束，新版本通过 GET state 恢复业务事实。

## 4. 监控告警

至少采集 LiveKit 节点/房间/参与者/丢包、Redis 可用性、后端 create→invite→accept→connect→end 延迟、outbox PENDING/FAILED 数和 Webhook 验签失败。建议阈值：LiveKit/Redis 不可用立即告警；FAILED outbox > 0 立即告警；PENDING 最老事件 > 30 秒告警；呼叫成功率 5 分钟低于 98% 告警。

所有日志统一携带 tenantId、callId、event version 和 traceId，严禁打印 access token、API secret 或推送凭据。

## 5. 容量起点与扩容

P0 单房最多 9 人。客户上线前以实际编码分辨率、上行带宽和终端型号压测；CPU 持续超过 60%、媒体带宽超过节点可用带宽 60% 或丢包持续升高时扩容。多节点必须共享 Redis，节点具有独立公网 IP 与一致端口策略。

## 6. 故障定位顺序

先 GET 通话 state 排除业务终态，再查 outbox/event version 与 WebSocket 投递，随后查 LiveKit WSS、Token room/identity、节点发布 IP，最后检查 UDP/TURN/TLS。看到 Docker `172.x` ICE 地址立即重启 `start-local.sh`；信令成功但无媒体重点检查 50000-50100/3478/relay 和宿主机防火墙。

## 7. 移动推送交付

Android 客户提供 Firebase 配置与服务账号，允许高优先级 data push、通知和全屏意图；iOS 客户提供 Apple Team/Bundle ID/APNs VoIP key 并启用 Push Notifications、Background Modes/VoIP。客户端收到 push 后只信任 callId，必须 GET state 确认仍可接听；推送中禁止携带 LiveKit Token。

## 8. 第三方许可

LiveKit Server 为 Apache-2.0；Java 后端不引入要求 Java 17 的 LiveKit Server SDK，而使用项目已有 Hutool JWT 按公开协议签发与验签。`livekit_client`、`flutter_callkit_incoming`、Flutter 及其直接依赖在每次发布时从锁文件生成 SBOM 并复核许可证。P0 不包含 LiveKit Cloud、Egress、录制或其他付费云服务依赖。

## 9. 本地构建命令

- Android：`/Users/zsy/app/flutter/bin/flutter build apk --debug --no-pub`
- Web：`/Users/zsy/app/flutter/bin/flutter build web --no-pub --no-tree-shake-icons`
- iOS 模拟器：在 Flutter 工程执行 `flutter build ios --simulator --debug`。
