# 设计文档: IM消息角标和菜单角标通知

## 概述

本设计实现完整的消息角标和菜单角标实时通知功能,包括:

1. **消息列表角标**: 每个会话显示未读消息数
2. **底部导航栏角标**: 显示总未读消息数
3. **菜单角标**: 工作台菜单项显示待办数量
4. **WebSocket 实时更新**: 通过 BADGE_UPDATE 消息实时推送角标更新
5. **多端同步**: 多个设备间角标数据实时同步
6. **本地持久化**: 角标数据本地缓存,应用重启后恢复

## 架构

### 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    移动端 (uni-app x)                        │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ 消息列表     │  │ 底部导航栏   │  │ 工作台菜单   │    │
│  │ (会话角标)   │  │ (总未读数)   │  │ (菜单角标)   │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                  │                  │             │
│         └──────────────────┴──────────────────┘             │
│                            ↓                                 │
│                  ┌─────────────────┐                        │
│                  │  BadgeService   │                        │
│                  │  (角标服务)     │                        │
│                  └────────┬────────┘                        │
│                           ↓                                  │
│         ┌─────────────────┴─────────────────┐              │
│         ↓                                     ↓              │
│  ┌──────────────┐                   ┌──────────────┐      │
│  │ LocalStorage │                   │ MessageService│      │
│  │ (本地缓存)   │                   │ (消息服务)   │      │
│  └──────────────┘                   └──────┬───────┘      │
│                                             ↓               │
│                                    ┌──────────────┐        │
│                                    │ WebSocket    │        │
│                                    │ (实时通信)   │        │
│                                    └──────┬───────┘        │
└───────────────────────────────────────────┼────────────────┘
                                            ↓
                    ┌───────────────────────┴───────────────────────┐
                    │     WebSocket 中间件 (Netty + Protobuf)       │
                    │                                                │
                    │  MessageType.BADGE_UPDATE = 204                │
                    │  - unreadCount: 总未读数                       │
                    │  - conversationBadges: 会话角标列表            │
                    │  - menuBadges: 菜单角标列表                    │
                    └───────────────────┬────────────────────────────┘
                                        ↓
                    ┌───────────────────┴────────────────────────────┐
                    │          后端业务层 (Spring Boot)              │
                    │                                                │
                    │  - ImConversationService: 计算会话未读数       │
                    │  - ImBadgeService: 管理角标数据               │
                    │  - WorkflowService: 计算待办数量               │
                    └────────────────────────────────────────────────┘
```

### 数据流

#### 流程1: 接收新消息时更新角标

```
1. WebSocket 接收到新消息 (MessageType.TEXT = 100)
2. MessageService 处理消息
   a. 将消息添加到消息列表
   b. 更新会话的最后消息
   c. 如果不是自己发送的消息,增加会话未读数
3. BadgeService 监听消息事件
   a. 增加对应会话的未读数
   b. 增加总未读数
   c. 更新本地存储
   d. 触发 UI 更新
4. UI 层响应更新
   a. 消息列表更新会话角标
   b. 底部导航栏更新总未读数角标
```

#### 流程2: 服务器主动推送角标更新

```
1. 后端检测到角标变化 (如其他设备阅读消息)
2. 后端构建 BADGE_UPDATE 消息
   {
     header: {
       messageType: 204,
       timestamp: xxx
     },
     body: {
       unreadCount: 10,
       conversationBadges: [
         { conversationId: 1, unreadCount: 5 },
         { conversationId: 2, unreadCount: 5 }
       ],
       menuBadges: [
         { menuId: 'todo', badgeCount: 99 }
       ]
     }
   }
3. WebSocket 中间件推送消息到客户端
4. MessageService 接收并解析消息
5. BadgeService 处理角标更新
   a. 更新总未读数
   b. 更新会话未读数
   c. 更新菜单角标
   d. 更新本地存储
   e. 触发 UI 更新
6. UI 层响应更新
```

#### 流程3: 用户进入会话清空未读数

```
1. 用户点击会话进入聊天页面
2. 聊天页面调用 BadgeService.clearConversationBadge(conversationId)
3. BadgeService 处理清空逻辑
   a. 将会话未读数设置为 0
   b. 减少总未读数
   c. 更新本地存储
   d. 调用后端 API 清空服务器端未读数
   e. 触发 UI 更新
4. 后端接收清空请求
   a. 更新数据库中的未读数
   b. 构建 BADGE_UPDATE 消息
   c. 推送到用户的其他在线设备
