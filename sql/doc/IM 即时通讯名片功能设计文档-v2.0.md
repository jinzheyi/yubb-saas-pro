# IM 即时通讯名片功能设计文档 v2.0

> **文档版本**: v2.0.0  
> **创建日期**: 2026-04-02  
> **项目**: 圣钰 SaaS Pro - IM 即时通讯系统  
> **定位**: 企业内部 IM 名片分享功能  
> **目标体验**: 对齐企业微信/钉钉的名片分享与快速操作体验  
> **关联文档**: `sql/doc/IM即时通讯架构设计文档-v2.0.md`

---

## 1. 功能概述与范围

### 1.1 功能定义
在企业 IM 系统中实现**名片消息**功能，支持用户在聊天中分享联系人名片，接收方可快速查看详情并发起对话。

**核心价值**：
- 快速介绍：避免手动输入用户信息
- 组织发现：帮助成员快速找到同事并建立联系
- 业务协同：支持跨部门、跨项目的人员推介

### 1.2 范围边界（In Scope / Out Scope）

#### In Scope
- ✅ **名片消息发送**：从聊天页"+"入口选择联系人并发送名片
- ✅ **名片卡片展示**：卡片式 UI 布局，显示头像、姓名、职位、公司
- ✅ **快速操作**：点击"发消息"直接跳转到私聊窗口
- ✅ **用户详情**：点击卡片查看完整用户信息（复用现有页面）
- ✅ **权限控制**：仅限同租户用户，敏感信息脱敏
- ✅ **多端一致**：App/H5 统一体验

#### Out Scope（本期不实现）
- ❌ **好友关系**：企业 IM 无好友概念，不涉及添加好友流程
- ❌ **外部联系人**：不支持分享企业外部人员名片
- ❌ **名片编辑**：不支持自定义名片信息
- ❌ **批量分享**：不支持一次分享多个名片
- ❌ **收藏功能**：不支持收藏名片到收藏夹

---

## 2. 技术方案设计

### 2.1 消息类型定义

#### 后端消息类型枚举
```java
// ImMessageTypeEnum.java 新增
CONTACT(11, "名片消息")

public static boolean isContact(Integer type) {
    return ObjUtil.equal(CONTACT.type, type);
}
```

#### 前端消息类型
```typescript
// MessageType 枚举扩展
enum MessageType {
  CONTACT = 11  // 名片消息
}
```

#### Protobuf 消息定义
```protobuf
// im_message.proto
message ContactMessage {
  string user_id = 1;           // 用户 ID（string，避免精度丢失）
  string user_name = 2;         // 用户姓名
  string avatar = 3;            // 头像 URL
  string nickname = 4;          // 昵称（可选）
  string position = 5;          // 职位（可选）
  string company = 6;           // 公司名称（可选）
  string phone = 7;             // 手机号（脱敏，可选）
  string email = 8;             // 邮箱（脱敏，可选）
  int32 gender = 9;             // 性别（可选）
  string tenant_id = 10;        // 租户 ID（权限控制用）
}
```

### 2.2 数据存储设计

#### 消息存储结构
```sql
-- im_chat_message 表结构（复用现有）
-- message_type = 11 表示名片消息
-- content 字段：固定为 "名片消息"
-- extra 字段：JSON 格式存储名片详细信息

INSERT INTO im_chat_message (
  chat_id, sender_id, message_type, content, extra, sequence, rev
) VALUES (
  'chat_123', 
  'user_001', 
  11, 
  '名片消息',
  '{"type":"CONTACT","userId":"user_002","userName":"张三","avatar":"https://.../avatar.jpg","position":"产品经理","company":"圣钰科技","phone":"138****1234","email":"zhang***@example.com","gender":1,"tenantId":"tenant_001"}',
  1001,
  1
);
```

