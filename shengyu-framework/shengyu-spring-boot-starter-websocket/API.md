# 即时通讯中间件 API 文档

## 一、核心服务接口

### 1.1 NettyMessageSender - 消息发送服务

消息发送服务，提供各种消息发送方法。

#### 方法列表

##### 1. 发送消息给指定用户

```java
/**
 * 发送消息给指定用户（所有设备）
 * 
 * @param userId 用户ID
 * @param messageType 消息类型
 * @param body 消息体（Protobuf MessageLite）
 */
void sendToUser(Long userId, MessageType messageType, MessageLite body);

/**
 * 发送消息给指定用户（所有设备）
 * 
 * @param userId 用户ID
 * @param messageType 消息类型
 * @param body 消息体（Protobuf MessageLite）
 * @param senderId 发送者ID
 */
void sendToUser(Long userId, MessageType messageType, MessageLite body, Long senderId);
```

**使用示例：**

```java
@Autowired
private NettyMessageSender messageSender;

// 发送文本消息
TextMessage textMessage = TextMessage.newBuilder()
    .setContent("您有新的订单")
    .build();
messageSender.sendToUser(userId, MessageType.TEXT, textMessage);

// 发送系统通知
SystemNotifyMessage notifyMessage = SystemNotifyMessage.newBuilder()
    .setTitle("系统通知")
    .setContent("您的账号已通过审核")
    .build();
messageSender.sendToUser(userId, MessageType.SYSTEM_NOTIFY, notifyMessage);
```

##### 2. 发送消息给指定租户的所有用户

```java
/**
 * 发送消息给指定租户的所有在线用户
 * 
 * @param tenantId 租户ID
 * @param messageType 消息类型
 * @param body 消息体
 */
void sendToTenant(Long tenantId, MessageType messageType, MessageLite body);
```

**使用示例：**

```java
// 租户公告
TextMessage announcement = TextMessage.newBuilder()
    .setContent("系统将于今晚22:00进行维护")
    .build();
messageSender.sendToTenant(tenantId, MessageType.SYSTEM_NOTIFY, announcement);
```

##### 3. 广播消息给所有在线用户

```java
/**
 * 广播消息给所有在线用户
 * 
 * @param messageType 消息类型
 * @param body 消息体
 */
void broadcast(MessageType messageType, MessageLite body);
```

**使用示例：**

```java
// 全局公告
TextMessage globalAnnouncement = TextMessage.newBuilder()
    .setContent("平台将于明天升级")
    .build();
messageSender.broadcast(MessageType.SYSTEM_NOTIFY, globalAnnouncement);
```

##### 4. 发送消息给指定设备

```java
/**
 * 发送消息给指定用户的指定设备
 * 
 * @param userId 用户ID
 * @param deviceId 设备ID
 * @param messageType 消息类型
 * @param body 消息体
 */
void sendToDevice(Long userId, String deviceId, MessageType messageType, MessageLite body);
```

**使用示例：**

```java
// 发送给特定设备
messageSender.sendToDevice(userId, "device-123", MessageType.TEXT, textMessage);
```

---

### 1.2 NettySessionManager - 会话管理服务

会话管理服务，管理所有在线用户的连接会话。

#### 方法列表

##### 1. 添加会话

```java
/**
 * 添加会话
 * 
 * @param session 会话信息
 */
void addSession(NettySession session);
```

##### 2. 移除会话

```java
/**
 * 移除会话
 * 
 * @param channel Netty Channel
 */
void removeSession(Channel channel);
```

##### 3. 获取会话

```java
/**
 * 根据 Channel ID 获取会话
 * 
 * @param channelId Channel ID
 * @return 会话信息
 */
NettySession getSession(String channelId);

/**
 * 根据 Channel 获取会话
 * 
 * @param channel Netty Channel
 * @return 会话信息
 */
NettySession getSession(Channel channel);
```

##### 4. 根据用户ID获取所有会话

```java
/**
 * 根据用户ID获取所有会话（支持多设备）
 * 
 * @param userId 用户ID
 * @return 会话列表
 */
List<NettySession> getSessionsByUserId(Long userId);
```

**使用示例：**

```java
@Autowired
private NettySessionManager sessionManager;

// 获取用户的所有在线设备
List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
for (NettySession session : sessions) {
    System.out.println("设备类型: " + session.getDeviceType());
    System.out.println("设备ID: " + session.getDeviceId());
    System.out.println("连接时间: " + session.getConnectTime());
}
```

##### 5. 根据租户ID获取所有会话

```java
/**
 * 根据租户ID获取所有会话
 * 
 * @param tenantId 租户ID
 * @return 会话列表
 */
List<NettySession> getSessionsByTenantId(Long tenantId);
```

##### 6. 获取统计信息

