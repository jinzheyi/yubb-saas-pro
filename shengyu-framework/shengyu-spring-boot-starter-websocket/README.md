# 即时通讯中间件（shengyu-spring-boot-starter-websocket）

## 一、简介

这是一个基于 Netty + Protobuf 的高性能即时通讯中间件，提供底层的连接管理、协议处理、消息路由等能力。

### 核心特性

- ✅ **高性能**：基于 Netty，单机支持 50w+ TCP 连接
- ✅ **双协议**：支持 WebSocket（Web/小程序）和 Protobuf（移动端）
- ✅ **多租户**：支持租户隔离，适配 system 和 platform 模块
- ✅ **可扩展**：SPI 接口设计，业务逻辑由业务模块实现
- ✅ **易集成**：Spring Boot 自动配置，开箱即用

### 架构设计

**中间件职责**：
- 连接管理（Netty 服务器、会话管理）
- 协议处理（WebSocket、Protobuf）
- 消息路由（消息分发、消息转发）
- 认证鉴权（Token 验证）

**业务模块职责**：
- 消息存储（数据库设计、表结构、存储逻辑）
- 业务逻辑（好友关系、群组管理、会话管理）
- 业务规则（权限控制、敏感词过滤）

详见：[ARCHITECTURE.md](ARCHITECTURE.md)

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
    worker-threads: 16        # 工作线程数
```

### 2.3 实现 SPI 接口

在业务模块（如 shengyu-module-system）中实现 `MessageStorageService` 接口：

```java
@Service
public class SystemMessageStorageServiceImpl implements MessageStorageService {
    
    @Autowired
    private SystemImMessageMapper messageMapper;
    
    @Override
    public void saveMessage(ImMessage message) {
        // 1. 转换为业务 DO 对象
        SystemImMessageDO messageDO = convertToMessageDO(message);
        
        // 2. 保存到数据库
        messageMapper.insert(messageDO);
        
        // 3. 其他业务逻辑...
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

- **NettyServer**：Netty 服务器，支持 Epoll 优化
- **NettySessionManager**：会话管理器，管理所有在线连接
- **NettySession**：会话信息，包含用户ID、设备ID、租户ID等

### 3.2 协议处理

- **WebSocket**：对外协议，兼容 Web/小程序
- **Protobuf**：内部协议，高性能二进制序列化
- **im_message.proto**：消息协议定义

### 3.3 消息路由

- **MessageProcessor**：消息处理器接口
- **MessageProcessorFactory**：消息处理器工厂
- **NettyMessageSender**：消息发送器（单播/多播/广播）

### 3.4 认证鉴权

- **AuthService**：认证服务接口
- **AuthHandler**：认证处理器
- 支持租户端和平台端双端认证

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

```java
@Service
public class ChatService {
    
    @Autowired
    private NettyMessageSender messageSender;
    
    public void sendTextMessage(Long senderId, Long receiverId, String content) {
        TextMessage textMessage = TextMessage.newBuilder()
            .setContent(content)
            .build();
        messageSender.sendToUser(receiverId, MessageType.TEXT, textMessage);
    }
}
```

### 5.2 查询在线状态

```java
@Service
public class SessionService {
    
    @Autowired
    private NettySessionManager sessionManager;
    
    public boolean isUserOnline(Long userId) {
        return sessionManager.isUserOnline(userId);
    }
    
    public int getOnlineUserCount() {
        return sessionManager.getOnlineUserCount();
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

- 单机连接数：50w+ TCP 连接
- 消息延迟：< 100ms（局域网）
- 消息吞吐：10w+ msg/s（单机）
- Protobuf 优势：体积小 3-10 倍，速度快 20-100 倍

## 九、技术栈

- Netty 4.1.x
- Protobuf 3.x
- Spring Boot 2.7.18
- JDK 8

## 十、后续规划

详见 [TODO.md](TODO.md)

---

**版本**：v1.0.0  
**作者**：圣钰科技  
**更新时间**：2026年1月27日
