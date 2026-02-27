# 实施计划: IM消息角标和菜单角标通知

## 概述

本实施计划实现完整的消息角标和菜单角标实时通知功能。系统将通过 WebSocket BADGE_UPDATE (messageType = 204) 消息实现实时角标更新,支持消息列表角标、底部导航栏角标、工作台菜单角标,并实现多端同步和本地持久化。

**技术栈**:
- 前端: uni-app x (UTS语言)
- 后端: Spring Boot + Netty WebSocket
- 协议: Protobuf
- 存储: uni.storage (本地持久化)

## 任务

- [ ] 1. 定义 Protobuf 协议和消息类型
  - [x] 1.1 更新 im_message.proto 添加 BADGE_UPDATE 消息定义
    - 文件位置: `shengyu-framework/shengyu-spring-boot-starter-websocket/src/main/proto/im_message.proto`
    - 在 MessageType 枚举中添加 `BADGE_UPDATE = 204`
    - 定义 BadgeUpdateMessage (unreadCount, conversationBadges, menuBadges)
    - 定义 ConversationBadge (conversationId, unreadCount)
    - 定义 MenuBadge (menuId, badgeCount)
    - _需求: 3.1, 3.2, 3.3, 10.1_
  
  - [x] 1.2 在前端定义对应的 TypeScript 类型
    - 创建类型定义文件或在 badge-service.uts 中定义
    - 定义 BadgeUpdateMessage 接口
    - 定义 ConversationBadge 接口
    - 定义 MenuBadge 接口
    - 确保与 Protobuf 定义结构一致
    - _需求: 10.1, 10.2_


