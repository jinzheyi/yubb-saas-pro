# 消息表情回应功能集成指南

## 概述

消息表情回应功能已实现，包含以下组件：
1. `message-reaction-service.uts` - 表情回应服务
2. `message-reaction-display.uvue` - 表情回应显示组件
3. `emoji-picker.uvue` - 表情选择器组件
4. `message-action-menu.uvue` - 消息操作菜单（已添加表情选项）

## 集成步骤

### 1. 在聊天页面导入组件和服务

```vue
<script setup lang="uts">
import { messageReactionService, ReactionItem } from '@/services/message-reaction-service.uts'
import MessageReactionDisplay from '@/components/message-reaction-display.uvue'
import EmojiPicker from '@/components/emoji-picker.uvue'
import MessageActionMenu from '@/components/message-action-menu.uvue'

// 表情选择器状态
const showEmojiPicker = ref(false)
const currentReactionMessageId = ref<number>(0)

// 消息表情回应数据（messageId -> ReactionItem[]）
const messageReactions = ref<Map<number, ReactionItem[]>>(new Map())
</script>
```

### 2. 在消息气泡下方添加表情回应显示组件

```vue
<template>
  <view class="message-item">
    <!-- 消息气泡 -->
    <view class="message-bubble">
      <!-- 消息内容 -->
    </view>
    
    <!-- 表情回应显示 -->
    <MessageReactionDisplay
      :reactions="messageReactions.get(msg.messageId) || []"
      @reactionClick="handleReactionClick(msg.messageId, $event)"
      @reactionLongPress="handleReactionLongPress(msg.messageId, $event)"
      @addClick="handleAddReaction(msg.messageId)"
    />
  </view>
</template>
```

### 3. 添加表情选择器组件

```vue
<template>
  <!-- 表情选择器 -->
  <EmojiPicker
    :visible="showEmojiPicker"
    @close="showEmojiPicker = false"
    @select="handleEmojiSelect"
  />
</template>
```

### 4. 实现事件处理函数

```typescript
/**
 * 加载消息的表情回应
 */
async function loadMessageReactions(messageId: number) {
  const reactions = await messageReactionService.getReactions(messageId)
  messageReactions.value.set(messageId, reactions)
}

/**
 * 点击表情回应（切换自己的回应）
 */
async function handleReactionClick(messageId: number, reaction: ReactionItem) {
  const success = await messageReactionService.toggleReaction(
    messageId,
    reaction.emoji,
    reaction.isSelf
  )
  
  if (success) {
    // 重新加载表情回应
    await loadMessageReactions(messageId)
  }
}

/**
 * 长按表情回应（查看回应用户列表）
 */
function handleReactionLongPress(messageId: number, reaction: ReactionItem) {
  const usersText = messageReactionService.getReactionUsersText(reaction)
  uni.showModal({
    title: reaction.emoji,
    content: usersText,
    showCancel: false
  })
}

/**
 * 点击添加表情回应
 */
function handleAddReaction(messageId: number) {
  currentReactionMessageId.value = messageId
  showEmojiPicker.value = true
}

/**
 * 选择表情
 */
async function handleEmojiSelect(emoji: string) {
  showEmojiPicker.value = false
  
  const messageId = currentReactionMessageId.value
  if (messageId === 0) return
  
  const success = await messageReactionService.addReaction(messageId, emoji)
  
  if (success) {
    // 重新加载表情回应
    await loadMessageReactions(messageId)
  } else {
    uni.showToast({
      title: '添加表情失败',
      icon: 'none'
    })
  }
}
```

### 5. 在消息操作菜单中处理表情选项

```typescript
/**
 * 处理消息操作菜单的表情选项
 */
function handleMenuReaction(message: MessageItem) {
  handleAddReaction(message.messageId)
}
```

在消息操作菜单的事件监听中添加：

```vue
<MessageActionMenu
  :visible="showMsgMenu"
  :message="selectedMsg"
  :position="{ top: menuY, left: menuX }"
  @reaction="handleMenuReaction(selectedMsg)"
  @close="closeMsgMenu"
  <!-- 其他事件 -->
/>
```

### 6. 在加载消息时加载表情回应

```typescript
/**
 * 加载历史消息
 */
async function loadMessages() {
  // ... 加载消息逻辑
  
  // 加载每条消息的表情回应
  for (const msg of messages.value) {
    await loadMessageReactions(msg.messageId)
  }
}

/**
 * 处理新消息
 */
function handleNewMessage(message: ServiceMessageItem) {
  // ... 添加消息到列表
  
  // 加载新消息的表情回应
  loadMessageReactions(message.messageId)
}
```

## 后端 API 接口

需要实现以下后端接口：

### 1. 添加表情回应
```
POST /system/im-message/add-reaction
Request Body:
{
  "messageId": 123456,
  "emoji": "👍"
}
Response:
{
  "code": 0,
  "data": true
}
```

### 2. 取消表情回应
```
POST /system/im-message/remove-reaction
Request Body:
{
  "messageId": 123456,
  "emoji": "👍"
}
Response:
{
  "code": 0,
  "data": true
}
```

### 3. 获取表情回应列表
```
GET /system/im-message/reactions?messageId=123456
Response:
{
  "code": 0,
  "data": [
    {
      "emoji": "👍",
      "userId": 1,
      "userName": "张三",
      "isSelf": true
    },
    {
      "emoji": "👍",
      "userId": 2,
      "userName": "李四",
      "isSelf": false
    },
    {
      "emoji": "❤️",
      "userId": 3,
      "userName": "王五",
      "isSelf": false
    }
  ]
}
```

## 数据库表设计

需要创建表情回应表：

```sql
CREATE TABLE `im_message_reaction` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `message_id` bigint NOT NULL COMMENT '消息ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `emoji` varchar(10) NOT NULL COMMENT '表情符号',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_message_user_emoji` (`message_id`, `user_id`, `emoji`, `deleted`),
  KEY `idx_message_id` (`message_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='消息表情回应表';
```

## 常用表情列表

服务中已定义常用表情：

```typescript
export const COMMON_EMOJIS = [
  '👍', '❤️', '😄', '😂', '😮', '😢', '🙏', '👏'
]
```

可以根据需要扩展更多表情。

## 样式说明

### 表情回应显示组件样式
- 表情项：圆角矩形，灰色背景
- 自己的回应：蓝色背景和边框
- 表情大小：32rpx
- 数量文字：24rpx，灰色

### 表情选择器样式
- 底部弹出层，白色背景
- 圆角顶部：24rpx
- 表情网格：每个96rpx x 96rpx
- 表情大小：48rpx

## 注意事项

1. 表情回应数据会缓存在 `MessageReactionService` 中，添加/删除后会自动清除缓存
2. 表情回应支持多个用户对同一表情的回应，会自动合并显示
3. 长按表情回应可以查看回应用户列表
4. 点击表情回应可以切换自己的回应状态
5. 需要确保后端接口支持租户隔离

## 完成状态

- ✅ MessageReactionService 服务实现
- ✅ MessageReactionDisplay 组件实现
- ✅ EmojiPicker 组件实现
- ✅ MessageActionMenu 添加表情选项
- ⏳ 后端 API 接口实现（待实现）
- ⏳ 数据库表创建（待实现）
- ⏳ 聊天页面集成（待实现）

## 下一步

1. 实现后端 API 接口
2. 创建数据库表
3. 在聊天页面中集成表情回应功能
4. 测试表情回应的添加、删除、显示功能
5. 测试多用户回应合并显示
6. 测试表情回应的实时更新
