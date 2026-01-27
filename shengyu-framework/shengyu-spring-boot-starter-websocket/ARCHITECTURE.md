# 即时通讯中间件架构设计

## 一、架构原则

### 1.1 职责划分

**中间件职责**（shengyu-spring-boot-starter-websocket）：
- ✅ 连接管理（Netty 服务器、会话管理）
- ✅ 协议处理（WebSocket、Protobuf）
- ✅ 消息路由（消息分发、消息转发）
- ✅ 认证鉴权（Token 验证）
- ✅ 心跳检测（连接保活）
- ✅ 异常处理（连接异常、消息异常）

**业务模块职责**（shengyu-module-system / shengyu-module-platform）：
- ✅ 消息存储（数据库设计、表结构、存储逻辑）
- ✅ 业务逻辑（好友关系、群组管理、会话管理）
- ✅ 业务规则（权限控制、敏感词过滤）
- ✅ 消息缓存（Redis 缓存策略）
- ✅ 离线推送（推送平台集成）

### 1.2 设计模式

中间件采用 **SPI（Service Provider Interface）** 模式：

```
┌─────────────────────────────────────────────────────────┐
│           中间件（shengyu-spring-boot-starter-websocket）  │
│                                                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ Netty Server│  │   Session   │  │   Message   │     │
│  │   连接管理   │  │   会话管理   │  │   消息路由   │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │           SPI 接口（由业务模块实现）                │   │
│  │  - MessageStorageService（消息存储）              │   │
│  │  - MessageCacheService（消息缓存）                │   │
│  │  - OfflinePushService（离线推送）                 │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │ 实现接口
                          │
        ┌─────────────────┴─────────────────┐
        │                                   │
┌───────▼────────┐              ┌──────────▼─────────┐
│  system 模块    │              │  platform 模块      │
│                │              │                    │
│ - 租户端消息存储 │              │ - 平台端消息存储    │
│ - 租户端业务逻辑 │              │ - 平台端业务逻辑    │
│ - 租户端缓存策略 │              │ - 平台端缓存策略    │
└────────────────┘              └────────────────────┘
```

## 二、SPI 接口说明

### 2.1 MessageStorageService（消息存储）

**接口定义**：
```java
public interface MessageStorageService {
    void saveMessage(ImMessage message);
    Long saveMessageWithId(ImMessage message);
}
```

**实现要求**：
- 业务模块必须实现此接口
- 负责将 Protobuf 消息转换为业务 DO 对象
- 负责消息的持久化存储
- 可以实现额外的业务逻辑（如更新会话、统计未读数等）

**实现示例**（system 模块）：
```java
@Service
public class SystemMessageStorageServiceImpl implements MessageStorageService {
    
    @Autowired
    private SystemImMessageMapper messageMapper;
    
    @Override
    public void saveMessage(ImMessage message) {
        // 1. 转换为业务 DO
        SystemImMessageDO messageDO = SystemImMessageDO.builder()
            .id(message.getHeader().getMessageId())
            .messageType(message.getHeader().getMessageType().getNumber())
            .senderId(message.getHeader().getSenderId())
            .receiverId(message.getHeader().getReceiverId())
            .tenantId(message.getHeader().getTenantId())
            .body(Base64.getEncoder().encodeToString(message.getBody().toByteArray()))
            .status(0) // 未读
            .build();
        
        // 2. 保存到数据库
        messageMapper.insert(messageDO);
        
        // 3. 更新会话（可选）
        updateConversation(messageDO);
        
        // 4. 更新未读数（可选）
        incrementUnreadCount(messageDO.getReceiverId());
    }
}
```

### 2.2 MessageCacheService（消息缓存）

**接口定义**：
```java
public interface MessageCacheService {
    void cacheUnreadCount(Long userId, long count);
    Long getCachedUnreadCount(Long userId);
    void removeCachedUnreadCount(Long userId);
    long incrementUnreadCount(Long userId, long delta);
}
```

**实现要求**：
- 业务模块可选实现（中间件提供空实现）
- 负责缓存热点数据，提升查询性能
- 可以根据业务需求设计缓存策略