#### extra 字段 JSON Schema
```json
{
  "type": "CONTACT",
  "userId": "string",           // 用户 ID（必填）
  "userName": "string",         // 用户姓名（必填）
  "avatar": "string",           // 头像 URL（必填）
  "nickname": "string",         // 昵称（可选）
  "position": "string",         // 职位（可选）
  "company": "string",          // 公司（可选）
  "phone": "string",           // 手机号（脱敏，可选）
  "email": "string",           // 邮箱（脱敏，可选）
  "gender": 1,                 // 性别（可选）
  "tenantId": "string"         // 租户 ID（必填，权限控制）
}
```

### 2.3 权限与隐私控制

#### 企业 IM 权限模型
- **租户隔离**：只能分享同租户内的用户名片
- **组织可见性**：基于组织架构的可见性控制

#### 权限验证逻辑
```java
private void validateContactPermission(ContactMessage contactMessage) {
    Long currentUserId = SecurityFrameworkUtils.getLoginUserId();
    String currentTenantId = SecurityFrameworkUtils.getLoginTenantId();
    Long contactUserId = Long.parseLong(contactMessage.getUserId());
    String contactTenantId = contactMessage.getTenantId();
    
    // 租户隔离检查
    if (!Objects.equals(currentTenantId, contactTenantId)) {
        throw new ServiceException("无权分享其他租户的用户名片");
    }
}
```

### 2.4 API 接口设计

#### 联系人搜索接口（复用现有）
```typescript
// GET /system/im/contact/list
interface ContactListReq {
  pageNo?: number
  pageSize?: number
  keyword?: string
  deptId?: string     // 按部门筛选
}

interface ContactListResp {
  list: ContactItem[]
  total: number
}

interface ContactItem {
  userId: string
  userName: string
  avatar: string
  nickname?: string
  position?: string
  company?: string
  deptId?: string
  deptName?: string
}
```

#### 名片消息发送接口（复用现有）
```typescript
// POST /system/im/message/send
interface SendContactMessageReq {
  chatId: string
  receiverId?: string
  groupId?: string
  messageType: 11  // CONTACT
  content: string   // "名片消息"
  extra: string     // JSON 字符串，ContactMessage 序列化
}
```

#### 用户详情接口（复用现有）
```typescript
// GET /system/user/profile/get?id={userId}
interface UserProfileResp {
  userId: string
  userName: string
  avatar: string
  nickname?: string
  position?: string
  company?: string
  phone?: string     // 根据权限返回（可能脱敏）
  email?: string     // 根据权限返回（可能脱敏）
  gender?: number
  deptId?: string
  deptName?: string
}
```

---

## 3. 前端实现方案

### 3.1 页面路由设计

#### 新增页面
```
pages/message/contact-picker.uvue     # 联系人选择页面
```

#### 复用页面
```
pages/contacts/user-detail.uvue       # 用户详情页面（已存在）
pages/message/chat.uvue               # 聊天页面（扩展名片功能）
```

### 3.2 联系人选择页面设计

#### 页面结构
```vue
<template>
  <view class="contact-picker">
    <!-- 状态栏 -->
    <view class="status-bar"></view>
    
    <!-- 头部导航 -->
    <view class="header">
      <view class="header-left" @click="handleBack">
        <text class="iconfont">&#xeb04;</text>
        <text class="back-text">返回</text>
      </view>
      <text class="header-title">选择联系人</text>
      <view class="header-right" @click="handleConfirm" v-if="selectedContact">
        <text class="confirm-btn">确定</text>
      </view>
    </view>
    
    <!-- 搜索框 -->
    <view class="search-container">
      <view class="search-box">
        <text class="search-icon">🔍</text>
        <input 
          class="search-input" 
          v-model="keyword" 
          placeholder="搜索联系人姓名或职位"
          @input="handleSearchInput"
        />
      </view>
    </view>
    
    <!-- 联系人列表 -->
    <scroll-view class="contact-list" scroll-y="true">
      <view 
        v-for="contact in filteredContacts" 
        :key="contact.userId"
        class="contact-item"
        @click="handleContactSelect(contact)"
      >
        <image class="contact-avatar" :src="contact.avatar" />
        <view class="contact-info">
          <text class="contact-name">{{ contact.userName }}</text>
          <text class="contact-position">{{ contact.position }} · {{ contact.company }}</text>
        </view>
        <view class="contact-selected" v-if="selectedContact?.userId === contact.userId">
          <text class="selected-icon">✓</text>
        </view>
      </view>
    </scroll-view>
  </view>
</template>
```

