# IM 功能集成指南

> 本文档说明如何将 WebSocket 消息服务集成到现有页面中

## 📋 目录

1. [已完成的核心功能](#已完成的核心功能)
2. [聊天页面集成](#聊天页面集成)
3. [消息列表页面集成](#消息列表页面集成)
4. [文件上传集成](#文件上传集成)
5. [常见问题](#常见问题)

---

## 已完成的核心功能

### ✅ 1. WebSocket 连接管理 (`utils/websocket.uts`)
- 自动连接、认证、重连
- 心跳保活
- 消息队列
- 状态管理

### ✅ 2. 消息编解码 (`utils/message-handler.uts`)
- MessageBuilder: 构建各种类型消息
- MessageParser: 解析和格式化消息

### ✅ 3. 消息服务 (`services/message-service.uts`)
- 消息发送和接收
- 消息缓存
- 会话管理
- 监听器机制

### ✅ 4. API 接口封装
- `api/conversation.uts`: 会话管理接口
- `api/message.uts`: 消息管理接口

---

## 聊天页面集成

### 文件位置
`pages/message/chat.uvue`

### 集成步骤

#### 1. 导入依赖

```typescript
<script setup lang="uts">
import { ref, onMounted, onUnmounted } from 'vue'
import { messageService, MessageItem } from '@/services/message-service.uts'
import { MessageType } from '@/utils/websocket.uts'
import { getMessageList } from '@/api/message.uts'

// 获取路由参数
const route = useRoute()
const conversationId = ref(0)
const targetId = ref(0)
const conversationType = ref(1)  // 1-单聊 2-群聊
const targetName = ref('')

// 消息列表
const messages = ref<MessageItem[]>([])

// 输入框内容
const inputText = ref('')

// 加载状态
const loading = ref(false)
const hasMore = ref(true)

// 当前用户信息（从 store 获取）
const userId = ref(0)
const tenantId = ref(0)
</script>
```

#### 2. 初始化页面

```typescript
onMounted(() => {
  // 1. 获取路由参数
  conversationId.value = parseInt(route.query.conversationId as string)
  targetId.value = parseInt(route.query.targetId as string)
  conversationType.value = parseInt(route.query.type as string)
  targetName.value = route.query.name as string
  
  // 2. 获取当前用户信息（从 store）
  const userStore = useUserStore()
  userId.value = userStore.userId
  tenantId.value = userStore.tenantId
  
  // 3. 设置消息服务的当前用户
  messageService.setCurrentUser(userId.value, tenantId.value)
  
  // 4. 加载历史消息
  loadMessages()
  
  // 5. 监听新消息
  messageService.addMessageListener(handleNewMessage)
  
  // 6. 清空未读数
  messageService.clearUnreadCount(conversationId.value)
})

onUnmounted(() => {
  // 移除消息监听器
  messageService.removeMessageListener(handleNewMessage)
})
```

#### 3. 加载历史消息

```typescript
/**
 * 加载历史消息
 */
async function loadMessages() {
  if (loading.value || !hasMore.value) {
    return
  }
  
  loading.value = true
  
  try {
    // 1. 先从缓存加载（立即显示）
    const cachedMessages = messageService.getMessages(conversationId.value)
    if (cachedMessages.length > 0) {
      messages.value = cachedMessages
      scrollToBottom()
    }
    
    // 2. 从服务器加载最新消息
    const lastMessageId = messages.value.length > 0 
      ? messages.value[0].messageId 
      : null
    
    const res = await getMessageList(conversationId.value, lastMessageId, 20)
    
    if (res.data && res.data.list) {
      const serverMessages = res.data.list as any[]
      
      // 转换为 MessageItem 格式
      const newMessages = serverMessages.map(msg => {
        return {
          id: msg.id,
          messageId: msg.messageId,
          senderId: msg.senderId,
          receiverId: msg.receiverId,
          groupId: msg.groupId,
          type: msg.messageType,
          content: JSON.parse(msg.content),
          status: msg.status,
          timestamp: new Date(msg.createTime).getTime(),
          isSelf: msg.senderId === userId.value,
          showTime: true,
          avatarText: '',
          avatarBg: '',
          senderName: msg.senderName || ''
        } as MessageItem
      })
      
      // 合并消息（去重）
      messages.value = mergeMessages(messages.value, newMessages)
      
      hasMore.value = res.data.hasMore
      scrollToBottom()
    }
    
  } catch (e) {
    console.error('[Chat] 加载消息失败:', e)
    uni.showToast({ title: '加载消息失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

/**
 * 合并消息（去重）
 */
function mergeMessages(oldMessages: MessageItem[], newMessages: MessageItem[]): MessageItem[] {
  const messageMap = new Map<number, MessageItem>()
  
  // 先添加旧消息
  oldMessages.forEach(msg => {
    messageMap.set(msg.messageId, msg)
  })
  
  // 再添加新消息（覆盖重复的）
  newMessages.forEach(msg => {
    messageMap.set(msg.messageId, msg)
  })
  
  // 转换为数组并按时间排序
  const result: MessageItem[] = []
  messageMap.forEach(msg => {
    result.push(msg)
  })
  
  result.sort((a, b) => a.timestamp - b.timestamp)
  
  return result
}
```

#### 4. 发送文本消息

```typescript
/**
 * 发送文本消息
 */
function sendTextMessage() {
  const content = inputText.value.trim()
  if (content === '') {
    return
  }
  
  // 1. 发送消息
  const message = messageService.sendTextMessage(
    conversationType.value === 1 ? targetId.value : 0,  // 单聊时传 receiverId
    conversationType.value === 2 ? targetId.value : 0,  // 群聊时传 groupId
    content,
    []  // @用户列表（暂不实现）
  )
  
  // 2. 添加到消息列表
  messages.value.push(message)
  
  // 3. 清空输入框
  inputText.value = ''
  
  // 4. 滚动到底部
  scrollToBottom()
}
```

#### 5. 处理新消息

```typescript
/**
 * 处理新消息
 */
function handleNewMessage(message: MessageItem) {
  // 只处理当前会话的消息
  const msgConversationId = message.groupId > 0 
    ? message.groupId 
    : (message.isSelf ? message.receiverId : message.senderId)
  
  if (msgConversationId !== conversationId.value) {
    return
  }
  
  // 添加到消息列表
  messages.value.push(message)
  
  // 滚动到底部
  scrollToBottom()
  
  // 发送已读回执（如果不是自己发送的）
  if (!message.isSelf) {
    messageService.sendReadReceipt(message.senderId, [message.messageId])
  }
}
```

#### 6. 发送图片消息

```typescript
/**
 * 发送图片消息
 */
async function sendImageMessage() {
  try {
    // 1. 选择图片
    const res = await uni.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera']
    })
    
    if (res.tempFilePaths.length === 0) {
      return
    }
    
    const tempFilePath = res.tempFilePaths[0]
    
    // 2. 上传图片
    uni.showLoading({ title: '上传中...' })
    
    const uploadRes = await uni.uploadFile({
      url: getBaseUrl() + '/infra/file/upload',
      filePath: tempFilePath,
      name: 'file',
      header: {
        'Authorization': 'Bearer ' + getAccessToken()
      }
    })
    
    uni.hideLoading()
    
    const uploadData = JSON.parse(uploadRes.data)
    if (uploadData.code !== 0) {
      uni.showToast({ title: '上传失败', icon: 'none' })
      return
    }
    
    const imageUrl = uploadData.data
    
    // 3. 获取图片信息
    const imageInfo = await uni.getImageInfo({ src: tempFilePath })
    
    // 4. 发送图片消息
    const message = messageService.sendImageMessage(
      conversationType.value === 1 ? targetId.value : 0,
      conversationType.value === 2 ? targetId.value : 0,
      imageUrl,
      imageUrl,  // 缩略图（暂时使用原图）
      imageInfo.width,
      imageInfo.height,
      0  // 文件大小（暂不获取）
    )
    
    // 5. 添加到消息列表
    messages.value.push(message)
    scrollToBottom()
    
  } catch (e) {
    console.error('[Chat] 发送图片失败:', e)
    uni.showToast({ title: '发送失败', icon: 'none' })
  }
}
```

#### 7. 滚动到底部

```typescript
/**
 * 滚动到底部
 */
function scrollToBottom() {
  nextTick(() => {
    // 使用 scroll-view 的 scroll-into-view 属性
    // 或者使用 uni.pageScrollTo
    uni.pageScrollTo({
      scrollTop: 999999,
      duration: 300
    })
  })
}
```

---

## 消息列表页面集成

### 文件位置
`pages/message/message.uvue`

### 集成步骤

#### 1. 导入依赖

```typescript
<script setup lang="uts">
import { ref, onMounted, onUnmounted } from 'vue'
import { messageService, ConversationItem } from '@/services/message-service.uts'
import { getConversationList } from '@/api/conversation.uts'

// 会话列表
const conversations = ref<ConversationItem[]>([])

// 加载状态
const loading = ref(false)
const refreshing = ref(false)
</script>
```

#### 2. 初始化页面

```typescript
onMounted(() => {
  // 1. 加载会话列表
  loadConversations()
  
  // 2. 监听会话更新
  messageService.addConversationUpdateListener(handleConversationUpdate)
})

onUnmounted(() => {
  // 移除监听器
  messageService.removeConversationUpdateListener(handleConversationUpdate)
})
```

#### 3. 加载会话列表

```typescript
/**
 * 加载会话列表
 */
async function loadConversations() {
  loading.value = true
  
  try {
    // 1. 先从缓存加载（立即显示）
    const cachedConversations = messageService.getConversations()
    if (cachedConversations.length > 0) {
      conversations.value = cachedConversations
    }
    
    // 2. 从服务器加载最新数据
    const res = await getConversationList()
    
    if (res.data) {
      const serverConversations = res.data as any[]
      
      // 转换为 ConversationItem 格式
      conversations.value = serverConversations.map(conv => {
        return {
          id: conv.id,
          type: conv.conversationType,
          targetId: conv.targetId,
          name: conv.targetName,
          avatar: conv.targetAvatar,
          avatarText: conv.targetName.substring(0, 1),
          avatarBg: getRandomColor(),
          lastMessage: conv.lastMessageContent,
          lastTime: formatTime(conv.lastMessageTime),
          timestamp: new Date(conv.lastMessageTime).getTime(),
          unreadCount: conv.unreadCount,
          isPinned: conv.isPinned,
          noDisturb: conv.noDisturb,
          groupMemberCount: conv.groupMemberCount || 0
        } as ConversationItem
      })
    }
    
  } catch (e) {
    console.error('[Message] 加载会话列表失败:', e)
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}
```

#### 4. 处理会话更新

```typescript
/**
 * 处理会话更新
 */
function handleConversationUpdate(conversation: ConversationItem) {
  // 查找会话
  const index = conversations.value.findIndex(c => c.id === conversation.id)
  
  if (index !== -1) {
    // 更新现有会话
    conversations.value[index] = conversation
  } else {
    // 添加新会话
    conversations.value.unshift(conversation)
  }
  
  // 重新排序（按时间戳降序）
  conversations.value.sort((a, b) => b.timestamp - a.timestamp)
}
```

#### 5. 跳转到聊天页面

```typescript
/**
 * 打开聊天页面
 */
function openChat(conversation: ConversationItem) {
  uni.navigateTo({
    url: `/pages/message/chat?conversationId=${conversation.id}&targetId=${conversation.targetId}&type=${conversation.type}&name=${conversation.name}`
  })
}
```

---

## 文件上传集成

### 配置上传地址

在 `utils/request.uts` 中添加：

```typescript
/**
 * 获取基础 URL
 */
export function getBaseUrl(): string {
  return CONFIG_BASE_URL + '/app-api'
}
```

### 上传文件示例

```typescript
import { getBaseUrl } from '@/utils/request.uts'
import { getAccessToken } from '@/utils/auth.uts'

/**
 * 上传文件
 */
async function uploadFile(filePath: string): Promise<string> {
  const res = await uni.uploadFile({
    url: getBaseUrl() + '/infra/file/upload',
    filePath: filePath,
    name: 'file',
    header: {
      'Authorization': 'Bearer ' + getAccessToken()
    }
  })
  
  const data = JSON.parse(res.data)
  if (data.code !== 0) {
    throw new Error(data.msg)
  }
  
  return data.data as string
}
```

---

## 常见问题

### Q1: WebSocket 连接失败怎么办？

**A**: 检查以下几点：
1. WebSocket 服务器地址是否正确（在 `websocket.uts` 中配置）
2. Token 是否有效（登录后才能连接）
3. 网络是否正常
4. 查看控制台日志，定位具体错误

### Q2: 消息发送后没有显示？

**A**: 检查：
1. 是否调用了 `messageService.setCurrentUser()`
2. 是否添加了消息监听器
3. 查看控制台是否有错误日志

### Q3: 如何调试 WebSocket 消息？

**A**: 在浏览器控制台查看：
```typescript
// 在 websocket.uts 中已有详细日志
console.log('[WebSocket] 发送消息:', message)
console.log('[WebSocket] 收到消息:', message)
```

### Q4: 如何清理缓存？

**A**: 调用清理方法：
```typescript
messageService.clearCache()
```

---

## 下一步开发计划

### 优先级 P0（必须完成）
- [ ] 集成到聊天页面（发送/接收文本消息）
- [ ] 集成到消息列表页面（显示会话列表）
- [ ] 实现图片上传和发送
- [ ] 实现消息已读回执

### 优先级 P1（重要）
- [ ] 实现语音录制和发送
- [ ] 实现视频录制和发送
- [ ] 实现文件上传和发送
- [ ] 实现消息撤回

### 优先级 P2（可选）
- [ ] 实现消息本地存储（SQLite）
- [ ] 实现消息搜索
- [ ] 实现消息转发
- [ ] 实现群聊 @功能

---

## 技术支持

如有问题，请查看：
1. 设计文档：`sql/doc/IM即时通讯逻辑设计文档-v1.0.md`
2. 代码注释：每个文件都有详细的注释说明
3. 控制台日志：查看详细的运行日志

**祝开发顺利！** 🚀
