# IM 即时通讯名片功能开发任务清单 v2.0

> **文档版本**: v2.0.0  
> **创建日期**: 2026-04-02  
> **项目**: 圣钰 SaaS Pro - IM 即时通讯系统  
> **迭代目标**: Milestone N - 名片消息功能  
> **关联文档**: `sql/doc/IM即时通讯架构设计文档-v2.0.md`、`sql/doc/IM即时通讯名片功能设计文档-v2.0.md`

---

## 1. 任务概述

### 1.1 功能目标
实现企业 IM 系统中的**名片消息**功能，支持用户在聊天中分享联系人名片，接收方可快速查看详情并发起对话。

### 1.2 核心价值
- **快速介绍**：避免手动输入用户信息，提高沟通效率
- **组织发现**：帮助成员快速找到同事并建立联系
- **业务协同**：支持跨部门、跨项目的人员推介

### 1.3 技术约束
- **Long 精度**：所有 ID 字段使用 `string` 类型，避免精度丢失
- **UTS 规范**：遵循 UTS 强类型约束，不使用 undefined、truthy/falsy
- **组件复用**：最大化复用现有组件和 API，减少重复开发
- **协议一致性**：遵循现有消息协议和 WebSocket 机制

---

## 2. 现有资源评估

### 2.1 可复用组件
| 组件名称 | 文件路径 | 复用方式 | 状态 |
|----------|----------|----------|------|
| 联系人选择器 | `components/contact-selector/contact-selector.uvue` | 参考实现逻辑 | 
| 用户详情页 | `pages/contacts/user-detail.uvue` | 直接跳转使用 | 
| 聊天页面 | `pages/message/chat.uvue` | 扩展名片功能 | 

### 2.2 可复用 API
| API 名称 | 文件路径 | 接口说明 | 状态 |
|----------|----------|----------|------|
| 联系人列表 | `api/contact.uts#getContactList` | 获取联系人列表 | 
| 用户详情 | `api/user.uts#getUserDetail` | 获取用户详情 | 
| 消息发送 | `api/message.uts#sendMessage` | 发送消息接口 | 

### 2.3 后端可复用接口
| 接口名称 | Controller 路径 | 功能说明 | 状态 |
|----------|----------------|----------|------|
| 联系人管理 | `AppImContactController` | 联系人列表/搜索 | 
| 用户管理 | `AppUserController` | 用户详情查询 | 
| 消息发送 | `AppImMessageController` | 消息发送接口 | 

---

## 3. 开发任务分解

### 3.1 阶段一：后端支持（0.5 人天）

#### 任务 1.1：消息类型枚举扩展
- **负责人**：后端开发
- **完成时间**：Day 1 上午
- **任务详情**：
  1. 在 `ImMessageTypeEnum.java` 中新增 `CONTACT(11, "名片消息")`
  2. 添加 `isContact()` 判断方法
  3. 更新数据库消息类型枚举表
- **代码实现**：
```java
// ImMessageTypeEnum.java
CONTACT(11, "名片消息");

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
- **验收标准**：
  - [ ] 枚举类编译通过
  - [ ] 数据库脚本执行成功
  - [ ] `isContact()` 方法逻辑正确

#### 任务 1.2：Protobuf 消息定义
- **负责人**：后端开发
- **完成时间**：Day 1 上午
- **任务详情**：
  1. 在 `im_message.proto` 中定义 `ContactMessage`
  2. 生成 Java 代码
  3. 验证序列化/反序列化
- **Protobuf 定义**：
```protobuf
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
- **验收标准**：
  - [ ] Protobuf 编译通过
  - [ ] Java 代码生成成功
  - [ ] 序列化/反序列化测试通过

### 3.2 阶段二：名片消息处理器（0.5 人天）

