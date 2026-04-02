# IM 即时通讯 - 名片功能开发任务清单 v2.0

## 任务概述

**任务目标**：在对话页面实现"名片"功能，支持用户分享联系人名片消息

**优先级**：高

**预计工期**：6 人天（1 周）

**技术选型**：
- 消息类型：CONTACT（type=11）
- 数据格式：JSON（兼容 vCard 标准）
- 隐私保护：敏感信息脱敏处理

**核心策略**：充分利用现有组件和 API，减少重复开发

---

## 现有可复用资源

### 前端可复用组件
1. **联系人选择器组件**
   - 文件：`components/contact-selector/contact-selector.uvue`
   - 功能：联系人列表展示、搜索、选择
   - 复用方式：直接嵌入名片选择页面

2. **用户详情页面**
   - 文件：`pages/contacts/user-detail.uvue`
   - 功能：展示用户详细信息
   - 复用方式：点击名片卡片直接跳转

3. **联系人列表页面**
   - 文件：`pages/contacts/contacts.uvue`
   - 功能：联系人列表管理
   - 复用方式：参考其数据加载逻辑

### 前端可复用 API
1. **联系人 API**
   - 文件：`api/contact.uts`
   - 接口：`getContactList()`, `searchContact(keyword)`
   - 复用方式：直接调用

2. **用户 API**
   - 文件：`api/user.uts`
   - 接口：`getUserDetail(id)`
   - 复用方式：直接调用

### 后端可复用接口
1. **联系人管理接口**
   - 文件：`AppImContactController.java`
   - 接口：`/system/im/contact/list`, `/system/im/contact/search`
   - 状态：✅ 已存在

2. **用户详情接口**
   - 文件：`AppUserController.java`
   - 接口：`/system/user/get`
   - 状态：✅ 已存在

---

## 开发任务分解

### 阶段一：后端支持（1 人天）

#### 任务 1.1：后端消息类型扩展
- **负责人**：后端开发
- **完成时间**：Day 1 上午
- **任务详情**：
  1. 在 `ImMessageTypeEnum.java` 中新增 `CONTACT(11, "名片消息")`
  2. 添加 `isContact()` 判断方法
  3. 更新数据库消息类型枚举表
- **代码示例**：
```java
// ImMessageTypeEnum.java
CONTACT(11, "名片消息"),

public static boolean isContact(Integer type) {
    return ObjUtil.equal(CONTACT.type, type);
}
```
- **数据库脚本**：
```sql
-- 插入消息类型枚举
INSERT INTO im_message_type_enum (type, name, sort, status)
VALUES (11, '名片消息', 11, 1);
```
- **交付物**：
  - 更新后的枚举类
  - 数据库脚本

#### 任务 1.2：名片消息 Protobuf 定义
- **负责人**：后端开发
- **完成时间**：Day 1 上午
- **任务详情**：
  1. 在 `im_message.proto` 中定义 `ContactMessage`
  2. 生成 Java 代码
  3. 验证序列化/反序列化
- **Protobuf 定义**：
```protobuf
message ContactMessage {
  string user_id = 1;           // 用户 ID
  string user_name = 2;         // 用户姓名
  string avatar = 3;            // 头像 URL
  string nickname = 4;          // 昵称
  string position = 5;          // 职位
  string company = 6;           // 公司
  string phone = 7;             // 手机号（脱敏）
  string email = 8;             // 邮箱
  int32 gender = 9;             // 性别
}
```
- **交付物**：
  - Protobuf 定义文件
  - 生成的 Java 类

---

### 阶段二：名片消息处理器（1 人天）

#### 任务 2.1：创建名片消息处理器
- **负责人**：后端开发
- **完成时间**：Day 1 下午
- **任务详情**：
  1. 创建 `ContactMessageProcessor.java`
  2. 实现 `MessageProcessor` 接口
  3. 处理名片消息的存储和转发
  4. 添加日志记录
