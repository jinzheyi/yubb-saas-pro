# 消息编辑功能集成指南

## 概述

消息编辑功能已实现，包含以下组件：
1. `message-edit-service.uts` - 消息编辑服务
2. `message-edit-dialog.uvue` - 消息编辑对话框组件
3. `message-edit-history.uvue` - 编辑历史查看组件
4. `message-action-menu.uvue` - 消息操作菜单（已添加编辑选项）

## 功能特性

- ✅ 5分钟编辑时间限制
- ✅ 实时显示剩余编辑时间
- ✅ 编辑内容验证（不能为空，必须有变化）
- ✅ 字数统计（最多5000字）
- ✅ 编辑历史记录查看
- ✅ 编辑后标记"已编辑"
- ✅ 通知接收者消息已编辑

## 集成步骤

### 1. 在聊天页面导入组件和服务

```vue
<script setup lang="uts">
import { messageEditService, EditHistory } from '@/services/message-edit-service.uts'
import MessageEditDialog from '@/components/message-edit-dialog.uvue'
import MessageEditHistory from '@/components/message-edit-history.uvue'
import MessageActionMenu from '@/components/message-action-menu.uvue'

// 编辑对话框状态
const showEditDialog = ref(false)
const editingMessage = ref<MessageItem | null>(null)
const editTimeHint = ref('')

// 编辑历史状态
const showEditHistory = ref(false)
const editHistoryList = ref<EditHistory[]>([])
</script>
```

### 2. 添加编辑对话框和历史查看组件

```vue
<template>
  <!-- 消息编辑对话框 -->
  <MessageEditDialog
    :visible="showEditDialog"
    :content="editingMessage?.content || ''"
    :timeHint="editTimeHint"
    :showHistory="true"
    @cancel="handleEditCancel"
    @confirm="handleEditConfirm"
    @viewHistory="handleViewHistory"
  />
  
  <!-- 编辑历史查看 -->
  <MessageEditHistory
    :visible="showEditHistory"
    :historyList="editHistoryList"
    @close="showEditHistory = false"
  />
</template>
```

### 3. 在消息操作菜单中添加编辑选项

```vue
<MessageActionMenu
  :visible="showMsgMenu"
  :message="selectedMsg"
  :position="{ top: menuY, left: menuX }"
  :isSelf="selectedMsg?.isSelf"
  :canRecall="canRecallMessage(selectedMsg)"
  :canEdit="canEditMessage(selectedMsg)"
  @edit="handleMenuEdit(selectedMsg)"
  @close="closeMsgMenu"
  <!-- 其他事件 -->
/>
```

### 4. 实现编辑相关函数

```typescript
/**
 * 检查消息是否可以编辑
 */
function canEditMessage(message: MessageItem | null): boolean {
  if (!message || !message.isSelf || message.type !== 'text') {
    return false
  }
  return messageEditService.canEdit(message.timestamp)
}

/**
 * 处理菜单编辑选项
 */
function handleMenuEdit(message: MessageItem) {
  editingMessage.value = message
  editTimeHint.value = messageEditService.formatEditTimeHint(message.timestamp)
  showEditDialog.value = true
}

/**
 * 取消编辑
 */
function handleEditCancel() {
  showEditDialog.value = false
  editingMessage.value = null
  editTimeHint.value = ''
}

/**
 * 确认编辑
 */
async function handleEditConfirm(newContent: string) {
  if (!editingMessage.value) return
  
  // 检查内容是否有变化
  if (!messageEditService.hasContentChanged(editingMessage.value.content, newContent)) {
    uni.showToast({
      title: '内容未修改',
      icon: 'none'
    })
    return
  }
  
  // 显示加载提示
  uni.showLoading({
    title: '保存中...'
  })
  
  try {
    const result = await messageEditService.editMessage(
      editingMessage.value.messageId,
      newContent
    )
    
    uni.hideLoading()
    
    if (result.success) {
      // 更新本地消息内容
      const index = messages.value.findIndex(m => m.messageId === editingMessage.value!.messageId)
      if (index !== -1) {
        messages.value[index].content = newContent
        messages.value[index].isEdited = true
      }
      
      uni.showToast({
        title: '编辑成功',
        icon: 'success'
      })
      
      showEditDialog.value = false
      editingMessage.value = null
    } else {
      uni.showToast({
        title: result.message || '编辑失败',
        icon: 'none'
      })
    }
  } catch (e) {
    uni.hideLoading()
    uni.showToast({
      title: '网络错误',
      icon: 'none'
    })
  }
}

/**
 * 查看编辑历史
 */
async function handleViewHistory() {
  if (!editingMessage.value) return
  
  uni.showLoading({
    title: '加载中...'
  })
  
  try {
    const history = await messageEditService.getEditHistory(editingMessage.value.messageId)
    editHistoryList.value = history
    showEditHistory.value = true
    uni.hideLoading()
  } catch (e) {
    uni.hideLoading()
    uni.showToast({
      title: '加载失败',
      icon: 'none'
    })
  }
}
```

### 5. 在消息气泡中显示"已编辑"标记

```vue
<template>
  <view class="message-bubble">
    <text class="message-text">{{ msg.content }}</text>
    <text v-if="msg.isEdited" class="message-edited-badge">已编辑</text>
  </view>
</template>

<style scoped>
.message-edited-badge {
  font-size: 20rpx;
  color: #999;
  margin-left: 8rpx;
}
</style>
```

### 6. 添加 MessageItem 类型的 isEdited 字段