#### 任务 2.1：创建名片消息处理器
- **负责人**：后端开发
- **完成时间**：Day 1 下午
- **任务详情**：
  1. 创建 `ContactMessageProcessor.java`
  2. 实现 `MessageProcessor` 接口
  3. 处理名片消息的存储和转发
  4. 添加权限验证和脱敏逻辑
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
            validateContactPermission(contactMessage);
            
            // 存储消息
            MessageSaveResult saveResult = messageStorageService.saveMessageWithResult(message);
            
            // 回推给发送者
            // 转发给接收者
            // ...
            
        } catch (InvalidProtocolBufferException e) {
            log.error("[ContactMessage] 解析消息失败", e);
        }
    }
    
    private void validateContactPermission(ContactMessage contactMessage) {
        // 租户隔离检查
        // 组织架构可见性检查
        // 敏感信息脱敏
    }
}
```
- **验收标准**：
  - [ ] 处理器注册成功
  - [ ] 权限验证逻辑正确
  - [ ] 消息存储和转发正常

#### 任务 2.2：权限验证实现
- **负责人**：后端开发
- **完成时间**：Day 1 下午
- **任务详情**：
  1. 实现租户隔离检查
  2. 实现组织架构可见性检查
- **权限规则**：
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
- **验收标准**：
  - [ ] 跨租户分享被正确拒绝
  - [ ] 权限验证日志完整

### 3.3 阶段三：前端实现（1.5 人天）

#### 任务 3.1：联系人选择页面开发
- **负责人**：前端开发
- **完成时间**：Day 2 上午
- **任务详情**：
  1. 创建 `pages/message/contact-picker.uvue`
  2. 实现搜索、选择、确认功能
  3. 集成现有联系人 API
  4. 实现防抖搜索和分页加载
- **页面结构**：
```vue
<template>
  <view class="contact-picker">
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
- **UTS 脚本关键逻辑**：
```typescript
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

// 搜索防抖
let searchTimer: number = 0
function handleSearchInput(): void {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    filterContacts()
  }, 500)
}

// 确认选择
function handleConfirm(): void {
  if (!selectedContact.value) return
  
  const eventChannel = getOpenerEventChannel()
  eventChannel.emit('contactSelected', selectedContact.value)
  uni.navigateBack({ delta: 1 })
}
```
- **验收标准**：
  - [ ] 页面正常渲染
  - [ ] 搜索功能正常（防抖 500ms）
  - [ ] 选择和返回逻辑正确
  - [ ] 分页加载正常

#### 任务 3.2：聊天页面名片功能集成
- **负责人**：前端开发
- **完成时间**：Day 2 下午
- **任务详情**：
  1. 在 `chat.uvue` 中添加名片功能入口
  2. 实现名片消息发送逻辑
  3. 集成联系人选择页面
- **功能入口扩展**：
```typescript
function handleFeature(item: any): void {
  if (item.nameKey === 'chat.features.card') {
    handleContactFeature()
  }
}

async function handleContactFeature(): Promise<void> {
  try {
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
    uni.showToast({ title: '发送失败', icon: 'none' })
  }
}
```
- **验收标准**：
  - [ ] 功能入口正常工作
  - [ ] 联系人选择页面跳转正常
  - [ ] 名片消息发送成功

#### 任务 3.3：名片消息渲染
- **负责人**：前端开发
- **完成时间**：Day 3 上午
- **任务详情**：
  1. 在 `chat.uvue` 中添加名片消息渲染模板
  2. 实现卡片样式和交互
  3. 实现用户详情跳转和发消息功能
- **卡片渲染模板**：
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
- **交互处理**：
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
- **验收标准**：
  - [ ] 名片卡片正确渲染
  - [ ] 点击卡片跳转用户详情
  - [ ] 点击"发消息"跳转私聊窗口

### 3.4 阶段四：联调测试（1 人天）

#### 任务 4.1：功能测试
- **负责人**：测试工程师
- **完成时间**：Day 4 上午
- **测试用例**：
  - [ ] 从聊天页"+"入口进入联系人选择页面
  - [ ] 搜索联系人功能正常
  - [ ] 选择联系人并发送名片成功
  - [ ] 名片卡片消息正确展示
  - [ ] 点击名片卡片查看用户详情
  - [ ] 点击"发消息"跳转到私聊窗口
  - [ ] 只能分享同租户内的用户名片

#### 任务 4.2：性能测试
- **负责人**：测试工程师
- **完成时间**：Day 4 下午
- **测试指标**：
  - [ ] 联系人选择页面打开时间 < 1 秒
  - [ ] 搜索响应时间 < 500ms
  - [ ] 名片消息发送成功率 > 99%
  - [ ] 联系人列表滚动流畅（60fps）

#### 任务 4.3：兼容性测试
- **负责人**：测试工程师
- **完成时间**：Day 5 上午
- **测试平台**：
  - [ ] App 端（Android 10+）
  - [ ] App 端（iOS 14+）
  - [ ] H5 端（Chrome/Safari）
  - [ ] 不同网络环境（WiFi/4G/5G）

#### 任务 4.4：安全测试
- **负责人**：测试工程师
- **完成时间**：Day 5 下午
- **测试用例**：
  - [ ] 跨租户名片分享被正确拒绝
  - [ ] 权限控制生效

---

## 4. 里程碑计划

| 里程碑 | 时间 | 交付物 | 验收标准 |
|--------|------|--------|----------|
| M1：后端支持完成 | Day 1 | 消息类型枚举、名片处理器 | 后端接口可正常调用 |
| M2：联系人选择页完成 | Day 2 | contact-picker.uvue | 可以搜索、选择、返回联系人 |
| M3：消息发送完成 | Day 2 | 名片消息发送逻辑 | 可以成功发送名片消息 |
| M4：消息渲染完成 | Day 3 | 名片卡片样式、交互 | 名片消息正确展示和交互 |
| M5：测试验收完成 | Day 5 | 测试报告、验收报告 | 所有测试用例通过 |

