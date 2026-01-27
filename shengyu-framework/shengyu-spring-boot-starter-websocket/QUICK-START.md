# 即时通讯中间件快速开始指南

## 一、快速集成

### 1.1 添加依赖

在业务模块的 `pom.xml` 中添加依赖：

```xml
<dependency>
    <groupId>com.shengyu.boot</groupId>
    <artifactId>shengyu-spring-boot-starter-websocket</artifactId>
</dependency>
```

### 1.2 配置文件

在 `application.yaml` 中添加配置：

```yaml
shengyu:
  netty:
    enable: true              # 启用 Netty 服务
    port: 9000                # WebSocket 端口
    worker-threads: 16        # 工作线程数（建议 CPU核心数 * 2）
    boss-threads: 1           # Boss 线程数
    use-epoll: true           # 是否使用 Epoll（Linux环境推荐）
    heartbeat:
      enabled: true           # 启用心跳
      interval: 30            # 心跳间隔（秒）
      timeout: 90             # 心跳超时（秒）
```

### 1.3 执行 SQL 脚本

执行 `sql/im_message.sql` 创建数据库表：

```sql
-- 消息表
CREATE TABLE im_message (...);

-- 会话表
CREATE TABLE im_conversation (...);

-- 群组表
CREATE TABLE im_group (...);

-- 群成员表
CREATE TABLE im_group_member (...);

-- 好友表
CREATE TABLE im_friend (...);

-- 好友申请表
CREATE TABLE im_friend_apply (...);
```

### 1.4 启动应用

启动 Spring Boot 应用，Netty 服务会自动启动：

```
[Netty] Netty 服务器启动成功: port=9000
[Netty] 注册文本消息处理器
[Netty] 注册图片消息处理器
[Netty] 注册语音消息处理器
[Netty] 注册文件消息处理器
```

## 二、基础使用

### 2.1 发送消息

```java
@Service
public class ChatService {
    
    @Autowired
    private NettyMessageSender messageSender;
    
    @Autowired
    private MessageStorageService messageStorageService;
    
    /**
     * 发送文本消息
     */
    public void sendTextMessage(Long senderId, Long receiverId, String content) {
        // 1. 构建消息
        ImMessageDO message = ImMessageDO.builder()
            .senderId(senderId)
            .receiverId(receiverId)
            .messageType(MessageType.TEXT.getNumber())
            .content(content)
            .status(0)
            .build();
        
        // 2. 保存到数据库
        Long messageId = messageStorageService.saveMessage(message);
        
        // 3. 发送给接收者
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent(content)
            .build();
        messageSender.sendToUser(receiverId, MessageType.TEXT, textMessage);
    }
}
```

### 2.2 查询消息

```java
@Service
public class MessageQueryService {
    
    @Autowired
    private MessageStorageService messageStorageService;
    
    /**
     * 查询历史消息
     */
    public List<ImMessageDO> getHistoryMessages(Long userId, Long receiverId, int pageNo) {
        return messageStorageService.getHistoryMessages(userId, receiverId, pageNo, 20);
    }
    
    /**
     * 查询离线消息
     */
    public List<ImMessageDO> getOfflineMessages(Long userId, Long lastMessageId) {
        return messageStorageService.getOfflineMessages(userId, lastMessageId);
    }
    
    /**
     * 统计未读消息
     */
    public long countUnreadMessages(Long userId) {
        return messageStorageService.countUnreadMessages(userId);
    }
}
```

### 2.3 会话管理

```java
@Service
public class SessionService {
    
    @Autowired
    private NettySessionManager sessionManager;
    
    /**
     * 检查用户是否在线
     */
    public boolean isUserOnline(Long userId) {
        return sessionManager.isUserOnline(userId);
    }
    
    /**
     * 获取用户的所有设备
     */
    public List<NettySession> getUserDevices(Long userId) {
        return sessionManager.getSessionsByUserId(userId);
    }
    
    /**
     * 获取在线用户数
     */
    public int getOnlineUserCount() {
        return sessionManager.getOnlineUserCount();
    }
    
    /**
     * 获取租户的在线用户
     */
    public List<NettySession> getTenantOnlineUsers(Long tenantId) {
        return sessionManager.getSessionsByTenantId(tenantId);
    }
}
```

### 2.4 消息缓存

```java
@Service
public class MessageCacheService {
    
    @Autowired
    private MessageCacheService messageCacheService;
    
    /**
     * 缓存消息
     */
    public void cacheMessage(ImMessageDO message) {
        messageCacheService.cacheMessage(message);
    }
    
    /**
     * 获取缓存的消息
     */
    public ImMessageDO getCachedMessage(Long messageId) {
        return messageCacheService.getCachedMessage(messageId);
    }
    
    /**
     * 增加未读计数
     */
    public long incrementUnreadCount(Long userId, long delta) {
        return messageCacheService.incrementUnreadCount(userId, delta);
    }
}
```

### 2.5 离线推送

