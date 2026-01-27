# Netty WebSocket 配置说明

## 配置文件结构

按照项目规范，Netty WebSocket 的配置已分别放置在以下文件中：

### 1. application.yaml（公共配置）
**位置**：`shengyu-server/src/main/resources/application.yaml`

**包含内容**：
- 基础配置（enable、host、协议配置）
- TCP 参数配置（通用参数）
- 心跳配置（通用参数）
- WebSocket 旧版配置（兼容性保留）

```yaml
shengyu:
  netty:
    # 基础配置
    enable: true
    host: 0.0.0.0
    
    # 协议配置
    enable-websocket: true
    websocket-path: /ws
    enable-protobuf: true
    max-content-length: 65536
    
    # 性能优化配置
    boss-threads: 1
    
    # TCP 参数配置
    so-backlog: 1024
    so-rcvbuf: 65536
    so-sndbuf: 65536
    write-buffer-low-water-mark: 32768
    write-buffer-high-water-mark: 65536
    
    # 心跳配置
    writer-idle-time: 0
    all-idle-time: 0
```

### 2. application-dev.yaml（生产环境配置）
**位置**：`shengyu-server/src/main/resources/application-dev.yaml`

**包含内容**：
- 生产环境端口配置
- 性能优化配置（Epoll、线程数）
- 生产环境 TCP 参数优化
- Redis 消息总线配置

```yaml
shengyu:
  netty:
    port: 9000
    use-epoll: true                    # Linux 环境启用 Epoll
    worker-threads: 32                 # 生产环境增加线程数
    reader-idle-time: 60               # 60秒超时
    so-backlog: 2048                   # 增大连接队列
    so-rcvbuf: 131072                  # 128KB
    so-sndbuf: 131072                  # 128KB
  
  websocket:
    sender-type: redis                 # 使用 Redis 消息总线
    sender-redis:
      channel: shengyu-server-websocket-channel
```

### 3. application-local.yaml（本地开发环境配置）
**位置**：`shengyu-server/src/main/resources/application-local.yaml`

**包含内容**：
- 本地开发端口配置
- 本地环境优化配置（不使用 Epoll）
- 延长超时时间（方便调试）
- Local 消息总线配置

```yaml
shengyu:
  netty:
    port: 9000
    use-epoll: false                   # Windows 不支持 Epoll
    worker-threads: 8                  # 本地环境减少线程数
    reader-idle-time: 120              # 延长超时时间，方便调试
  
  websocket:
    sender-type: local                 # 本地模式，不依赖外部消息队列
```

## 配置项说明

### 基础配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `shengyu.netty.enable` | Boolean | true | 是否启用 Netty 服务器 |
| `shengyu.netty.host` | String | 0.0.0.0 | 服务器绑定地址 |
| `shengyu.netty.port` | Integer | 9000 | 服务器端口 |

### 协议配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `shengyu.netty.enable-websocket` | Boolean | true | 是否启用 WebSocket 协议 |
| `shengyu.netty.websocket-path` | String | /ws | WebSocket 路径 |
| `shengyu.netty.enable-protobuf` | Boolean | true | 是否启用 Protobuf 协议 |
| `shengyu.netty.max-content-length` | Integer | 65536 | HTTP 最大内容长度（字节） |

### 性能优化配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `shengyu.netty.use-epoll` | Boolean | false | 是否使用 Epoll（仅 Linux） |
| `shengyu.netty.boss-threads` | Integer | 1 | Boss 线程数（接收连接） |
| `shengyu.netty.worker-threads` | Integer | 16 | Worker 线程数（建议 CPU 核心数 * 2） |

### TCP 参数配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `shengyu.netty.so-backlog` | Integer | 1024 | TCP 连接队列大小 |
| `shengyu.netty.so-rcvbuf` | Integer | 65536 | TCP 接收缓冲区大小（字节） |
| `shengyu.netty.so-sndbuf` | Integer | 65536 | TCP 发送缓冲区大小（字节） |
| `shengyu.netty.write-buffer-low-water-mark` | Integer | 32768 | 写缓冲区低水位线（字节） |
| `shengyu.netty.write-buffer-high-water-mark` | Integer | 65536 | 写缓冲区高水位线（字节） |

### 心跳配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `shengyu.netty.reader-idle-time` | Integer | 60 | 读空闲超时时间（秒），0表示不检测 |
| `shengyu.netty.writer-idle-time` | Integer | 0 | 写空闲超时时间（秒），0表示不检测 |
| `shengyu.netty.all-idle-time` | Integer | 0 | 读写空闲超时时间（秒），0表示不检测 |

### 消息总线配置

| 配置项 | 类型 | 可选值 | 说明 |
|--------|------|--------|------|
| `shengyu.websocket.sender-type` | String | local/redis/rocketmq/kafka/rabbitmq | 消息发送类型 |

#### Redis 消息总线

```yaml
shengyu:
  websocket:
    sender-type: redis
    sender-redis:
      channel: im-message-channel  # Redis 频道名称
```

#### RocketMQ 消息总线

```yaml
shengyu:
  websocket:
    sender-type: rocketmq
    sender-rocketmq:
      topic: im-message-topic
      consumer-group: im-message-consumer-group
```