- [ ] 2. 创建 BadgeService 核心服务
  - [x] 2.1 创建 badge-service.uts 文件和基础结构
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/services/badge-service.uts`
    - 定义 BadgeData 类型 (totalUnread, conversationBadges, menuBadges, lastUpdateTime)
    - 定义 StoredBadgeData 类型 (用于本地存储序列化)
    - 定义 BadgeListener 接口
    - 创建 BadgeService 类骨架
    - _需求: 6.1, 6.2, 10.2_
  
  - [x] 2.2 实现基础角标查询方法
    - 实现 `getTotalUnread()`: 返回总未读数
    - 实现 `getConversationBadge(conversationId)`: 返回会话未读数
    - 实现 `getMenuBadge(menuId)`: 返回菜单角标数量
    - _需求: 1.1, 2.1, 4.1_
  
  - [x] 2.3 实现角标更新方法
    - 实现 `incrementConversationBadge(conversationId, delta)`: 增加会话未读数并更新总未读数
    - 实现 `decrementConversationBadge(conversationId, delta)`: 减少会话未读数并更新总未读数
    - 实现 `clearConversationBadge(conversationId)`: 清空会话未读数,调用后端API,更新总未读数
    - 实现 `updateMenuBadge(menuId, count)`: 更新菜单角标
    - 每个方法调用后触发 `notifyListeners()` 和 `saveToLocal()`
    - _需求: 1.5, 1.6, 2.5, 2.6, 4.5, 4.6, 6.1, 6.2, 6.3_
  
  - [x] 2.4 实现监听器机制
    - 实现 `addListener(listener)`: 添加角标监听器到列表
    - 实现 `removeListener(listener)`: 从列表移除角标监听器
    - 实现 `notifyListeners()`: 遍历所有监听器并调用 onBadgeUpdate
    - 使用防抖机制 (300ms) 避免频繁通知
    - _需求: 6.3, 8.1_
  
  - [x] 2.5 实现本地存储功能
    - 实现 `saveToLocal()`: 将 BadgeData 转换为 StoredBadgeData 并保存到 uni.setStorageSync
    - 实现 `loadFromLocal()`: 从 uni.getStorageSync 加载并转换为 BadgeData
    - 使用节流机制 (1000ms) 避免频繁保存
    - 添加 try-catch 错误处理,失败时记录错误但不影响功能
    - 添加数据版本检查 (version 字段)
    - _需求: 5.1, 5.2, 5.4, 9.3_
  
  - [x] 2.6 实现 WebSocket 消息处理方法
    - 实现 `handleBadgeUpdate(message)`: 处理 BadgeUpdateMessage
    - 批量更新 totalUnread
    - 批量更新 conversationBadges (使用 Map.set)
    - 批量更新 menuBadges (使用 Map.set)
    - 更新 lastUpdateTime
    - 调用 `saveToLocal()` 和 `notifyListeners()`
    - _需求: 3.1, 3.2, 3.3, 7.1, 7.2, 7.3, 8.2_
  
  - [x] 2.7 实现服务器同步方法
    - 实现 `syncFromServer()`: 调用后端 API `GET /app-api/system/im/badge/get`
    - 解析响应数据并更新 badgeData
    - 调用 `saveToLocal()` 和 `notifyListeners()`
    - 添加 try-catch 错误处理,失败时使用本地缓存
    - _需求: 3.5, 5.3, 7.5, 9.2_
  
  - [x] 2.8 实现初始化方法
    - 实现 `init()`: 初始化角标服务
    - 调用 `loadFromLocal()` 加载本地数据
    - 如果本地数据不存在或过期,调用 `syncFromServer()`
    - _需求: 5.2, 6.5_
  
  - [x] 2.9 实现内存优化方法
    - 实现 `pruneConversationBadges()`: 限制会话角标缓存数量
    - 设置 MAX_CONVERSATION_BADGES = 1000
    - 当超过限制时,移除最旧的角标数据
    - _需求: 8.3_
  
  - [~] 2.10 编写 BadgeService 单元测试
    - 测试角标增加/减少/清空逻辑
    - 测试本地存储和加载
    - 测试监听器通知机制
    - 测试防抖和节流机制
    - 测试内存优化逻辑
    - 测试错误处理


- [ ] 3. 集成 WebSocket 消息处理
  - [x] 3.1 在 message-service.uts 中添加 BADGE_UPDATE 消息处理
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`
    - 在 `handleReceivedMessage()` 中添加 `messageType === 204` 判断分支
    - 创建 `handleBadgeUpdateMessage(message)` 方法
    - 解析 message.body 为 BadgeUpdateMessage 对象
    - 调用 `badgeService.handleBadgeUpdate(badgeUpdate)`
    - 添加 try-catch 错误处理,解析失败时记录错误并使用本地数据
    - _需求: 3.1, 3.6, 9.1, 10.1_
  
  - [x] 3.2 实现 WebSocket 重连后的角标同步
    - 在 message-service.uts 的 `onOpen()` 回调中
    - 调用 `badgeService.syncFromServer()`
    - 确保连接成功后立即同步最新角标数据
    - _需求: 3.4, 3.5, 7.4, 7.5_
  
  - [x] 3.3 在 message-service.uts 中监听新消息自动更新角标
    - 在 `handleReceivedMessage()` 中处理 TEXT 消息时
    - 判断消息是否为自己发送 (senderId !== currentUserId)
    - 如果不是自己发送,调用 `badgeService.incrementConversationBadge(conversationId)`
    - 自动增加对应会话的未读数
    - _需求: 6.1, 6.2_
  
  - [~] 3.4 编写 WebSocket 消息处理的单元测试
    - 测试 BADGE_UPDATE 消息解析和处理
    - 测试错误消息处理和降级
    - 测试重连后同步逻辑
    - 测试新消息自动更新角标

- [ ] 4. 检查点 - 核心服务层验证
  - 确保 BadgeService 所有方法正常工作
  - 确保 WebSocket 消息处理正确
  - 确保本地存储和同步功能正常
  - 如有问题请向用户询问