```typescript
type MessageItem = {
  id: string
  messageId: number
  senderId: string
  receiverId: string
  type: string
  content: string
  isSelf: boolean
  time: string
  timestamp: number
  showTime: boolean
  avatarText: string
  avatarBg: string
  senderName: string
  status?: string
  isEdited?: boolean  // 新增：是否已编辑
}
```

## 后端 API 接口

需要实现以下后端接口：

### 1. 编辑消息
```
POST /system/im-message/edit
Request Body:
{
  "messageId": 123456,
  "content": "新的消息内容"
}
Response:
{
  "code": 0,
  "data": true,
  "msg": "编辑成功"
}

错误响应:
{
  "code": 400,
  "data": false,
  "msg": "已超过编辑时间限制"
}
```

### 2. 获取编辑历史
```
GET /system/im-message/edit-history?messageId=123456
Response:
{
  "code": 0,
  "data": [
    {
      "content": "最新的消息内容",
      "editTime": "2024-01-15 10:30:00"
    },
    {
      "content": "之前的消息内容",
      "editTime": "2024-01-15 10:25:00"
    },
    {
      "content": "原始消息内容",
      "editTime": "2024-01-15 10:20:00"
    }
  ]
}
```

## 数据库表设计

### 1. 在 im_message 表中添加字段

```sql
ALTER TABLE `im_message` 
ADD COLUMN `is_edited` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否已编辑' AFTER `status`,
ADD COLUMN `edit_time` datetime NULL COMMENT '最后编辑时间' AFTER `is_edited`;
```

### 2. 创建编辑历史表

```sql
CREATE TABLE `im_message_edit_history` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `message_id` bigint NOT NULL COMMENT '消息ID',
  `content` text NOT NULL COMMENT '编辑后的内容',
  `edit_time` datetime NOT NULL COMMENT '编辑时间',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT '0' COMMENT '租户编号',
  PRIMARY KEY (`id`),
  KEY `idx_message_id` (`message_id`),
  KEY `idx_edit_time` (`edit_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='消息编辑历史表';
```

## 后端实现要点

### 1. 编辑时间限制检查

```java
public void editMessage(Long messageId, String newContent) {
    // 1. 查询消息
    ImMessageDO message = messageMapper.selectById(messageId);
    if (message == null) {
        throw new ServiceException("消息不存在");
    }
    
    // 2. 检查权限（只能编辑自己的消息）
    if (!message.getSenderId().equals(getUserId())) {
        throw new ServiceException("无权编辑此消息");
    }
    
    // 3. 检查消息类型（只能编辑文本消息）
    if (message.getMessageType() != 1) {
        throw new ServiceException("只能编辑文本消息");
    }
    
    // 4. 检查编辑时间限制（5分钟）
    long elapsed = System.currentTimeMillis() - message.getCreateTime().getTime();
    if (elapsed > 5 * 60 * 1000) {
        throw new ServiceException("已超过编辑时间限制");
    }
    
    // 5. 保存编辑历史
    ImMessageEditHistoryDO history = new ImMessageEditHistoryDO();
    history.setMessageId(messageId);
    history.setContent(message.getContent());
    history.setEditTime(LocalDateTime.now());
    editHistoryMapper.insert(history);
    
    // 6. 更新消息内容
    message.setContent(newContent);
    message.setIsEdited(true);
    message.setEditTime(LocalDateTime.now());
    messageMapper.updateById(message);
    
    // 7. 通知接收者消息已编辑
    notifyMessageEdited(message);
}
```

### 2. 通知接收者

```java
private void notifyMessageEdited(ImMessageDO message) {
    // 构建编辑通知消息
    MessageEditNotify notify = MessageEditNotify.newBuilder()
        .setMessageId(message.getMessageId())
        .setNewContent(message.getContent())
        .setEditTime(System.currentTimeMillis())
        .build();
    
    // 发送给接收者
    if (message.getReceiverId() != null) {
        // 单聊
        webSocketService.sendToUser(message.getReceiverId(), notify);
    } else if (message.getGroupId() != null) {
        // 群聊
        webSocketService.sendToGroup(message.getGroupId(), notify);
    }
}
```

## WebSocket 消息定义

需要在 Protobuf 中添加消息编辑通知：

```protobuf
message MessageEditNotify {
  int64 message_id = 1;
  string new_content = 2;
  int64 edit_time = 3;
}
```

## 前端处理编辑通知

```typescript
/**
 * 处理消息编辑通知
 */
function handleMessageEditNotify(notify: any) {
  const messageId = notify.messageId
  const newContent = notify.newContent
  
  // 更新本地消息
  const index = messages.value.findIndex(m => m.messageId === messageId)
  if (index !== -1) {
    messages.value[index].content = newContent
    messages.value[index].isEdited = true
  }
}
```

## 注意事项

1. 编辑时间限制为5分钟，超时后不能编辑
2. 只能编辑文本消息，其他类型消息不支持编辑
3. 只能编辑自己发送的消息
4. 编辑后会标记"已编辑"
5. 编辑历史会保存所有版本
6. 编辑后会通知接收者
7. 需要确保后端接口支持租户隔离

## 完成状态

- ✅ MessageEditService 服务实现
- ✅ MessageEditDialog 组件实现
- ✅ MessageEditHistory 组件实现
- ✅ MessageActionMenu 添加编辑选项
- ⏳ 后端 API 接口实现（待实现）
- ⏳ 数据库表创建（待实现）
- ⏳ WebSocket 编辑通知（待实现）
- ⏳ 聊天页面集成（待实现）

## 下一步

1. 实现后端 API 接口
2. 创建数据库表和字段
3. 实现 WebSocket 编辑通知
4. 在聊天页面中集成消息编辑功能
5. 测试编辑时间限制
6. 测试编辑历史记录
7. 测试编辑通知的实时推送