#### UTS 脚本实现
```typescript
<script setup lang="uts">
  // 类型定义
  type ContactItem = {
    userId: string
    userName: string
    avatar: string
    nickname?: string
    position?: string
    company?: string
    deptId?: string
    deptName?: string
  }
  
  // 响应式数据
  const contactList = ref<ContactItem[]>([])
  const filteredContacts = ref<ContactItem[]>([])
  const selectedContact = ref<ContactItem | null>(null)
  const keyword = ref<string>('')
  const loading = ref<boolean>(false)
  
  // 导入 API
  import { getContactList } from '../../api/contact.uts'
  
  // 加载联系人列表
  async function loadContacts(): Promise<void> {
    if (loading.value) return
    loading.value = true
    
    try {
      const response = await getContactList({
        pageNo: 1,
        pageSize: 100,
        keyword: keyword.value
      })
      
      contactList.value = response.list.map((item: any) => ({
        userId: item.userId,
        userName: item.userName,
        avatar: item.avatar,
        nickname: item.nickname,
        position: item.position,
        company: item.company,
        deptId: item.deptId,
        deptName: item.deptName
      }))
      
      filteredContacts.value = contactList.value
    } catch (error) {
      console.error('[ContactPicker] 加载联系人失败:', error)
      uni.showToast({ 
        title: '加载失败', 
        icon: 'none' 
      })
    } finally {
      loading.value = false
    }
  }
  
  // 搜索防抖
  let searchTimer: number = 0
  function handleSearchInput(): void {
    clearTimeout(searchTimer)
    searchTimer = setTimeout(() => {
      filterContacts()
    }, 500)
  }
  
  // 过滤联系人
  function filterContacts(): void {
    if (!keyword.value) {
      filteredContacts.value = contactList.value
      return
    }
    
    const keywordLower = keyword.value.toLowerCase()
    filteredContacts.value = contactList.value.filter(contact => 
      contact.userName.toLowerCase().includes(keywordLower) ||
      (contact.position && contact.position.toLowerCase().includes(keywordLower)) ||
      (contact.company && contact.company.toLowerCase().includes(keywordLower))
    )
  }
  
  // 选择联系人
  function handleContactSelect(contact: ContactItem): void {
    selectedContact.value = contact
  }
  
  // 确认选择
  function handleConfirm(): void {
    if (!selectedContact.value) return
    
    // 通过事件总线返回选中的联系人
    const eventChannel = getOpenerEventChannel()
    eventChannel.emit('contactSelected', selectedContact.value)
    
    uni.navigateBack({ delta: 1 })
  }
  
  // 返回
  function handleBack(): void {
    uni.navigateBack({ delta: 1 })
  }
  
  // 生命周期
  onMounted(() => {
    loadContacts()
  })
  
  onUnload(() => {
    clearTimeout(searchTimer)
  })
</script>
```

### 3.3 聊天页面名片功能集成

#### 功能入口扩展
```typescript
// chat.uvue 中的 handleFeature 函数扩展
function handleFeature(item: any): void {
  if (item.nameKey === 'chat.features.card') {
    handleContactFeature()
  }
  // ... 其他功能处理
}

async function handleContactFeature(): Promise<void> {
  try {
    // 跳转到联系人选择页面
    const contact = await new Promise<ContactItem>((resolve, reject) => {
      uni.navigateTo({
        url: '/pages/message/contact-picker',
        events: {
          contactSelected: (contact: ContactItem) => {
            resolve(contact)
          }
        },
        fail: (err) => reject(err)
      })
    })
    
    if (contact) {
      await sendContactMessage(contact)
      scrollToBottom()
    }
  } catch (error) {
    console.error('[Chat] 发送名片消息失败:', error)
    uni.showToast({ 
      title: '发送失败', 
      icon: 'none' 
    })
  }
}
```