- [ ] 5. 更新消息列表页面角标显示
  - [x] 5.1 在 message.uvue 中集成 BadgeService
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/message.uvue`
    - 导入 badgeService
    - 在 `onMounted()` 中添加角标监听器
    - 在 `onUnmounted()` 中移除角标监听器
    - _需求: 1.1, 6.2, 6.3, 10.3_
  
  - [x] 5.2 实现角标更新回调逻辑
    - 在监听器的 `onBadgeUpdate(badgeData)` 回调中
    - 遍历 conversations 列表
    - 更新每个会话的 unreadCount 字段
    - 使用 `badgeData.conversationBadges.get(conv.id) || 0`
    - _需求: 1.1, 1.5, 2.5, 6.2_
  
  - [x] 5.3 实现进入会话时清空角标
    - 在点击会话进入聊天页面的事件处理中
    - 调用 `badgeService.clearConversationBadge(conversationId)`
    - BadgeService 会自动调用后端 API 并更新本地数据
    - _需求: 1.5, 6.3, 6.4_
  
  - [~] 5.4 编写消息列表角标的单元测试
    - 测试角标显示逻辑 (数字、99+、红点、隐藏)
    - 测试免打扰模式下的红点显示
    - 测试进入会话清空角标
    - 测试监听器注册和移除

- [ ] 6. 实现底部导航栏角标
  - [x] 6.1 在 index.uvue 中集成 BadgeService
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/pages/index/index.uvue`
    - 导入 badgeService
    - 在 `onMounted()` 中添加角标监听器
    - 在 `onUnmounted()` 中移除角标监听器
    - _需求: 2.1, 6.2, 6.3, 10.3_
  
  - [x] 6.2 实现 TabBar 角标更新方法
    - 创建 `updateTabBarBadge(totalUnread)` 方法
    - 当 totalUnread > 0 时,调用 `uni.setTabBarBadge({ index: 1, text: badgeText })`
    - 当 totalUnread ≤ 99 时,显示具体数字
    - 当 totalUnread > 99 时,显示 "99+"
    - 当 totalUnread = 0 时,调用 `uni.removeTabBarBadge({ index: 1 })`
    - _需求: 2.1, 2.2, 2.3, 2.4_
  
  - [x] 6.3 在角标监听器中调用更新方法
    - 在 `onBadgeUpdate(badgeData)` 回调中
    - 调用 `updateTabBarBadge(badgeData.totalUnread)`
    - _需求: 2.5, 2.6_
  
  - [~] 6.4 编写底部导航栏角标的单元测试
    - 测试 TabBar 角标显示逻辑
    - 测试角标数字格式化
    - 测试角标移除逻辑


- [ ] 7. 实现工作台菜单角标
  - [x] 7.1 在 workbench.uvue 中集成 BadgeService
    - 文件位置: `shengyu-ui/shengyu-ui-admin-uniappx/pages/workbench/workbench.uvue`
    - 导入 badgeService
    - 在 `onMounted()` 中添加角标监听器
    - 在 `onUnmounted()` 中移除角标监听器
    - _需求: 4.1, 6.2, 6.3, 10.3_
  
  - [x] 7.2 实现菜单角标更新逻辑
    - 创建 `getMenuId(nameKey)` 方法,将 nameKey 转换为 menuId
    - 在 `onBadgeUpdate(badgeData)` 回调中
    - 遍历 processList
    - 更新每个菜单项的 badge 字段
    - 使用 `badgeData.menuBadges.get(menuId) || 0`
    - _需求: 4.1, 4.5, 4.6_
  
  - [x] 7.3 验证菜单角标显示模板
    - 确认模板中已有 `v-if="item.badge > 0"` 条件显示
    - 确认角标数字格式化逻辑 (≤99 显示数字, >99 显示 "99+")
    - 确认角标样式 (红色背景、白色文字、定位在右上角)
    - _需求: 4.2, 4.3, 4.4_
  
  - [~] 7.4 编写工作台菜单角标的单元测试
    - 测试菜单角标显示逻辑
    - 测试角标数字格式化
    - 测试角标隐藏逻辑
    - 测试 nameKey 到 menuId 的转换

- [ ] 8. 检查点 - 前端 UI 集成验证
  - 确保所有 UI 组件正确集成 BadgeService
  - 确保监听器机制正常工作
  - 确保角标显示逻辑符合需求
  - 如有问题请向用户询问