**实现示例**（system 模块）：
```java
@Service
public class SystemMessageCacheServiceImpl implements MessageCacheService {
    
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    private static final String UNREAD_COUNT_KEY = "system:im:unread:";
    private static final Duration TTL = Duration.ofMinutes(30);
    
    @Override
    public void cacheUnreadCount(Long userId, long count) {
        String key = UNREAD_COUNT_KEY + userId;
        redisTemplate.opsForValue().set(key, count, TTL);
    }
    
    @Override
    public long incrementUnreadCount(Long userId, long delta) {
        String key = UNREAD_COUNT_KEY + userId;
        Long newCount = redisTemplate.opsForValue().increment(key, delta);
        redisTemplate.expire(key, TTL);
        return newCount != null ? newCount : 0;
    }
}
```

### 2.3 OfflinePushService（离线推送）

**接口定义**：
```java
public interface OfflinePushService {
    boolean pushOfflineMessage(Long userId, ImMessageDO message);
    boolean pushUnreadCount(Long userId, long count);
    boolean pushSystemNotify(Long userId, String title, String content);
    // ... 其他方法
}
```

**实现要求**：
- 业务模块根据需要实现
- 负责集成第三方推送平台（极光推送、个推等）
- 负责推送策略和推送模板管理

## 三、数据库设计

### 3.1 表结构设计

业务模块需要自己设计表结构，以下是参考示例：

**system 模块**（租户端）：
```sql
-- 消息表
CREATE TABLE system_im_message (
    id BIGINT PRIMARY KEY COMMENT '消息ID',
    message_type INT NOT NULL COMMENT '消息类型',
    sender_id BIGINT NOT NULL COMMENT '发送者ID',
    receiver_id BIGINT COMMENT '接收者ID',
    group_id BIGINT COMMENT '群组ID',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    body TEXT COMMENT '消息体（Protobuf Base64）',
    status INT DEFAULT 0 COMMENT '状态（0-未读 1-已读 2-已撤回）',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_receiver_status (receiver_id, status),
    INDEX idx_tenant (tenant_id)
) COMMENT='租户端消息表';

-- 会话表
CREATE TABLE system_im_conversation (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    target_id BIGINT NOT NULL COMMENT '对方ID',
    conversation_type INT COMMENT '会话类型（1-单聊 2-群聊）',
    unread_count INT DEFAULT 0 COMMENT '未读数',
    last_message_id BIGINT COMMENT '最后一条消息ID',
    last_message_time DATETIME COMMENT '最后消息时间',
    tenant_id BIGINT NOT NULL,
    UNIQUE KEY uk_user_target (user_id, target_id, conversation_type),
    INDEX idx_tenant (tenant_id)
) COMMENT='租户端会话表';
```

**platform 模块**（平台端）：
```sql
-- 消息表
CREATE TABLE platform_im_message (
    id BIGINT PRIMARY KEY COMMENT '消息ID',
    message_type INT NOT NULL COMMENT '消息类型',
    sender_id BIGINT NOT NULL COMMENT '发送者ID',
    receiver_id BIGINT COMMENT '接收者ID',
    body TEXT COMMENT '消息体（Protobuf Base64）',
    status INT DEFAULT 0 COMMENT '状态',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_receiver_status (receiver_id, status)
) COMMENT='平台端消息表';

-- 会话表
CREATE TABLE platform_im_conversation (
    id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    target_id BIGINT NOT NULL COMMENT '对方ID',
    conversation_type INT COMMENT '会话类型',
    unread_count INT DEFAULT 0 COMMENT '未读数',
    last_message_id BIGINT COMMENT '最后一条消息ID',
    last_message_time DATETIME COMMENT '最后消息时间',
    UNIQUE KEY uk_user_target (user_id, target_id, conversation_type)
) COMMENT='平台端会话表';
```

### 3.2 表结构差异

不同业务模块可以有不同的表结构：

| 字段 | system 模块 | platform 模块 | 说明 |
|------|------------|--------------|------|
| tenant_id | ✅ 必须 | ❌ 不需要 | 租户隔离 |
| group_id | ✅ 支持 | ❌ 不支持 | 群组功能 |
| 索引策略 | 按租户分区 | 全局索引 | 性能优化 |

## 四、业务模块集成步骤

### 4.1 添加依赖

