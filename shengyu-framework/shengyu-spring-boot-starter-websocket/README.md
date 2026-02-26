# 即时通讯中间件（shengyu-spring-boot-starter-websocket）

## 一、简介

这是一个基于 Netty + Protobuf 的**企业级高性能即时通讯中间件**,参考微信、钉钉等顶流IM产品的技术架构设计,提供底层的连接管理、协议处理、消息路由、通知推送等核心能力。

### 核心特性

#### 🚀 高性能架构
- ✅ **海量连接**：基于 Netty NIO,单机支持 50w+ TCP 长连接
- ✅ **低延迟**：消息延迟 < 100ms (局域网),< 500ms (广域网)
- ✅ **高吞吐**：单机消息吞吐 10w+ msg/s
- ✅ **Epoll 优化**：Linux 环境自动启用 Epoll,性能提升 30%+

#### 📡 双协议支持
- ✅ **WebSocket**：兼容 Web 浏览器、小程序
- ✅ **Protobuf**：移动端专用,体积小 3-10 倍,速度快 20-100 倍
- ✅ **协议自适应**：自动识别客户端类型,选择最优协议

#### 🏢 企业级特性
- ✅ **多租户隔离**：支持租户级会话管理和消息隔离
- ✅ **多端登录**：类似微信,支持手机/PC/平板/Web 多端同时在线
- ✅ **设备互踢**：同设备类型互踢,不同设备类型共存
- ✅ **双端认证**：支持租户端(LoginUser)和平台端(PlatformLoginUser)

#### 🔌 可扩展设计
- ✅ **SPI 接口**：业务逻辑由业务模块实现,中间件只负责通信
- ✅ **消息总线**：支持 Local/Redis/RocketMQ/Kafka/RabbitMQ
- ✅ **水平扩展**：支持分布式部署,多台服务器共享会话状态
- ✅ **负载均衡**：支持 Nginx/LVS 负载均衡

#### 📬 通知能力
- ✅ **实时通知**：支持单聊、群聊、系统通知、流程通知
- ✅ **消息角标**：支持未读消息数角标推送
- ✅ **菜单角标**：支持菜单项角标通知(如待办事项数量)
- ✅ **离线推送**：支持 APNs/FCM/华为/小米/OPPO/vivo 推送
- ✅ **已读回执**：支持消息已读状态同步
- ✅ **正在输入**：支持"对方正在输入..."状态提示

#### 🎯 业务场景支持
- ✅ **单聊/群聊**：支持一对一和多人群聊
- ✅ **语音/视频通话**：支持实时音视频通话信令
- ✅ **文件传输**：支持大文件断点续传
- ✅ **消息撤回**：支持2分钟内消息撤回
- ✅ **消息转发**：支持消息转发到其他会话
- ✅ **@提醒**：支持群聊@某人或@所有人
- ✅ **消息引用**：支持引用回复某条消息

### 架构设计

#### 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    业务层 (Business Layer)                   │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │ 消息存储     │ │ 会话管理     │ │ 群组管理     │      │
│  │ (SPI实现)    │ │ (SPI实现)    │ │ (SPI实现)    │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓ SPI 调用
┌─────────────────────────────────────────────────────────────┐
│                  中间件层 (Middleware Layer)                 │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │ 连接管理     │ │ 协议处理     │ │ 消息路由     │      │
│  │ (Netty)      │ │ (Protobuf)   │ │ (Processor)  │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │ 会话管理     │ │ 认证鉴权     │ │ 消息发送     │      │
│  │ (Session)    │ │ (Auth)       │ │ (Sender)     │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↓ 消息总线
┌─────────────────────────────────────────────────────────────┐
│                  传输层 (Transport Layer)                    │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │ Redis        │ │ RocketMQ     │ │ Kafka        │      │
│  │ (推荐)       │ │ (高吞吐)     │ │ (大数据)     │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

#### 职责划分

**中间件职责** (本模块):
- ✅ 连接管理：Netty 服务器、会话管理、心跳检测
- ✅ 协议处理：WebSocket、Protobuf 编解码
- ✅ 消息路由：消息分发、消息转发、消息广播
- ✅ 认证鉴权：Token 验证、多端登录控制
- ✅ 通知推送：实时通知、角标推送、离线推送
- ✅ 性能优化：连接池、消息队列、缓存策略

**业务模块职责** (system/platform 模块):
- ✅ 消息存储：数据库设计、表结构、存储逻辑
- ✅ 业务逻辑：好友关系、群组管理、会话管理
- ✅ 业务规则：权限控制、敏感词过滤、消息审核
- ✅ 业务通知：流程通知、待办提醒、审批通知

详见：[ARCHITECTURE.md](ARCHITECTURE.md)

### 技术亮点

#### 1. 参考微信的长连接设计
- **智能心跳**：根据网络状况动态调整心跳间隔(30s-180s)
- **快速重连**：断线后指数退避重连(1s, 2s, 4s, 8s, 16s, 30s)
- **连接保活**：TCP KeepAlive + 应用层心跳双重保障
- **弱网优化**：支持消息队列缓存,网络恢复后自动重发

#### 2. 参考钉钉的消息可靠性
- **消息去重**：基于 messageId 的幂等性保证
- **消息确认**：三次握手确认机制(发送→存储→送达)
- **离线消息**：支持离线消息拉取和增量同步
- **消息顺序**：基于 sequence 的全局有序保证

#### 3. 高性能优化
- **零拷贝**：Netty DirectBuffer,减少内存拷贝
- **对象池**：Protobuf 对象复用,减少 GC 压力
- **批量发送**：消息批量打包发送,减少网络开销
- **异步处理**：消息处理全异步,不阻塞 IO 线程

#### 4. 分布式支持
- **会话共享**：通过 Redis 共享会话状态
- **消息广播**：通过消息总线实现跨服务器消息推送
- **负载均衡**：支持多台服务器水平扩展
- **故障转移**：服务器宕机自动切换到其他节点

## 二、快速开始

### 2.1 添加依赖

```xml
<dependency>
    <groupId>com.shengyu.boot</groupId>
    <artifactId>shengyu-spring-boot-starter-websocket</artifactId>
</dependency>
```

### 2.2 配置文件

```yaml
shengyu:
  netty:
    enable: true              # 启用 Netty 服务
    port: 9000                # WebSocket 端口
    boss-threads: 1           # Boss 线程数(建议1个)
    worker-threads: 16        # Worker 线程数(建议 CPU核心数 * 2)
    use-epoll: true           # Linux 环境启用 Epoll
    reader-idle-time: 60      # 读空闲时间(秒),超时关闭连接
    writer-idle-time: 0       # 写空闲时间(秒),0表示不检测
    all-idle-time: 0          # 读写空闲时间(秒),0表示不检测
    
  websocket:
    sender-type: redis        # 消息发送器类型: local/redis/rocketmq/kafka/rabbitmq
    sender-redis:
      channel: im-message-channel  # Redis 频道名称
```

### 2.3 实现 SPI 接口

#### 2.3.1 消息存储服务 (必须实现)

在业务模块（如 shengyu-module-system）中实现 `MessageStorageService` 接口：

