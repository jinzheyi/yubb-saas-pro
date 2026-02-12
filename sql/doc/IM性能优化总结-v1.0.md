# IM 即时通讯系统 - 高并发性能优化总结 v1.0

> **文档版本**: v1.0  
> **创建日期**: 2026年2月12日  
> **目标**: 支持 50w+ 在线用户的企业级高并发场景  
> **优化范围**: WebSocket 中间件、数据库、Redis、异步处理

---

## 📊 性能目标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 并发连接数 | 50w+ | 单机支持 50 万以上 WebSocket 长连接 |
| 消息吞吐量 | 10w+ msg/s | 单机每秒处理 10 万条消息 |
| 消息延迟 | < 100ms | 局域网环境下消息端到端延迟小于 100 毫秒 |
| CPU 使用率 | < 80% | 高峰期 CPU 使用率不超过 80% |
| 内存使用率 | < 70% | 高峰期内存使用率不超过 70% |
| 连接建立速度 | < 50ms | 单个连接建立时间小于 50 毫秒 |

---

## 🚀 已完成的优化项

### 1. Netty WebSocket 中间件优化

#### 1.1 Epoll 优化（Linux 环境）
```yaml
shengyu:
  netty:
    use-epoll: true  # 启用 Epoll，性能提升 30%+
```

**优势**:
- 使用 Linux 原生的 Epoll 机制，减少系统调用开销
- 支持更高的并发连接数
- 降低 CPU 使用率

#### 1.2 线程池优化
```yaml
shengyu:
  netty:
    boss-threads: 2      # Boss 线程数（接收连接）
    worker-threads: 64   # Worker 线程数（处理 IO）
```

**说明**:
- Boss 线程：负责接收新连接，2 个线程足够
- Worker 线程：负责处理 IO 事件，设置为 CPU 核心数 * 2
- 对于 32 核 CPU，Worker 线程数为 64

#### 1.3 TCP 参数优化
```yaml
shengyu:
  netty:
    so-backlog: 4096           # TCP 连接队列大小
    so-rcvbuf: 262144          # TCP 接收缓冲区（256KB）
    so-sndbuf: 262144          # TCP 发送缓冲区（256KB）
    write-buffer-low-water-mark: 65536   # 写缓冲区低水位线（64KB）
    write-buffer-high-water-mark: 131072 # 写缓冲区高水位线（128KB）
```

**优势**:
- `so-backlog`: 增大连接队列，支持高并发连接建立
- `so-rcvbuf/so-sndbuf`: 增大缓冲区，提升数据传输效率
- `write-buffer-water-mark`: 防止内存溢出，实现流量控制

#### 1.4 心跳检测优化
```yaml
shengyu:
  netty:
    reader-idle-time: 90  # 读空闲超时（秒）
```

**说明**:
- 适当放宽心跳超时时间，避免频繁断线重连
- 客户端每 30 秒发送一次心跳
- 服务端 90 秒未收到消息则关闭连接

### 2. 异步处理优化

#### 2.1 创建专用线程池
```java
@Bean("imTaskExecutor")
public Executor imTaskExecutor() {
    ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
    executor.setCorePoolSize(16);        // 核心线程数
    executor.setMaxPoolSize(64);         // 最大线程数
    executor.setQueueCapacity(2000);     // 队列容量
    executor.setThreadNamePrefix("im-async-");
    executor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
    return executor;
}
```

**优势**:
- 消息保存和会话更新使用异步处理，不阻塞 Netty IO 线程
- 核心线程数 16，适合 IO 密集型任务
- 队列容量 2000，可以缓冲短时间的流量峰值
- CallerRunsPolicy 拒绝策略，保证任务不丢失

#### 2.2 异步方法实现
```java
@Async("imTaskExecutor")
protected void updateConversationAsync(MessageHeader header, ImMessageDO messageDO) {
    // 异步更新会话信息
}
```

**优势**:
- 消息保存立即返回，不等待会话更新完成
- 提升消息处理吞吐量
- 降低消息延迟

### 3. 数据库连接池优化

#### 3.1 Druid 连接池配置
```yaml
spring:
  datasource:
    dynamic:
      druid:
        initial-size: 10           # 初始连接数
        min-idle: 20               # 最小空闲连接数
        max-active: 100            # 最大连接数
        max-wait: 60000            # 获取连接超时时间（毫秒）
        min-evictable-idle-time-millis: 300000  # 最小空闲时间（5分钟）
        remove-abandoned: true     # 移除泄漏的连接
        remove-abandoned-timeout: 300  # 泄漏连接超时时间（秒）
```