- [ ] 9. 实现后端角标服务
  - [x] 9.1 创建 ImBadgeService 服务类
    - 文件位置: `shengyu-module-system/shengyu-module-system-biz/src/main/java/cn/iocoder/yudao/module/system/service/im/ImBadgeService.java`
    - 注入 NettyMessageSender, ImConversationService
    - 实现 `getBadgeData(userId)`: 获取用户的角标数据
    - 实现 `pushBadgeUpdate(userId)`: 推送角标更新到用户的所有设备
    - 实现 `getMenuBadges(userId)`: 获取菜单角标列表
    - _需求: 3.5, 7.1, 7.2, 7.3_
  
  - [x] 9.2 实现角标数据计算逻辑
    - 在 `getBadgeData()` 中
    - 调用 `conversationService.getTotalUnreadCount(userId)` 获取总未读数
    - 调用 `conversationService.getConversationBadges(userId)` 获取会话角标列表
    - 调用 `getMenuBadges(userId)` 获取菜单角标列表
    - 构建并返回 BadgeData 对象
    - _需求: 3.5, 5.3_
  
  - [x] 9.3 实现菜单角标计算逻辑
    - 在 `getMenuBadges()` 中
    - 调用 `workflowService.getTodoCount(userId)` 获取待办数量
    - 构建 MenuBadge 列表
    - 支持扩展其他菜单角标类型
    - _需求: 4.5, 4.6_
  
  - [x] 9.4 实现角标更新推送逻辑
    - 在 `pushBadgeUpdate()` 中
    - 调用 `getBadgeData(userId)` 获取最新角标数据
    - 构建 BadgeUpdateMessage (Protobuf)
    - 使用 `messageSender.sendToUser(userId, MessageType.BADGE_UPDATE, badgeUpdate)`
    - 推送到用户的所有在线设备
    - _需求: 3.1, 3.2, 3.3, 7.1, 7.2, 7.3, 10.1_
  
  - [~] 9.5 编写 ImBadgeService 单元测试
    - 测试获取角标数据逻辑
    - 测试菜单角标计算
    - 测试角标更新推送
    - 测试 Protobuf 消息构建

- [ ] 10. 创建后端角标 API 接口
  - [x] 10.1 创建 ImBadgeController
    - 文件位置: `shengyu-module-system/shengyu-module-system-biz/src/main/java/cn/iocoder/yudao/module/system/controller/app/im/ImBadgeController.java`
    - 创建 `getBadgeData()` 接口: `GET /app-api/system/im/badge/get`
    - 调用 `imBadgeService.getBadgeData(userId)`
    - 返回 CommonResult 包装的角标数据
    - _需求: 3.5, 10.1_
  
  - [x] 10.2 更新 ImConversationController 清空未读数接口
    - 文件位置: `shengyu-module-system/shengyu-module-system-biz/src/main/java/cn/iocoder/yudao/module/system/controller/app/im/ImConversationController.java`
    - 在 `clearUnread(id)` 接口中: `PUT /app-api/system/im/conversation/clear-unread/{id}`
    - 清空数据库中的未读数后
    - 调用 `imBadgeService.pushBadgeUpdate(userId)` 推送更新到其他设备
    - _需求: 1.5, 7.1, 7.2, 7.3_
  
  - [~] 10.3 编写后端 API 的单元测试
    - 测试获取角标数据 API
    - 测试清空未读数 API
    - 测试角标推送触发逻辑


- [ ] 11. 实现后端数据库查询方法
  - [x] 11.1 在 ImConversationService 中添加角标查询方法
    - 文件位置: `shengyu-module-system/shengyu-module-system-biz/src/main/java/cn/iocoder/yudao/module/system/service/im/ImConversationService.java`
    - 实现 `getTotalUnreadCount(userId)`: 查询用户的总未读数
    - 实现 `getConversationBadges(userId)`: 查询用户的所有会话角标
    - 使用 MyBatis 查询数据库中的 unread_count 字段
    - _需求: 3.5, 5.3_
  
  - [~] 11.2 编写数据库查询方法的单元测试
    - 测试总未读数查询
    - 测试会话角标列表查询
    - 测试空数据情况