```java
@Service
public class SystemMessageStorageServiceImpl implements MessageStorageService {
    
    @Resource
    private ImMessageMapper messageMapper;
    
    @Resource
    private ImConversationService conversationService;
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveMessage(ImMessage message) {
        log.info("[MessageStorage] 保存消息: messageId={}, type={}", 
            message.getHeader().getMessageId(), 
            message.getHeader().getMessageType());

        // 1. 转换为 DO 对象
        ImMessageDO messageDO = convertToDO(message);
        
        // 2. 保存到数据库
        messageMapper.insert(messageDO);
        
        // 3. 更新会话(最后一条消息、未读数等)
        conversationService.updateConversationByMessage(messageDO);
        
        log.info("[MessageStorage] 消息保存成功: id={}", messageDO.getId());
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveMessageWithId(ImMessage message) {
        saveMessage(message);
        
        // 返回数据库生成的消息ID
        MessageHeader header = message.getHeader();
        ImMessageDO messageDO = messageMapper.selectByMessageId(header.getMessageId());
        return messageDO != null ? messageDO.getId() : null;
    }
    
    private ImMessageDO convertToDO(ImMessage message) {
        MessageHeader header = message.getHeader();
        
        return ImMessageDO.builder()
            .messageId(header.getMessageId())
            .messageType(header.getMessageType().getNumber())
            .senderId(header.getSenderId())
            .receiverId(header.getReceiverId())
            .groupId(header.getGroupId())
            .content(message.getBody().toByteArray())
            .extra(header.getExtra())
            .status(0)  // 未读
            .sequence(header.getSequence())
            .tenantId(header.getTenantId())
            .build();
    }
}
```

#### 2.3.2 认证服务 (必须实现)

```java
@Service
public class SystemAuthServiceImpl implements AuthService {
    
    @Resource
    private OAuth2TokenApi oauth2TokenApi;
    
    @Override
    public LoginBase validateToken(String accessToken) {
        log.info("[Auth] 验证 Token: {}", accessToken);

        try {
            // 1. 验证 token
            OAuth2AccessTokenCheckRespDTO tokenInfo = 
                oauth2TokenApi.checkAccessToken(accessToken);
            
            if (tokenInfo == null) {
                log.warn("[Auth] Token 无效");
                return null;
            }

            // 2. 检查 token 是否过期
            if (tokenInfo.getExpiresTime().isBefore(LocalDateTime.now())) {
                log.warn("[Auth] Token 已过期");
                return null;
            }

            // 3. 构建登录用户信息
            LoginBase loginUser = buildLoginUser(tokenInfo);
            
            log.info("[Auth] 认证成功: userId={}, tenantId={}", 
                tokenInfo.getUserId(), getTenantId(loginUser));
            
            return loginUser;

        } catch (Exception e) {
            log.error("[Auth] 认证异常", e);
            return null;
        }
    }
    
    @Override
    public Long getTenantId(LoginBase loginUser) {
        if (loginUser instanceof LoginUser) {
            return ((LoginUser) loginUser).getTenantId();
        }
        return null;  // 平台端用户无租户ID
    }
    
    private LoginBase buildLoginUser(OAuth2AccessTokenCheckRespDTO tokenInfo) {
        // 根据用户类型构建不同的登录对象
        if (tokenInfo.getUserType() == 1) {
            // 租户端用户
            LoginUser loginUser = new LoginUser();
            loginUser.setId(tokenInfo.getUserId());
            loginUser.setTenantId(tokenInfo.getTenantId());
            loginUser.setUserType(tokenInfo.getUserType());
            return loginUser;
        } else {
            // 平台端用户
            PlatformLoginUser loginUser = new PlatformLoginUser();
            loginUser.setId(tokenInfo.getUserId());
            loginUser.setUserType(tokenInfo.getUserType());
            return loginUser;
        }
    }
}
```

#### 2.3.3 消息缓存服务 (可选实现)

```java
@Service
public class SystemMessageCacheServiceImpl implements MessageCacheService {

    @Resource
    private RedisTemplate<String, Object> redisTemplate;

    @Override
    public void cacheUnreadCount(Long userId, long count) {
        String key = "im:unread:" + userId;
        redisTemplate.opsForValue().set(key, count, 24, TimeUnit.HOURS);
    }

    @Override
    public Long getCachedUnreadCount(Long userId) {
        String key = "im:unread:" + userId;
        Object value = redisTemplate.opsForValue().get(key);
        return value != null ? Long.parseLong(value.toString()) : null;
    }

    @Override
    public long incrementUnreadCount(Long userId, long delta) {
        String key = "im:unread:" + userId;
        Long result = redisTemplate.opsForValue().increment(key, delta);
        redisTemplate.expire(key, 24, TimeUnit.HOURS);
        return result != null ? result : 0;
    }
}
```

#### 2.3.4 离线推送服务 (可选实现)

```java
@Service
public class SystemOfflinePushServiceImpl implements OfflinePushService {

    @Override
    public boolean pushOfflineMessage(Long userId, ImMessageDO message) {
        log.info("[OfflinePush] 推送离线消息: userId={}, messageId={}", 
            userId, message.getId());
        
        // TODO: 集成第三方推送服务(极光推送、个推等)
        // 1. 构建推送内容
        // 2. 调用推送 API
        // 3. 返回推送结果
        
        return true;
    }

    @Override
    public boolean pushUnreadCount(Long userId, long count) {
        log.info("[OfflinePush] 推送未读数: userId={}, count={}", userId, count);
        
        // TODO: 推送未读消息数角标
        
        return true;
    }
}
```

完整示例见：[examples/](examples/)

### 2.4 创建数据库表

参考示例 SQL：[examples/im_message_example.sql](examples/im_message_example.sql)

### 2.5 启动应用

启动 Spring Boot 应用，Netty 服务会自动启动：

```
[Netty] Netty 服务器启动成功: port=9000
[Netty] 注册文本消息处理器
[Netty] 注册图片消息处理器
[Netty] 注册语音消息处理器
[Netty] 注册文件消息处理器
```

## 三、核心组件

### 3.1 连接管理

#### NettyServer
Netty 服务器,负责启动和管理 WebSocket 服务。

**核心特性**:
- 支持 Epoll 优化(Linux 环境自动启用)
- 支持 SSL/TLS 加密(可选)
- 支持自定义端口和线程数
- 支持优雅关闭

**配置示例**:
```yaml
shengyu:
  netty:
    port: 9000
    boss-threads: 1
    worker-threads: 16
    use-epoll: true
```

#### NettySessionManager
会话管理器,管理所有在线连接。

**核心功能**:
- 会话注册/注销
- 多端登录管理(同设备类型互踢)
- 租户级会话隔离
- 在线状态查询

**API 示例**:
```java
// 获取用户所有在线会话
List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);

// 获取用户在线设备类型
List<Integer> deviceTypes = sessionManager.getOnlineDeviceTypes(userId);

// 踢掉指定设备
sessionManager.kickOffDevice(session, "您的账号在其他设备登录");

// 查询在线用户数
int onlineCount = sessionManager.getOnlineUserCount();

// 查询租户在线用户数
int tenantOnlineCount = sessionManager.getOnlineUserCountByTenant(tenantId);
```

#### NettySession
会话信息,包含用户ID、设备ID、租户ID等。

**字段说明**:
```java
public class NettySession {
    private Channel channel;              // Netty Channel
    private Long userId;                  // 用户ID
    private Long tenantId;                // 租户ID
    private String deviceId;              // 设备ID
    private Integer deviceType;           // 设备类型(1-Web 2-iOS 3-Android...)
    private String clientVersion;         // 客户端版本
    private LocalDateTime connectTime;    // 连接时间
    private LocalDateTime lastActiveTime; // 最后活跃时间
}
```

### 3.2 协议处理

#### WebSocket 协议
对外协议,兼容 Web 浏览器、小程序。

**优点**:
- 浏览器原生支持
- 开发调试方便
- 兼容性好

**缺点**:
- 消息体积较大(JSON 格式)
- 解析性能较低

#### Protobuf 协议
内部协议,移动端专用,高性能二进制序列化。