```xml
<dependency>
    <groupId>com.shengyu.boot</groupId>
    <artifactId>shengyu-spring-boot-starter-websocket</artifactId>
</dependency>
```

### 4.2 创建数据库表

根据业务需求创建表结构（参考上面的示例）。

### 4.3 创建 DO 对象

```java
@TableName("system_im_message")
@Data
public class SystemImMessageDO extends BaseDO {
    @TableId(type = IdType.INPUT)
    private Long id;
    private Integer messageType;
    private Long senderId;
    private Long receiverId;
    private Long tenantId;
    private String body;
    private Integer status;
}
```

### 4.4 创建 Mapper

```java
@Mapper
public interface SystemImMessageMapper extends BaseMapperX<SystemImMessageDO> {
}
```

### 4.5 实现 SPI 接口

```java
@Service
public class SystemMessageStorageServiceImpl implements MessageStorageService {
    
    @Autowired
    private SystemImMessageMapper messageMapper;
    
    @Override
    public void saveMessage(ImMessage message) {
        // 实现存储逻辑
    }
}
```

### 4.6 配置文件

```yaml
shengyu:
  netty:
    enable: true
    port: 9000
    worker-threads: 16
```

### 4.7 启动应用

启动后，中间件会自动：
1. 启动 Netty 服务器
2. 注册消息处理器
3. 使用业务模块提供的 MessageStorageService 实现

## 五、消息流程

### 5.1 消息发送流程

```
客户端
  │
  │ 1. 发送消息（WebSocket/Protobuf）
  ▼
中间件（Netty）
  │
  │ 2. 协议解析
  ▼
中间件（MessageProcessor）
  │
  │ 3. 调用 MessageStorageService.saveMessage()
  ▼
业务模块（SystemMessageStorageServiceImpl）
  │
  │ 4. 转换为 DO 对象
  │ 5. 保存到数据库（system_im_message）
  │ 6. 更新会话（system_im_conversation）
  │ 7. 更新未读数（Redis）
  ▼
中间件（MessageProcessor）
  │
  │ 8. 转发给接收者
  ▼
接收者客户端
```

### 5.2 消息接收流程

```
中间件（Netty）
  │
  │ 1. 检查接收者是否在线
  ▼
在线？
  │
  ├─ 是 ──▶ 直接推送消息
  │
  └─ 否 ──▶ 业务模块处理离线推送
              │
              ▼
          OfflinePushService.pushOfflineMessage()
```

## 六、优势总结

### 6.1 架构优势

✅ **职责清晰**：中间件只负责底层能力，业务逻辑由业务模块实现  
✅ **灵活扩展**：不同业务模块可以有不同的实现策略  
✅ **独立演进**：中间件和业务模块可以独立升级  
✅ **多租户支持**：system 和 platform 可以有不同的表结构和业务逻辑  

### 6.2 技术优势

✅ **高性能**：Netty + Protobuf + Redis 缓存  
✅ **高可用**：支持集群部署、负载均衡  
✅ **易维护**：代码分层清晰，职责单一  
✅ **易测试**：接口驱动，便于单元测试  

### 6.3 业务优势

✅ **业务自主**：业务模块完全控制数据存储和业务逻辑  
✅ **灵活定制**：可以根据业务需求定制功能  
✅ **数据隔离**：不同业务模块的数据完全隔离  
✅ **安全可控**：业务数据不经过中间件，更安全  

## 七、注意事项

### 7.1 必须实现的接口

- ✅ **MessageStorageService**：必须实现，否则消息不会被持久化

### 7.2 可选实现的接口

- ⚪ **MessageCacheService**：可选，不实现则使用空实现（NoOp）
- ⚪ **OfflinePushService**：可选，不实现则不支持离线推送

### 7.3 性能优化建议

1. **数据库优化**：
   - 按租户分表
   - 按时间分表
   - 添加合适的索引

2. **缓存优化**：
   - 缓存热点数据
   - 设置合理的过期时间
   - 使用 Redis 集群

3. **消息优化**：
   - 使用 Protobuf 减少带宽
   - 批量操作减少数据库压力
   - 异步处理耗时操作

---

**更新时间**：2026年1月27日  
**版本**：v1.0.0  
**作者**：圣钰科技