#### 名片消息发送
```typescript
async function sendContactMessage(contact: ContactItem): Promise<void> {
  // 构建名片消息
  const contactMessage = {
    type: 'CONTACT',
    userId: contact.userId,
    userName: contact.userName,
    avatar: contact.avatar,
    nickname: contact.nickname,
    position: contact.position,
    company: contact.company,
    tenantId: getTenantId()
  }
  
  const payload = {
    chatId: chatId.value,
    receiverId: getReceiverIdForMessage(),
    groupId: getGroupIdForMessage(),
    messageType: 11, // CONTACT
    content: '名片消息',
    extra: JSON.stringify(contactMessage)
  }
  
  // 发送消息
  await messageService.sendMessage(payload)
}
```

### 3.4 名片消息渲染

#### 卡片渲染模板
```vue
<!-- 名片消息类型 -->
<view v-else-if="msg.messageType === 11" class="message-bubble bubble-contact">
  <view class="contact-card" @click="handleContactOpen(msg)">
    <view class="contact-header">
      <image class="contact-avatar" :src="msg.avatar" />
      <view class="contact-info">
        <text class="contact-name">{{ msg.userName }}</text>
        <text class="contact-position">{{ msg.position }} · {{ msg.company }}</text>
      </view>
    </view>
    
    <view class="contact-details" v-if="msg.phone || msg.email">
      <text v-if="msg.phone" class="contact-detail">📞 {{ msg.phone }}</text>
      <text v-if="msg.email" class="contact-detail">✉️ {{ msg.email }}</text>
    </view>
    
    <view class="contact-actions" v-if="!isSelf(msg.senderId)">
      <button class="action-btn primary" @click.stop="handleSendMessage(msg)">发消息</button>
    </view>
  </view>
</view>
```

#### 交互处理
```typescript
// 打开用户详情
function handleContactOpen(msg: MessageItem): void {
  uni.navigateTo({
    url: `/pages/contacts/user-detail?id=${msg.userId}`
  })
}

// 发消息
function handleSendMessage(msg: MessageItem): void {
  const targetIdParam = encodeIdParam(msg.userId)
  uni.navigateTo({
    url: `/pages/message/chat?type=single&targetId=${targetIdParam}&name=${encodeURIComponent(msg.userName)}&entryMode=latest`
  })
}
```

---

## 四、实现步骤

### 4.1 后端实现

#### Step 1：新增消息类型枚举
文件：`ImMessageTypeEnum.java`
```java
CONTACT(11, "名片消息"),

public static boolean isContact(Integer type) {
    return ObjUtil.equal(CONTACT.type, type);
}
```

#### Step 2：创建联系人 API
文件：`AppImContactController.java`
```java
@RestController
@RequestMapping("/im/contact")
public class AppImContactController {
    
    @GetMapping("/list")
    public CommonResult<PageResult<ContactVO>> getContactList(
            @RequestParam(value = "pageNo", defaultValue = "1") Integer pageNo,
            @RequestParam(value = "pageSize", defaultValue = "50") Integer pageSize,
            @RequestParam(value = "keyword", required = false) String keyword) {
        
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(contactService.getContactList(userId, pageNo, pageSize, keyword));
    }
}
```

#### Step 3：名片消息处理器
文件：`ContactMessageProcessor.java`
```java
@Slf4j
@Component
@RequiredArgsConstructor
public class ContactMessageProcessor implements MessageProcessor {
    
    private final NettySessionManager sessionManager;
    private final MessageStorageService messageStorageService;
    private final NettyMessageSender messageSender;
    
    @Override
    public void process(ChannelHandlerContext ctx, ImMessage message) {
        try {
            // 解析名片消息
            ContactMessage contactMessage = ContactMessage.parseFrom(message.getBody());
            
            // 验证名片信息权限
            validateContactPrivacy(contactMessage);
            
            // 存储消息
            MessageSaveResult saveResult = messageStorageService.saveMessageWithResult(message);
            
            // 回推给发送者
            // 转发给接收者
            // ...
            
        } catch (InvalidProtocolBufferException e) {
            log.error("[ContactMessage] 解析消息失败", e);
        }
    }
    
    private void validateContactPrivacy(ContactMessage contactMessage) {
        // 验证发送者是否有权分享该名片
        // 检查隐私权限
    }
}
```