```java
/**
 * 获取在线用户数
 * 
 * @return 在线用户数
 */
int getOnlineUserCount();

/**
 * 获取在线连接数
 * 
 * @return 在线连接数
 */
int getOnlineConnectionCount();

/**
 * 判断用户是否在线
 * 
 * @param userId 用户ID
 * @return true-在线，false-离线
 */
boolean isUserOnline(Long userId);
```

**使用示例：**

```java
// 获取在线统计
int userCount = sessionManager.getOnlineUserCount();
int connectionCount = sessionManager.getOnlineConnectionCount();
System.out.println("在线用户数: " + userCount);
System.out.println("在线连接数: " + connectionCount);

// 判断用户是否在线
boolean online = sessionManager.isUserOnline(userId);
if (online) {
    // 用户在线，发送实时消息
} else {
    // 用户离线，发送离线推送
}
```

---

### 1.3 MessageStorageService - 消息存储服务

消息存储服务，提供消息的持久化存储和查询功能。

#### 方法列表

##### 1. 保存消息

```java
/**
 * 保存消息
 * 
 * @param message IM 消息
 * @return 消息ID
 */
Long saveMessage(ImMessage message);

/**
 * 批量保存消息
 * 
 * @param messages 消息列表
 * @return 成功保存的数量
 */
int batchSaveMessages(List<ImMessage> messages);
```

##### 2. 查询消息

```java
/**
 * 根据消息ID查询消息
 * 
 * @param messageId 消息ID
 * @return 消息DO
 */
ImMessageDO getMessageById(Long messageId);

/**
 * 查询用户的历史消息
 * 
 * @param userId 用户ID
 * @param receiverId 接收者ID
 * @param pageNo 页码
 * @param pageSize 每页数量
 * @return 消息列表
 */
List<ImMessageDO> getHistoryMessages(Long userId, Long receiverId, int pageNo, int pageSize);

/**
 * 查询用户的离线消息
 * 
 * @param userId 用户ID
 * @param lastMessageId 最后一条消息ID
 * @return 离线消息列表
 */
List<ImMessageDO> getOfflineMessages(Long userId, Long lastMessageId);
```

**使用示例：**

```java
@Autowired
private MessageStorageService messageStorageService;

// 查询历史消息
List<ImMessageDO> messages = messageStorageService.getHistoryMessages(
    userId, 
    friendId, 
    1,  // 第1页
    20  // 每页20条
);

// 查询离线消息
List<ImMessageDO> offlineMessages = messageStorageService.getOfflineMessages(
    userId,
    lastMessageId
);
```

##### 3. 更新消息状态

```java
/**
 * 更新消息状态
 * 
 * @param messageId 消息ID
 * @param status 状态（0-未读 1-已读 2-已撤回）
 * @return 是否成功
 */
boolean updateMessageStatus(Long messageId, Integer status);

/**
 * 批量更新消息状态为已读
 * 
 * @param messageIds 消息ID列表
 * @return 更新数量
 */
int batchMarkAsRead(List<Long> messageIds);
```

##### 4. 撤回和删除消息

```java
/**
 * 撤回消息
 * 
 * @param messageId 消息ID
 * @param userId 用户ID（只能撤回自己的消息）
 * @return 是否成功
 */
boolean recallMessage(Long messageId, Long userId);

/**
 * 删除消息
 * 
 * @param messageId 消息ID
 * @param userId 用户ID（只能删除自己的消息）
 * @return 是否成功
 */
boolean deleteMessage(Long messageId, Long userId);
```

##### 5. 统计未读消息

```java
/**
 * 统计未读消息数
 * 
 * @param userId 用户ID
 * @return 未读消息数
 */
long countUnreadMessages(Long userId);

/**
 * 统计会话未读消息数
 * 
 * @param userId 用户ID
 * @param senderId 发送者ID
 * @return 未读消息数
 */
long countUnreadMessagesBySender(Long userId, Long senderId);
```

---

### 1.4 AuthService - 认证服务

认证服务，提供 Token 验证功能，支持租户端和平台端。

#### 方法列表

```java
/**
 * 验证 Token
 * 
 * @param accessToken 访问令牌
 * @return 登录用户信息，验证失败返回 null
 */
LoginBase validateToken(String accessToken);

/**
 * 获取租户ID
 * 
 * @param loginUser 登录用户
 * @return 租户ID，平台端用户返回 null
 */
Long getTenantId(LoginBase loginUser);

/**
 * 判断是否为租户端用户
 * 
 * @param loginUser 登录用户
 * @return true-租户端用户，false-平台端用户
 */
boolean isTenantUser(LoginBase loginUser);

/**
 * 判断是否为平台端用户
 * 
 * @param loginUser 登录用户
 * @return true-平台端用户，false-租户端用户
 */
boolean isPlatformUser(LoginBase loginUser);
```

---

## 二、自定义消息处理器

### 2.1 实现 MessageProcessor 接口