#### Kafka 消息总线

```yaml
shengyu:
  websocket:
    sender-type: kafka
    sender-kafka:
      topic: im-message-topic
      consumer-group: im-message-consumer-group
```

#### RabbitMQ 消息总线

```yaml
shengyu:
  websocket:
    sender-type: rabbitmq
    sender-rabbitmq:
      exchange: im-message-exchange
      queue: im-message-queue
```

## 环境配置建议

### 本地开发环境（application-local.yaml）

```yaml
shengyu:
  netty:
    port: 9000
    use-epoll: false              # Windows 不支持
    worker-threads: 8             # 减少资源占用
    reader-idle-time: 120         # 延长超时，方便调试
  
  websocket:
    sender-type: local            # 不依赖外部服务
```

**特点**：
- 不使用 Epoll（Windows 不支持）
- 减少线程数，降低资源占用
- 延长超时时间，方便断点调试
- 使用 local 模式，无需启动 Redis 等外部服务

### 生产环境（application-dev.yaml）

```yaml
shengyu:
  netty:
    port: 9000
    use-epoll: true               # Linux 环境启用
    worker-threads: 32            # 根据 CPU 核心数调整
    reader-idle-time: 60          # 正常超时时间
    so-backlog: 2048              # 增大连接队列
    so-rcvbuf: 131072             # 128KB
    so-sndbuf: 131072             # 128KB
  
  websocket:
    sender-type: redis            # 使用 Redis 支持集群
    sender-redis:
      channel: shengyu-server-websocket-channel
```

**特点**：
- 启用 Epoll 优化（Linux 环境）
- 增加线程数，提升并发能力
- 增大 TCP 缓冲区，提升吞吐量
- 使用 Redis 消息总线，支持集群部署

## 性能调优建议

### 1. 线程数配置

```yaml
# 根据 CPU 核心数调整
worker-threads: ${CPU_CORES * 2}

# 示例：
# 4核CPU：worker-threads: 8
# 8核CPU：worker-threads: 16
# 16核CPU：worker-threads: 32
```

### 2. TCP 缓冲区配置

```yaml
# 高并发场景
so-rcvbuf: 131072    # 128KB
so-sndbuf: 131072    # 128KB

# 超高并发场景
so-rcvbuf: 262144    # 256KB
so-sndbuf: 262144    # 256KB
```

### 3. 连接队列配置

```yaml
# 普通场景
so-backlog: 1024

# 高并发场景
so-backlog: 2048

# 超高并发场景
so-backlog: 4096
```

### 4. 心跳超时配置

```yaml
# 移动网络（网络不稳定）
reader-idle-time: 90

# 稳定网络
reader-idle-time: 60

# 内网环境
reader-idle-time: 30
```

## 集群部署配置

### 使用 Redis 消息总线

```yaml
shengyu:
  websocket:
    sender-type: redis
    sender-redis:
      channel: ${spring.application.name}-websocket-channel

spring:
  redis:
    host: redis-cluster.example.com
    port: 6379
    password: your-password
    database: 0
```

### 使用 RocketMQ 消息总线

```yaml
shengyu:
  websocket:
    sender-type: rocketmq
    sender-rocketmq:
      topic: ${spring.application.name}-websocket
      consumer-group: ${spring.application.name}-websocket-consumer

rocketmq:
  name-server: rocketmq-cluster.example.com:9876
```

## 监控指标

建议监控以下指标：

1. **连接数**：当前在线连接数
2. **消息吞吐**：每秒发送/接收的消息数
3. **延迟**：消息端到端延迟
4. **线程池**：Worker 线程池使用率
5. **内存**：堆内存和直接内存使用情况
6. **网络**：网络 I/O 吞吐量

## 常见问题

### Q1: Windows 环境启动报错 "Epoll not available"

**解决方案**：在 `application-local.yaml` 中设置：
```yaml
shengyu:
  netty:
    use-epoll: false
```

### Q2: 连接频繁断开

**解决方案**：延长心跳超时时间：
```yaml
shengyu:
  netty:
    reader-idle-time: 120  # 延长到 120 秒
```

### Q3: 高并发下连接失败

**解决方案**：增大连接队列和线程数：
```yaml
shengyu:
  netty:
    so-backlog: 4096
    worker-threads: 32
```

### Q4: 集群环境消息无法跨节点发送

**解决方案**：使用 Redis 或 RocketMQ 消息总线：
```yaml
shengyu:
  websocket:
    sender-type: redis
```

## 相关文档

- [WebSocket模块完成总结.md](WebSocket模块完成总结.md) - 模块完成总结
- [ARCHITECTURE.md](shengyu-framework/shengyu-spring-boot-starter-websocket/ARCHITECTURE.md) - 架构设计
- [QUICK-START.md](shengyu-framework/shengyu-spring-boot-starter-websocket/QUICK-START.md) - 快速开始
- [API.md](shengyu-framework/shengyu-spring-boot-starter-websocket/API.md) - API 文档

---

**更新时间**：2026年1月27日  
**版本**：v1.0.0  
**作者**：圣钰科技
