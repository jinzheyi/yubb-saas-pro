# Netty WebSocket Starter

高性能的Netty+WebSocket中间件starter，提供底层的独立于业务之外的消息发送核心设计、鉴权、相关工具类。方便业务模块依赖starter集成IM发送消息。

## 功能特性

- ✅ 高性能Netty WebSocket服务器
- ✅ 灵活的消息发送机制
- ✅ 可扩展的认证机制
- ✅ 完整的通道管理
- ✅ 丰富的工具类
- ✅ 简单易用的API接口
- ✅ 支持心跳检测

## 快速开始

### 1. 添加依赖

在业务模块的pom.xml中添加以下依赖：

```xml
<dependency>
    <groupId>com.shengyu.boot</groupId>
    <artifactId>shengyu-spring-boot-starter-netty</artifactId>
    <version>${project.version}</version>
</dependency>
```

### 2. 配置参数

在application.yaml或application.properties中添加以下配置：

```yaml
shengyu:
  netty:
    # 是否开启服务
    enable: true
    # 服务端口
    port: 8088
    # 即时通讯协议
    im-protocol: ws
    # WebSocket连接路径
    im-socket-url: /ws
    # 主线程数（默认：CPU核数*2）
    boss-thread: 0
    # 工作线程数（默认：CPU核数*2）
    worker-thread: 0
    # 连接队列大小
    back-log: 128
    # 读心跳检测时间（秒）
    read-heart-beat-time: 60
    # 写心跳检测时间（秒）
    writer-heart-beat-time: 60
    # 读写心跳检测时间（秒）
    all-heart-beat-time: 60
```

### 3. 使用API

#### 注入NettyService

```java
@Autowired
private NettyService nettyService;
```

#### 发送消息给指定用户

```java
// 发送普通对象
nettyService.sendToUser("userId", "Hello, World!");

// 发送ImChat格式消息
ImChat imChat = ImChat.builder()
        .type("chat")
        .msg("Hello, World!")
        .build();
nettyService.sendToUser("userId", imChat);
```

#### 发送消息给多个用户

```java
List<String> userIds = Arrays.asList("userId1", "userId2", "userId3");
nettyService.sendToUsers(userIds, "Hello, All!");
```

#### 发送消息给所有在线用户

```java
nettyService.sendToAll("System Notification: Server is going to restart.");
```

#### 检查用户是否在线

```java
boolean isOnline = nettyService.isUserOnline("userId");
```

#### 获取在线用户数量

```java
int onlineCount = nettyService.getOnlineUserCount();
```

## API说明

### NettyService

统一的服务入口，提供以下主要方法：

| 方法名 | 描述 | 参数 | 返回值 |
|--------|------|------|--------|
| `sendToUser` | 发送消息给指定用户 | `userId`: 用户ID<br>`message`: 消息内容 | `boolean`: 是否发送成功 |
| `sendToUsers` | 发送消息给多个用户 | `userIds`: 用户ID列表<br>`message`: 消息内容 | `void` |
| `sendToAll` | 发送消息给所有在线用户 | `message`: 消息内容 | `void` |
| `closeUserChannel` | 关闭用户连接 | `userId`: 用户ID | `void` |
| `getUserChannel` | 获取用户通道 | `userId`: 用户ID | `Channel`: 通道对象 |
| `getOnlineUserCount` | 获取在线用户数量 | - | `int`: 在线用户数量 |
| `isUserOnline` | 检查用户是否在线 | `userId`: 用户ID | `boolean`: 是否在线 |

### ImChat消息格式

```java
public class ImChat {
    private Long id;           // 消息ID
    private String type;       // 消息类型
    private Integer sendStatus; // 发送状态
    private String msg;        // 消息内容
    private String code;       // 错误码
    private String fromId;     // 发送者ID
    private String toId;       // 接收者ID
    private Date createTime;   // 创建时间
    private Object data;       // 附加数据
}
```

## 配置项说明

| 配置项 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| `shengyu.netty.enable` | boolean | true | 是否开启Netty服务 |
| `shengyu.netty.port` | int | - | 服务端口（必填） |
| `shengyu.netty.im-protocol` | string | - | 即时通讯协议（必填，如ws或wss） |
| `shengyu.netty.im-socket-url` | string | - | WebSocket连接路径 |
| `shengyu.netty.boss-thread` | int | 0 | 主线程数，0表示使用默认值（CPU核数*2） |
| `shengyu.netty.worker-thread` | int | 0 | 工作线程数，0表示使用默认值（CPU核数*2） |
| `shengyu.netty.back-log` | int | 128 | 连接队列大小 |
| `shengyu.netty.read-heart-beat-time` | int | 60 | 读心跳检测时间（秒） |
| `shengyu.netty.writer-heart-beat-time` | int | 60 | 写心跳检测时间（秒） |
| `shengyu.netty.all-heart-beat-time` | int | 60 | 读写心跳检测时间（秒） |

## 扩展与定制

### 自定义认证机制

如果需要自定义认证逻辑，可以实现`NettyAuthService`接口，然后在Spring容器中注册为Bean，框架会自动使用你的实现。

```java
@Component
public class CustomAuthService implements NettyAuthService {
    // 实现自定义认证逻辑
}
```

### 自定义消息处理

如果需要自定义消息处理逻辑，可以继承`ShengyuChannelInboundHandler`类，并重写相应的方法，然后在Spring容器中注册为Bean。

## 注意事项

1. 确保配置文件中的端口没有被其他服务占用
2. WebSocket连接URL格式：`ws://host:port/im-socket-url`
3. 客户端连接时需要在header或参数中提供认证信息（token和userId）
4. 建议使用心跳检测机制，确保连接的有效性

## 版本历史

- 1.0.0 - 初始版本，提供基本的WebSocket服务和消息发送功能

## 许可证

Apache License 2.0