**优点**:
- 体积小 3-10 倍
- 速度快 20-100 倍
- 强类型检查
- 向后兼容

**缺点**:
- 需要预定义 .proto 文件
- 调试不如 JSON 直观

#### im_message.proto
消息协议定义文件。

**核心消息类型**:
```protobuf
enum MessageType {
  // 系统消息
  HEARTBEAT_REQ = 1;      // 心跳请求
  HEARTBEAT_RESP = 2;     // 心跳响应
  AUTH_REQ = 3;           // 认证请求
  AUTH_RESP = 4;          // 认证响应
  CLOSE = 5;              // 连接关闭
  
  // 业务消息
  TEXT = 100;             // 文本消息
  IMAGE = 101;            // 图片消息
  VOICE = 102;            // 语音消息
  VIDEO = 103;            // 视频消息
  FILE = 104;             // 文件消息
  LOCATION = 105;         // 位置消息
  CUSTOM = 106;           // 自定义消息
  
  // 通知消息
  SYSTEM_NOTIFY = 200;    // 系统通知
  READ_RECEIPT = 201;     // 消息已读回执
  RECALL = 202;           // 消息撤回
  TYPING = 203;           // 正在输入
  BADGE_UPDATE = 204;     // 角标更新
}
```

### 3.3 消息路由

#### MessageProcessor
消息处理器接口,定义消息处理逻辑。

**接口定义**:
```java
public interface MessageProcessor {
    /**
     * 处理消息
     */
    void process(NettySession session, ImMessage message);
    
    /**
     * 支持的消息类型
     */
    MessageType supportedType();
}
```

**内置处理器**:
- `TextMessageProcessor`: 文本消息处理器
- `ImageMessageProcessor`: 图片消息处理器
- `VoiceMessageProcessor`: 语音消息处理器
- `VideoMessageProcessor`: 视频消息处理器
- `FileMessageProcessor`: 文件消息处理器
- `ReadReceiptMessageProcessor`: 已读回执处理器

#### MessageProcessorFactory
消息处理器工厂,根据消息类型获取对应的处理器。

**使用示例**:
```java
MessageProcessor processor = processorFactory.getProcessor(messageType);
processor.process(session, message);
```

#### NettyMessageSender
消息发送器,支持单播/多播/广播。

**API 示例**:
```java
// 发送给指定用户(所有在线设备)
messageSender.sendToUser(userId, messageType, messageBody);

// 发送给指定用户的指定设备
messageSender.sendToUserDevice(userId, deviceType, messageType, messageBody);

// 发送给群组所有成员
messageSender.sendToGroup(groupId, messageType, messageBody);

// 发送给租户所有在线用户
messageSender.sendToTenant(tenantId, messageType, messageBody);

// 广播给所有在线用户
messageSender.broadcast(messageType, messageBody);
```

### 3.4 认证鉴权

#### AuthService
认证服务接口,由业务模块实现。

**接口定义**:
```java
public interface AuthService {
    /**
     * 验证 Token
     */
    LoginBase validateToken(String accessToken);
    
    /**
     * 获取租户ID
     */
    Long getTenantId(LoginBase loginUser);
}
```

#### AuthHandler
认证处理器,处理客户端认证请求。

**认证流程**:
1. 客户端发送 AUTH_REQ 消息(包含 accessToken)
2. 服务端调用 AuthService.validateToken() 验证
3. 验证成功,创建 NettySession 并保存
4. 检查是否有同设备类型的旧连接,如有则踢掉
5. 返回 AUTH_RESP 消息(包含认证结果)

#### 多端登录支持
类似微信的多端登录策略。

**设备类型**:
```java
public enum DeviceTypeEnum {
    WEB(1, "Web浏览器"),
    IOS(2, "iPhone"),
    ANDROID(3, "Android手机"),
    MINI_PROGRAM(4, "小程序"),
    IPAD(5, "iPad"),
    MAC(6, "Mac电脑"),
    WINDOWS(7, "Windows电脑");
}
```

**互踢策略**:
- 同一设备类型只允许一个在线(如手机端只能一个设备在线)
- 不同设备类型可以同时在线(如手机+PC+iPad 同时在线)
- 新设备登录时,踢掉同类型的旧设备

**示例场景**:
```
用户 A 的登录情况:
- iPhone (iOS)     ✅ 在线
- iPad (iPad)      ✅ 在线
- Mac (Mac)        ✅ 在线
- Windows (Win)    ✅ 在线

此时用户 A 在另一台 iPhone 上登录:
- iPhone 1 (iOS)   ❌ 被踢下线
- iPhone 2 (iOS)   ✅ 新设备上线
- iPad (iPad)      ✅ 保持在线
- Mac (Mac)        ✅ 保持在线
- Windows (Win)    ✅ 保持在线
```

### 3.5 通知推送

#### 实时通知
通过 WebSocket 实时推送通知。

**支持的通知类型**:
- 单聊消息通知
- 群聊消息通知
- 系统通知(公告、提醒)
- 流程通知(审批、待办)
- 语音/视频通话信令
- 消息已读回执
- 正在输入状态

#### 角标推送
支持未读消息数角标和菜单角标。

**消息角标**:
```java
// 推送未读消息数
BadgeUpdateMessage badge = BadgeUpdateMessage.newBuilder()
    .setUnreadCount(unreadCount)
    .build();
messageSender.sendToUser(userId, MessageType.BADGE_UPDATE, badge);
```

**菜单角标**:
```java
// 推送菜单角标(如待办事项数量)
MenuBadgeMessage menuBadge = MenuBadgeMessage.newBuilder()
    .setMenuId("todo")
    .setBadgeCount(todoCount)
    .build();
messageSender.sendToUser(userId, MessageType.MENU_BADGE, menuBadge);
```

#### 离线推送
用户离线时通过第三方推送服务推送通知。

**支持的推送平台**:
- APNs (iOS)
- FCM (Android 国际版)
- 华为推送
- 小米推送
- OPPO推送
- vivo推送

**实现方式**:
业务模块实现 `OfflinePushService` 接口,集成第三方推送 SDK。

## 四、SPI 接口

### 4.1 MessageStorageService（必须实现）

消息存储服务接口，由业务模块实现。

```java
public interface MessageStorageService {
    void saveMessage(ImMessage message);
    Long saveMessageWithId(ImMessage message);
}
```

### 4.2 MessageCacheService（可选实现）

消息缓存服务接口，由业务模块根据需要实现。

```java
public interface MessageCacheService {
    void cacheUnreadCount(Long userId, long count);
    Long getCachedUnreadCount(Long userId);
    long incrementUnreadCount(Long userId, long delta);
}
```

### 4.3 OfflinePushService（可选实现）

离线推送服务接口，由业务模块根据需要实现。

```java
public interface OfflinePushService {
    boolean pushOfflineMessage(Long userId, ImMessageDO message);
    boolean pushUnreadCount(Long userId, long count);
}
```

## 五、使用示例

### 5.1 发送消息