5. 其他设备接收并更新角标
```

## 组件和接口

### 1. BadgeService (角标服务)

**位置**: `shengyu-ui/shengyu-ui-admin-uniappx/services/badge-service.uts`

**职责**:
- 管理所有角标数据 (消息角标、菜单角标)
- 处理 WebSocket BADGE_UPDATE 消息
- 提供角标查询和更新接口
- 管理本地存储和缓存
- 触发 UI 更新事件

**接口定义**:

```typescript
/**
 * 角标数据结构
 */
type BadgeData = {
  totalUnread: number                    // 总未读数
  conversationBadges: Map<number, number> // 会话ID -> 未读数
  menuBadges: Map<string, number>        // 菜单ID -> 角标数
  lastUpdateTime: number                 // 最后更新时间
}

/**
 * 角标服务类
 */
class BadgeService {
  private badgeData: BadgeData
  private listeners: Array<BadgeListener>
  private messageService: MessageService
  
  /**
   * 初始化角标服务
   */
  public init(): void
  
  /**
   * 获取总未读数
   */
  public getTotalUnread(): number
  
  /**
   * 获取会话未读数
   */
  public getConversationBadge(conversationId: number): number
  
  /**
   * 获取菜单角标
   */
  public getMenuBadge(menuId: string): number
  
  /**
   * 增加会话未读数
   */
  public incrementConversationBadge(conversationId: number, delta: number = 1): void
  
  /**
   * 减少会话未读数
   */
  public decrementConversationBadge(conversationId: number, delta: number = 1): void
  
  /**
   * 清空会话未读数
   */
  public clearConversationBadge(conversationId: number): void
  
  /**
   * 更新菜单角标
   */
  public updateMenuBadge(menuId: string, count: number): void
  
  /**
   * 处理 WebSocket BADGE_UPDATE 消息
   */
  public handleBadgeUpdate(message: BadgeUpdateMessage): void
  
  /**
   * 从服务器同步角标数据
   */
  public syncFromServer(): Promise<void>
  
  /**
   * 添加角标监听器
   */
  public addListener(listener: BadgeListener): void
  
  /**
   * 移除角标监听器
   */
  public removeListener(listener: BadgeListener): void
  
  /**
   * 保存到本地存储
   */
  private saveToLocal(): void
  
  /**
   * 从本地存储加载
   */
  private loadFromLocal(): void
  
  /**
   * 通知所有监听器
   */
  private notifyListeners(): void
}

/**
 * 角标监听器接口
 */
interface BadgeListener {
  onBadgeUpdate(badgeData: BadgeData): void
}
```

### 2. 消息列表角标组件

**位置**: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/message.uvue`

**需要的更改**:

```typescript
// 在 onMounted 中初始化角标监听
onMounted(() => {
  // ... 现有代码
  
  // 监听角标更新
  badgeService.addListener({
    onBadgeUpdate: (badgeData) => {
      // 更新会话列表的未读数
      conversations.value.forEach(conv => {
        conv.unreadCount = badgeData.conversationBadges.get(conv.id) || 0
      })
    }
  })
})

// 在 onUnmounted 中移除监听
onUnmounted(() => {
  badgeService.removeListener(badgeListener)
})
```

### 3. 底部导航栏角标

**位置**: `shengyu-ui/shengyu-ui-admin-uniappx/pages/index/index.uvue` (或 tabbar 配置)

**实现方式**:

```typescript
// 使用 uni.setTabBarBadge API
const updateTabBarBadge = (totalUnread: number) => {
  if (totalUnread > 0) {
    const badgeText = totalUnread > 99 ? '99+' : totalUnread.toString()
    uni.setTabBarBadge({
      index: 1,  // 消息标签的索引
      text: badgeText
    })
  } else {
    uni.removeTabBarBadge({
      index: 1
    })
  }
}

// 监听角标更新
badgeService.addListener({
  onBadgeUpdate: (badgeData) => {
    updateTabBarBadge(badgeData.totalUnread)
  }
})
```

### 4. 工作台菜单角标

**位置**: `shengyu-ui/shengyu-ui-admin-uniappx/pages/workbench/workbench.uvue`

**需要的更改**:

```typescript
// 菜单数据结构添加 badge 字段
const processList = ref([
  { 
    nameKey: 'workbench.todo', 
    icon: '\uea83', 
    gradient: 'linear-gradient(135deg, #fb923c, #f97316)', 
    badge: 0  // 动态更新
  },
  // ... 其他菜单项
])

// 监听角标更新
badgeService.addListener({
  onBadgeUpdate: (badgeData) => {
    processList.value.forEach(item => {
      const menuId = getMenuId(item.nameKey)  // 将 nameKey 转换为 menuId
      item.badge = badgeData.menuBadges.get(menuId) || 0
    })
  }
})

// 模板中显示角标
<view v-if="item.badge > 0" class="badge">
  <text class="badge-text">{{ item.badge > 99 ? '99+' : item.badge }}</text>
</view>
```