- [ ] 12. 实现应用初始化时的角标加载
  - [x] 12.1 在应用启动时初始化 BadgeService
    - 在 App.vue 或主入口文件的 `onLaunch()` 中
    - 调用 `badgeService.init()`
    - 确保在 MessageService 初始化之前完成
    - _需求: 5.2, 6.5_
  
  - [x] 12.2 在 MessageService 初始化时同步角标
    - 在 message-service.uts 的 `init()` 方法中
    - 确保 badgeService 已初始化
    - WebSocket 连接成功后会自动调用 `syncFromServer()`
    - _需求: 6.5, 3.5_

- [ ] 13. 检查点 - 端到端功能验证
  - 确保前后端集成正常
  - 确保角标数据正确显示
  - 确保 WebSocket 推送正常工作
  - 如有问题请向用户询问


- [ ] 14. 实现性能优化
  - [x] 14.1 添加防抖机制到监听器通知
    - 在 BadgeService 的 `notifyListeners()` 中
    - 使用防抖函数包装,延迟 300ms
    - 避免频繁触发 UI 更新
    - _需求: 8.1_
  
  - [x] 14.2 添加节流机制到本地存储
    - 在 BadgeService 的 `saveToLocal()` 中
    - 使用节流函数包装,间隔 1000ms
    - 避免频繁写入存储
    - _需求: 8.1_
  
  - [x] 14.3 实现批量更新优化
    - 在 BadgeService 的 `handleBadgeUpdate()` 中
    - 批量更新所有 conversationBadges
    - 批量更新所有 menuBadges
    - 只触发一次监听器通知
    - _需求: 8.2_
  
  - [x] 14.4 实现内存优化
    - 在 BadgeService 中调用 `pruneConversationBadges()`
    - 在每次更新后检查缓存大小
    - 超过 MAX_CONVERSATION_BADGES (1000) 时清理旧数据
    - _需求: 8.3_
  
  - [~] 14.5 编写性能优化的单元测试
    - 测试防抖和节流机制
    - 测试批量更新逻辑
    - 测试内存优化逻辑
    - 测试大量会话的性能

- [ ] 15. 实现错误处理和降级
  - [x] 15.1 添加 WebSocket 消息解析错误处理
    - 在 message-service.uts 的 `handleBadgeUpdateMessage()` 中
    - 使用 try-catch 包装 JSON.parse
    - 解析失败时记录错误到 console.error
    - 继续使用本地缓存的角标数据
    - _需求: 9.1_
  
  - [x] 15.2 添加本地存储错误处理
    - 在 BadgeService 的 `saveToLocal()` 和 `loadFromLocal()` 中
    - 使用 try-catch 包装 uni.setStorageSync 和 uni.getStorageSync
    - 存储失败时记录错误
    - 继续使用内存中的数据
    - _需求: 5.4, 9.3_
  
  - [x] 15.3 添加服务器同步错误处理
    - 在 BadgeService 的 `syncFromServer()` 中
    - 使用 try-catch 包装 API 调用
    - 同步失败时记录错误
    - 使用本地缓存的数据
    - _需求: 3.6, 9.2_
  
  - [x] 15.4 实现手动同步功能
    - 在 BadgeService 中添加 `forceSync()` 方法
    - 强制从服务器同步角标数据
    - 在设置页面或消息页面添加"同步角标"按钮
    - _需求: 9.5_
  
  - [~] 15.5 编写错误处理的单元测试
    - 测试消息解析错误处理
    - 测试本地存储错误处理
    - 测试服务器同步错误处理
    - 测试手动同步功能


- [ ] 16. 实现多端同步支持
  - [x] 16.1 验证后端推送到多设备
    - 在 ImBadgeService 的 `pushBadgeUpdate()` 中
    - 使用 `messageSender.sendToUser(userId, ...)` 自动推送到所有在线设备
    - 验证 WebSocket 中间件的多端推送功能
    - _需求: 7.1, 7.2, 7.3, 10.1_
  
  - [x] 16.2 实现离线设备的角标同步
    - 在 message-service.uts 的 `onOpen()` 回调中
    - 设备重新上线时自动调用 `badgeService.syncFromServer()`
    - 确保离线期间的角标变化能够同步
    - _需求: 7.4, 7.5_
  
  - [~] 16.3 编写多端同步的集成测试
    - 测试设备A阅读消息,设备B角标更新
    - 测试设备A收到新消息,设备B角标更新
    - 测试设备离线后重连同步

