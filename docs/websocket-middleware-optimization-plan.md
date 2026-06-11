# WebSocket 核心中间件优化方案

> 版本：v1.0
> 日期：2026-06-11
> 目标：企业级 Netty WebSocket 中间件性能、安全性、稳定性优化

---

## 一、P0 级优化项（核心性能/安全问题）

| # | 问题 | 文件 | 行号 | 风险 |
|---|------|------|------|------|
| 1 | EventLoopGroup 优雅关闭缺少超时 | NettyServer.java | L126 | 僵尸进程 |
| 2 | NettySession 泄漏缺少定时清理 | NettySessionManager.java | L47 | OOM |
| 3 | 缺少最大连接数限制/防 DDoS | NettyProperties.java | 全局 | 连接风暴 |
| 4 | WebSocket BinaryFrame 无最大帧限制 | NettyChannelInitializer.java | L54 | OOM |
| 5 | removeSession 复合操作非原子 | NettySessionManager.java | L193 | 索引不一致 |
| 6 | WRITER_IDLE 服务端不发心跳 | HeartbeatHandler.java | L113 | 僵尸连接 |
| 7 | writeAndFlush 无背压控制 | NettyMessageSender.java | L152 | OOM |
| 8 | NettyAuthLeaseMonitor 全量遍历 | NettyAuthLeaseMonitor.java | L67 | GC 压力 |

## 二、P1 级优化项（架构优化）

| # | 问题 | 文件 | 行号 | 风险 |
|---|------|------|------|------|
| 9 | 群消息无批量发送机制 | NettyMessageSender.java | L126 | 性能差 |
| 10 | TenantUtils 嵌套 ThreadLocal 泄漏 | NettyMessageSender.java | L108 | 上下文污染 |
| 11 | 缺少 Prometheus 监控指标 | 全局 | - | 可观测性差 |
| 12 | generateMessageId 时间戳冲突 | NettyMessageSender.java | L765 | 消息去重失败 |
| 13 | JSON payload 未限制大小 | JsonWebSocketMessageHandler.java | L58 | GC 压力 |
| 14 | getSessionList 并发 IndexOutOfBounds | WebSocketSessionManagerImpl.java | L106 | 崩溃 |
| 15 | Token 撤销后连接未实时失效 | NettySessionManager.java | L65 | 权限残留 |

## 三、P2 级优化项（代码规范）

| # | 问题 | 文件 | 行号 | 风险 |
|---|------|------|------|------|
| 16 | 硬编码设备类型 | NettySessionManager.java | L321 | 维护差 |
| 17 | 硬编码 messageType 数字 | AuthHandler.java | L74,L78 | 维护差 |
| 18 | 异常堆栈信息丢失 | JsonWebSocketMessageHandler.java | L78 | 排查困难 |
| 19 | 生产环境过多 info 日志 | NettyMessageSender.java | 多处 | 性能差 |
| 20 | 硬编码 userType 数字 | NettySession.java | L149 | 维护差 |
| 21 | LoggingHandler 级别过高 | NettyServer.java | L80 | 日志噪音 |
| 22 | clear() 非原子操作 | NettySessionManager.java | L487 | 清理不完整 |

---

## 四、实施记录

### 第一轮（P0 级 + P2 级 - 已完成）
| 任务 | 状态 | 效果 |
|------|------|------|
| EventLoopGroup 优雅关闭超时 | ✅ | 30 秒超时，避免僵尸进程 |
| 最大连接数/防 DDoS 配置 | ✅ | 新增 maxConnections、perIpMaxConnections 配置项 |
| WebSocket 最大帧大小限制 | ✅ | 1MB 限制，防止 OOM |
| writeAndFlush 背压控制 | ✅ | 所有发送路径增加 isWritable 检查 |
| generateMessageId 雪花算法 | ✅ | 使用 IdGenerator，ID 不再冲突 |
| 异常堆栈信息修复 | ✅ | JsonWebSocketMessageHandler 输出完整堆栈 |
| LoggingHandler 级别调整 | ✅ | INFO → DEBUG，减少日志噪音 |
| 发送日志降级 | ✅ | 7 处 info → debug，高吞吐友好 |

### 第二轮（P1 级 - 待执行）
| 任务 | 优先级 | 说明 |
|------|--------|------|
| NettySession 定时清理机制 | P1 | 扫描 !isActive() 的 Session 并清理 |
| JSON payload 大小限制 | P1 | 解析前检查 payload 长度 |
| Token 撤销实时失效 | P1 | Token 撤销时主动关闭 Channel |
| getSessionList 并发安全 | P1 | 防止 CopyOnWriteArrayList get(0) IndexOutOfBounds |