### 5. WebSocket 消息处理

**位置**: `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`

**需要的更改**:

```typescript
// 在 handleReceivedMessage 中添加 BADGE_UPDATE 处理
private handleReceivedMessage(data: any): void {
  const message = data as ImMessage
  
  // 处理角标更新消息
  if (message.header.messageType === 204) {  // BADGE_UPDATE
    this.handleBadgeUpdateMessage(message)
    return
  }
  
  // ... 其他消息类型处理
}

/**
 * 处理角标更新消息
 */
private handleBadgeUpdateMessage(message: ImMessage): void {
  try {
    const badgeUpdate = JSON.parse(message.body) as BadgeUpdateMessage
    badgeService.handleBadgeUpdate(badgeUpdate)
  } catch (e) {
    console.error('[MessageService] 解析角标更新消息失败:', e)
  }
}
```

## 数据模型

### BadgeUpdateMessage (Protobuf 消息)

```protobuf
message BadgeUpdateMessage {
  int32 unreadCount = 1;                    // 总未读数
  repeated ConversationBadge conversationBadges = 2;  // 会话角标列表
  repeated MenuBadge menuBadges = 3;        // 菜单角标列表
}

message ConversationBadge {
  int64 conversationId = 1;                 // 会话ID
  int32 unreadCount = 2;                    // 未读数
}

message MenuBadge {
  string menuId = 1;                        // 菜单ID
  int32 badgeCount = 2;                     // 角标数量
}
```

### 本地存储数据结构

```typescript
// 存储在 localStorage 中的数据
type StoredBadgeData = {
  totalUnread: number
  conversationBadges: Record<number, number>  // 转换为普通对象以便序列化
  menuBadges: Record<string, number>
  lastUpdateTime: number
  version: string  // 数据版本,用于兼容性检查
}
```

## 后端 API 设计

### 1. 获取角标数据

**接口**: `GET /app-api/system/im/badge/get`

**响应**:
```json
{
  "code": 0,
  "data": {
    "totalUnread": 10,
    "conversationBadges": [
      { "conversationId": 1, "unreadCount": 5 },
      { "conversationId": 2, "unreadCount": 5 }
    ],
    "menuBadges": [
      { "menuId": "todo", "badgeCount": 99 }
    ]
  }
}
```

### 2. 清空会话未读数

**接口**: `PUT /app-api/system/im/conversation/clear-unread/{id}`

**说明**: 清空指定会话的未读数,并推送 BADGE_UPDATE 消息到用户的其他设备

### 3. 后端推送角标更新

**触发时机**:
- 用户在其他设备阅读消息
- 用户在其他设备清空未读数
- 系统检测到待办数量变化
- 管理员发送系统通知

**实现**:
```java
@Service
public class ImBadgeService {
    
    @Resource
    private NettyMessageSender messageSender;
    
    @Resource
    private ImConversationService conversationService;
    
    /**
     * 推送角标更新到用户
     */
    public void pushBadgeUpdate(Long userId) {
        // 1. 计算总未读数
        int totalUnread = conversationService.getTotalUnreadCount(userId);
        
        // 2. 获取会话角标列表
        List<ConversationBadge> conversationBadges = 
            conversationService.getConversationBadges(userId);
        
        // 3. 获取菜单角标列表
        List<MenuBadge> menuBadges = getMenuBadges(userId);
        
        // 4. 构建角标更新消息
        BadgeUpdateMessage badgeUpdate = BadgeUpdateMessage.newBuilder()
            .setUnreadCount(totalUnread)
            .addAllConversationBadges(conversationBadges)
            .addAllMenuBadges(menuBadges)
            .build();
        
        // 5. 推送到用户的所有在线设备
        messageSender.sendToUser(userId, MessageType.BADGE_UPDATE, badgeUpdate);
    }
    
    /**
     * 获取菜单角标列表
     */
    private List<MenuBadge> getMenuBadges(Long userId) {
        List<MenuBadge> badges = new ArrayList<>();
        
        // 待办事项数量
        int todoCount = workflowService.getTodoCount(userId);
        if (todoCount > 0) {
            badges.add(MenuBadge.newBuilder()
                .setMenuId("todo")
                .setBadgeCount(todoCount)
                .build());
        }
        
        // 其他菜单角标...
        
        return badges;
    }
}
```

## 性能优化

### 1. 防抖和节流

```typescript
// 使用防抖避免频繁更新 UI
const debouncedUpdateUI = debounce(() => {
  // 更新 UI
}, 300)

// 使用节流避免频繁保存到本地存储
const throttledSaveToLocal = throttle(() => {
  // 保存到本地存储
}, 1000)
```

### 2. 批量更新