```java
@Component
public class CustomMessageProcessor implements MessageProcessor {
    
    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        // 自定义消息处理逻辑
        log.info("处理自定义消息: {}", message);
    }
}
```

### 2.2 注册到工厂

```java
@Configuration
public class MessageProcessorConfig {
    
    @Bean
    public CustomMessageProcessor customMessageProcessor(
            MessageProcessorFactory processorFactory) {
        CustomMessageProcessor processor = new CustomMessageProcessor();
        // 注册到工厂
        processorFactory.registerProcessor(MessageType.CUSTOM, processor);
        return processor;
    }
}
```

---

## 三、业务集成示例

### 3.1 订单通知

```java
@Service
public class OrderService {
    
    @Autowired
    private NettyMessageSender messageSender;
    
    public void createOrder(OrderDTO orderDTO) {
        // 创建订单逻辑...
        
        // 发送订单通知
        TextMessage message = TextMessage.newBuilder()
            .setContent("您的订单已创建成功，订单号：" + orderDTO.getOrderNo())
            .build();
        messageSender.sendToUser(orderDTO.getUserId(), MessageType.TEXT, message);
    }
}
```

### 3.2 系统公告

```java
@Service
public class AnnouncementService {
    
    @Autowired
    private NettyMessageSender messageSender;
    
    public void publishAnnouncement(String content, Long tenantId) {
        TextMessage message = TextMessage.newBuilder()
            .setContent(content)
            .build();
        
        if (tenantId != null) {
            // 发送给指定租户
            messageSender.sendToTenant(tenantId, MessageType.SYSTEM_NOTIFY, message);
        } else {
            // 全局广播
            messageSender.broadcast(MessageType.SYSTEM_NOTIFY, message);
        }
    }
}
```

### 3.3 在线状态查询

```java
@Service
public class UserService {
    
    @Autowired
    private NettySessionManager sessionManager;
    
    public UserOnlineStatusVO getUserOnlineStatus(Long userId) {
        boolean online = sessionManager.isUserOnline(userId);
        List<NettySession> sessions = sessionManager.getSessionsByUserId(userId);
        
        return UserOnlineStatusVO.builder()
            .userId(userId)
            .online(online)
            .deviceCount(sessions.size())
            .devices(sessions.stream()
                .map(s -> DeviceInfo.builder()
                    .deviceType(s.getDeviceType())
                    .deviceId(s.getDeviceId())
                    .connectTime(s.getConnectTime())
                    .build())
                .collect(Collectors.toList()))
            .build();
    }
}
```

### 3.4 消息历史查询

```java
@Service
public class ChatService {
    
    @Autowired
    private MessageStorageService messageStorageService;
    
    public PageResult<MessageVO> getChatHistory(Long userId, Long friendId, int pageNo, int pageSize) {
        // 查询历史消息
        List<ImMessageDO> messages = messageStorageService.getHistoryMessages(
            userId, friendId, pageNo, pageSize
        );
        
        // 转换为 VO
        List<MessageVO> messageVOs = messages.stream()
            .map(this::convertToVO)
            .collect(Collectors.toList());
        
        return new PageResult<>(messageVOs, messages.size());
    }
}
```

---

## 四、配置说明

### 4.1 基础配置

```yaml
shengyu:
  netty:
    enable: true                    # 是否启用
    host: 0.0.0.0                   # 监听地址
    port: 9000                      # 监听端口
    use-epoll: true                 # 是否使用 Epoll
    boss-threads: 1                 # Boss 线程数
    worker-threads: 16              # Worker 线程数
    reader-idle-time: 60            # 读空闲超时（秒）
    enable-websocket: true          # 启用 WebSocket
    enable-protobuf: true           # 启用 Protobuf
```

### 4.2 性能配置

```yaml
shengyu:
  netty:
    so-backlog: 1024                # TCP 连接队列
    so-rcvbuf: 65536                # 接收缓冲区（64KB）
    so-sndbuf: 65536                # 发送缓冲区（64KB）
    write-buffer-low-water-mark: 32768   # 写缓冲区低水位（32KB）
    write-buffer-high-water-mark: 65536  # 写缓冲区高水位（64KB）
```

---

## 五、注意事项

1. **线程安全**：所有服务接口都是线程安全的，可以在多线程环境下使用。

2. **性能优化**：
   - 批量操作优先使用批量接口
   - 大量消息发送时考虑使用消息队列
   - 合理设置缓存策略

3. **异常处理**：
   - 所有接口都会捕获异常并记录日志
   - 业务代码应该处理返回的 null 值

4. **扩展性**：
   - 可以通过实现 MessageProcessor 接口扩展新的消息类型
   - 可以通过继承 MessageStorageService 实现自定义存储逻辑

5. **兼容性**：
   - 支持租户端（system）和平台端（platform）
   - 支持多设备登录
   - 支持多租户隔离