- **代码框架**：
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
            
            // 验证权限
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
}
```
- **交付物**：
  - 名片消息处理器
  - 单元测试

#### 任务 2.2：名片分享权限验证
- **负责人**：后端开发
- **完成时间**：Day 1 下午
- **任务详情**：
  1. 实现名片分享权限检查
  2. 敏感信息脱敏处理
  3. **企业内部用户可见性控制**
- **权限规则**（企业 IM 场景）：
```java
private void validateContactPrivacy(ContactMessage contactMessage) {
    Long currentUserId = getCurrentUserId();
    Long contactUserId = Long.valueOf(contactMessage.getUserId());
    
    // 1. 只能分享自己的名片
    if (!currentUserId.equals(contactUserId)) {
        // 2. 检查是否在同一企业/租户下
        boolean isSameTenant = checkSameTenant(currentUserId, contactUserId);
        if (!isSameTenant) {
            throw new ServiceException("无权分享该名片");
        }
        
        // 3. 检查组织架构可见性（可选）
        // 例如：只能分享本部门或可见部门的名片
        boolean isVisible = checkOrgVisibility(currentUserId, contactUserId);
        if (!isVisible) {
            throw new ServiceException("该用户不在您的可见范围内");
        }
    }
    
    // 4. 敏感信息脱敏（根据企业配置）
    // 企业可配置：手机号、邮箱是否对外展示
    if (!canShowSensitiveInfo(currentUserId, contactUserId)) {
        contactMessage.setPhone(desensitizePhone(contactMessage.getPhone()));
        contactMessage.setEmail(desensitizeEmail(contactMessage.getEmail()));
    }
}
```
- **交付物**：
  - 隐私权限验证逻辑
  - 脱敏工具类
- **任务详情**：
  1. 创建 `ContactMessageProcessor.java`
  2. 实现 `MessageProcessor` 接口
  3. 处理名片消息的存储和转发
  4. 添加日志记录
- **代码框架**：
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
            
            // 验证权限
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
}
```
- **交付物**：
  - 名片消息处理器
  - 单元测试

#### 任务 2.2：名片隐私权限验证
- **负责人**：后端开发
- **完成时间**：Day 2 下午
- **任务详情**：
  1. 实现名片分享权限检查
  2. 敏感信息脱敏处理
  3. 好友/非好友信息可见性控制
- **权限规则**：
```java
private void validateContactPrivacy(ContactMessage contactMessage) {
    Long currentUserId = getCurrentUserId();
    Long contactUserId = Long.valueOf(contactMessage.getUserId());
    
    // 1. 只能分享自己的名片
    if (!currentUserId.equals(contactUserId)) {
        // 2. 或者已授权的名片
        boolean isAuthorized = checkAuthorization(currentUserId, contactUserId);
        if (!isAuthorized) {
            throw new ServiceException("无权分享该名片");
        }
    }
    
    // 3. 敏感信息脱敏
    if (!isFriend(currentUserId, contactUserId)) {
        // 非好友脱敏处理
        contactMessage.setPhone(desensitizePhone(contactMessage.getPhone()));
        contactMessage.setEmail(desensitizeEmail(contactMessage.getEmail()));
    }
}
```
- **交付物**：
  - 隐私权限验证逻辑
  - 脱敏工具类

---

### 阶段三：前端实现（3 人天）

#### 任务 3.1：创建名片选择页面（复用 contact-selector 组件）
- **负责人**：前端开发
- **完成时间**：Day 2 上午
- **任务详情**：
  1. 创建文件：`pages/message/contact-picker.uvue`
  2. 复用 `components/contact-selector/contact-selector.uvue` 组件
  3. 实现页面头部（返回、标题、确定按钮）
  4. 集成现有联系人 API
- **页面结构**：
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
  import { getContactList } from '../../api/contact.uts'
  import contactSelector from '../../components/contact-selector/contact-selector.uvue'
  
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
    uni.navigateBack({ delta: 1 })
  }
  
  onMounted(() => {
    loadContacts()
  })