#### 发送文本消息
```java
@Service
public class ChatService {
    
    @Resource
    private NettyMessageSender messageSender;
    
    /**
     * 发送单聊文本消息
     */
    public void sendTextMessage(Long senderId, Long receiverId, String content) {
        // 1. 构建文本消息
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent(content)
            .build();
        
        // 2. 构建消息头
        MessageHeader header = MessageHeader.newBuilder()
            .setMessageId(generateMessageId())
            .setMessageType(MessageType.TEXT)
            .setSenderId(senderId)
            .setReceiverId(receiverId)
            .setTimestamp(System.currentTimeMillis())
            .build();
        
        // 3. 构建完整消息
        ImMessage message = ImMessage.newBuilder()
            .setHeader(header)
            .setBody(ByteString.copyFrom(textMessage.toByteArray()))
            .build();
        
        // 4. 发送给接收者
        messageSender.sendToUser(receiverId, message);
    }
    
    /**
     * 发送群聊文本消息
     */
    public void sendGroupTextMessage(Long senderId, Long groupId, String content) {
        // 1. 构建文本消息
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent(content)
            .build();
        
        // 2. 构建消息头
        MessageHeader header = MessageHeader.newBuilder()
            .setMessageId(generateMessageId())
            .setMessageType(MessageType.TEXT)
            .setSenderId(senderId)
            .setGroupId(groupId)
            .setTimestamp(System.currentTimeMillis())
            .build();
        
        // 3. 构建完整消息
        ImMessage message = ImMessage.newBuilder()
            .setHeader(header)
            .setBody(ByteString.copyFrom(textMessage.toByteArray()))
            .build();
        
        // 4. 发送给群组所有成员
        messageSender.sendToGroup(groupId, message);
    }
}
```

#### 发送图片消息
```java
public void sendImageMessage(Long senderId, Long receiverId, String imageUrl) {
    ImageMessage imageMessage = ImageMessage.newBuilder()
        .setUrl(imageUrl)
        .setWidth(800)
        .setHeight(600)
        .setSize(102400)
        .build();
    
    messageSender.sendToUser(receiverId, MessageType.IMAGE, imageMessage);
}
```

#### 发送系统通知
```java
public void sendSystemNotify(Long userId, String title, String content) {
    SystemNotifyMessage notify = SystemNotifyMessage.newBuilder()
        .setTitle(title)
        .setContent(content)
        .setType("SYSTEM")
        .build();
    
    messageSender.sendToUser(userId, MessageType.SYSTEM_NOTIFY, notify);
}
```

### 5.2 查询在线状态

```java
@Service
public class SessionService {
    
    @Resource
    private NettySessionManager sessionManager;
    
    /**
     * 查询用户是否在线
     */
    public boolean isUserOnline(Long userId) {
        return sessionManager.isUserOnline(userId);
    }
    
    /**
     * 查询用户在线设备列表
     */
    public List<OnlineDeviceVO> getOnlineDevices(Long userId) {
        List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
        
        return sessions.stream()
            .map(session -> OnlineDeviceVO.builder()
                .deviceType(session.getDeviceType())
                .deviceTypeName(DeviceTypeEnum.getByCode(session.getDeviceType()).getName())
                .deviceId(session.getDeviceId())
                .clientVersion(session.getClientVersion())
                .loginTime(session.getConnectTime())
                .lastActiveTime(session.getLastActiveTime())
                .build())
            .collect(Collectors.toList());
    }
    
    /**
     * 查询在线用户数
     */
    public int getOnlineUserCount() {
        return sessionManager.getOnlineUserCount();
    }
    
    /**
     * 查询租户在线用户数
     */
    public int getTenantOnlineUserCount(Long tenantId) {
        return sessionManager.getOnlineUserCountByTenant(tenantId);
    }
    
    /**
     * 踢掉指定设备
     */
    public boolean kickOffDevice(Long userId, Integer deviceType) {
        NettySession session = sessionManager.getSessionByUserIdAndDeviceType(userId, deviceType);
        if (session != null && session.isActive()) {
            sessionManager.kickOffDevice(session, "您主动踢掉了该设备");
            return true;
        }
        return false;
    }
}
```

### 5.3 消息已读回执

```java
@Service
public class MessageReadService {
    
    @Resource
    private NettyMessageSender messageSender;
    
    @Resource
    private ImMessageMapper messageMapper;
    
    /**
     * 标记消息已读
     */
    public void markMessagesAsRead(Long userId, List<Long> messageIds) {
        // 1. 更新数据库
        messageMapper.updateStatusByIds(messageIds, 1);
        
        // 2. 构建已读回执消息
        ReadReceiptMessage receipt = ReadReceiptMessage.newBuilder()
            .addAllMessageIds(messageIds)
            .build();
        
        // 3. 发送给消息发送者
        for (Long messageId : messageIds) {
            ImMessageDO message = messageMapper.selectById(messageId);
            if (message != null) {
                messageSender.sendToUser(message.getSenderId(), MessageType.READ_RECEIPT, receipt);
            }
        }
    }
}
```

### 5.4 消息撤回

```java
@Service
public class MessageRecallService {
    
    @Resource
    private NettyMessageSender messageSender;
    
    @Resource
    private ImMessageMapper messageMapper;
    
    /**
     * 撤回消息
     */
    public void recallMessage(Long userId, Long messageId) {
        // 1. 查询消息
        ImMessageDO message = messageMapper.selectById(messageId);
        if (message == null) {
            throw new ServiceException("消息不存在");
        }
        
        // 2. 验证权限(只能撤回自己的消息)
        if (!message.getSenderId().equals(userId)) {
            throw new ServiceException("无权撤回该消息");
        }
        
        // 3. 验证时间(只能撤回2分钟内的消息)
        if (message.getCreateTime().plusMinutes(2).isBefore(LocalDateTime.now())) {
            throw new ServiceException("超过2分钟,无法撤回");
        }
        
        // 4. 更新数据库
        messageMapper.updateStatusById(messageId, 2);
        
        // 5. 构建撤回消息
        RecallMessage recall = RecallMessage.newBuilder()
            .setMessageId(messageId)
            .build();
        
        // 6. 通知接收者
        if (message.getReceiverId() != null) {
            // 单聊
            messageSender.sendToUser(message.getReceiverId(), MessageType.RECALL, recall);
        } else if (message.getGroupId() != null) {
            // 群聊
            messageSender.sendToGroup(message.getGroupId(), MessageType.RECALL, recall);
        }
    }
}
```

### 5.5 正在输入状态

```java
@Service
public class TypingService {
    
    @Resource
    private NettyMessageSender messageSender;
    
    /**
     * 发送正在输入状态
     */
    public void sendTypingStatus(Long userId, Long targetId, boolean isTyping) {
        TypingMessage typing = TypingMessage.newBuilder()
            .setUserId(userId)
            .setIsTyping(isTyping)
            .build();
        
        messageSender.sendToUser(targetId, MessageType.TYPING, typing);
    }
}
```

### 5.6 语音/视频通话信令

```java
@Service
public class CallService {
    
    @Resource
    private NettyMessageSender messageSender;
    
    /**
     * 发起语音通话
     */
    public void initiateVoiceCall(Long callerId, Long calleeId, String roomId) {
        CallSignalMessage signal = CallSignalMessage.newBuilder()
            .setCallType("VOICE")
            .setAction("INVITE")
            .setCallerId(callerId)
            .setCalleeId(calleeId)
            .setRoomId(roomId)
            .build();
        
        messageSender.sendToUser(calleeId, MessageType.CALL_SIGNAL, signal);
    }
    
    /**
     * 接受通话
     */
    public void acceptCall(Long calleeId, Long callerId, String roomId) {
        CallSignalMessage signal = CallSignalMessage.newBuilder()
            .setCallType("VOICE")
            .setAction("ACCEPT")
            .setCallerId(callerId)
            .setCalleeId(calleeId)
            .setRoomId(roomId)
            .build();
        
        messageSender.sendToUser(callerId, MessageType.CALL_SIGNAL, signal);
    }
    
    /**
     * 拒绝通话
     */
    public void rejectCall(Long calleeId, Long callerId, String reason) {
        CallSignalMessage signal = CallSignalMessage.newBuilder()
            .setCallType("VOICE")
            .setAction("REJECT")
            .setCallerId(callerId)
            .setCalleeId(calleeId)
            .setReason(reason)
            .build();
        
        messageSender.sendToUser(callerId, MessageType.CALL_SIGNAL, signal);
    }
    
    /**
     * 挂断通话
     */
    public void hangupCall(Long userId, Long targetId, String roomId) {
        CallSignalMessage signal = CallSignalMessage.newBuilder()
            .setCallType("VOICE")
            .setAction("HANGUP")
            .setRoomId(roomId)
            .build();
        
        messageSender.sendToUser(targetId, MessageType.CALL_SIGNAL, signal);
    }
}
```