### 4.2 前端实现（充分利用现有组件）

#### 现有可复用组件分析

**1. 联系人选择器组件**
- 文件：`components/contact-selector/contact-selector.uvue`
- 功能：联系人列表展示、搜索、选择
- 可直接复用：✅ 是
- 使用方式：作为子组件嵌入名片选择页面

**2. 用户详情页面**
- 文件：`pages/contacts/user-detail.uvue`
- 功能：展示用户详细信息
- 可直接复用：✅ 是
- 使用方式：点击名片卡片直接跳转到该页面

**3. 联系人 API**
- 文件：`api/contact.uts`
- 接口：`getContactList()`, `searchContact(keyword)`
- 可直接复用：✅ 是

**4. 用户 API**
- 文件：`api/user.uts`
- 接口：`getUserDetail(id)`
- 可直接复用：✅ 是

#### Step 1：创建名片选择页面（复用 contact-selector 组件）
文件：`pages/message/contact-picker.uvue`

**方案 A：完全复用组件（推荐）**
```vue
<template>
  <view class="contact-picker">
    <view class="status-bar"></view>
    <view class="header">
      <view class="header-left" @click="handleBack">
        <text class="iconfont">&#xeb04;</text>
        <text class="back-text">返回</text>
      </view>
      <text class="header-title">选择联系人</text>
      <view class="header-right" @click="handleConfirm" v-if="selectedContact">
        <text class="confirm-btn">确定</text>
      </view>
    </view>
    
    <!-- 复用联系人选择器组件 -->
    <contact-selector 
      :contacts="contactList"
      :selectable="false"
      @select="handleContactSelect"
    />
  </view>
</template>

<script setup lang="uts">
  import { useI18n } from '../../hooks/useI18n.uts'
  import { getContactList, searchContact } from '../../api/contact.uts'
  import contactSelector from '../../components/contact-selector/contact-selector.uvue'
  
  const { t } = useI18n()
  const contactList = ref<any[]>([])
  const selectedContact = ref<any>(null)
  
  // 加载联系人列表
  async function loadContacts() {
    try {
      const contacts = await getContactList()
      contactList.value = contacts.map(contact => ({
        id: contact.id.toString(),
        userId: contact.id.toString(),
        name: contact.remarkName || contact.nickname || '未知',
        role: contact.deptName || '',
        avatar: contact.avatar, // 如果有头像 URL
        avatarText: contact.nickname?.charAt(0) || '未',
        avatarBg: getUserAvatarColor(contact.id.toString()),
        pinyin: contact.pinyin || getPinyinFirstLetter(contact.nickname)
      }))
    } catch (e) {
      console.error('[ContactPicker] 加载联系人失败:', e)
      uni.showToast({ title: '加载失败', icon: 'none' })
    }
  }
  
  // 处理联系人选择
  function handleContactSelect(item: any) {
    selectedContact.value = item
    // 直接返回选中的联系人
    uni.navigateBack({
      delta: 1
    })
  }
  
  // 返回选中的联系人（通过事件总线或全局状态）
  onMounted(() => {
    loadContacts()
  })
</script>
```

**方案优势**：
- ✅ 复用现有组件，开发成本低
- ✅ 样式统一，用户体验一致
- ✅ 维护成本低

#### Step 2：扩展消息服务
文件：`services/message-service.uts`

```typescript
/**
 * 发送名片消息
 */
async function sendContactMessage(
  chatId: string,
  receiverId: string,
  groupId: string,
  contact: ContactMessage
): Promise<void> {
  const payload = {
    chatId,
    receiverId,
    groupId,
    messageType: 11, // CONTACT
    content: '名片消息',
    extra: JSON.stringify({
      type: 'CONTACT',
      userId: contact.userId,
      userName: contact.userName,
      avatar: contact.avatar,
      nickname: contact.nickname,
      position: contact.position,
      company: contact.company,
      phone: contact.phone,
      email: contact.email,
      gender: contact.gender
    })
  }
  
  await request({
    url: '/im/message/send',
    method: 'POST',
    data: payload
  })
}
```