**优势**:
- 增大连接池大小，支持高并发数据库访问
- 减少连接创建开销，提升性能
- 连接泄漏检测，避免连接耗尽

### 4. Redis 连接池优化

#### 4.1 Lettuce 连接池配置
```yaml
spring:
  redis:
    lettuce:
      pool:
        max-active: 200   # 最大连接数
        max-idle: 50      # 最大空闲连接数
        min-idle: 10      # 最小空闲连接数
        max-wait: 3000    # 最大等待时间（毫秒）
    timeout: 3000ms       # 连接超时时间
```

**优势**:
- 增大连接池大小，支持高并发 Redis 访问
- 用于 WebSocket 消息总线（分布式部署）
- 用于会话信息缓存（可扩展）

### 5. 消息存储优化

#### 5.1 雪花算法生成消息 ID
```java
messageDO.setId(header.getMessageId());  // 使用雪花算法生成的 ID
```

**优势**:
- 避免数据库自增 ID 的性能瓶颈
- 支持分布式环境
- 全局唯一且有序

#### 5.2 Protobuf 消息解析
```java
private String parseMessageContent(ImMessage message) {
    MessageType messageType = message.getHeader().getMessageType();
    switch (messageType) {
        case TEXT:
            TextMessage textMsg = TextMessage.parseFrom(message.getBody());
            return textMsg.getContent();
        // ... 其他类型
    }
}
```

**优势**:
- 高效解析 Protobuf 消息
- 提取消息内容用于会话列表显示
- 支持多种消息类型

### 6. 会话更新优化

#### 6.1 异步更新会话
```java
@Async("imTaskExecutor")
protected void updateConversationAsync(MessageHeader header, ImMessageDO messageDO) {
    // 单聊：更新发送者和接收者的会话
    // 群聊：更新群成员的会话（可优化为批量更新）
}
```

**优势**:
- 不阻塞消息保存
- 失败不影响消息持久化
- 支持单聊和群聊

#### 6.2 唯一索引避免重复创建
```sql
UNIQUE KEY `uk_user_target_type` (`user_id`, `target_id`, `conversation_type`, `tenant_id`)
```

**优势**:
- 避免重复创建会话
- 保证数据一致性

---

## 🔧 待优化项

### 1. 消息缓存（可选）

**目标**: 减少数据库查询，提升消息读取性能

**方案**:
```java
@Service
public class SystemMessageCacheServiceImpl implements MessageCacheService {
    
    @Autowired
    private RedisTemplate<String, ImMessageDO> redisTemplate;
    
    @Override
    public ImMessageDO getMessageFromCache(Long messageId) {
        String key = "im:message:" + messageId;
        return redisTemplate.opsForValue().get(key);
    }
    
    @Override
    public void cacheMessage(ImMessageDO message) {
        String key = "im:message:" + message.getId();
        redisTemplate.opsForValue().set(key, message, 1, TimeUnit.HOURS);
    }
}
```

**优势**:
- 热点消息缓存到 Redis
- 减少数据库查询压力
- 提升消息读取速度

### 2. 会话信息缓存（可选）

**目标**: 减少会话列表查询的数据库压力

**方案**:
```java
@Cacheable(value = "im:conversation", key = "#userId")
public List<ImConversationDO> getConversationList(Long userId) {
    return conversationMapper.selectByUserId(userId);
}

@CacheEvict(value = "im:conversation", key = "#userId")
public void updateConversation(Long userId, ImConversationDO conversation) {
    conversationMapper.updateById(conversation);
}
```

**优势**:
- 会话列表缓存到 Redis
- 减少频繁的数据库查询
- 提升会话列表加载速度

### 3. 消息分库分表（可选）

**目标**: 支持海量消息存储，提升查询性能

**方案**:
- 按用户 ID 分片：`im_message_0` ~ `im_message_15`（16 个分片）
- 按时间分片：`im_message_202601` ~ `im_message_202612`（按月分表）

**优势**:
- 单表数据量控制在千万级别
- 提升查询和插入性能
- 支持历史数据归档

### 4. 群聊会话更新优化（可选）