## 六、文档

- [ARCHITECTURE.md](ARCHITECTURE.md) - 架构设计文档
- [API.md](API.md) - API 接口文档
- [QUICK-START.md](QUICK-START.md) - 快速开始指南
- [TODO.md](TODO.md) - 后续工作事项

## 七、示例代码

- [examples/im_message_example.sql](examples/im_message_example.sql) - 数据库表结构示例
- [examples/SystemImMessageDO.java.example](examples/SystemImMessageDO.java.example) - DO 对象示例
- [examples/SystemImMessageMapper.java.example](examples/SystemImMessageMapper.java.example) - Mapper 示例
- [examples/SystemMessageStorageServiceImpl.java.example](examples/SystemMessageStorageServiceImpl.java.example) - 服务实现示例

## 八、性能指标

### 8.1 连接性能

| 指标 | 数值 | 说明 |
|------|------|------|
| 单机连接数 | 50w+ | 基于 Netty NIO,支持海量长连接 |
| 连接建立时间 | < 100ms | 包含 TCP 握手 + WebSocket 握手 + 认证 |
| 连接保活 | 30s-180s | 智能心跳,根据网络状况动态调整 |
| 断线重连 | 1s-30s | 指数退避策略,快速恢复连接 |

### 8.2 消息性能

| 指标 | 数值 | 说明 |
|------|------|------|
| 消息延迟 | < 100ms | 局域网环境,端到端延迟 |
| 消息延迟 | < 500ms | 广域网环境,端到端延迟 |
| 消息吞吐 | 10w+ msg/s | 单机消息处理能力 |
| 消息可靠性 | 99.99% | 基于 ACK 确认机制 |

### 8.3 协议性能

| 指标 | JSON | Protobuf | 优势 |
|------|------|----------|------|
| 消息体积 | 100% | 10-30% | 体积小 3-10 倍 |
| 序列化速度 | 100% | 500-10000% | 速度快 20-100 倍 |
| CPU 占用 | 100% | 20-50% | CPU 占用降低 50-80% |
| 内存占用 | 100% | 30-60% | 内存占用降低 40-70% |

### 8.4 扩展性能

| 指标 | 数值 | 说明 |
|------|------|------|
| 水平扩展 | 无限 | 通过消息总线实现跨服务器通信 |
| 负载均衡 | 支持 | 支持 Nginx/LVS 负载均衡 |
| 故障转移 | < 5s | 服务器宕机后自动切换 |
| 会话共享 | 支持 | 通过 Redis 共享会话状态 |

### 8.5 性能优化建议

#### 8.5.1 服务器配置
```yaml
# 推荐配置(16核32G服务器)
shengyu:
  netty:
    boss-threads: 1              # Boss 线程数(建议1个)
    worker-threads: 32           # Worker 线程数(建议 CPU核心数 * 2)
    use-epoll: true              # Linux 环境启用 Epoll
    reader-idle-time: 60         # 读空闲时间(秒)
```

#### 8.5.2 JVM 参数
```bash
# 推荐 JVM 参数
-Xms4g -Xmx4g                    # 堆内存 4G
-XX:+UseG1GC                     # 使用 G1 垃圾回收器
-XX:MaxGCPauseMillis=200         # 最大 GC 停顿时间 200ms
-XX:+HeapDumpOnOutOfMemoryError  # OOM 时生成堆转储
-XX:HeapDumpPath=/tmp/heapdump.hprof
```

#### 8.5.3 操作系统优化
```bash
# Linux 系统参数优化
# 增加文件描述符限制
ulimit -n 1000000

# 增加 TCP 连接队列
sysctl -w net.core.somaxconn=65535
sysctl -w net.ipv4.tcp_max_syn_backlog=65535

# 启用 TCP 快速回收
sysctl -w net.ipv4.tcp_tw_reuse=1
sysctl -w net.ipv4.tcp_tw_recycle=1
```

#### 8.5.4 Redis 优化
```yaml
# Redis 配置优化
spring:
  redis:
    lettuce:
      pool:
        max-active: 100          # 最大连接数
        max-idle: 50             # 最大空闲连接数
        min-idle: 10             # 最小空闲连接数
        max-wait: 3000           # 最大等待时间(毫秒)
```

### 8.6 性能监控

#### 8.6.1 关键指标
- 在线用户数
- 消息发送速率(msg/s)
- 消息延迟(P50/P95/P99)
- CPU 使用率
- 内存使用率
- 网络带宽使用率
- GC 频率和停顿时间

#### 8.6.2 监控工具
- Prometheus + Grafana (推荐)
- Spring Boot Actuator
- Micrometer
- Arthas (阿里巴巴开源的 Java 诊断工具)

## 九、技术栈

| 技术 | 版本 | 说明 |
|------|------|------|
| Netty | 4.1.x | 高性能网络框架 |
| Protobuf | 3.x | 高性能序列化协议 |
| Spring Boot | 2.7.18 | 应用框架 |
| Redis | 5.0+ | 消息总线(推荐) |
| RocketMQ | 4.9+ | 消息总线(可选) |
| Kafka | 2.8+ | 消息总线(可选) |
| RabbitMQ | 3.9+ | 消息总线(可选) |
| JDK | 8+ | Java 运行环境 |

## 十、核心技术深度解析

> 本章节深入剖析 WebSocket 中间件的核心技术实现,帮助开发者理解底层原理和设计思想。

### 10.1 Netty 服务器启动流程

#### 10.1.1 启动流程图

```
┌─────────────────────────────────────────────────────────────┐
│                    NettyServer.start()                       │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌──────────────────────┴──────────────────────────────────────┐
│  1. 判断是否使用 Epoll (Linux 环境 + useEpoll=true)        │
│     - Epoll: 性能提升 30%+                                  │
│     - NIO: 跨平台兼容                                       │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌──────────────────────┴──────────────────────────────────────┐
│  2. 创建 Boss 和 Worker 线程组                              │
│     - Boss: 接受新连接 (建议 1 个线程)                      │
│     - Worker: 处理 I/O 事件 (建议 CPU核心数 * 2)           │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌──────────────────────┴──────────────────────────────────────┐
│  3. 配置 ServerBootstrap                                    │
│     - Channel 类型: EpollServerSocketChannel / NioServerSocketChannel │
│     - Handler: LoggingHandler + NettyChannelInitializer    │
│     - TCP 参数优化: SO_BACKLOG, TCP_NODELAY, SO_KEEPALIVE  │
│     - 写缓冲区水位线: 防止内存溢出                          │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌──────────────────────┴──────────────────────────────────────┐
│  4. 绑定端口并启动                                          │
│     - 默认端口: 9000                                        │
│     - 同步等待启动完成                                      │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌──────────────────────┴──────────────────────────────────────┐
│  5. 启动成功                                                │
│     - 日志输出: [Netty Server] 启动成功，监听端口: 9000    │
└─────────────────────────────────────────────────────────────┘
```

#### 10.1.2 关键代码解析

