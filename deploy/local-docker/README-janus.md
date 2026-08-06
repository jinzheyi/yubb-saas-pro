# Janus Gateway 本地部署指南

本文档介绍如何在本地 Docker 环境中部署 Janus Gateway 和 TURN 服务器，用于支持 IM 音视频通话功能。

## 1. 前置条件

- Docker Desktop 已安装并运行
- Docker Compose v2.0+ 已安装
- 本地端口未占用：8088（Janus HTTP）、8188（Janus WebSocket）、3478（TURN）、10000-10200（RTP）

## 2. 配置文件准备

### 2.1 环境变量文件

创建 `docker.janus.env` 文件：

```bash
# Janus Gateway 配置
JANUS_API_SECRET=your-janus-api-secret-change-this-in-production
JANUS_ADMIN_SECRET=your-janus-admin-secret-change-this-in-production

# TURN 服务器配置
TURN_SECRET=your-turn-secret-change-this-in-production
TURN_USERNAME=turnuser
TURN_PASSWORD=turnpassword

# 网络配置（根据实际环境调整）
JANUS_PUBLIC_IP=127.0.0.1
TURN_PUBLIC_IP=127.0.0.1
```

### 2.2 Janus 主配置文件

创建 `janus.jcfg` 文件：

```ini
general:
  configs_folder = "/usr/local/etc/janus"
  plugins_folder = "/usr/local/lib/janus/plugins"
  log_to_stdout = true
  debug_level = 3
  admin_secret = "${JANUS_ADMIN_SECRET}"

media:
  rtp_port_range = "10000-10200"

nat:
  stun_server = "stun.l.google.com"
  stun_port = 19302
  nice_debug = false
  ice_tcp = false
  turn_server = "coturn"
  turn_port = 3478
  turn_type = "udp"
  turn_user = "${TURN_USERNAME}"
  turn_pwd = "${TURN_PASSWORD}"
  nat_1_1_mapping = "${JANUS_PUBLIC_IP}"

plugins:
  enabled = "libjanus_videoroom.so,libjanus_streaming.so,libjanus_textroom.so"

transports:
  enabled = "libjanus_http.so,libjanus_websockets.so"

websockets:
  ws = true
  ws_port = 8188
  ws_ip = "0.0.0.0"
  ws_secure = false

http:
  http = true
  http_port = 8088
  http_ip = "0.0.0.0"
  base_path = "/janus"
```

### 2.3 Janus VideoRoom 插件配置

创建 `janus.plugin.videoroom.jcfg` 文件：

```ini
general:
  admin_key = "${JANUS_ADMIN_SECRET}"
  events = true

rooms:
  # 默认房间配置（可通过 API 动态创建）
  - room_id = 1
    description = "Default Room"
    is_private = false
    secret = "default-room-secret"
    publishers = 9
    bitrate = 128000
    fir_secs = 10
    save_pvtfiles = false
```

### 2.4 TURN 服务器配置

创建 `turnserver.conf` 文件：

```conf
# TURN Server Configuration
listening-port=3478
fingerprint
lt-cred-mech
user=${TURN_USERNAME}:${TURN_PASSWORD}
realm=shengyu.local
total-quota=100
stale-nonce=600
cert=/etc/ssl/certs/ssl-cert-snakeoil.pem
pkey=/etc/ssl/private/ssl-cert-snakeoil.key
no-multicast-peers
no-cli
no-tlsv1
no-tlsv1_1

# 网络配置
external-ip=${TURN_PUBLIC_IP}
relay-ip=0.0.0.0

# 日志
log-file=/var/log/turnserver.log
verbose
```

## 3. Docker Compose 配置

创建 `docker-compose.janus.yml` 文件：