- [ ] 17. 实现后端触发角标推送的场景
  - [x] 17.1 在消息发送后触发角标推送
    - 在 ImMessageService 的消息发送逻辑中
    - 消息发送成功后,调用 `imBadgeService.pushBadgeUpdate(receiverId)`
    - 推送角标更新到接收方的所有设备
    - _需求: 6.1, 7.1, 7.2_
  
  - [x] 17.2 在清空未读数后触发角标推送
    - 在 ImConversationController 的 `clearUnread()` 中
    - 清空成功后,调用 `imBadgeService.pushBadgeUpdate(userId)`
    - 推送角标更新到用户的其他设备
    - _需求: 1.5, 7.1, 7.2, 7.3_
  
  - [x] 17.3 在待办事项变化后触发角标推送
    - 在 WorkflowService 的待办事项创建/完成逻辑中
    - 调用 `imBadgeService.pushBadgeUpdate(userId)`
    - 推送菜单角标更新
    - _需求: 4.5, 4.6_


- [ ] 18. 最终集成测试和验收
  - [~] 18.1 端到端消息角标测试
    - 用户A发送消息给用户B
    - 验证用户B的会话角标增加
    - 验证用户B的底部导航栏角标增加
    - 用户B进入会话
    - 验证用户B的会话角标清空
    - 验证用户B的底部导航栏角标减少
    - _需求: 1.1-1.6, 2.1-2.6, 6.1-6.4_
  
  - [~] 18.2 端到端多端同步测试
    - 用户在设备A阅读消息
    - 验证设备B的角标实时更新
    - 用户在设备B收到新消息
    - 验证设备A的角标实时更新
    - _需求: 7.1-7.5_
  
  - [~] 18.3 端到端菜单角标测试
    - 创建待办事项
    - 验证工作台菜单角标增加
    - 完成待办事项
    - 验证工作台菜单角标减少
    - _需求: 4.1-4.6_
  
  - [~] 18.4 离线和重连场景测试
    - 断开 WebSocket 连接
    - 验证角标使用本地缓存
    - 重新连接 WebSocket
    - 验证角标从服务器同步
    - _需求: 3.4, 3.5, 5.4, 7.4, 7.5_
  
  - [~] 18.5 错误恢复场景测试
    - 模拟服务器错误
    - 验证角标使用本地缓存
    - 模拟本地存储失败
    - 验证角标使用内存数据
    - 测试手动同步功能
    - _需求: 9.1-9.5_
  
  - [~] 18.6 性能测试
    - 测试大量会话 (1000+) 的角标更新性能
    - 测试频繁角标更新 (每秒10+条消息) 的 UI 响应
    - 测试长时间运行的内存占用
    - 验证防抖、节流、批量更新机制生效
    - _需求: 8.1-8.4_

- [ ] 19. 最终验收检查点
  - 运行所有单元测试并确保通过
  - 运行所有集成测试并确保通过
  - 在真实设备上手动测试所有功能
  - 验证所有需求的验收标准
  - 验证与 WebSocket 中间件的兼容性
  - 验证与现有消息服务的集成
  - 验证多端同步功能
  - 验证离线和重连场景
  - 验证错误处理和恢复机制
  - 如有问题请向用户询问

## 注意事项

- 任务标记 `*` 的为可选测试任务,可以跳过以加快 MVP 开发
- 每个任务都引用了具体的需求编号以便追溯
- 检查点任务确保渐进式验证
- 遵循现有代码风格和架构模式
- 使用现有的 WebSocket 中间件和消息服务基础设施
- 确保所有错误都被妥善处理,不影响其他功能
- 优先实现核心功能,再优化性能和错误处理