#### Step 3：在 chat.uvue 中添加名片功能入口
```typescript
function handleFeature(item: any) {
  if (item.nameKey === 'chat.features.card') {
    handleContactFeature()
  }
  // ...
}

async function handleContactFeature() {
  try {
    // 跳转到名片选择页面
    const contact = await new Promise<ContactMessage>((resolve, reject) => {
      uni.navigateTo({
        url: '/pages/message/contact-picker',
        events: {
          // 监听页面返回时传递的数据
          contactSelected: (contact: ContactMessage) => {
            resolve(contact)
          }
        },
        fail: (err) => reject(err)
      })
      
      // 备用方案：通过全局状态管理传递数据
      setTimeout(() => {
        const selectedContact = getApp().globalData.selectedContact
        if (selectedContact) {
          resolve(selectedContact)
        }
      }, 1000)
    })
    
    if (contact) {
      await messageService.sendContactMessage(
        chatId.value,
        getReceiverIdForMessage(),
        getGroupIdForMessage(),
        contact
      )
      scrollToBottom()
    }
  } catch (e) {
    console.error('[Chat] 发送名片消息失败:', e)
    uni.showToast({ title: '发送失败', icon: 'none' })
  }
}
```

#### Step 4：名片消息渲染
文件：`chat.uvue`（模板部分）

```vue
<!-- 名片消息类型 -->
<view v-else-if="msg.type === 'contact'" class="message-bubble bubble-contact">
  <view class="contact-card" @click="handleContactOpen(msg)">
    <view class="contact-header">
      <image class="contact-avatar" :src="msg.avatar || getDefaultAvatar()" />
      <view class="contact-info">
        <text class="contact-name">{{ msg.userName }}</text>
        <text class="contact-position">{{ msg.position || msg.company || '' }}</text>
      </view>
    </view>
    <view class="contact-actions">
      <button class="action-btn primary" @click.stop="handleMessage(msg)">发消息</button>
    </view>
  </view>
</view>
```

```typescript
// 打开用户详情（复用现有 user-detail 页面）
function handleContactOpen(msg: MessageItem) {
  uni.navigateTo({
    url: `/pages/contacts/user-detail?id=${msg.userId}`
  })
}

// 发消息
function handleMessage(msg: MessageItem) {
  // 跳转到与 msg.userId 的私聊窗口
  const targetIdParam = encodeIdParam(msg.userId)
  uni.navigateTo({
    url: `/pages/message/chat?type=single&targetId=${targetIdParam}&name=${encodeURIComponent(msg.userName)}&entryMode=latest`
  })
}
```

#### Step 4：名片消息渲染
文件：`chat.uvue` 模板部分
```vue
<view v-else-if="msg.type === 'contact'" class="message-bubble bubble-contact">
  <view class="contact-card" @click="handleContactOpen(msg)">
    <view class="contact-header">
      <image class="contact-avatar" :src="msg.avatar" />
      <view class="contact-info">
        <text class="contact-name">{{ msg.userName }}</text>
        <text class="contact-position">{{ msg.position }} · {{ msg.company }}</text>
      </view>
    </view>
    <view class="contact-details" v-if="msg.phone || msg.email">
      <text v-if="msg.phone" class="contact-detail">📞 {{ msg.phone }}</text>
      <text v-if="msg.email" class="contact-detail">✉️ {{ msg.email }}</text>
    </view>
    <view class="contact-actions" v-if="!isSelf(msg.senderId)">
      <button class="action-btn primary" @click.stop="handleSendMessage(msg)">发消息</button>
    </view>
  </view>
</view>
```

---

## 五、成本分析

### 5.1 开发成本