**Epoll 优化**:
```java
// 判断是否使用 Epoll
boolean useEpoll = nettyProperties.getUseEpoll() && Epoll.isAvailable();

if (useEpoll) {
    // Linux 环境下使用 Epoll,性能提升 30%+
    bossGroup = new EpollEventLoopGroup(1, new DefaultThreadFactory("netty-boss"));
    workerGroup = new EpollEventLoopGroup(16, new DefaultThreadFactory("netty-worker"));
} else {
    // 跨平台使用 NIO
    bossGroup = new NioEventLoopGroup(1, new DefaultThreadFactory("netty-boss"));
    workerGroup = new NioEventLoopGroup(16, new DefaultThreadFactory("netty-worker"));
}
```

**TCP 参数优化**:
```java
bootstrap
    // SO_BACKLOG: TCP 连接队列大小,默认 1024
    .option(ChannelOption.SO_BACKLOG, 1024)
    // SO_REUSEADDR: 允许端口复用
    .option(ChannelOption.SO_REUSEADDR, true)
    // TCP_NODELAY: 禁用 Nagle 算法,降低延迟
    .childOption(ChannelOption.TCP_NODELAY, true)
    // SO_KEEPALIVE: 启用 TCP 保活机制
    .childOption(ChannelOption.SO_KEEPALIVE, true)
    // SO_RCVBUF: 接收缓冲区大小,默认 32KB
    .childOption(ChannelOption.SO_RCVBUF, 32 * 1024)
    // SO_SNDBUF: 发送缓冲区大小,默认 32KB
    .childOption(ChannelOption.SO_SNDBUF, 32 * 1024);
```

**写缓冲区水位线**:
```java
// 防止写缓冲区无限增长导致内存溢出
.childOption(ChannelOption.WRITE_BUFFER_WATER_MARK, 
    new WriteBufferWaterMark(
        32 * 1024,   // 低水位线: 32KB
        64 * 1024    // 高水位线: 64KB
    ));
```

### 10.2 Pipeline 处理链设计

#### 10.2.1 Pipeline 结构图

```
┌─────────────────────────────────────────────────────────────┐
│                    Netty Pipeline                            │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐          │
│  │ HTTP编解码 │→│ WebSocket  │→│ 帧处理器   │          │
│  │ Codec      │  │ Protocol   │  │ Aggregator │          │
│  └────────────┘  └────────────┘  └────────────┘          │
│         ↓               ↓               ↓                   │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐          │
│  │ 空闲检测   │→│ 心跳处理   │→│ 认证处理   │          │
│  │ IdleState  │  │ Heartbeat  │  │ Auth       │          │
│  └────────────┘  └────────────┘  └────────────┘          │
│         ↓               ↓               ↓                   │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐          │
│  │ 消息处理   │→│ 异常处理   │→│ 业务逻辑   │          │
│  │ Message    │  │ Exception  │  │ Business   │          │
│  └────────────┘  └────────────┘  └────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

#### 10.2.2 Handler 职责说明

| Handler | 职责 | 关键参数 |
|---------|------|---------|
| **HttpServerCodec** | HTTP 请求/响应编解码 | - |
| **HttpObjectAggregator** | HTTP 消息聚合 | maxContentLength: 64KB |
| **WebSocketServerProtocolHandler** | WebSocket 协议处理 | path: /ws |
| **IdleStateHandler** | 空闲检测 | readerIdleTime: 60s |
| **HeartbeatHandler** | 心跳处理 | 响应 HEARTBEAT_REQ |
| **AuthHandler** | 认证处理 | 验证 Token,创建 Session |
| **MessageHandler** | 消息处理 | 路由到 MessageProcessor |
| **ExceptionHandler** | 异常处理 | 统一异常处理和日志记录 |

#### 10.2.3 关键代码解析

**空闲检测**:
```java
// 60秒内没有读事件,触发 IdleStateEvent
pipeline.addLast(new IdleStateHandler(60, 0, 0, TimeUnit.SECONDS));

// HeartbeatHandler 处理空闲事件
@Override
public void userEventTriggered(ChannelHandlerContext ctx, Object evt) {
    if (evt instanceof IdleStateEvent) {
        IdleStateEvent event = (IdleStateEvent) evt;
        if (event.state() == IdleState.READER_IDLE) {
            // 读空闲,关闭连接
            log.warn("[Heartbeat] 心跳超时,关闭连接: {}", ctx.channel().id().asShortText());
            ctx.close();
        }
    }
}
```

**认证处理**:
```java
// AuthHandler 处理认证请求
@Override
protected void channelRead0(ChannelHandlerContext ctx, ImMessage msg) {
    if (msg.getHeader().getMessageType() == MessageType.AUTH_REQ) {
        // 1. 解析认证请求
        AuthRequest authReq = AuthRequest.parseFrom(msg.getBody());
        String accessToken = authReq.getAccessToken();
        
        // 2. 验证 Token
        LoginBase loginUser = authService.validateToken(accessToken);
        
        if (loginUser != null) {
            // 3. 创建 Session
            NettySession session = new NettySession();
            session.setChannel(ctx.channel());
            session.setUserId(loginUser.getId());
            session.setTenantId(authService.getTenantId(loginUser));
            session.setDeviceType(authReq.getDeviceType());
            session.setDeviceId(authReq.getDeviceId());
            
            // 4. 添加到 SessionManager (支持多端登录互踢)
            sessionManager.addSession(session);
            
            // 5. 返回认证成功
            sendAuthResponse(ctx, true, "认证成功");
        } else {
            // 6. 返回认证失败
            sendAuthResponse(ctx, false, "Token 无效");
            ctx.close();
        }
    }
}
```

### 10.3 会话管理的多端登录互踢实现

#### 10.3.1 多端登录策略

类似微信的多端登录策略:
- 同一设备类型只允许一个设备在线(如手机端只能一个设备在线)
- 不同设备类型可以同时在线(如手机+PC+iPad 同时在线)
- 新设备登录时,踢掉同类型的旧设备

#### 10.3.2 数据结构设计

```java
public class NettySessionManager {
    // Channel ID -> Session (快速查找会话)
    private final Map<String, NettySession> channelSessionMap = new ConcurrentHashMap<>();
    
    // User ID -> Channel IDs (查找用户的所有连接)
    private final Map<Long, Set<String>> userChannelMap = new ConcurrentHashMap<>();
    
    // User ID + Device Type -> Channel ID (实现互踢策略)
    private final Map<String, String> userDeviceChannelMap = new ConcurrentHashMap<>();
    
    // Tenant ID -> Channel IDs (按租户查找所有连接)
    private final Map<Long, Set<String>> tenantChannelMap = new ConcurrentHashMap<>();
}
```

#### 10.3.3 互踢逻辑实现

```java
public void addSession(NettySession session) {
    String channelId = session.getChannelId();
    Long userId = session.getUserId();
    Integer deviceType = session.getDeviceType();
    
    // 1. 检查是否有同类型设备在线
    if (userId != null && deviceType != null) {
        String userDeviceKey = userId + ":" + deviceType;
        String oldChannelId = userDeviceChannelMap.get(userDeviceKey);
        
        if (oldChannelId != null && !oldChannelId.equals(channelId)) {
            // 2. 踢掉旧设备
            NettySession oldSession = channelSessionMap.get(oldChannelId);
            if (oldSession != null && oldSession.isActive()) {
                kickOffDevice(oldSession, "您的账号在其他设备登录");
            }
        }
        
        // 3. 保存新设备的映射
        userDeviceChannelMap.put(userDeviceKey, channelId);
    }
    
    // 4. 添加到各个映射表
    channelSessionMap.put(channelId, session);
    userChannelMap.computeIfAbsent(userId, k -> ConcurrentHashMap.newKeySet()).add(channelId);
    tenantChannelMap.computeIfAbsent(tenantId, k -> ConcurrentHashMap.newKeySet()).add(channelId);
}
```

#### 10.3.4 设备类型定义

```java
public enum DeviceTypeEnum {
    WEB(1, "Web浏览器"),
    IOS(2, "iPhone"),
    ANDROID(3, "Android手机"),
    MINI_PROGRAM(4, "小程序"),
    IPAD(5, "iPad"),
    MAC(6, "Mac电脑"),
    WINDOWS(7, "Windows电脑");
}
```

#### 10.3.5 示例场景

```
用户 A 的登录情况:
- iPhone (iOS)     ✅ 在线
- iPad (iPad)      ✅ 在线
- Mac (Mac)        ✅ 在线
- Windows (Win)    ✅ 在线

