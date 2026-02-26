# 实施计划: IM消息角标和菜单角标通知

## 概述

本实施计划实现完整的消息角标和菜单角标实时通知功能,包括:

1. **BadgeService 服务**: 统一管理所有角标数据和逻辑
2. **WebSocket 集成**: 处理 BADGE_UPDATE (messageType = 204) 消息
3. **消息列表角标**: 每个会话显示未读消息数
4. **底部导航栏角标**: 显示总未读消息数
5. **工作台菜单角标**: 显示待办数量
6. **本地持久化**: 角标数据缓存和恢复
7. **多端同步**: 利用 WebSocket 中间件实现多设备同步
8. **后端 API**: 提供角标数据查询和清空接口

**关键理解**: 
- WebSocket 中间件已支持 BADGE_UPDATE (messageType = 204)
- 前端使用 BadgeService 统一管理角标状态
- 后端通过 WebSocket 主动推送角标更新
- 本地缓存确保离线时的用户体验

## 任务

### 阶段1: 核心服务层

- [ ] 1. 创建 BadgeService 服务类
  - [ ] 1.1 创建 badge-service.uts 文件
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/services/badge-service.uts`
    - 定义 BadgeData 类型 (totalUnread, conversationBadges, menuBadges, lastUpdateTime)
    - 定义 BadgeListener 接口
    - 创建 BadgeService 类骨架
    - _需求: 6.1, 6.2_
  
  - [ ] 1.2 实现基础角标管理方法
    - 实现 `getTotalUnread()`: 返回总未读数
    - 实现 `getConversationBadge(conversationId)`: 返回会话未读数
    - 实现 `getMenuBadge(menuId)`: 返回菜单角标
    - 实现 `incrementConversationBadge()`: 增加会话未读数
    - 实现 `decrementConversationBadge()`: 减少会话未读数
    - 实现 `clearConversationBadge()`: 清空会话未读数
    - 实现 `updateMenuBadge()`: 更新菜单角标
    - _需求: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 4.1, 4.2, 4.3, 4.4_
  
  - [ ] 1.3 实现监听器机制
    - 实现 `addListener()`: 添加角标监听器
    - 实现 `removeListener()`: 移除角标监听器
    - 实现 `notifyListeners()`: 通知所有监听器
    - 使用防抖机制避免频繁通知 (300ms)
    - _需求: 6.3, 8.1_
  
  - [ ] 1.4 实现本地存储功能
    - 实现 `saveToLocal()`: 保存角标数据到 localStorage
    - 实现 `loadFromLocal()`: 从 localStorage 加载角标数据
    - 数据格式: StoredBadgeData (包含 version 字段)
    - 使用节流机制避免频繁保存 (1000ms)
    - 添加错误处理,存储失败时继续使用内存数据
    - _需求: 5.1, 5.2, 5.3, 5.4, 5.5, 9.3_
  
  - [ ] 1.5 实现初始化方法
    - 实现 `init()`: 初始化角标服务
    - 从本地存储加载数据
    - 如果本地数据不存在或过期,从服务器同步
    - 注册 MessageService 监听器
    - _需求: 5.2, 6.5_

- [ ] 1.6 编写 BadgeService 的单元测试
  - 测试角标增加/减少/清空逻辑
  - 测试本地存储和加载
  - 测试监听器通知机制
  - 测试防抖和节流机制
  - **验证: 需求 1.1-1.6, 4.1-4.4, 5.1-5.5**

### 阶段2: WebSocket 集成

- [ ] 2. 集成 WebSocket BADGE_UPDATE 消息处理
  - [ ] 2.1 在 message-service.uts 中添加 BADGE_UPDATE 处理
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`
    - 在 `handleReceivedMessage()` 中添加 messageType === 204 的判断
    - 创建 `handleBadgeUpdateMessage()` 方法
    - 解析 message.body 为 BadgeUpdateMessage 对象
    - 调用 `badgeService.handleBadgeUpdate(badgeUpdate)`
    - 添加 try-catch 错误处理
    - _需求: 3.1, 3.2, 3.3, 3.6, 9.1_
  
  - [ ] 2.2 实现 BadgeService.handleBadgeUpdate() 方法
    - 更新 totalUnread
    - 批量更新 conversationBadges
    - 批量更新 menuBadges
    - 更新 lastUpdateTime
    - 保存到本地存储
    - 通知所有监听器
    - _需求: 3.1, 3.2, 3.3, 7.1, 7.2, 7.3_
  
  - [ ] 2.3 实现 WebSocket 重连后的角标同步
    - 在 message-service.uts 的 `onOpen()` 回调中
    - 调用 `badgeService.syncFromServer()`
    - 确保连接成功后立即同步最新角标数据
    - _需求: 3.4, 3.5, 7.4, 7.5_
  
  - [ ] 2.4 实现 BadgeService.syncFromServer() 方法
    - 调用后端 API: `GET /app-api/system/im/badge/get`
    - 解析响应数据
    - 更新本地角标数据
    - 保存到本地存储
    - 通知所有监听器
    - 添加错误处理,失败时使用本地缓存
    - _需求: 3.5, 5.3, 9.2_

