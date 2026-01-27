# Maven 依赖问题解决总结

## 问题描述

在刷新 Maven 时遇到错误：
```
com.google.protobuf:protobuf-java:jar:unknown was not found
```

## 根本原因

1. `shengyu-spring-boot-starter-websocket/pom.xml` 中引用了 `protobuf-java` 依赖
2. 但没有指定版本号（依赖父 POM 的版本管理）
3. 父 POM `shengyu-dependencies/pom.xml` 中没有定义 `protobuf-java` 的版本

## 解决方案

### 1. 添加 Protobuf 版本定义

在 `shengyu-dependencies/pom.xml` 中添加：

**properties 部分：**
```xml
<protobuf.version>3.21.7</protobuf.version>
```

**dependencyManagement 部分：**
```xml
<dependency>
    <groupId>com.google.protobuf</groupId>
    <artifactId>protobuf-java</artifactId>
    <version>${protobuf.version}</version>
</dependency>
```

### 2. 修复 Maven 插件版本兼容性

由于用户的 Maven 版本是 3.5.4，需要降级插件版本：

**pom.xml：**
```xml
<maven-surefire-plugin.version>2.22.2</maven-surefire-plugin.version>
<maven-compiler-plugin.version>3.8.1</maven-compiler-plugin.version>
<flatten-maven-plugin.version>1.5.0</flatten-maven-plugin.version>
```

**shengyu-dependencies/pom.xml：**
```xml
<flatten-maven-plugin.version>1.5.0</flatten-maven-plugin.version>
```

### 3. 修复重复依赖

删除 `shengyu-dependencies/pom.xml` 中重复的 `shengyu-spring-boot-starter-file` 依赖声明（第 750 行附近）。

### 4. 修复代码问题

#### 4.1 修复 OfflinePushService 和 OfflinePushServiceImpl

将 `ImMessageDO` 引用改为 `ImMessage`（Protobuf 生成的类）：

```java
// 修改前
void pushOfflineMessage(Long userId, ImMessageDO message);

// 修改后
void pushOfflineMessage(Long userId, ImMessage message);
```

#### 4.2 简化 AuthServiceImpl

由于中间件不应该依赖业务模块，将 `AuthServiceImpl` 改为默认空实现，业务模块需要提供自己的实现。

#### 4.3 添加缺失的导入

在 `NettyAutoConfiguration.java` 中添加：
```java
import com.shengyu.framework.websocket.core.netty.handler.AuthHandler;
import com.shengyu.framework.websocket.core.netty.handler.ExceptionHandler;
import com.shengyu.framework.websocket.core.netty.handler.HeartbeatHandler;
import com.shengyu.framework.websocket.core.netty.handler.ProtobufMessageHandler;
import com.shengyu.framework.websocket.core.netty.handler.WebSocketFrameHandler;
import com.shengyu.framework.websocket.core.processor.impl.FileMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.ImageMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.TextMessageProcessor;
import com.shengyu.framework.websocket.core.processor.impl.VoiceMessageProcessor;
```

#### 4.4 修复 Lombok 生成的方法名

Lombok 对 Boolean 类型生成 `getXxx()` 而不是 `isXxx()`，需要修改调用：

```java
// 修改前
nettyProperties.isUseEpoll()
nettyProperties.isEnableWebSocket()
nettyProperties.isEnableProtobuf()

// 修改后
nettyProperties.getUseEpoll()
nettyProperties.getEnableWebSocket()
nettyProperties.getEnableProtobuf()
```

## 编译结果

✅ **编译成功！**

```
[INFO] BUILD SUCCESS
[INFO] Total time: 48.136 s
```

## Protobuf 编译

Maven 插件自动下载并编译了 Protobuf 文件：

```
[INFO] --- protobuf-maven-plugin:0.6.1:compile (default) @ shengyu-spring-boot-starter-websocket ---
[INFO] Compiling 1 proto file(s) to D:\jxctkj\ideaProject\sy-saas\yubb-saas-pro\shengyu-framework\shengyu-spring-boot-starter-websocket\src\main\java
```

生成的文件位于：
```
shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/protocol/
```

包含 26 个 Java 类文件（Protobuf 生成的消息类）。

## 后续步骤

1. ✅ Protobuf 文件已成功编译
2. ✅ 所有依赖已正确解析
3. ✅ 代码编译通过
4. ⚠️ 业务模块需要实现 `AuthService` 接口以集成 OAuth2 认证
5. ⚠️ 业务模块需要实现 `MessageStorageService` 接口以存储消息
6. ⚠️ 业务模块需要实现 `OfflinePushService` 接口以集成推送服务

## 注意事项

1. Maven 版本：当前使用 3.5.4，建议升级到 3.6.3+ 以使用最新的插件版本
2. 中间件设计：遵循"只提供底层能力"的原则，业务逻辑由业务模块实现
3. Protobuf 编译：已配置 Maven 插件自动编译，无需手动执行脚本

## 相关文档

- [Protobuf 编译说明](./Protobuf编译说明.md)
- [架构调整总结](./架构调整总结.md)
- [WebSocket 模块 README](./shengyu-framework/shengyu-spring-boot-starter-websocket/README.md)
- [架构设计文档](./shengyu-framework/shengyu-spring-boot-starter-websocket/ARCHITECTURE.md)