| 模块 | 工作量（人天） | 说明 |
|------|---------------|------|
| 后端消息类型扩展 | 0.5 | 新增 CONTACT 类型枚举 |
| 联系人 API 验证 | 0.5 | 验证现有联系人 API |
| 名片消息处理器 | 1 | 权限验证、消息处理 |
| 前端联系人选择页 | 2 | 复用 contact-selector 组件 |
| 消息发送功能 | 0.5 | 扩展 message-service |
| 名片消息渲染 | 0.5 | 卡片样式、交互 |
| 用户详情页 | 0.5 | 复用现有 user-detail 页面 |
| 联调测试 | 1.5 | 前后端联调、多端测试 |
| **总计** | **6.5 人天** | 约 1.5 周 |

### 5.2 技术资源
- 无需第三方 SDK
- 使用现有用户信息接口
- 依赖现有消息发送框架

---

## 5. 企业级安全与合规

### 5.1 数据安全
- **租户隔离**：严格的租户级别数据隔离
- **权限最小化**：只显示用户有权限查看的信息

### 5.2 容错机制
- **用户不存在处理**：名片中的用户被删除时的优雅降级
- **网络异常处理**：弱网环境下的重试与降级

### 5.3 多端兼容
- App 端：使用原生组件渲染
- H5 端：使用 Web 组件渲染
- 确保各端样式一致

### 5.4 性能优化
- 联系人列表分页加载

---

## 六、注意事项

### 6.1 技术约束
- **Long 精度**：所有 ID 字段使用 `string` 类型，避免精度丢失
- **UTS 规范**：遵循 UTS 强类型约束，不使用 undefined、truthy/falsy
- **组件复用**：最大化复用现有组件和 API，减少重复开发
- **协议一致性**：遵循现有消息协议和 WebSocket 机制

### 6.2 设计原则
- **用户体验优先**：对齐企业微信/钉钉的交互体验
- **性能优先**：确保大列表和搜索的流畅性
- **可维护性**：清晰的代码结构和文档

### 6.3 多端兼容
- App 端：使用原生组件渲染
- H5 端：使用 Web 组件渲染
- 确保各端样式一致

### 6.4 性能优化
- 联系人列表分页加载

---

## 七、验收标准

### 7.1 功能验收
- [ ] 从聊天页"+"入口可以进入联系人选择页面
- [ ] 支持按姓名、职位搜索联系人
- [ ] 选择联系人后可以成功发送名片消息
- [ ] 名片卡片消息正确展示（头像、姓名、职位、公司）
- [ ] 点击名片卡片可以查看用户详情
- [ ] 点击"发消息"可以跳转到私聊窗口
- [ ] 只能分享同租户内的用户名片

### 7.2 性能验收
- [ ] 联系人选择页面打开时间 < 1 秒
- [ ] 搜索响应时间 < 500ms
- [ ] 名片消息发送成功率 > 99%
- [ ] 联系人列表滚动流畅（60fps）
- [ ] 内存使用合理，无明显内存泄漏

### 7.3 兼容性验收
- [ ] App 端（Android 10+）正常工作
- [ ] App 端（iOS 14+）正常工作
- [ ] H5 端（Chrome/Safari）正常工作
- [ ] 不同网络环境（WiFi/4G/5G）正常工作

### 7.4 安全验收
- [ ] 跨租户名片分享被正确拒绝
- [ ] 权限控制生效

---

## 8. 参考资料

- [IM即时通讯架构设计文档-v2.0.md](./IM即时通讯架构设计文档-v2.0.md)
- [IM即时通讯开发任务清单-v2.0.md](./IM即时通讯开发任务清单-v2.0.md)
- [企业微信名片功能设计](https://work.weixin.qq.com/)
- [钉钉数字化名片](https://www.dingtalk.com/)
- [Web 性能最佳实践](https://developer.mozilla.org/zh-CN/docs/Web/Performance)
---

**文档版本**：v2.0.0  
**创建日期**：2026-04-02  
**适用项目**：shengyu-im-saas  
**责任人**：开发团队  
**审核人**：架构师、产品经理