</script>
```
- **交付物**：
  - 名片选择页面
  - 集成测试

#### 任务 3.2：扩展消息服务
- **负责人**：前端开发
- **完成时间**：Day 2 下午
- **任务详情**：
  1. 在 `services/message-service.uts` 中添加 `sendContactMessage` 方法
  2. 构建名片消息 payload
  3. 调用后端消息发送接口
- **代码示例**：
```typescript
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
- **交付物**：
  - 名片消息发送方法

#### 任务 3.3：在 chat.uvue 中添加名片功能入口
- **负责人**：前端开发
- **完成时间**：Day 2 下午
- **任务详情**：
  1. 在 `handleFeature` 函数中添加名片处理逻辑
  2. 跳转到联系人选择页面
  3. 接收返回的联系人信息并发送
- **代码示例**：
```typescript
function handleFeature(item: any) {
  if (item.nameKey === 'chat.features.card') {
    handleContactFeature()
  }
  // ...
}

async function handleContactFeature() {
  try {
    const contact = await new Promise<ContactMessage>((resolve, reject) => {
      uni.navigateTo({
        url: '/pages/message/contact-picker',
        events: {
          contactSelected: (contact: ContactMessage) => {
            resolve(contact)
          }
        },
        fail: (err) => reject(err)
      })
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
- **交付物**：
  - 名片功能入口
  - 消息发送逻辑

---

### 阶段四：名片消息渲染（1 人天）

#### 任务 4.1：名片卡片样式开发
- **负责人**：前端开发
- **完成时间**：Day 3 上午
- **任务详情**：
  1. 在 `chat.uvue` 中添加名片消息渲染模板
  2. 实现卡片布局（头像、姓名、职位）
  3. 添加操作按钮（发消息）
- **模板代码**：
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
- **样式要求**：
  - 卡片圆角：8px
  - 阴影效果：box-shadow
  - 响应式布局
- **交付物**：
  - 名片卡片组件

#### 任务 4.2：实现名片卡片交互
- **负责人**：前端开发
- **完成时间**：Day 3 下午
- **任务详情**：
  1. 点击卡片打开用户详情页（复用 `pages/contacts/user-detail.uvue`）
  2. 点击"发消息"跳转到私聊窗口
- **交互处理**：
```typescript
// 打开用户详情（复用现有 user-detail 页面）
function handleContactOpen(msg: MessageItem) {
  uni.navigateTo({
    url: `/pages/contacts/user-detail?id=${msg.userId}`
  })
}

// 发消息
function handleMessage(msg: MessageItem) {
  const targetIdParam = encodeIdParam(msg.userId)
  uni.navigateTo({
    url: `/pages/message/chat?type=single&targetId=${targetIdParam}&name=${encodeURIComponent(msg.userName)}&entryMode=latest`
  })
}
```
- **交付物**：
  - 卡片交互逻辑
  2. 实现分页加载
  3. 实现搜索功能（防抖 500ms）
- **代码示例**：
```typescript
// 获取联系人列表
async function fetchContactList(page: number = 1) {
  const res = await request({
    url: '/im/contact/list',
    method: 'GET',
    data: {
      pageNo: page,
      pageSize: 50,
      keyword: keyword.value
    }
  })
  contactList.value = res.list
}

// 搜索（防抖）
const searchDebounced = debounce(() => {
  fetchContactList()
}, 500)

