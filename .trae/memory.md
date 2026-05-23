# 项目记忆 - IM SaaS 系统

> 更新时间: 2026-05-23
> 助手身份: 全栈开发工程师，主攻 Spring Boot2 + Vue3 技术栈

## 1. 项目结构

### 1.1 核心模块

| 模块路径 | 说明 |
|---------|------|
| `shengyu-module-system` | **IM业务后端服务模块**，包含所有IM相关服务 |
| `shengyu-ui/shengyu-ui-admin-flutter` | **正在开发的Flutter新版IM客户端** |
| `shengyu-ui/shengyu-ui-admin-uniappx` | uniappx版老IM客户端，**有重要参考价值** |
| `shengyu-ui/shengyu-ui-admin-vue3` | Vue3管理端 |
| `sql/IM-Flutter统一任务文档-v1.0.md` | Flutter IM统一执行文档(主文档) |

### 1.2 后端技术栈

- **框架**: Spring Boot2
- **Java版本**: JDK 8
- **IM协议**: WebSocket + HTTP REST
- **核心服务**: ImConversationService, ImMessageService, ImGroupService, ImContactService

### 1.3 Flutter客户端技术栈

- **状态管理**: Riverpod
- **路由**: go_router
- **网络**: Dio
- **WebSocket**: web_socket_channel
- **架构**: 四层架构 (presentation/application/domain/infrastructure)

## 2. 核心业务能力

### 2.1 IM功能模块

- [x] 登录与鉴权
- [x] 会话列表 (conversation)
- [x] 单聊/群聊 (chat/group)
- [x] 多消息类型 (text/image/video/file/voice/location/emoji...)
- [x] 搜索 (search)
- [x] 收藏 (favorite)
- [x] 组织通讯录 (contact)
- [x] 群管理 (group management)
- [x] 已读与角标 (read-receipt/badge)
- [x] 文件与媒体 (file/media)
- [ ] 音视频通话 (call) - 协议已定义，代码待完善
- [ ] 多端在线一致性

### 2.2 Flutter项目目录结构

```
lib/
├── app/                    # 应用层
│   ├── bootstrap/          # 启动引导
│   ├── router/             # 路由配置
│   ├── shell/             # 应用壳
│   └── theme/             # 主题配置
├── core/                   # 核心基础设施
│   ├── auth/              # 认证鉴权
│   ├── network/           # 网络请求(Dio)
│   ├── websocket/         # WebSocket客户端
│   ├── storage/           # 本地存储
│   └── platform/          # 平台能力(音视频/地图/推送)
└── features/               # 功能模块
    ├── im/
    │   ├── conversation/  # 会话
    │   ├── chat/          # 聊天
    │   ├── call/          # 通话
    │   ├── group/         # 群组
    │   ├── contact/       # 联系人
    │   ├── search/        # 搜索
    │   ├── favorite/      # 收藏
    │   └── receipt/       # 已读回执
    └── profile/           # 个人设置
```

## 3. 核心协议契约

### 3.1 HTTP接口(后端IM模块)

**认证相关**:
- `POST /system/auth/login` - 登录
- `POST /system/auth/refresh-token` - 刷新token
- `GET /system/auth/get-permission-info` - 获取权限信息

**会话相关**:
- `GET /system/im/conversation/list` - 获取会话列表
- `GET /system/im/conversation/sync` - 会话增量同步
- `GET /system/im/conversation/search` - 搜索会话
- `PUT /system/im/conversation/mark-read-seq` - 标记已读水位

**消息相关**:
- `GET /system/im/message/window` - 聊天窗口消息
- `GET /system/im/message/history` - 历史消息
- `POST /system/im/message/send` - 发送消息
- `POST /system/im/message/mark-read` - 标记消息已读

**角标相关**:
- `GET /system/im/badge/get` - 获取角标

### 3.2 WebSocket事件类型

**Session级**:
- `connected`, `authSucceeded`, `authFailed`
- `reauthSucceeded`, `reconnecting`, `invalidated`

**Conversation级**:
- `conversationHint`, `conversationUpdated`, `conversationDeleted`

**Message级**:
- `messageReceived`, `messageRecalled`, `readReceiptChanged`, `voicePlayedChanged`

**Badge级**:
- `badgeUpdated`

**Call级**:
- `callInvite`, `callAccepted`, `callRejected`, `callBusy`, `callCancelled`, `callEnded`

## 4. 冻结业务规则

### 4.1 ID处理规范

所有ID统一使用**String**类型，避免精度丢失:
- `messageId`, `chatId`, `groupId`, `userId`, `tenantId`
- `sequence`, `cursorVersion`, `conversationVersion`
- `lastReadSequence`, `lastMessageSequence`

### 4.2 会话规则

- 会话主键统一为 `chatId`
- `lastReadSequence` 只升不降
- `cursorVersion` 只前进

### 4.3 消息规则

- 消息最终态以更大 `rev` 为准
- 引用关系主键为 `quoteMessageId`
- 语音未听状态与已读状态分离

## 5. Flutter项目当前状态

### 5.1 已完成的功能

- 启动壳与路由骨架
- 核心基础设施(Auth, Dio, WebSocket)
- 会话列表页面与逻辑
- 聊天页面主状态机
- 消息发送/接收
- 已读水位推进
- 多消息类型UI(text/image/video/file/voice/location/emoji)

### 5.2 待完善功能

- 音视频通话完整实现
- 文件预览细节
- 地图与位置能力
- 离线推送
- 多端在线一致性

## 6. 关键设计文档索引

| 文档 | 路径 | 用途 |
|-----|------|------|
| Flutter统一任务文档 | `sql/IM-Flutter统一任务文档-v1.0.md` | **唯一执行主文档** |
| Flutter主目录与阅读顺序 | `sql/flutter-doc/IM-Flutter主目录与阅读顺序-v1.0.md` | 代码索引 |
| Flutter依赖建议 | `sql/flutter-doc/IM-Flutter依赖与Pubspec建议-v1.0.md` | 依赖参考 |
| Flutter后端协同约束 | `sql/flutter-doc/IM-Flutter后端协同约束与接口整顿建议.md` | 接口规范 |

## 7. 开发续接约定

当新开对话时，统一续接指令:
```
系统性阅读sql/flutter-doc/IM-Flutter统一任务文档-v1.0.md文档继续稳步推进
```

## 8. 用户偏好

- **沟通语言**: 中文
- **响应风格**: 简洁、结构化
- **代码风格**: 严格遵循项目现有规范
- **技术选型**: 不引入未在项目中使用的第三方库