```yaml
version: '3.8'

name: shengyu-janus-local

services:
  janus:
    image: canyan/janus-gateway:latest
    container_name: shengyu-janus-local
    ports:
      - "8088:8088"   # HTTP API
      - "8188:8188"   # WebSocket API
      - "10000-10200:10000-10200/udp"  # RTP 端口范围
    environment:
      - JANUS_API_SECRET=${JANUS_API_SECRET}
      - JANUS_ADMIN_SECRET=${JANUS_ADMIN_SECRET}
      - TURN_USERNAME=${TURN_USERNAME}
      - TURN_PASSWORD=${TURN_PASSWORD}
      - JANUS_PUBLIC_IP=${JANUS_PUBLIC_IP}
    volumes:
      - ./janus.jcfg:/usr/local/etc/janus/janus.jcfg:ro
      - ./janus.plugin.videoroom.jcfg:/usr/local/etc/janus/janus.plugin.videoroom.jcfg:ro
    depends_on:
      - coturn
    restart: unless-stopped
    networks:
      - janus-network

  coturn:
    image: coturn/coturn:latest
    container_name: shengyu-coturn-local
    ports:
      - "3478:3478/udp"
      - "3478:3478/tcp"
    environment:
      - TURN_USERNAME=${TURN_USERNAME}
      - TURN_PASSWORD=${TURN_PASSWORD}
      - TURN_PUBLIC_IP=${TURN_PUBLIC_IP}
    volumes:
      - ./turnserver.conf:/etc/turnserver.conf:ro
    command: -c /etc/turnserver.conf
    restart: unless-stopped
    networks:
      - janus-network

networks:
  janus-network:
    driver: bridge
```

## 4. 启动服务

### 4.1 启动 Janus 和 TURN 服务

```bash
cd deploy/local-docker
docker compose --env-file docker.janus.env -f docker-compose.janus.yml up -d
```

### 4.2 查看服务状态

```bash
docker compose -f docker-compose.janus.yml ps
```

### 4.3 查看日志

```bash
# 查看 Janus 日志
docker logs -f shengyu-janus-local

# 查看 TURN 日志
docker logs -f shengyu-coturn-local
```

## 5. 健康检查

### 5.1 Janus HTTP API 检查

```bash
curl http://localhost:8088/janus/info
```

预期响应：
```json
{
  "janus": "server_info",
  "name": "Janus Gateway",
  "version": 1001,
  "version_string": "0.10.1",
  "author": "Meetecho s.r.l.",
  "data_channels": true,
  "ipv6": false,
  "ice-tcp": false,
  "full_trickle": false,
  "plugins": {
    "janus.plugin.videoroom": "0.0.9",
    "janus.plugin.streaming": "0.0.6",
    "janus.plugin.textroom": "0.0.4"
  },
  "transports": {
    "janus.transport.http": "0.0.8",
    "janus.transport.websockets": "0.0.7"
  }
}
```

### 5.2 Janus WebSocket 检查

```bash
# 使用 wscat 测试 WebSocket 连接
npm install -g wscat
wscat -c ws://localhost:8188
```

连接成功后发送：
```json
{
  "janus": "info",
  "transaction": "test123"
}
```

### 5.3 TURN 服务器检查

```bash
# 使用 turnutils_uclient 测试 TURN 服务器
turnutils_uclient -u turnuser -w turnpassword -p 3478 127.0.0.1
```

## 6. 与主系统集成

### 6.1 更新主 docker-compose.local.yml

在 `docker-compose.local.yml` 中添加 Janus 网络：

```yaml
services:
  server:
    # ... 现有配置 ...
    networks:
      - default
      - janus-network

networks:
  janus-network:
    external: true
    name: shengyu-janus-local_janus-network
```

### 6.2 更新 Spring Boot 配置

在 `application-local.yml` 中添加 Janus 配置：

```yaml
janus:
  ws-url: ws://localhost:8188/janus
  http-url: http://localhost:8088/janus
  api-secret: ${JANUS_API_SECRET}
  admin-secret: ${JANUS_ADMIN_SECRET}
  tenant-isolation: true
  
turn:
  server: localhost
  port: 3478
  username: ${TURN_USERNAME}
  password: ${TURN_PASSWORD}
```