watch(keyword, () => {
  searchDebounced()
})
```
- **交付物**：
  - API 集成代码
  - 搜索功能

#### 任务 3.3：实现选择与返回
- **负责人**：前端开发
- **完成时间**：Day 4 下午
- **任务详情**：
  1. 点击联系人选中
  2. 右上角确定按钮可用
  3. 返回选中的联系人信息给聊天页面
- **返回数据格式**：
```typescript
interface ContactMessage {
  userId: string
  userName: string
  avatar: string
  nickname?: string
  position?: string
  company?: string
  phone?: string
  email?: string
  gender?: number
}
```
- **交付物**：
  - 选择与返回逻辑

---

### 阶段四：消息发送功能（1 人天）

#### 任务 4.1：扩展消息服务
- **负责人**：前端开发
- **完成时间**：Day 5 上午
- **任务详情**：
  1. 在 `message-service.uts` 中添加 `sendContactMessage` 方法
  2. 构建名片消息 payload
  3. 调用后端消息发送接口
- **代码示例**：
```typescript
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
- **交付物**：
  - 名片消息发送方法

#### 任务 4.2：在 chat.uvue 中添加名片功能入口
- **负责人**：前端开发
- **完成时间**：Day 5 下午
- **任务详情**：
  1. 在 `handleFeature` 函数中添加名片处理逻辑
  2. 跳转到联系人选择页面
  3. 接收返回的联系人信息并发送
- **代码示例**：
```typescript
function handleFeature(item: any) {
  if (item.nameKey === 'chat.features.card') {
    handleContactFeature()
  }
  // ...
}

async function handleContactFeature() {
  try {
    const contact = await navigateToContactPicker()
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

function navigateToContactPicker(): Promise<ContactMessage> {
  return new Promise((resolve, reject) => {
    uni.navigateTo({
      url: '/pages/message/contact-picker',
      events: {
        contactSelected: (contact: ContactMessage) => {
          resolve(contact)
        }
      },
      fail: (err) => reject(err)
    })
  })
}
```
- **交付物**：
  - 名片功能入口
  - 消息发送逻辑

---

### 阶段五：联调测试（1 人天）

#### 任务 5.1：功能测试
- **负责人**：测试工程师
- **完成时间**：Day 4 上午
- **测试用例**：
  1. [ ] 从对话页面进入联系人选择界面
  2. [ ] 选择联系人并发送名片
  3. [ ] 接收名片消息并展示
  4. [ ] 点击名片卡片查看详情
  5. [ ] 点击"发消息"跳转到私聊窗口
- **Bug 修复**：
  - 前端开发负责修复 UI 问题
  - 后端开发负责修复接口问题

#### 任务 5.2：隐私权限测试
- **负责人**：测试工程师
- **完成时间**：Day 4 下午
- **测试用例**：
  1. [ ] 用户只能分享自己的名片
  2. [ ] 无权分享其他租户的用户名片
  3. [ ] 敏感信息正确脱敏（手机、邮箱）
  4. [ ] 名片消息正确存储到聊天记录表
- **验证点**：
  - 手机号中间 4 位隐藏（如配置）
  - 邮箱@前部分隐藏（如配置）
  - 职位、公司不脱敏
  - 同企业用户可见完整信息

#### 任务 5.3：性能测试
- **负责人**：测试工程师
- **完成时间**：Day 5 上午
- **测试指标**：
  1. [ ] 联系人选择页面打开时间 < 1 秒
  2. [ ] 名片消息发送成功率 > 99%
  3. [ ] 联系人列表分页加载正常
- **优化建议**：
  - 搜索结果本地缓存
  - 头像 CDN 加速

#### 任务 5.4：兼容性测试
- **负责人**：测试工程师
- **完成时间**：Day 5 下午
- **测试平台**：
  1. [ ] App 端（Android 10+）
  2. [ ] App 端（iOS 14+）
  3. [ ] H5 端（Chrome）
  4. [ ] H5 端（Safari）
  5. [ ] H5 端（微信内置浏览器）

#### 任务 5.5：验收评审
- **负责人**：产品经理
- **完成时间**：Day 6 下午
- **验收标准**：
  1. [ ] 所有功能测试用例通过
  2. [ ] 性能指标达标
  3. [ ] 兼容性测试通过
  4. [ ] UI/UX 符合设计稿
  5. [ ] 隐私权限验证通过
  6. [ ] 无严重 Bug
