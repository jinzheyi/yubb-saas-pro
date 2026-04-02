# IM 即时通讯 - 名片功能设计补充文档 v2.0

## 一、功能概述

### 1.1 功能描述
在对话页面中添加"名片"功能，用户可以：
- 点击名片图标进入联系人选择界面
- 从联系人列表中选择要分享的用户
- 发送用户名片消息到当前对话
- 接收方点击名片卡片可以查看用户详情
- 接收方可以快速发起与该用户的会话

### 1.2 UI 交互流程
```
对话页面 → 点击"+"更多 → 点击"名片"图标 
→ 进入联系人选择页面
→ 搜索或选择联系人
→ 确认发送名片
→ 对话页面显示名片卡片消息
→ 点击卡片 → 查看用户详情
→ 点击"发消息" → 跳转到与该用户的私聊窗口
```

---

## 二、技术方案

### 2.1 名片消息类型定义

#### 后端消息类型枚举
```java
// ImMessageTypeEnum.java 新增
CONTACT(11, "名片消息")
```

#### 前端消息类型
```typescript
enum MessageType {
  CONTACT = 11  // 名片消息
}
```

### 2.2 名片数据结构

#### 名片消息结构（前端发送）
```typescript
interface ContactMessage {
  type: 'contact' | 11      // 消息类型
  userId: string            // 用户 ID
  userName: string          // 用户姓名
  avatar: string            // 头像 URL
  nickname?: string         // 昵称
  position?: string         // 职位
  company?: string          // 公司
  phone?: string            // 手机号（脱敏）
  email?: string            // 邮箱
  gender?: number           // 性别（0-未知 1-男 2-女）
  userIds?: string[]        // 允许查看完整信息的用户 ID 列表
}
```

#### 后端存储结构
```sql
-- 消息表 extra 字段存储
{
  "type": "CONTACT",
  "userId": "1001",
  "userName": "张三",
  "avatar": "https://.../avatar.jpg",
  "nickname": "张三",
  "position": "产品经理",
  "company": "圣钰科技",
  "phone": "138****1234",
  "email": "zhangsan@example.com",
  "gender": 1,
  "userIds": ["1002", "1003"]  // 隐私控制：允许查看完整信息的用户
}
```

#### vCard 标准兼容（可选）
```vcard
BEGIN:VCARD
VERSION:3.0
FN:张三
N:张;三;;;
ORG:圣钰科技;产品部;
TITLE:产品经理
TEL;TYPE=WORK,VOICE:138****1234
EMAIL;TYPE=WORK:zhangsan@example.com
PHOTO;VALUE=URI:https://.../avatar.jpg
END:VCARD
```

### 2.3 权限控制设计（企业 IM 场景）

#### 企业级 IM 设计理念
- ✅ **联系人 = 企业内部所有用户**（同租户下的系统用户）
- ❌ **没有"好友"概念**（不需要添加好友）
- ✅ **权限控制 = 租户隔离 + 组织架构可见性**

#### 权限验证逻辑
```java
private void validateContactPrivacy(ContactMessage contactMessage) {
    Long currentUserId = getCurrentUserId();
    Long contactUserId = Long.valueOf(contactMessage.getUserId());
    
    // 1. 只能分享自己的名片，或同企业/租户下的用户名片
    if (!currentUserId.equals(contactUserId)) {
        boolean isSameTenant = checkSameTenant(currentUserId, contactUserId);
        if (!isSameTenant) {
            throw new ServiceException("无权分享该名片");
        }
    }
}
```

#### 名片信息展示
- 用户基本信息：姓名、头像、职位、公司（全部可见）
- 联系方式：手机、邮箱（同企业用户可见）

### 2.4 后端消息存储设计

#### 数据库表结构
```sql
-- 消息表 (im_chat_message)
-- 已有表结构，支持 message_type=11

-- 验证消息类型枚举
SELECT * FROM im_message_type_enum WHERE type = 11;

-- 测试插入名片消息
INSERT INTO im_chat_message (
  chat_id, sender_id, message_type, content, extra
) VALUES (
  1001, 
  1001, 
  11, 
  '名片消息',
  '{
    "type":"CONTACT",
    "userId":"1002",
    "userName":"张三",
    "avatar":"https://.../avatar.jpg",
    "position":"产品经理",
    "company":"圣钰科技",
    "phone":"138****1234",
    "email":"zhangsan@example.com"
  }'
);
```

#### extra 字段存储规范
```json
{
  "type": "CONTACT",
  "userId": "1002",
  "userName": "张三",
  "avatar": "https://example.com/avatars/1002.jpg",
  "nickname": "张三",
  "position": "产品经理",
  "company": "圣钰科技",
  "phone": "138****1234",
  "email": "zhangsan@example.com",
  "gender": 1,
  "userIds": ["1001", "1003"],
  "createdAt": 1712044800000
}
```

### 2.5 API 接口设计

#### 获取联系人列表
```typescript
// GET /im/contact/list
interface ContactListReq {
  page?: number
  pageSize?: number
  keyword?: string  // 搜索关键字
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
  isFriend: boolean  // 是否好友
}
```