```java
@Service
public class PushService {
    
    @Autowired
    private OfflinePushService offlinePushService;
    
    /**
     * 推送离线消息
     */
    public void pushOfflineMessage(Long userId, ImMessageDO message) {
        if (offlinePushService.isPushEnabled(userId)) {
            offlinePushService.pushOfflineMessage(userId, message);
        }
    }
    
    /**
     * 绑定推送Token
     */
    public void bindPushToken(Long userId, String deviceType, String pushToken) {
        offlinePushService.bindPushToken(userId, deviceType, pushToken);
    }
    
    /**
     * 设置推送开关
     */
    public void setPushEnabled(Long userId, boolean enabled) {
        offlinePushService.setPushEnabled(userId, enabled);
    }
}
```

## 三、高级使用

### 3.1 自定义消息处理器

```java
@Component
public class CustomMessageProcessor implements MessageProcessor {
    
    @Autowired
    private NettySessionManager sessionManager;
    
    @Autowired
    private MessageStorageService messageStorageService;
    
    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        // 1. 获取会话信息
        NettySession session = sessionManager.getSession(ctx.channel());
        if (session == null) {
            log.warn("会话不存在");
            return;
        }
        
        // 2. 处理自定义消息
        // ... 你的业务逻辑
        
        // 3. 保存消息
        ImMessageDO messageDO = convertToMessageDO(message);
        messageStorageService.saveMessage(messageDO);
        
        // 4. 转发消息
        Long receiverId = message.getHeader().getReceiverId();
        if (sessionManager.isUserOnline(receiverId)) {
            List<NettySession> receiverSessions = sessionManager.getSessionsByUserId(receiverId);
            for (NettySession receiverSession : receiverSessions) {
                receiverSession.getChannel().writeAndFlush(message);
            }
        }
    }
}

// 注册处理器
@Configuration
public class CustomMessageConfig {
    
    @Bean
    public CustomMessageProcessor customMessageProcessor(
            MessageProcessorFactory processorFactory,
            NettySessionManager sessionManager,
            MessageStorageService messageStorageService) {
        CustomMessageProcessor processor = new CustomMessageProcessor();
        processorFactory.registerProcessor(MessageType.CUSTOM, processor);
        return processor;
    }
}
```

### 3.2 自定义存储实现

```java
@Service
public class MongoMessageStorageService implements MessageStorageService {
    
    @Autowired
    private MongoTemplate mongoTemplate;
    
    @Override
    public Long saveMessage(ImMessageDO messageDO) {
        // 使用 MongoDB 存储
        mongoTemplate.save(messageDO);
        return messageDO.getId();
    }
    
    // 实现其他方法...
}
```

### 3.3 集成推送平台

以极光推送为例：

```java
@Service
public class JPushOfflinePushService implements OfflinePushService {
    
    private JPushClient jpushClient;
    
    @PostConstruct
    public void init() {
        String masterSecret = "your-master-secret";
        String appKey = "your-app-key";
        jpushClient = new JPushClient(masterSecret, appKey);
    }
    
    @Override
    public boolean pushOfflineMessage(Long userId, ImMessageDO message) {
        try {
            // 构建推送内容
            PushPayload payload = PushPayload.newBuilder()
                .setPlatform(Platform.all())
                .setAudience(Audience.alias(userId.toString()))
                .setNotification(Notification.newBuilder()
                    .setAlert("您有新消息")
                    .addPlatformNotification(IosNotification.newBuilder()
                        .setAlert(message.getContent())
                        .setBadge(1)
                        .setSound("default")
                        .build())
                    .addPlatformNotification(AndroidNotification.newBuilder()
                        .setAlert(message.getContent())
                        .build())
                    .build())
                .build();
            
            // 发送推送
            PushResult result = jpushClient.sendPush(payload);
            return result.isResultOK();
        } catch (Exception e) {
            log.error("推送失败", e);
            return false;
        }
    }
}
```

## 四、客户端连接

### 4.1 WebSocket 连接（Web/小程序）

```javascript
// JavaScript 示例
const ws = new WebSocket('ws://localhost:9000/ws');

// 连接成功
ws.onopen = function() {
    console.log('WebSocket 连接成功');
    
    // 发送认证消息
    const authMessage = {
        header: {
            messageType: 'AUTH',
            senderId: 123,
            timestamp: Date.now()
        },
        body: {
            token: 'your-access-token'
        }
    };
    ws.send(JSON.stringify(authMessage));
};

// 接收消息
ws.onmessage = function(event) {
    const message = JSON.parse(event.data);
    console.log('收到消息:', message);
};

// 发送文本消息
function sendTextMessage(receiverId, content) {
    const message = {
        header: {
            messageType: 'TEXT',
            senderId: 123,
            receiverId: receiverId,
            timestamp: Date.now()
        },
        body: {
            content: content
        }
    };
    ws.send(JSON.stringify(message));
}

// 心跳
setInterval(() => {
    const heartbeat = {
        header: {
            messageType: 'HEARTBEAT',
            timestamp: Date.now()
        }
    };
    ws.send(JSON.stringify(heartbeat));
}, 30000); // 30秒一次
```

### 4.2 Protobuf 连接（移动端）

