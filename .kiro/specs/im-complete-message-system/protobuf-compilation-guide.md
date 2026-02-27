# Protobuf 编译指南

## 概述

本文档说明如何编译扩展后的 Protobuf 消息定义，生成 Java 和 TypeScript 代码。

## 已完成的工作

### 1. 扩展 Protobuf 消息定义

已在 `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/proto/im_message.proto` 中添加以下新消息类型:

#### 1.1 QuoteReplyMessage (引用回复消息)
- **需求**: 8.3 (引用回复功能)
- **字段**:
  - `quoteMessageId`: 引用的消息ID
  - `quoteContent`: 引用的消息内容摘要
  - `quoteSenderId`: 引用的消息发送者ID
  - `quoteSenderName`: 引用的消息发送者名称
  - `replyContent`: 回复的文本内容
  - `atUserIds`: @用户列表

#### 1.2 TypingMessage (正在输入消息)
- **需求**: 10.1 (正在输入状态)
- **字段**:
  - `targetUserId`: 目标用户ID (单聊时使用)
  - `groupId`: 群组ID (群聊时使用)
  - `isTyping`: 是否正在输入

#### 1.3 CallSignalMessage (通话信令消息)
- **需求**: 21.1, 22.1 (语音/视频通话信令处理)
- **字段**:
  - `callId`: 通话ID
  - `callType`: 通话类型 (1-语音 2-视频)
  - `signalType`: 信令类型 (1-呼叫 2-接听 3-拒绝 4-挂断 5-忙线 6-切换摄像头)
  - `callerId`: 呼叫方ID
  - `calleeId`: 接听方ID
  - `rejectReason`: 拒绝原因
  - `extraData`: 扩展数据 (JSON格式，用于传递WebRTC信令)

#### 1.4 WorkflowNotifyMessage (流程通知消息)
- **需求**: 24.1 (流程引擎通知集成)
- **字段**:
  - `processInstanceId`: 流程实例ID
  - `processName`: 流程名称
  - `initiatorId`: 发起人ID
  - `initiatorName`: 发起人名称
  - `content`: 审批内容
  - `buttons`: 操作按钮列表
  - `status`: 流程状态 (1-待审批 2-已通过 3-已拒绝 4-已撤回)
  - `jumpUrl`: 跳转URL

#### 1.5 TodoReminderMessage (待办提醒消息)
- **需求**: 25.1 (待办提醒通知)
- **字段**:
  - `todoId`: 待办ID
  - `title`: 待办标题
  - `content`: 待办内容
  - `dueTime`: 截止日期 (时间戳，毫秒)
  - `reminderType`: 提醒类型 (1-新待办 2-截止日期提醒 3-过期提醒 4-完成通知)
  - `jumpUrl`: 跳转URL
  - `status`: 待办状态 (1-待处理 2-已完成 3-已过期)

#### 1.6 MessageType 枚举扩展

已在 `MessageType` 枚举中添加以下新类型:
- `QUOTE_REPLY = 205`: 引用回复
- `CALL_SIGNAL = 206`: 通话信令
- `WORKFLOW_NOTIFY = 207`: 流程通知
- `TODO_REMINDER = 208`: 待办提醒

**注意**: `TYPING = 203` 和 `BADGE_UPDATE = 204` 已在原始定义中存在。

## 编译步骤

### 方法1: 使用 Maven 编译 (推荐)

#### 前提条件
- 已安装 Maven 3.6+
- 已配置 Maven 环境变量

#### 编译命令

```bash
# 进入项目根目录
cd D:\jxctkj\ideaProject\sy-saas\yubb-saas-pro

# 编译 Protobuf 生成 Java 代码
mvn protobuf:compile -f shengyu-framework/shengyu-spring-boot-starter-websocket/pom.xml
```

#### 输出位置

Java 代码将生成到:
```
shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/protocol/
```

生成的文件包括:
- `QuoteReplyMessage.java`
- `QuoteReplyMessageOrBuilder.java`
- `TypingMessage.java`
- `TypingMessageOrBuilder.java`
- `CallSignalMessage.java`
- `CallSignalMessageOrBuilder.java`
- `WorkflowNotifyMessage.java`
- `WorkflowNotifyMessageOrBuilder.java`
- `WorkflowButton.java`
- `WorkflowButtonOrBuilder.java`
- `TodoReminderMessage.java`
- `TodoReminderMessageOrBuilder.java`
- `MessageType.java` (更新)
- `ImMessageProto.java` (更新)

### 方法2: 使用 IntelliJ IDEA 编译