- **交付物**：
  - 测试报告
  - 验收报告
  - 上线清单

---

## 里程碑计划

| 里程碑 | 时间 | 交付物 | 验收标准 |
|--------|------|--------|----------|
| M1：后端支持完成 | Day 1 | 消息类型枚举、名片处理器 | 后端接口可正常调用 |
| M2：名片选择页完成 | Day 2 | contact-picker.uvue | 可以搜索、选择、返回联系人 |
| M3：消息发送完成 | Day 2 | sendContactMessage | 可以成功发送名片消息 |
| M4：消息渲染完成 | Day 3 | 名片卡片样式、交互 | 名片消息正确展示和交互 |
| M5：测试验收完成 | Day 6 | 测试报告、验收报告 | 所有测试用例通过 |

---

## 风险评估

### 风险 1：名片隐私泄露
- **概率**：中
- **影响**：高
- **应对措施**：
  1. 严格的权限验证（只能分享自己或同企业用户的名片）
  2. 敏感信息自动脱敏（根据企业配置）
  3. 租户隔离确保数据安全
  4. 添加隐私协议说明

### 风险 2：组件复用兼容性问题
- **概率**：低
- **影响**：中
- **应对措施**：
  1. 充分测试 contact-selector 组件在名片场景的兼容性
  2. 准备备用方案（独立开发名片选择页）
  3. 样式对齐检查

### 风险 3：后端消息存储失败
- **概率**：低
- **影响**：高
- **应对措施**：
  1. 提前验证 im_chat_message 表支持 message_type=11
  2. 验证 extra 字段能正确存储 JSON 格式名片信息
  3. 测试消息发送接口支持名片消息类型
  4. 添加消息存储失败的异常处理和日志记录

---

## 资源需求

### 人力资源
- 前端开发：1 人（3 人天）
- 后端开发：1 人（1 人天）
- 测试工程师：1 人（1 人天）
- 产品经理：0.5 人天（验收）

### 技术资源
- 无需第三方 SDK
- 复用现有联系人组件和 API
- 依赖现有消息发送框架

### 环境资源
- 开发环境：可以调用用户信息接口
- 测试环境：独立部署，配置完整数据
- 生产环境：配置权限控制策略

---

## 上线检查清单

### 上线前检查
- [ ] 代码审查通过
- [ ] 所有测试用例通过
- [ ] 性能指标达标
- [ ] 无严重 Bug
- [ ] 产品验收通过
- [ ] 隐私协议已更新
- [ ] 权限控制策略已配置
- [ ] 监控告警已配置

### 上线后验证
- [ ] 生产环境功能验证
- [ ] 监控数据正常
- [ ] 用户反馈收集
- [ ] 性能指标监控

---

## 参考资料