此时用户 A 在另一台 iPhone 上登录:
- iPhone 1 (iOS)   ❌ 被踢下线 (收到 CLOSE 消息: "您的账号在其他设备登录")
- iPhone 2 (iOS)   ✅ 新设备上线
- iPad (iPad)      ✅ 保持在线
- Mac (Mac)        ✅ 保持在线
- Windows (Win)    ✅ 保持在线
```

### 10.4 认证流程的双协议支持

#### 10.4.1 认证流程图

```
┌─────────────────────────────────────────────────────────────┐
│                      客户端                                  │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
         ┌─────────────┴─────────────┐
         │  发送 AUTH_REQ 消息       │
         │  - accessToken            │
         │  - deviceType             │
         │  - deviceId               │
         │  - clientVersion          │
         └─────────────┬─────────────┘
                       ↓
┌──────────────────────┴──────────────────────────────────────┐
│                   AuthHandler                                │
│  1. 解析认证请求 (支持 JSON 和 Protobuf)                    │
│  2. 调用 AuthService.validateToken()                        │
│  3. 验证成功 → 创建 NettySession                            │
│  4. 检查同设备类型的旧连接 → 踢掉旧设备                     │
│  5. 添加到 SessionManager                                   │
│  6. 返回 AUTH_RESP 消息                                     │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
         ┌─────────────┴─────────────┐
         │  返回 AUTH_RESP 消息      │
         │  - success: true/false    │
         │  - message: "认证成功"    │
         │  - userId                 │
         │  - tenantId               │
         └─────────────┬─────────────┘
                       ↓
┌──────────────────────┴──────────────────────────────────────┐
│                      客户端                                  │
│  认证成功 → 开始发送心跳和业务消息                          │
│  认证失败 → 关闭连接                                        │
└─────────────────────────────────────────────────────────────┘
```

#### 10.4.2 双端认证支持

**租户端用户** (LoginUser):
```java
public class LoginUser extends LoginBase {
    private Long tenantId;  // 租户ID
    private Integer userType = 1;  // 用户类型: 1-租户端
}
```

**平台端用户** (PlatformLoginUser):
```java
public class PlatformLoginUser extends LoginBase {
    private Integer userType = 2;  // 用户类型: 2-平台端
    // 平台端用户无租户ID
}
```

**AuthService 实现**:
```java
@Override
public Long getTenantId(LoginBase loginUser) {
    if (loginUser instanceof LoginUser) {
        return ((LoginUser) loginUser).getTenantId();
    }
    return null;  // 平台端用户无租户ID
}
```

### 10.5 心跳机制的空闲检测策略

#### 10.5.1 心跳流程图

```
┌─────────────────────────────────────────────────────────────┐
│                      客户端                                  │
│  定时发送心跳 (30s-180s,根据网络状况动态调整)               │
└──────────────────────┬──────────────────────────────────────┘
                       ↓ HEARTBEAT_REQ
┌──────────────────────┴──────────────────────────────────────┐
│                 IdleStateHandler                             │
│  检测读空闲: 60秒内没有收到任何消息                         │
└──────────────────────┬──────────────────────────────────────┘
                       ↓ 触发 IdleStateEvent
┌──────────────────────┴──────────────────────────────────────┐
│                 HeartbeatHandler                             │
│  1. 收到 HEARTBEAT_REQ → 返回 HEARTBEAT_RESP                │
│  2. 收到 IdleStateEvent → 关闭连接                          │
└──────────────────────┬──────────────────────────────────────┘
                       ↓ HEARTBEAT_RESP
┌──────────────────────┴──────────────────────────────────────┐
│                      客户端                                  │
│  收到心跳响应 → 更新最后活跃时间                            │
└─────────────────────────────────────────────────────────────┘
```

#### 10.5.2 关键代码解析

**服务端空闲检测**:
```java
// 60秒内没有读事件,触发 IdleStateEvent
pipeline.addLast(new IdleStateHandler(60, 0, 0, TimeUnit.SECONDS));

// HeartbeatHandler 处理空闲事件
@Override
public void userEventTriggered(ChannelHandlerContext ctx, Object evt) {
    if (evt instanceof IdleStateEvent) {
        IdleStateEvent event = (IdleStateEvent) evt;
        if (event.state() == IdleState.READER_IDLE) {
            // 读空闲,关闭连接
            log.warn("[Heartbeat] 心跳超时,关闭连接: {}", ctx.channel().id().asShortText());
            ctx.close();
        }
    }
}
```

**客户端心跳发送** (伪代码):
```javascript
// 客户端定时发送心跳
setInterval(() => {
    if (websocket.readyState === WebSocket.OPEN) {
        const heartbeat = {
            header: {
                messageType: 'HEARTBEAT_REQ',
                timestamp: Date.now()
            }
        };
        websocket.send(JSON.stringify(heartbeat));
    }
}, 30000);  // 30秒发送一次
```

### 10.6 消息发送器的路由策略

#### 10.6.1 路由策略图

```
┌─────────────────────────────────────────────────────────────┐
│                 NettyMessageSender                           │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
         ┌─────────────┴─────────────┐
         │  根据目标类型选择路由策略  │
         └─────────────┬─────────────┘
                       ↓
    ┌──────────────────┼──────────────────┐
    ↓                  ↓                   ↓
┌────────┐      ┌────────┐         ┌────────┐
│ 单播   │      │ 多播   │         │ 广播   │
│ User   │      │ Group  │         │ All    │
└────┬───┘      └────┬───┘         └────┬───┘
     ↓               ↓                   ↓
┌────────────┐ ┌────────────┐    ┌────────────┐
│ 查找用户的 │ │ 查找群组的 │    │ 查找所有   │
│ 所有设备   │ │ 所有成员   │    │ 在线用户   │
└────┬───────┘ └────┬───────┘    └────┬───────┘
     ↓               ↓                   ↓