### 6.3 更新 Flutter 客户端配置

在 `app_config.dart` 中配置 Janus 地址：

```dart
abstract final class AppConfig {
  // ... 现有配置 ...
  
  /// Janus WebSocket 地址（本地开发环境）
  static const String janusWsUrl = 'ws://localhost:8188/janus';
  
  /// Janus HTTP API 地址（本地开发环境）
  static const String janusHttpUrl = 'http://localhost:8088/janus';
  
  /// TURN 服务器地址
  static const String turnServer = 'localhost';
  static const int turnPort = 3478;
}
```

## 7. 常用运维命令

### 7.1 停止服务

```bash
docker compose -f docker-compose.janus.yml down
```

### 7.2 重启服务

```bash
docker compose -f docker-compose.janus.yml restart
```

### 7.3 重新构建并启动

```bash
docker compose -f docker-compose.janus.yml up -d --build
```

### 7.4 清理所有数据

```bash
# 警告：这会删除所有容器和网络
docker compose -f docker-compose.janus.yml down -v --remove-orphans
```

## 8. 故障排查

### 8.1 Janus 无法启动

**问题**：容器启动后立即退出

**排查步骤**：
1. 查看日志：`docker logs shengyu-janus-local`
2. 检查配置文件路径是否正确
3. 确认端口未被占用：`lsof -i :8088`

### 8.2 WebSocket 连接失败

**问题**：客户端无法连接到 Janus WebSocket

**排查步骤**：
1. 确认 WebSocket 插件已启用：检查 `janus.jcfg` 中的 `transports.enabled`
2. 检查防火墙设置
3. 验证 WebSocket 端口：`curl -v ws://localhost:8188`

### 8.3 TURN 服务器无法连接

**问题**：NAT 穿透失败

**排查步骤**：
1. 检查 TURN 服务是否运行：`docker ps | grep coturn`
2. 验证 TURN 配置：`turnutils_uclient -u turnuser -w turnpassword localhost`
3. 确认 Janus 配置中的 TURN 地址正确

### 8.4 RTP 端口不通

**问题**：媒体流无法建立

**排查步骤**：
1. 确认 RTP 端口范围已映射：`docker port shengyu-janus-local`
2. 检查防火墙是否允许 UDP 端口
3. 验证 Janus 配置中的 `rtp_port_range`

## 9. 生产环境注意事项

### 9.1 安全配置

- **修改默认密钥**：生产环境必须修改 `JANUS_API_SECRET` 和 `JANUS_ADMIN_SECRET`
- **启用 HTTPS/WSS**：配置 SSL 证书，使用 `wss://` 和 `https://`
- **TURN 认证**：使用动态认证机制，避免硬编码用户名密码
- **网络隔离**：使用 Docker 网络隔离，限制外部访问

### 9.2 性能优化

- **RTP 端口范围**：根据并发通话数调整（每个通话需要 2 个端口）
- **TURN 配额**：设置合理的 `total-quota` 防止资源耗尽
- **日志级别**：生产环境将 `debug_level` 调整为 2 或更低
- **资源限制**：为容器设置 CPU 和内存限制

### 9.3 监控告警

- **Janus 监控**：使用 Prometheus + Grafana 监控 Janus 指标
- **日志收集**：集成 ELK 或 Loki 收集日志
- **告警配置**：配置关键指标告警（CPU、内存、连接数）

## 10. 参考文档

- [Janus Gateway 官方文档](https://janus.conf.meetecho.com/docs/)
- [Janus Docker 镜像](https://hub.docker.com/r/canyan/janus-gateway)
- [coturn 官方文档](https://github.com/coturn/coturn)
- [WebRTC 穿透 NAT](https://webrtc.org/getting-started/turn-server)

---

**文档版本**: v1.0  
**最后更新**: 2026-07-21  
**维护者**: 圣钰科技 IM 团队