- [设计文档](./IM 即时通讯名片功能设计文档-v2.0.md)
- [微信名片消息实现](https://developers.weixin.qq.com/doc/)
- [钉钉数字化名片](https://blog.csdn.net/Z1Y492Vn3ZYD9et3B06/article/details/84948872)
- [融云 IM 名片消息](https://docs.rongcloud.cn/ios-imkit/features/contact-message)

---

**文档版本**：v2.0  
**创建日期**：2026-04-02  
**更新日期**：2026-04-02  
**适用项目**：shengyu-im-saas  
**责任人**：开发团队
      <text v-if="msg.phone" class="contact-detail">📞 {{ msg.phone }}</text>
      <text v-if="msg.email" class="contact-detail">✉️ {{ msg.email }}</text>
    </view>
    <view class="contact-actions" v-if="!isSelf(msg.senderId)">
      <button class="action-btn primary" @click.stop="handleSendMessage(msg)">发消息</button>
    </view>
  </view>
</view>
```
- **样式要求**：
  - 卡片圆角：8px
  - 阴影效果：box-shadow
  - 响应式布局
- **交付物**：
  - 名片卡片组件

#### 任务 5.2：实现名片卡片交互
- **负责人**：前端开发
- **完成时间**：Day 6 下午
- **任务详情**：
  1. 点击卡片打开用户详情页
  2. 点击"发消息"跳转到私聊窗口
- **交互处理**：
```typescript
// 打开用户详情
function handleContactOpen(msg: MessageItem) {
  uni.navigateTo({
    url: `/pages/user/profile?userId=${msg.userId}`
  })
}

// 发消息
function handleSendMessage(msg: MessageItem) {
  // 跳转到与 msg.userId 的私聊窗口
  uni.navigateTo({
    url: `/pages/message/chat?receiverId=${msg.userId}&type=single`
  })
}
```
- **交付物**：
  - 卡片交互逻辑

#### 任务 5.3：创建用户详情页面
- **负责人**：前端开发
- **完成时间**：Day 7
- **任务详情**：
  1. 创建文件：`pages/user/profile.uvue`
  2. 展示用户完整信息
  3. 提供发消息按钮
  4. 根据好友关系显示不同信息
- **页面结构**：
```vue
<template>
  <view class="user-profile">
    <image class="avatar-large" :src="userProfile.avatar" />
    <text class="user-name">{{ userProfile.userName }}</text>
    <text class="user-position">{{ userProfile.position }} · {{ userProfile.company }}</text>
    
    <view class="info-section">
      <view class="info-item">
        <text class="info-label">📱 手机</text>
        <text class="info-value">{{ userProfile.phone }}</text>
      </view>
      <view class="info-item">
        <text class="info-label">✉️ 邮箱</text>
        <text class="info-value">{{ userProfile.email }}</text>
      </view>
      <!-- 更多信息... -->
    </view>
    
    <view class="actions">
      <button class="action-btn primary" @click="handleSendMessage">发消息</button>
    </view>
  </view>
</template>
```
- **交付物**：
  - 用户详情页面

---

### 阶段六：联调测试（2.5 人天）

#### 任务 6.1：功能测试
- **负责人**：测试工程师
- **完成时间**：Day 8 上午
- **测试用例**：
  1. [ ] 从对话页面进入联系人选择界面
  2. [ ] 搜索联系人
  3. [ ] 选择联系人并发送名片
  4. [ ] 接收名片消息并展示
  5. [ ] 点击名片卡片查看详情
  6. [ ] 添加好友功能
  7. [ ] 发消息功能
- **Bug 修复**：
  - 前端开发负责修复 UI 问题
  - 后端开发负责修复接口问题

#### 任务 6.2：隐私权限测试
- **负责人**：测试工程师
- **完成时间**：Day 8 下午
- **测试用例**：
  1. [ ] 非好友只能查看脱敏信息
  2. [ ] 好友可以查看完整信息
  3. [ ] 无权分享他人名片
  4. [ ] 敏感信息正确脱敏（手机、邮箱）
- **验证点**：
  - 手机号中间 4 位隐藏
  - 邮箱@前部分隐藏
  - 职位、公司不脱敏

#### 任务 6.3：性能测试
- **负责人**：测试工程师
- **完成时间**：Day 9 上午
- **测试指标**：
  1. [ ] 联系人选择页面打开时间 < 1 秒
  2. [ ] 搜索响应时间 < 500ms
  3. [ ] 名片消息发送成功率 > 99%
  4. [ ] 联系人列表分页加载正常
- **优化建议**：
  - 搜索结果本地缓存
  - 头像 CDN 加速
  - 列表虚拟滚动

#### 任务 6.4：兼容性测试
- **负责人**：测试工程师
- **完成时间**：Day 9 下午
- **测试平台**：
  1. [ ] App 端（Android 10+）
  2. [ ] App 端（iOS 14+）
  3. [ ] H5 端（Chrome）
  4. [ ] H5 端（Safari）
  5. [ ] H5 端（微信内置浏览器）
- **测试网络**：
  1. [ ] 4G 网络
  2. [ ] 5G 网络
  3. [ ] WiFi
  4. [ ] 弱网环境

#### 任务 6.5：验收评审
- **负责人**：产品经理
- **完成时间**：Day 10 下午
- **验收标准**：
  1. [ ] 所有功能测试用例通过
  2. [ ] 性能指标达标
  3. [ ] 兼容性测试通过
  4. [ ] UI/UX 符合设计稿
  5. [ ] 隐私权限验证通过
  6. [ ] 无严重 Bug
- **交付物**：
  - 测试报告
  - 验收报告
  - 上线清单

---

## 里程碑计划

| 里程碑 | 时间 | 交付物 | 验收标准 |
|--------|------|--------|----------|
| M1：后端支持完成 | Day 1 | 消息类型枚举、名片处理器 | 后端接口可正常调用 |
| M2：名片选择页完成 | Day 2 | contact-picker.uvue | 可以搜索、选择、返回联系人 |
| M3：消息发送完成 | Day 2 | sendContactMessage | 可以成功发送名片消息 |
| M4：消息渲染完成 | Day 3 | 名片卡片样式、交互 | 名片消息正确展示和交互 |
| M5：测试验收完成 | Day 6 | 测试报告、验收报告 | 所有测试用例通过 |

---

## 风险评估

### 风险 1：名片隐私泄露
- **概率**：中
- **影响**：高
- **应对措施**：
  1. 严格的权限验证（只能分享自己或同企业用户的名片）
  2. 租户隔离确保数据安全

### 风险 2：联系人列表性能问题
- **概率**：中
- **影响**：中
- **应对措施**：
  1. 分页加载（每页 50 条）
  2. 搜索防抖（500ms）
  3. 搜索结果本地缓存（5 分钟）
  4. 头像懒加载

### 风险 3：名片卡片样式不一致
- **概率**：低
- **影响**：低
- **应对措施**：
  1. 使用统一的设计规范
  2. 多端样式对齐检查
  3. 响应式布局适配

### 风险 4：后端消息存储失败
- **概率**：低
- **影响**：高
- **应对措施**：
  1. 提前验证 im_chat_message 表支持 message_type=11
  2. 验证 extra 字段能正确存储 JSON 格式名片信息
  3. 测试消息发送接口支持名片消息类型
  4. 添加消息存储失败的异常处理和日志记录

---

## 资源需求

### 人力资源
- 前端开发：1 人（7 人天）
- 后端开发：1 人（2.5 人天）
- 测试工程师：1 人（2 人天）
- 产品经理：0.5 人天（验收）

### 技术资源
- 无需第三方 SDK
- 使用现有用户信息接口
- 依赖现有消息发送框架

### 环境资源
- 开发环境：可以调用用户信息接口
- 测试环境：独立部署，配置完整数据
- 生产环境：配置权限控制策略

---

## 上线检查清单

### 上线前检查
- [ ] 代码审查通过
- [ ] 所有测试用例通过
- [ ] 性能指标达标
- [ ] 无严重 Bug
- [ ] 产品验收通过
- [ ] 隐私协议已更新
- [ ] 权限控制策略已配置
- [ ] 监控告警已配置

### 上线后验证
- [ ] 生产环境功能验证
- [ ] 监控数据正常
- [ ] 用户反馈收集
- [ ] 性能指标监控

---

## 参考资料

- [设计文档](./IM 即时通讯名片功能设计文档-v2.0.md)
- [微信名片消息实现](https://developers.weixin.qq.com/doc/)
- [钉钉数字化名片](https://blog.csdn.net/Z1Y492Vn3ZYD9et3B06/article/details/84948872)
- [融云 IM 名片消息](https://docs.rongcloud.cn/ios-imkit/features/contact-message)
- [vCard 标准](https://www.choge-blog.com/programming/vcard-vcf/)

---

**文档版本**：v2.0  
**创建日期**：2026-04-02  
**更新日期**：2026-04-02  
**适用项目**：shengyu-im-saas  
**责任人**：开发团队