#### 发送名片消息
```typescript
// POST /im/message/send
interface SendContactMessageReq {
  chatId: string
  receiverId?: string
  groupId?: string
  messageType: 11
  content: string  // "名片消息"
  extra: string    // JSON 字符串，名片详细信息
}
```

#### 获取用户详情
```typescript
// GET /user/profile/{userId}
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
  isFriend: boolean
}
```

---

## 三、UI 设计

### 3.1 联系人选择界面

**布局结构**：
```
┌─────────────────────────────────┐
│ ←返回      选择联系人     确定  │
├─────────────────────────────────┤
│ 🔍 搜索联系人姓名或职位...      │
├─────────────────────────────────┤
│ 最近分享 (3)                    │
│ ┌────┐ ┌────┐ ┌────┐          │
│ │头像│ │头像│ │头像│          │
│ │张三│ │李四│ │王五│          │
│ └────┘ └────┘ └────┘          │
├─────────────────────────────────┤
│ 全部联系人                      │
│ ○ 张三  产品经理  圣钰科技      │
│ ○ 李四  技术总监  圣钰科技      │
│ ○ 王五  销售主管  圣钰科技      │
│ ○ 赵六  运营经理  圣钰科技      │
└─────────────────────────────────┘
```

**交互说明**：
1. 顶部搜索框：支持按姓名、职位搜索
2. 最近分享：展示最近分享过的 3 个联系人
3. 联系人列表：单选，点击选中联系人
4. 确定按钮：发送选中联系人的名片

### 3.2 名片卡片消息样式

**对话页面展示**：
```
┌─────────────────────────────┐
│ [头像]  张三                │
│        产品经理 · 圣钰科技   │
│                             │
│ 📞 138****1234              │
│ ✉️ zhangsan@example.com    │
│                             │
│        [发消息]             │
└─────────────────────────────┘
```

**点击交互**：
- 点击卡片 → 打开用户详情页
- 点击"发消息" → 跳转到与该用户的私聊窗口

### 3.3 用户详情页面

**布局结构**：
```
┌─────────────────────────────────┐
│ ←返回                           │
├─────────────────────────────────┤
│                                 │
│          [大头像]               │
│                                 │
│            张三                 │
│        产品经理 · 圣钰科技       │
│                                 │
├─────────────────────────────────┤
│ 详细信息                        │
│ ─────────────────────────────   │
│ 📱 手机：138****1234            │
│ ✉️ 邮箱：zhangsan@example.com   │
│ 💼 职位：产品经理                │
│ 🏢 公司：圣钰科技               │
│ 👤 性别：男                     │
│                                 │
├─────────────────────────────────┤
│          [发消息]                │
└─────────────────────────────────┘
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

## 六、注意事项

### 6.1 隐私合规
- 必须获得用户授权才能分享其名片
- 敏感信息（手机、邮箱）需要脱敏处理
- 支持用户设置名片可见性
- 符合 GDPR 等隐私保护法规

### 6.2 权限控制
- 只能分享自己的名片或已授权的名片
- 非好友只能查看公开信息
- 群聊中分享名片需群主同意（可选）

### 6.3 多端兼容
- App 端：使用原生组件渲染
- H5 端：使用 Web 组件渲染
- 确保各端样式一致

### 6.4 性能优化
- 联系人列表分页加载
- 头像使用 CDN 加速
- 搜索结果本地缓存（5 分钟）

---

## 七、验收标准

### 7.1 功能验收
- [ ] 可以从对话页面进入联系人选择界面
- [ ] 支持搜索联系人
- [ ] 选择联系人后能成功发送名片
- [ ] 名片卡片消息正确展示
- [ ] 点击卡片能查看用户详情
- [ ] 支持添加好友和发消息操作

### 7.2 隐私验收
- [ ] 非好友只能查看脱敏信息
- [ ] 好友可以查看完整信息
- [ ] 用户可设置名片可见性
- [ ] 敏感信息正确脱敏

### 7.3 性能验收
- [ ] 联系人选择页面打开时间 < 1 秒
- [ ] 搜索响应时间 < 500ms
- [ ] 名片消息发送成功率 > 99%

### 7.4 兼容性验收
- [ ] App 端（Android/iOS）正常工作
- [ ] H5 端正常工作
- [ ] 不同网络环境正常工作

---

## 八、参考资料

- [微信名片消息实现](https://developers.weixin.qq.com/doc/)
- [钉钉数字化名片](https://blog.csdn.net/Z1Y492Vn3ZYD9et3B06/article/details/84948872)
- [融云 IM 名片消息](https://docs.rongcloud.cn/ios-imkit/features/contact-message)
- [vCard 标准](https://www.choge-blog.com/programming/vcard-vcf/)
- [网易云信用户名片](https://doc.yunxin.163.com/messaging/server-apis/TA0NzYzNjk)

---

**文档版本**：v2.0  
**更新日期**：2026-04-02  
**适用项目**：shengyu-im-saas  
**责任人**：开发团队