- [ ] 2.5 编写 WebSocket 消息处理的单元测试
  - 测试 BADGE_UPDATE 消息解析
  - 测试错误消息处理
  - 测试消息格式兼容性
  - 测试重连后同步逻辑
  - **验证: 需求 3.1-3.6, 9.1**

### 阶段3: 前端 UI 集成

- [ ] 3. 更新消息列表页面角标显示
  - [ ] 3.1 在 message.uvue 中集成 BadgeService
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/message.uvue`
    - 导入 badgeService
    - 在 `onMounted()` 中添加角标监听器
    - 在 `onUnmounted()` 中移除角标监听器
    - _需求: 1.1, 6.2, 6.3_
  
  - [ ] 3.2 实现角标更新回调
    - 在监听器的 `onBadgeUpdate()` 中
    - 遍历 conversations 列表
    - 更新每个会话的 unreadCount
    - 使用 `badgeData.conversationBadges.get(conv.id) || 0`
    - _需求: 1.1, 1.5, 2.5_
  
  - [ ] 3.3 优化角标显示逻辑
    - 未读数 ≤ 99: 显示具体数字
    - 未读数 > 99: 显示 "99+"
    - 免打扰模式: 只显示红点
    - 未读数 = 0: 隐藏角标
    - _需求: 1.2, 1.3, 1.4, 1.6_
  
  - [ ] 3.4 实现进入会话时清空角标
    - 在点击会话进入聊天页面时
    - 调用 `badgeService.clearConversationBadge(conversationId)`
    - BadgeService 内部会调用后端 API 清空服务器端未读数
    - _需求: 1.5, 6.4_

- [ ] 3.5 编写消息列表角标的单元测试
  - 测试角标显示逻辑
  - 测试角标数字格式化 (99+)
  - 测试免打扰模式下的红点显示
  - 测试进入会话清空角标
  - **验证: 需求 1.1-1.6**

- [ ] 4. 实现底部导航栏角标
  - [ ] 4.1 在 index.uvue 中集成 BadgeService
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/pages/index/index.uvue`
    - 导入 badgeService
    - 在 `onMounted()` 中添加角标监听器
    - 在 `onUnmounted()` 中移除角标监听器
    - _需求: 2.1, 6.2, 6.3_
  
  - [ ] 4.2 实现 TabBar 角标更新
    - 创建 `updateTabBarBadge()` 方法
    - 使用 `uni.setTabBarBadge()` API 设置角标
    - 总未读数 > 0: 显示角标
    - 总未读数 ≤ 99: 显示具体数字
    - 总未读数 > 99: 显示 "99+"
    - 总未读数 = 0: 使用 `uni.removeTabBarBadge()` 移除角标
    - _需求: 2.1, 2.2, 2.3, 2.4_
  
  - [ ] 4.3 在角标监听器中调用更新方法
    - 在 `onBadgeUpdate()` 回调中
    - 调用 `updateTabBarBadge(badgeData.totalUnread)`
    - _需求: 2.5, 2.6_

- [ ] 4.4 编写底部导航栏角标的单元测试
  - 测试 TabBar 角标显示逻辑
  - 测试角标数字格式化
  - 测试角标移除逻辑
  - **验证: 需求 2.1-2.6**