```java
// Android 示例
public class IMClient {
    
    private Channel channel;
    
    public void connect(String host, int port) {
        EventLoopGroup group = new NioEventLoopGroup();
        Bootstrap bootstrap = new Bootstrap();
        bootstrap.group(group)
            .channel(NioSocketChannel.class)
            .handler(new ChannelInitializer<SocketChannel>() {
                @Override
                protected void initChannel(SocketChannel ch) {
                    ch.pipeline()
                        .addLast(new ProtobufVarint32FrameDecoder())
                        .addLast(new ProtobufDecoder(ImMessage.getDefaultInstance()))
                        .addLast(new ProtobufVarint32LengthFieldPrepender())
                        .addLast(new ProtobufEncoder())
                        .addLast(new IMClientHandler());
                }
            });
        
        ChannelFuture future = bootstrap.connect(host, port).sync();
        channel = future.channel();
    }
    
    public void sendTextMessage(long receiverId, String content) {
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent(content)
            .build();
        
        ImMessage message = ImMessage.newBuilder()
            .setHeader(MessageHeader.newBuilder()
                .setMessageType(MessageType.TEXT)
                .setSenderId(userId)
                .setReceiverId(receiverId)
                .setTimestamp(System.currentTimeMillis())
                .build())
            .setBody(textMessage.toByteString())
            .build();
        
        channel.writeAndFlush(message);
    }
}
```

## 五、监控和运维

### 5.1 查看在线状态

```java
@RestController
@RequestMapping("/api/im/monitor")
public class IMMonitorController {
    
    @Autowired
    private NettySessionManager sessionManager;
    
    /**
     * 获取在线统计
     */
    @GetMapping("/stats")
    public Map<String, Object> getStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("onlineUserCount", sessionManager.getOnlineUserCount());
        stats.put("onlineConnectionCount", sessionManager.getOnlineConnectionCount());
        return stats;
    }
    
    /**
     * 获取租户在线用户
     */
    @GetMapping("/tenant/{tenantId}/online")
    public List<Long> getTenantOnlineUsers(@PathVariable Long tenantId) {
        return sessionManager.getSessionsByTenantId(tenantId).stream()
            .map(NettySession::getUserId)
            .distinct()
            .collect(Collectors.toList());
    }
}
```

### 5.2 性能监控

```java
@Component
public class IMMetrics {
    
    @Autowired
    private MeterRegistry meterRegistry;
    
    @Autowired
    private NettySessionManager sessionManager;
    
    @Scheduled(fixedRate = 60000) // 每分钟
    public void recordMetrics() {
        // 在线用户数
        meterRegistry.gauge("im.online.users", sessionManager.getOnlineUserCount());
        
        // 在线连接数
        meterRegistry.gauge("im.online.connections", sessionManager.getOnlineConnectionCount());
    }
}
```

## 六、常见问题

### 6.1 连接失败

**问题**：客户端无法连接到 WebSocket 服务

**解决**：
1. 检查端口是否开放：`netstat -an | grep 9000`
2. 检查防火墙规则
3. 检查 Netty 服务是否启动成功
4. 检查客户端连接地址是否正确

### 6.2 认证失败

**问题**：连接后立即断开，提示认证失败

**解决**：
1. 检查 Token 是否有效
2. 检查 Token 是否过期
3. 检查用户类型是否正确（ADMIN/PLATFORM）
4. 查看服务端日志：`[AuthHandler] Token 验证失败`

### 6.3 消息发送失败

**问题**：消息发送后接收者收不到

**解决**：
1. 检查接收者是否在线：`sessionManager.isUserOnline(receiverId)`
2. 检查消息是否保存成功
3. 检查消息处理器是否注册
4. 查看服务端日志

### 6.4 性能问题

**问题**：连接数增加后性能下降

**解决**：
1. 调整工作线程数：`worker-threads: 32`
2. 启用 Epoll（Linux）：`use-epoll: true`
3. 调整 JVM 参数：`-Xmx4g -Xms4g`
4. 考虑集群部署

## 七、最佳实践

### 7.1 消息发送

- ✅ 先保存到数据库，再发送
- ✅ 检查接收者是否在线
- ✅ 离线用户推送通知
- ✅ 使用缓存提升性能

### 7.2 会话管理

- ✅ 定期清理过期会话
- ✅ 支持多设备登录
- ✅ 记录设备信息
- ✅ 实现连接迁移

### 7.3 性能优化

- ✅ 使用 Protobuf 减少带宽
- ✅ 使用 Redis 缓存热点数据
- ✅ 批量操作减少数据库压力
- ✅ 异步处理耗时操作

### 7.4 安全性

- ✅ Token 认证
- ✅ 消息加密（可选）
- ✅ 敏感词过滤
- ✅ 频率限制

## 八、参考文档

- [README.md](README.md) - 项目说明
- [API.md](API.md) - API 接口文档
- [TODO.md](TODO.md) - 后续工作事项
- [第一阶段完成总结-最新.md](../../../第一阶段完成总结-最新.md) - 完成总结

---

**更新时间**：2026年1月27日  
**版本**：v1.0.0