#### 步骤

1. 在 IntelliJ IDEA 中打开项目
2. 右键点击 `shengyu-spring-boot-starter-websocket` 模块
3. 选择 `Maven` -> `Generate Sources and Update Folders`
4. 或者在 Maven 面板中找到 `shengyu-spring-boot-starter-websocket` -> `Plugins` -> `protobuf` -> `protobuf:compile`
5. 双击执行编译

### 方法3: 手动使用 protoc 编译

#### 前提条件
- 下载并安装 protoc 编译器: https://github.com/protocolbuffers/protobuf/releases
- 将 protoc 添加到系统 PATH

#### 编译命令

```bash
# 进入 proto 文件目录
cd shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/proto

# 编译生成 Java 代码
protoc --java_out=../java im_message.proto
```

## TypeScript 代码生成 (前端)

### 前提条件

安装 protobuf.js 工具:
```bash
npm install -g protobufjs
```

### 生成 TypeScript 定义

```bash
# 进入 proto 文件目录
cd shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/proto

# 生成 TypeScript 定义文件
pbjs -t static-module -w es6 -o im_message.js im_message.proto
pbts -o im_message.d.ts im_message.js

# 将生成的文件复制到前端项目
cp im_message.js shengyu-ui/shengyu-ui-admin-uniappx/types/
cp im_message.d.ts shengyu-ui/shengyu-ui-admin-uniappx/types/
```

### 前端使用示例

```typescript
import { ImMessage, MessageType, QuoteReplyMessage, TypingMessage } from '@/types/im_message'

// 构建引用回复消息
const quoteReply = QuoteReplyMessage.create({
  quoteMessageId: 123456,
  quoteContent: "这是被引用的消息内容",
  quoteSenderId: 1001,
  quoteSenderName: "张三",
  replyContent: "我同意你的观点",
  atUserIds: [1002, 1003]
})

// 构建正在输入消息
const typing = TypingMessage.create({
  targetUserId: 1001,
  isTyping: true
})

// 构建 IM 消息
const message = ImMessage.create({
  header: {
    messageId: Date.now(),
    messageType: MessageType.QUOTE_REPLY,
    senderId: 1000,
    receiverId: 1001,
    timestamp: Date.now(),
    sequence: 1
  },
  body: QuoteReplyMessage.encode(quoteReply).finish()
})
```

## 验证编译结果

### 检查 Java 文件

确认以下文件已生成:
```bash
ls shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/protocol/QuoteReplyMessage.java
ls shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/protocol/TypingMessage.java
ls shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/protocol/CallSignalMessage.java
ls shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/protocol/WorkflowNotifyMessage.java
ls shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/java/com/shengyu/framework/websocket/core/protocol/TodoReminderMessage.java
```

### 检查 MessageType 枚举

打开 `MessageType.java` 确认包含以下枚举值:
- `QUOTE_REPLY(205)`
- `CALL_SIGNAL(206)`
- `WORKFLOW_NOTIFY(207)`
- `TODO_REMINDER(208)`

### 编译项目

```bash
# 编译整个项目确保没有错误
mvn clean compile -f shengyu-framework/shengyu-spring-boot-starter-websocket/pom.xml
```

## 常见问题

### Q1: Maven 编译失败，提示找不到 protoc

**解决方案**: 
- 确保 Maven 配置了 `os-maven-plugin` 扩展
- 确保网络连接正常，Maven 会自动下载 protoc 编译器
- 如果网络问题，可以手动下载 protoc 并配置 `protocExecutable` 参数

### Q2: 生成的 Java 文件编码错误

**解决方案**:
- 确保 proto 文件使用 UTF-8 编码
- 在 Maven 配置中添加 `<encoding>UTF-8</encoding>`

### Q3: TypeScript 定义文件导入错误

**解决方案**:
- 确保使用 `pbjs` 和 `pbts` 工具生成
- 检查 TypeScript 配置中的 `moduleResolution` 设置
- 使用 `import type` 导入类型定义

## 下一步

编译完成后，可以继续执行以下任务:
1. 实现后端消息处理器 (MessageProcessor)
2. 实现前端消息服务 (MessageService)
3. 集成到 WebSocket 中间件
4. 编写单元测试和集成测试

## 参考资料

- [Protocol Buffers 官方文档](https://protobuf.dev/)
- [protobuf-maven-plugin 文档](https://www.xolstice.org/protobuf-maven-plugin/)
- [protobuf.js 文档](https://github.com/protobufjs/protobuf.js)