- [ ] 5. 实现工作台菜单角标
  - [ ] 5.1 在 workbench.uvue 中集成 BadgeService
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/pages/workbench/workbench.uvue`
    - 导入 badgeService
    - 在菜单数据结构中添加 badge 字段
    - 在 `onMounted()` 中添加角标监听器
    - 在 `onUnmounted()` 中移除角标监听器
    - _需求: 4.1, 6.2, 6.3_
  
  - [ ] 5.2 实现菜单角标更新逻辑
    - 创建 `getMenuId()` 方法,将 nameKey 转换为 menuId
    - 在 `onBadgeUpdate()` 回调中
    - 遍历 processList
    - 更新每个菜单项的 badge 字段
    - 使用 `badgeData.menuBadges.get(menuId) || 0`
    - _需求: 4.1, 4.5_
  
  - [ ] 5.3 添加菜单角标显示模板
    - 在菜单项模板中添加角标元素
    - 使用 `v-if="item.badge > 0"` 条件显示
    - 待办数量 ≤ 99: 显示具体数字
    - 待办数量 > 99: 显示 "99+"
    - 待办数量 = 0: 隐藏角标
    - _需求: 4.2, 4.3, 4.4_
  
  - [ ] 5.4 添加菜单角标样式
    - 创建 .badge 和 .badge-text CSS 类
    - 红色背景,白色文字
    - 圆形或圆角矩形
    - 定位在菜单图标右上角
    - _需求: 4.1_

- [ ] 5.5 编写工作台菜单角标的单元测试
  - 测试菜单角标显示逻辑
  - 测试角标数字格式化
  - 测试角标隐藏逻辑
  - **验证: 需求 4.1-4.5**

### 阶段4: 消息服务集成

- [ ] 6. 集成消息服务自动更新角标
  - [ ] 6.1 在 message-service.uts 中监听新消息
    - 在 `handleReceivedMessage()` 中
    - 当接收到非自己发送的消息时
    - 调用 `badgeService.incrementConversationBadge(conversationId)`
    - 自动增加对应会话的未读数
    - _需求: 6.1, 6.2_
  
  - [ ] 6.2 在 chat.uvue 中监听消息已读
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/pages/chat/chat.uvue`
    - 当用户进入会话时
    - 调用 `badgeService.clearConversationBadge(conversationId)`
    - 自动清空该会话的未读数
    - _需求: 6.3, 6.4_
  
  - [ ] 6.3 实现消息服务初始化时同步角标
    - 在 message-service.uts 的 `init()` 方法中
    - 调用 `badgeService.init()`
    - 确保角标服务在消息服务之前初始化
    - _需求: 6.5_

- [ ] 6.4 编写消息服务集成的单元测试
  - 测试接收新消息时角标增加
  - 测试进入会话时角标清空
  - 测试服务初始化顺序
  - **验证: 需求 6.1-6.5**

### 阶段5: 后端 API 开发

- [ ] 7. 实现后端角标数据 API
  - [ ] 7.1 创建 ImBadgeController
    - 文件位置: `shengyu-module-system/shengyu-module-system-biz/src/main/java/cn/iocoder/yudao/module/system/controller/app/im/ImBadgeController.java`
    - 创建 `getBadgeData()` 接口: `GET /app-api/system/im/badge/get`
    - 返回总未读数、会话角标列表、菜单角标列表
    - _需求: 3.5, 10.1_
  
  - [ ] 7.2 创建 ImBadgeService
    - 文件位置: `shengyu-module-system/shengyu-module-system-biz/src/main/java/cn/iocoder/yudao/module/system/service/im/ImBadgeService.java`
    - 实现 `getBadgeData(userId)`: 获取用户的角标数据
    - 实现 `pushBadgeUpdate(userId)`: 推送角标更新到用户的所有设备
    - 实现 `getMenuBadges(userId)`: 获取菜单角标列表
    - _需求: 3.5, 7.1, 7.2, 7.3_
  
  - [ ] 7.3 实现清空会话未读数 API
    - 在 ImConversationController 中
    - 更新 `clearUnread(id)` 接口: `PUT /app-api/system/im/conversation/clear-unread/{id}`
    - 清空数据库中的未读数
    - 调用 `imBadgeService.pushBadgeUpdate(userId)` 推送更新
    - _需求: 1.5, 7.1, 7.2, 7.3_
  
  - [ ] 7.4 实现角标更新推送逻辑
    - 在 ImBadgeService 中
    - 计算总未读数: `conversationService.getTotalUnreadCount(userId)`
    - 获取会话角标列表: `conversationService.getConversationBadges(userId)`
    - 获取菜单角标列表: `getMenuBadges(userId)`
    - 构建 BadgeUpdateMessage (Protobuf)
    - 使用 `messageSender.sendToUser(userId, MessageType.BADGE_UPDATE, badgeUpdate)`
    - _需求: 3.1, 3.2, 3.3, 7.1, 7.2, 7.3, 10.1_
  
  - [ ] 7.5 实现菜单角标计算逻辑
    - 在 ImBadgeService.getMenuBadges() 中
    - 调用 `workflowService.getTodoCount(userId)` 获取待办数量
    - 构建 MenuBadge 列表
    - 支持扩展其他菜单角标
    - _需求: 4.5, 4.6_