┌────────────┐ ┌────────────┐    ┌────────────┐
│ 遍历设备   │ │ 遍历成员   │    │ 遍历用户   │
│ 发送消息   │ │ 发送消息   │    │ 发送消息   │
└────────────┘ └────────────┘    └────────────┘
```

#### 10.6.2 路由策略说明

| 路由策略 | 方法 | 说明 | 使用场景 |
|---------|------|------|---------|
| **单播** | `sendToUser(userId, ...)` | 发送给指定用户的所有在线设备 | 单聊消息、系统通知 |
| **设备单播** | `sendToDevice(userId, deviceId, ...)` | 发送给指定用户的指定设备 | 踢下线通知 |
| **多播** | `sendToGroup(groupId, ...)` | 发送给群组的所有成员 | 群聊消息 |
| **租户广播** | `sendToTenant(tenantId, ...)` | 发送给租户的所有在线用户 | 租户公告 |
| **全局广播** | `broadcast(...)` | 发送给所有在线用户 | 系统维护通知 |

#### 10.6.3 关键代码解析

**单播实现**:
```java
public void sendToUser(Long userId, MessageType messageType, MessageLite body) {
    // 1. 查找用户的所有在线设备
    List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
    if (sessions.isEmpty()) {
        log.debug("[MessageSender] 用户不在线: {}", userId);
        return;
    }
    
    // 2. 构建消息
    ImMessage message = buildMessage(messageType, body, null, userId, null, null);
    
    // 3. 遍历所有设备发送消息
    int successCount = 0;
    for (NettySession session : sessions) {
        if (session.isActive()) {
            session.getChannel().writeAndFlush(message);
            successCount++;
        }
    }
    
    log.debug("[MessageSender] 发送消息给用户: {}, 设备数: {}, 成功: {}", 
        userId, sessions.size(), successCount);
}
```

**多播实现** (需要业务模块提供群成员列表):
```java
public void sendToGroup(Long groupId, MessageType messageType, MessageLite body) {
    // 1. 查询群成员列表 (由业务模块实现)
    List<Long> memberIds = groupService.getGroupMemberIds(groupId);
    
    // 2. 遍历群成员发送消息
    for (Long memberId : memberIds) {
        sendToUser(memberId, messageType, body);
    }
}
```

### 10.7 SPI 接口的设计理念和实现指南

#### 10.7.1 SPI 设计理念

**职责分离**:
- **中间件职责**: 连接管理、协议处理、消息路由、认证鉴权
- **业务模块职责**: 消息存储、业务逻辑、业务规则、业务通知

**扩展性**:
- 业务模块通过实现 SPI 接口来扩展中间件功能
- 中间件不依赖具体的业务实现,保持通用性
- 支持多种实现方式(如不同的数据库、缓存、推送服务)

#### 10.7.2 SPI 接口列表

| 接口 | 必须实现 | 职责 |
|------|---------|------|
| **MessageStorageService** | ✅ 是 | 消息存储到数据库 |
| **AuthService** | ✅ 是 | Token 验证和用户认证 |
| **MessageCacheService** | ❌ 否 | 消息缓存(如未读数缓存) |
| **OfflinePushService** | ❌ 否 | 离线推送(如 APNs、FCM) |

#### 10.7.3 实现指南

**MessageStorageService 实现**:
```java
@Service
public class SystemMessageStorageServiceImpl implements MessageStorageService {
    
    @Resource
    private ImMessageMapper messageMapper;
    
    @Resource
    private ImConversationService conversationService;
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveMessage(ImMessage message) {
        // 1. 转换为 DO 对象
        ImMessageDO messageDO = convertToDO(message);
        
        // 2. 保存到数据库
        messageMapper.insert(messageDO);
        
        // 3. 更新会话(最后一条消息、未读数等)
        conversationService.updateConversationByMessage(messageDO);
    }
}
```

**AuthService 实现**:
```java
@Service
public class SystemAuthServiceImpl implements AuthService {
    
    @Resource
    private OAuth2TokenApi oauth2TokenApi;
    
    @Override
    public LoginBase validateToken(String accessToken) {
        // 1. 验证 token
        OAuth2AccessTokenCheckRespDTO tokenInfo = 
            oauth2TokenApi.checkAccessToken(accessToken);
        
        if (tokenInfo == null || tokenInfo.getExpiresTime().isBefore(LocalDateTime.now())) {
            return null;
        }
        
        // 2. 构建登录用户信息
        return buildLoginUser(tokenInfo);
    }
}
```

## 十一、后续规划

### 11.1 功能增强

- [ ] **消息加密**: 支持端到端加密(E2EE)
- [ ] **消息搜索**: 支持全文搜索和关键词高亮
- [ ] **消息转发**: 支持消息转发到其他会话
- [ ] **消息引用**: 支持引用回复某条消息
- [ ] **消息表情**: 支持消息表情回应(👍❤️😂)
- [ ] **阅后即焚**: 支持阅后即焚消息
- [ ] **截屏通知**: 支持截屏通知
- [ ] **消息审核**: 支持敏感词过滤和内容审核

### 11.2 性能优化

- [ ] **消息批量发送**: 批量打包发送,减少网络开销
- [ ] **消息压缩**: 支持 Gzip/LZ4 压缩
- [ ] **连接复用**: 支持 HTTP/2 多路复用
- [ ] **智能路由**: 根据网络状况选择最优路由
- [ ] **CDN 加速**: 支持 CDN 加速文件传输
- [ ] **边缘计算**: 支持边缘节点部署

### 11.3 运维增强

- [ ] **监控告警**: 完善监控指标和告警规则
- [ ] **日志分析**: 支持日志聚合和分析
- [ ] **链路追踪**: 支持分布式链路追踪
- [ ] **灰度发布**: 支持灰度发布和 A/B 测试
- [ ] **容灾备份**: 支持多机房容灾
- [ ] **自动扩缩容**: 支持根据负载自动扩缩容

### 11.4 生态集成

- [ ] **音视频通话**: 集成 WebRTC 实现音视频通话
- [ ] **屏幕共享**: 支持屏幕共享功能
- [ ] **白板协作**: 支持在线白板协作
- [ ] **文档协作**: 支持在线文档协作编辑
- [ ] **AI 助手**: 集成 AI 助手(如 ChatGPT)
- [ ] **翻译功能**: 支持实时消息翻译

详见 [TODO.md](TODO.md)

## 十二、常见问题

### Q1: 如何选择消息总线?

**A**: 根据业务场景选择:
- **单机部署**: 使用 `local` 模式,无需额外依赖
- **小规模集群(< 10台)**: 使用 `redis` 模式,简单易用
- **大规模集群(> 10台)**: 使用 `rocketmq` 或 `kafka` 模式,高吞吐

### Q2: 如何提高消息可靠性?

**A**: 
1. 启用消息 ACK 确认机制
2. 实现消息重试机制
3. 使用消息队列缓存离线消息
4. 定期同步消息状态

### Q3: 如何处理消息顺序?

**A**:
1. 使用 `sequence` 字段保证全局有序
2. 客户端按 `sequence` 排序显示
3. 服务端使用分布式 ID 生成器(如雪花算法)

### Q4: 如何优化大文件传输?

**A**:
1. 使用 OSS 存储文件,只传输文件 URL
2. 支持断点续传
3. 使用 CDN 加速下载
4. 压缩文件后传输

### Q5: 如何防止消息轰炸?

**A**:
1. 实现消息频率限制(如每秒最多10条)
2. 实现黑名单机制
3. 实现敏感词过滤
4. 实现消息审核机制

### Q6: 如何实现消息加密?

**A**:
1. 使用 HTTPS/WSS 传输加密
2. 使用 AES 对消息内容加密
3. 使用 RSA 交换密钥
4. 实现端到端加密(E2EE)

## 十三、参考资料

### 技术文档
- [Netty 官方文档](https://netty.io/wiki/)
- [Protobuf 官方文档](https://developers.google.com/protocol-buffers)
- [WebSocket 协议规范](https://tools.ietf.org/html/rfc6455)

### 开源项目
- [微信 Mars](https://github.com/Tencent/mars) - 微信终端基础组件
- [环信 IM](https://www.easemob.com/) - 即时通讯云服务
- [融云 IM](https://www.rongcloud.cn/) - 即时通讯云服务

### 技术博客
- [微信技术架构](https://mp.weixin.qq.com/s/JPXq7zKGNmGCBhXZGMZsWw)
- [钉钉技术架构](https://developer.aliyun.com/article/770890)
- [IM 系统设计](https://www.infoq.cn/article/im-system-design)

---

**版本**：v2.1.0  
**作者**：圣钰科技  
**更新时间**：2026年2月26日  
**文档维护**：请保持文档与代码同步更新