---

## 5. 风险评估与应对

### 5.1 技术风险
| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 联系人列表性能问题 | 中 | 中 | 分页加载、搜索防抖 |
| 权限控制漏洞 | 低 | 高 | 严格权限验证、多层校验 |
| 名片消息存储失败 | 低 | 高 | 异常处理、重试机制、日志记录 |

### 5.2 业务风险
| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 用户隐私泄露 | 中 | 高 | 权限控制 |
| 用户体验不佳 | 中 | 中 | 充分测试、用户反馈 |
| 兼容性问题 | 低 | 中 | 多端测试、渐进增强 |

---

## 6. 资源需求

### 6.1 人力资源
- **前端开发**：1 人（1.5 人天）
- **后端开发**：1 人（1 人天）
- **测试工程师**：1 人（1 人天）
- **产品经理**：0.5 人天（验收）

### 6.2 技术资源
- 无需第三方 SDK
- 复用现有组件和 API
- 依赖现有消息发送框架

### 6.3 环境资源
- 开发环境：可以调用用户信息接口
- 测试环境：独立部署，配置完整数据
- 生产环境：配置权限控制策略

---

## 7. 关键文件清单

### 7.1 后端文件
```
shengyu-module-system/.../enums/ImMessageTypeEnum.java          # 消息类型枚举
shengyu-module-system/.../processor/ContactMessageProcessor.java  # 名片消息处理器
shengyu-module-system/.../controller/app/im/AppImMessageController.java  # 消息接口
shengyu-module-system/.../service/ImUserService.java              # 用户信息服务
```

### 7.2 前端文件
```
shengyu-ui/.../pages/message/contact-picker.uvue                   # 联系人选择页面
shengyu-ui/.../pages/message/chat.uvue                            # 聊天页面（扩展）
shengyu-ui/.../api/contact.uts                                    # 联系人 API
shengyu-ui/.../services/message-service.uts                       # 消息服务（扩展）
```

### 7.3 配置文件
```
sql/mysql/1.0/im/ddl_im_tables.sql                                # 数据库表结构
shengyu-ui/.../pages.json                                         # 页面路由配置
```

---

## 8. 验收标准

### 8.1 功能验收
- [ ] 从聊天页"+"入口可以进入联系人选择页面
- [ ] 支持按姓名、职位搜索联系人
- [ ] 选择联系人后可以成功发送名片消息
- [ ] 名片卡片消息正确展示（头像、姓名、职位、公司）
- [ ] 点击名片卡片可以查看用户详情
- [ ] 点击"发消息"可以跳转到私聊窗口
- [ ] 只能分享同租户内的用户名片

### 8.2 性能验收
- [ ] 联系人选择页面打开时间 < 1 秒
- [ ] 搜索响应时间 < 500ms
- [ ] 名片消息发送成功率 > 99%
- [ ] 联系人列表滚动流畅（60fps）
- [ ] 内存使用合理，无明显内存泄漏

### 8.3 兼容性验收
- [ ] App 端（Android 10+）正常工作
- [ ] App 端（iOS 14+）正常工作
- [ ] H5 端（Chrome/Safari）正常工作
- [ ] 不同网络环境（WiFi/4G/5G）正常工作

### 8.4 安全验收
- [ ] 跨租户名片分享被正确拒绝
- [ ] 权限控制生效

---

## 9. 上线检查清单

### 9.1 上线前检查
- [ ] 代码审查通过
- [ ] 所有测试用例通过
- [ ] 性能指标达标
- [ ] 无严重 Bug
- [ ] 产品验收通过
- [ ] 权限控制策略已配置

### 9.2 上线后验证
- [ ] 生产环境功能验证
- [ ] 监控数据正常
- [ ] 用户反馈收集
- [ ] 性能指标监控

---

## 10. 参考资料

- [IM即时通讯架构设计文档-v2.0.md](./IM即时通讯架构设计文档-v2.0.md)
- [IM即时通讯名片功能设计文档-v2.0.md](./IM即时通讯名片功能设计文档-v2.0.md)
- [企业微信名片功能设计](https://work.weixin.qq.com/)
- [钉钉数字化名片](https://www.dingtalk.com/)
- [Web 性能最佳实践](https://developer.mozilla.org/zh-CN/docs/Web/Performance)

---

**文档版本**：v2.0.0  
**创建日期**：2026-04-02  
**适用项目**：shengyu-im-saas  
**责任人**：开发团队  
**审核人**：架构师、产品经理