- [ ] 7.6 编写后端 API 的单元测试
  - 测试获取角标数据 API
  - 测试清空未读数 API
  - 测试角标更新推送逻辑
  - 测试菜单角标计算
  - **验证: 需求 3.1-3.5, 7.1-7.5**

### 阶段6: Protobuf 协议定义

- [ ] 8. 定义 BadgeUpdateMessage Protobuf 消息
  - [ ] 8.1 在 im_message.proto 中添加消息定义
    - 文件位置: `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/proto/im_message.proto`
    - 定义 BadgeUpdateMessage (unreadCount, conversationBadges, menuBadges)
    - 定义 ConversationBadge (conversationId, unreadCount)
    - 定义 MenuBadge (menuId, badgeCount)
    - _需求: 3.1, 3.2, 3.3, 10.1, 10.2_
  
  - [ ] 8.2 重新编译 Protobuf 文件
    - 运行 `mvn clean compile` 生成 Java 类
    - 确保生成的类可以在后端使用
    - _需求: 10.1, 10.4_
  
  - [ ] 8.3 在前端定义对应的 TypeScript 类型
    - 在 badge-service.uts 中
    - 定义 BadgeUpdateMessage 类型
    - 定义 ConversationBadge 类型
    - 定义 MenuBadge 类型
    - 确保与 Protobuf 定义一致
    - _需求: 10.1, 10.2_

### 阶段7: 性能优化和错误处理

- [ ] 9. 实现性能优化
  - [ ] 9.1 添加防抖和节流机制
    - 在 BadgeService 中
    - UI 更新使用防抖 (300ms)
    - 本地存储使用节流 (1000ms)
    - _需求: 8.1, 8.2_
  
  - [ ] 9.2 实现批量更新优化
    - 在 BadgeService.handleBadgeUpdate() 中
    - 批量更新 conversationBadges
    - 批量更新 menuBadges
    - 只触发一次监听器通知
    - _需求: 8.2_
  
  - [ ] 9.3 实现内存优化
    - 在 BadgeService 中
    - 限制缓存的会话角标数量 (MAX_CONVERSATION_BADGES = 1000)
    - 实现 `pruneConversationBadges()` 方法
    - 移除最旧的角标数据
    - _需求: 8.3_

- [ ] 9.4 编写性能优化的单元测试
  - 测试防抖和节流机制
  - 测试批量更新逻辑
  - 测试内存优化逻辑
  - **验证: 需求 8.1-8.3**

- [ ] 10. 实现错误处理
  - [ ] 10.1 添加 WebSocket 消息解析错误处理
    - 在 message-service.uts 的 `handleBadgeUpdateMessage()` 中
    - 使用 try-catch 包装 JSON.parse
    - 解析失败时记录错误
    - 使用本地缓存的角标数据
    - _需求: 9.1_
  
  - [ ] 10.2 添加本地存储错误处理
    - 在 BadgeService 的 `saveToLocal()` 中
    - 使用 try-catch 包装 uni.setStorageSync
    - 存储失败时记录错误
    - 继续使用内存中的数据
    - _需求: 9.3_
  
  - [ ] 10.3 添加服务器同步错误处理
    - 在 BadgeService 的 `syncFromServer()` 中
    - 使用 try-catch 包装 API 调用
    - 同步失败时记录错误
    - 使用本地缓存的数据
    - _需求: 9.2_
  
  - [ ] 10.4 添加角标数据不一致处理
    - 在 BadgeService 中
    - 提供 `forceSync()` 方法手动同步
    - 在设置页面添加"同步角标"按钮
    - _需求: 9.5_