**目标**: 优化群聊消息的会话更新性能

**方案 1**: 使用消息队列异步处理
```java
@Async("imTaskExecutor")
protected void updateGroupConversationAsync(Long groupId, ImMessageDO messageDO) {
    // 查询群成员列表
    List<Long> memberIds = groupUserMapper.selectUserIdsByGroupId(groupId);
    
    // 批量更新会话
    conversationMapper.batchUpdateByUserIds(memberIds, messageDO);
}
```

**方案 2**: 延迟更新（拉取时更新）
```java
// 用户拉取消息时，才更新会话信息
public List<ImMessageDO> getGroupMessages(Long groupId, Long userId) {
    // 1. 查询消息
    List<ImMessageDO> messages = messageMapper.selectByGroupId(groupId);
    
    // 2. 更新会话（如果有新消息）
    if (!messages.isEmpty()) {
        updateConversation(userId, groupId, messages.get(0));
    }
    
    return messages;
}
```

**优势**:
- 减少群聊消息的会话更新开销
- 避免大群（1000+ 成员）的性能问题
- 提升消息发送速度

### 5. 离线推送（可选）

**目标**: 用户离线时，通过第三方推送服务通知用户

**方案**:
```java
@Service
public class SystemOfflinePushServiceImpl implements OfflinePushService {
    
    @Autowired
    private PushService pushService;  // 第三方推送服务（极光、友盟等）
    
    @Override
    public void pushOfflineMessage(Long userId, ImMessageDO message) {
        // 检查用户是否在线
        if (!sessionManager.isUserOnline(userId)) {
            // 发送离线推送
            pushService.push(userId, message.getContent());
        }
    }
}
```

**优势**:
- 用户离线时也能收到消息通知
- 提升用户体验
- 支持多种推送渠道

---

## 📈 性能测试建议

### 1. 连接性能测试

**测试目标**: 验证单机支持 50w+ 并发连接

**测试工具**: JMeter + WebSocket 插件

**测试步骤**:
1. 配置 JMeter 线程组：50w 线程
2. 每个线程建立一个 WebSocket 连接
3. 保持连接 10 分钟
4. 监控服务器 CPU、内存、网络使用率

**预期结果**:
- 成功建立 50w+ 连接
- CPU 使用率 < 80%
- 内存使用率 < 70%
- 连接建立速度 < 50ms

### 2. 消息吞吐量测试

**测试目标**: 验证单机支持 10w+ msg/s

**测试工具**: 自定义测试脚本

**测试步骤**:
1. 建立 10w 个 WebSocket 连接
2. 每个连接每秒发送 1 条消息
3. 持续发送 10 分钟
4. 监控消息延迟、丢失率

**预期结果**:
- 消息吞吐量 > 10w msg/s
- 消息延迟 < 100ms
- 消息丢失率 < 0.01%

### 3. 数据库压力测试

**测试目标**: 验证数据库支持高并发写入

**测试工具**: sysbench

**测试步骤**:
1. 使用 sysbench 模拟高并发插入
2. 并发线程数：100
3. 持续插入 10 分钟
4. 监控数据库 TPS、QPS、响应时间

**预期结果**:
- TPS > 5000
- 平均响应时间 < 20ms
- 无死锁和超时错误

---

## 🎯 下一步计划

### 短期（1 周内）
1. ✅ 完成 WebSocket 中间件集成
2. ✅ 完成异步处理优化
3. ✅ 完成配置优化
4. ⏳ 执行性能测试
5. ⏳ 根据测试结果调优

### 中期（1 个月内）
1. 实现消息缓存
2. 实现会话信息缓存
3. 优化群聊会话更新
4. 实现离线推送

### 长期（3 个月内）
1. 实现消息分库分表
2. 实现历史消息归档
3. 实现消息搜索功能
4. 实现消息统计分析

---

## 📚 参考资料

1. [Netty 官方文档](https://netty.io/wiki/)
2. [Protobuf 官方文档](https://developers.google.com/protocol-buffers)
3. [Druid 连接池配置](https://github.com/alibaba/druid/wiki/DruidDataSource%E9%85%8D%E7%BD%AE)
4. [Redis 性能优化](https://redis.io/topics/optimization)
5. [MySQL 性能优化](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)

---

## 📝 更新日志

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-02-12 | 初始版本，完成 WebSocket 中间件集成和高并发优化 |