```typescript
// 批量更新会话角标
public batchUpdateConversationBadges(updates: Array<{conversationId: number, unreadCount: number}>): void {
  updates.forEach(update => {
    this.badgeData.conversationBadges.set(update.conversationId, update.unreadCount)
  })
  
  // 只触发一次 UI 更新
  this.notifyListeners()
}
```

### 3. 内存优化

```typescript
// 限制缓存的会话角标数量
private static readonly MAX_CONVERSATION_BADGES = 1000

private pruneConversationBadges(): void {
  if (this.badgeData.conversationBadges.size > MAX_CONVERSATION_BADGES) {
    // 移除最旧的角标数据
    const sortedEntries = Array.from(this.badgeData.conversationBadges.entries())
      .sort((a, b) => a[0] - b[0])
    
    const toRemove = sortedEntries.slice(0, sortedEntries.length - MAX_CONVERSATION_BADGES)
    toRemove.forEach(([conversationId]) => {
      this.badgeData.conversationBadges.delete(conversationId)
    })
  }
}
```

## 错误处理

### 1. WebSocket 消息解析失败

```typescript
private handleBadgeUpdateMessage(message: ImMessage): void {
  try {
    const badgeUpdate = JSON.parse(message.body) as BadgeUpdateMessage
    badgeService.handleBadgeUpdate(badgeUpdate)
  } catch (e) {
    console.error('[MessageService] 解析角标更新消息失败:', e)
    // 使用本地缓存的角标数据
    // 不影响其他功能
  }
}
```

### 2. 本地存储失败

```typescript
private saveToLocal(): void {
  try {
    const data: StoredBadgeData = {
      totalUnread: this.badgeData.totalUnread,
      conversationBadges: Object.fromEntries(this.badgeData.conversationBadges),
      menuBadges: Object.fromEntries(this.badgeData.menuBadges),
      lastUpdateTime: this.badgeData.lastUpdateTime,
      version: '1.0'
    }
    
    uni.setStorageSync('badge_data', JSON.stringify(data))
  } catch (e) {
    console.error('[BadgeService] 保存角标数据失败:', e)
    // 继续使用内存中的数据
  }
}
```

### 3. 服务器同步失败

```typescript
public async syncFromServer(): Promise<void> {
  try {
    const response = await getBadgeData()
    
    if (response.code === 0) {
      this.badgeData.totalUnread = response.data.totalUnread
      
      // 更新会话角标
      this.badgeData.conversationBadges.clear()
      response.data.conversationBadges.forEach(badge => {
        this.badgeData.conversationBadges.set(badge.conversationId, badge.unreadCount)
      })
      
      // 更新菜单角标
      this.badgeData.menuBadges.clear()
      response.data.menuBadges.forEach(badge => {
        this.badgeData.menuBadges.set(badge.menuId, badge.badgeCount)
      })
      
      this.saveToLocal()
      this.notifyListeners()
    }
  } catch (e) {
    console.error('[BadgeService] 同步角标数据失败:', e)
    // 使用本地缓存的数据
  }
}
```

## 测试策略

### 单元测试

1. **BadgeService 测试**:
   - 测试角标增加/减少/清空逻辑
   - 测试本地存储和加载
   - 测试监听器通知机制

2. **WebSocket 消息处理测试**:
   - 测试 BADGE_UPDATE 消息解析
   - 测试错误消息处理
   - 测试消息格式兼容性

3. **UI 组件测试**:
   - 测试角标显示逻辑
   - 测试角标数字格式化 (99+)
   - 测试免打扰模式下的红点显示

### 集成测试

1. **端到端角标更新流程**:
   - 发送消息 → 接收方角标增加
   - 阅读消息 → 角标清空
   - 多端同步 → 所有设备角标一致

2. **性能测试**:
   - 大量会话的角标更新性能
   - 频繁角标更新的 UI 响应性能
   - 内存占用测试

3. **错误恢复测试**:
   - WebSocket 断线重连后角标同步
   - 本地存储失败后的降级处理
   - 服务器错误后的重试机制

## 与 WebSocket 中间件的集成

### 中间件支持

根据 WebSocket 中间件文档,已经支持:

1. **BADGE_UPDATE 消息类型** (MessageType = 204)
2. **消息发送器**: `NettyMessageSender.sendToUser()`
3. **多端推送**: 自动推送到用户的所有在线设备

### 集成要点

1. **消息类型**: 使用 204 (BADGE_UPDATE)
2. **消息格式**: 遵循 Protobuf 协议定义
3. **推送策略**: 服务器主动推送 + 客户端轮询
4. **多端同步**: 利用中间件的多端登录支持

### 参考文档

- WebSocket 中间件 README: 第3.5节 通知推送
- Protobuf 协议: `im_message.proto`
- 中间件设计: 消息路由策略