- [ ] 10.5 编写错误处理的单元测试
  - 测试消息解析错误处理
  - 测试本地存储错误处理
  - 测试服务器同步错误处理
  - 测试手动同步功能
  - **验证: 需求 9.1-9.5**

### 阶段8: 集成测试和验收

- [ ] 11. 端到端集成测试
  - [ ] 11.1 测试消息角标更新流程
    - 用户A发送消息给用户B
    - 验证用户B的会话角标增加
    - 验证用户B的底部导航栏角标增加
    - 用户B进入会话
    - 验证用户B的会话角标清空
    - 验证用户B的底部导航栏角标减少
    - _需求: 1.1-1.6, 2.1-2.6_
  
  - [ ] 11.2 测试多端同步流程
    - 用户在设备A阅读消息
    - 验证设备B的角标实时更新
    - 用户在设备B收到新消息
    - 验证设备A的角标实时更新
    - _需求: 7.1-7.5_
  
  - [ ] 11.3 测试菜单角标更新流程
    - 创建待办事项
    - 验证工作台菜单角标增加
    - 完成待办事项
    - 验证工作台菜单角标减少
    - _需求: 4.1-4.6_
  
  - [ ] 11.4 测试离线和重连流程
    - 断开 WebSocket 连接
    - 验证角标使用本地缓存
    - 重新连接 WebSocket
    - 验证角标从服务器同步
    - _需求: 3.4, 3.5, 5.4_
  
  - [ ] 11.5 测试错误恢复流程
    - 模拟服务器错误
    - 验证角标使用本地缓存
    - 模拟本地存储失败
    - 验证角标使用内存数据
    - _需求: 9.1-9.5_

- [ ] 12. 性能测试
  - [ ] 12.1 测试大量会话的角标更新性能
    - 创建 1000+ 会话
    - 批量更新角标
    - 验证 UI 响应时间 < 100ms
    - _需求: 8.1, 8.2, 8.3_
  
  - [ ] 12.2 测试频繁角标更新的性能
    - 每秒接收 10+ 条消息
    - 验证 UI 不卡顿
    - 验证防抖机制生效
    - _需求: 8.1, 8.4_
  
  - [ ] 12.3 测试内存占用
    - 长时间运行应用
    - 验证内存占用稳定
    - 验证内存优化机制生效
    - _需求: 8.3_

- [ ] 13. 最终验收检查点
  - 运行所有单元测试
  - 运行所有集成测试
  - 运行所有性能测试
  - 在真实设备上手动测试
  - 验证所有需求的验收标准
  - 验证与 WebSocket 中间件的兼容性
  - 验证与现有消息服务的集成
  - 验证多端同步功能
  - 验证离线和重连场景
  - 验证错误处理和恢复机制

## 注意事项

- **遵循中间件协议**: 严格遵循 WebSocket 中间件的 BADGE_UPDATE (messageType = 204) 消息格式
- **使用现有组件**: 复用现有的 MessageService、WebSocket 连接、存储工具等
- **性能优先**: 使用防抖、节流、批量更新等机制确保性能
- **错误容错**: 所有错误都应该被捕获和处理,不影响其他功能
- **多端同步**: 利用 WebSocket 中间件的多端推送能力实现实时同步
- **本地缓存**: 确保离线时的用户体验,重连后立即同步
- **测试覆盖**: 单元测试 + 集成测试 + 性能测试全面覆盖
- **渐进式开发**: 先实现核心功能,再优化性能和错误处理

**参考文档**:
- WebSocket 中间件 README: `shengyu-framework/shengyu-spring-boot-starter-websocket/README.md`
- Protobuf 协议定义: `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/proto/im_message.proto`
- 消息服务实现: `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`
- 消息列表页面: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/message.uvue`
- IM 设计文档: `sql/doc/IM即时通讯逻辑设计文档-v1.0.md`

**关键集成点**:
1. BadgeService 与 MessageService 的集成
2. WebSocket BADGE_UPDATE 消息的处理
3. UI 组件与 BadgeService 的监听器机制
4. 后端 API 与 WebSocket 推送的协同
5. 本地存储与服务器同步的平衡
