# IM 即时通讯 - 收藏功能开发任务清单 v2.0

> **文档版本**: v2.0.0  
> **创建日期**: 2026-04-02  
> **项目**: 圣钰 SaaS Pro - IM 即时通讯系统  
> **定位**: 企业内部 IM 消息收藏功能开发  
> **目标体验**: 对齐企业微信/钉钉的收藏管理体验  
> **关联文档**: `sql/doc/IM即时通讯架构设计文档-v2.0.md`

## 一、任务概述

### 1.1 功能目标
实现 IM 收藏功能，支持消息收藏、分类浏览、搜索检索、一键转发等核心功能，确保符合企业级使用需求。

### 1.2 核心价值
- **信息沉淀**：重要消息快速收藏，形成个人知识库
- **高效重用**：收藏内容一键转发，提升工作效率
- **快速检索**：分类浏览和关键词搜索，快速定位信息

### 1.3 技术约束
- **UTS 规范**：遵循强类型约束，不使用 undefined、truthy/falsy
- **ID 处理**：所有 ID 字段使用 string 类型，避免精度丢失
- **组件复用**：最大化复用现有组件和 API，减少重复开发
- **协议一致性**：遵循现有消息协议和 WebSocket 机制

---

## 二、现有资源评估

### 2.1 可复用组件分析

#### 消息列表组件
- **文件**：`components/message-list/message-list.uvue`
- **功能**：消息列表展示、点击交互
- **复用程度**：✅ 高度可复用
- **适配方案**：直接用于收藏列表，添加收藏操作按钮

#### 搜索组件
- **文件**：`components/search-bar/search-bar.uvue`
- **功能**：搜索输入、防抖处理
- **复用程度**：✅ 完全可复用
- **适配方案**：直接嵌入收藏页面

#### 分类标签组件
- **文件**：`components/category-tabs/category-tabs.uvue`
- **功能**：标签切换、状态管理
- **复用程度**：✅ 完全可复用
- **适配方案**：配置消息类型分类选项

### 2.2 可复用 API 分析

#### 消息相关 API
- **文件**：`api/message.uts`
- **现有接口**：`getMessageDetail()`, `sendMessage()`
- **复用程度**：✅ 高度可复用
- **扩展需求**：添加收藏相关接口

#### 用户信息 API
- **文件**：`api/user.uts`
- **现有接口**：`getUserInfo()`
- **复用程度**：✅ 完全可复用
- **用途**：获取发送者信息

---

## 三、开发任务分解

### 3.1 阶段一：后端支持（1 人天）

#### 任务 1.1：数据库表设计
- **负责人**：后端开发
- **完成时间**：Day 1 上午
- **任务详情**：
  1. 创建 `im_favorites` 表
  2. 建立必要索引
  3. 添加外键约束
- **SQL 脚本**：
```sql
-- 收藏表 (im_favorites)
CREATE TABLE im_favorites (
  id bigint PRIMARY KEY AUTO_INCREMENT COMMENT '收藏ID',
  user_id bigint NOT NULL COMMENT '用户ID',
  tenant_id varchar(64) NOT NULL COMMENT '租户ID',
  message_id bigint NOT NULL COMMENT '原消息ID',
  chat_id bigint NOT NULL COMMENT '原聊天ID',
  message_type int NOT NULL COMMENT '消息类型：1-文字 2-图片 3-文件 4-语音 5-链接',
  content text COMMENT '收藏内容（JSON格式）',
  create_time datetime DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  update_time datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  INDEX idx_user_tenant (user_id, tenant_id),
  INDEX idx_user_type (user_id, message_type),
  INDEX idx_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM收藏表';
```
- **验收标准**：
  - [ ] 表结构创建成功
  - [ ] 索引建立正确
  - [ ] 外键约束生效

#### 任务 1.2：收藏接口开发
- **负责人**：后端开发
- **完成时间**：Day 1 下午
- **任务详情**：
  1. 实现收藏添加接口
  2. 实现收藏删除接口
  3. 实现收藏列表查询接口
- **Controller 代码**：
```java
@RestController
@RequestMapping("/system/im/favorite")
public class ImFavoriteController {
    
    @PostMapping("/add")
    @SaCheckPermission("im:message:add")
    public CommonResult<Void> addFavorite(@RequestBody FavoriteAddReq req) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        String tenantId = SecurityFrameworkUtils.getLoginTenantId();
        
        favoriteService.addFavorite(userId, tenantId, req.getMessageId());
        return CommonResult.success();
    }
    
    @PostMapping("/delete")
    @SaCheckPermission("im:message:delete")
    public CommonResult<Void> deleteFavorite(@RequestBody FavoriteDeleteReq req) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        String tenantId = SecurityFrameworkUtils.getLoginTenantId();
        
        favoriteService.deleteFavorite(userId, tenantId, req.getFavoriteId());
        return CommonResult.success();
    }
    
    @GetMapping("/list")
    @SaCheckPermission("im:message:query")
    public CommonResult<PageResult<FavoriteVO>> listFavorites(FavoriteListReq req) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        String tenantId = SecurityFrameworkUtils.getLoginTenantId();
        
        PageResult<FavoriteVO> result = favoriteService.listFavorites(
            userId, tenantId, req);
        return CommonResult.success(result);
    }
}
```
- **验收标准**：
  - [ ] 接口开发完成
  - [ ] 参数校验正确
  - [ ] 权限控制生效

#### 任务 1.3：收藏服务实现
- **负责人**：后端开发
- **完成时间**：Day 2 上午
- **任务详情**：
  1. 实现收藏业务逻辑
  2. 实现消息内容解析
  3. 实现分页查询优化
- **Service 代码**：
```java
@Service
public class ImFavoriteServiceImpl implements ImFavoriteService {
    
    @Override
    public void addFavorite(Long userId, String tenantId, String messageId) {
        // 获取原消息信息
        ImMessage message = messageService.getMessageById(messageId);
        if (message == null) {
            throw new ServiceException("消息不存在");
        }
        
        // 检查是否已收藏
        ImFavorite existFavorite = favoriteMapper.selectByUserAndMessage(userId, messageId);
        if (existFavorite != null) {
            throw new ServiceException("该消息已收藏");
        }
        
        // 创建收藏记录
        ImFavorite favorite = new ImFavorite();
        favorite.setUserId(userId);
        favorite.setTenantId(tenantId);
        favorite.setMessageId(Long.parseLong(messageId));
        favorite.setChatId(message.getChatId());
        favorite.setMessageType(message.getMessageType());
        favorite.setContent(buildFavoriteContent(message));
        
        favoriteMapper.insert(favorite);
    }
    
    private String buildFavoriteContent(ImMessage message) {
        Map<String, Object> content = new HashMap<>();
        content.put("messageId", message.getId().toString());
        content.put("chatId", message.getChatId().toString());
        content.put("messageType", message.getMessageType());
        content.put("content", message.getContent());
        content.put("senderId", message.getSenderId().toString());
        content.put("senderName", message.getSenderName());
        content.put("senderAvatar", message.getSenderAvatar());
        content.put("createTime", message.getCreateTime());
        
        return JsonUtils.toJsonString(content);
    }
}
```
- **验收标准**：
  - [ ] 业务逻辑正确
  - [ ] 数据格式正确
  - [ ] 异常处理完善

### 3.2 阶段二：前端实现（1.5 人天）

#### 任务 2.1：收藏列表页面开发
- **负责人**：前端开发
- **完成时间**：Day 2 下午
- **任务详情**：
  1. 创建 `pages/message/favorites.uvue`
  2. 集成分类标签和搜索组件
  3. 实现收藏列表展示
- **页面结构**：
```vue
<!-- pages/message/favorites.uvue -->
<template>
  <view class="favorites-page">
    <!-- 分类标签栏（复用 category-tabs 组件）-->
    <category-tabs 
      :tabs="categoryTabs"
      :activeTab="currentType"
      @tabChange="handleCategoryChange"
    />
    
    <!-- 搜索框（复用 search-bar 组件）-->
    <search-bar 
      v-model="keyword"
      placeholder="搜索收藏内容"
      @search="handleSearch"
    />
    
    <!-- 收藏列表（复用 message-list 组件）-->
    <message-list 
      :messages="favoriteList"
      :showActions="true"
      @itemClick="handleItemClick"
      @forward="handleForward"
      @delete="handleDelete"
    />
    
    <!-- 加载更多 -->
    <view v-if="hasMore" class="load-more" @click="loadMore">
      <text>加载更多</text>
    </view>
  </view>
</template>

<script setup lang="uts">
import { ref, onMounted, onUnload } from 'vue'
import { favoriteService } from '@/services/favorite-service'

// 分类标签
const categoryTabs = ref([
  { type: 0, name: '全部' },
  { type: 1, name: '文字' },
  { type: 2, name: '图片' },
  { type: 3, name: '文件' },
  { type: 4, name: '语音' },
  { type: 5, name: '链接' }
])

const currentType = ref(0)
const keyword = ref('')
const favoriteList = ref([])
const pageNo = ref(1)
const hasMore = ref(true)

// 切换分类
function handleCategoryChange(type: number): void {
  currentType.value = type
  pageNo.value = 1
  hasMore.value = true
  loadFavorites()
}

// 搜索处理（防抖）
let searchTimer: number = 0
function handleSearch(): void {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    pageNo.value = 1
    hasMore.value = true
    loadFavorites()
  }, 500)
}

// 加载收藏列表
async function loadFavorites(): Promise<void> {
  try {
    const list = await favoriteService.getFavoriteList(
      currentType.value === 0 ? undefined : currentType.value,
      keyword.value || undefined,
      pageNo.value
    )
    
    if (pageNo.value === 1) {
      favoriteList.value = list
    } else {
      favoriteList.value.push(...list)
    }
    
    hasMore.value = list.length >= 20
  } catch (error) {
    console.error('[Favorites] 加载失败:', error)
  }
}

// 加载更多
function loadMore(): void {
  if (!hasMore.value) return
  pageNo.value++
  loadFavorites()
}

// 生命周期
onMounted(() => {
  loadFavorites()
})

onUnload(() => {
  clearTimeout(searchTimer)
})
</script>
```
- **验收标准**：
  - [ ] 页面创建成功
  - [ ] 分类切换正常
  - [ ] 搜索功能正常
  - [ ] 列表展示正确

#### 任务 2.2：收藏服务开发
- **负责人**：前端开发
- **完成时间**：Day 3 上午
- **任务详情**：
  1. 创建 `services/favorite-service.uts`
  2. 实现收藏相关 API 调用
  3. 实现本地状态管理
- **服务代码**：
```typescript
// services/favorite-service.uts
export class FavoriteService {
  
  // 添加收藏
  async function addFavorite(messageId: string): Promise<void> {
    try {
      await request({
        url: '/system/im/favorite/add',
        method: 'POST',
        data: { messageId }
      })
      
      uni.showToast({ title: '已收藏', icon: 'success' })
    } catch (error) {
      console.error('[Favorite] 添加收藏失败:', error)
      uni.showToast({ title: '收藏失败', icon: 'none' })
    }
  }
  
  // 获取收藏列表
  async function getFavoriteList(
    messageType?: number,
    keyword?: string,
    pageNo: number = 1
  ): Promise<any[]> {
    try {
      const res = await request({
        url: '/system/im/favorite/list',
        method: 'GET',
        data: {
          messageType,
          keyword,
          pageNo,
          pageSize: 20
        }
      })
      
      return res.list || []
    } catch (error) {
      console.error('[Favorite] 获取收藏列表失败:', error)
      return []
    }
  }
  
  // 删除收藏
  async function deleteFavorite(favoriteId: string): Promise<void> {
    try {
      await request({
        url: '/system/im/favorite/delete',
        method: 'POST',
        data: { favoriteId }
      })
      
      uni.showToast({ title: '已删除', icon: 'success' })
    } catch (error) {
      console.error('[Favorite] 删除收藏失败:', error)
      uni.showToast({ title: '删除失败', icon: 'none' })
    }
  }
  
  // 转发收藏内容
  async function forwardFavorite(item: any, targetChatId: string): Promise<void> {
    try {
      const payload = {
        chatId: targetChatId,
        messageType: item.messageType,
        content: item.content,
        extra: JSON.stringify({
          type: 'FORWARD_FAVORITE',
          originalMessageId: item.messageId,
          originalChatId: item.chatId
        })
      }
      
      await request({
        url: '/im/message/send',
        method: 'POST',
        data: payload
      })
      
      uni.showToast({ title: '转发成功', icon: 'success' })
    } catch (error) {
      console.error('[Favorite] 转发失败:', error)
      uni.showToast({ title: '转发失败', icon: 'none' })
    }
  }
}

export const favoriteService = new FavoriteService()
```
- **验收标准**：
  - [ ] 服务创建成功
  - [ ] API 调用正常
  - [ ] 错误处理完善

#### 任务 2.3：聊天页面收藏集成
- **负责人**：前端开发
- **完成时间**：Day 3 下午
- **任务详情**：
  1. 在消息长按菜单添加"收藏"选项
  2. 实现收藏操作调用
  3. 添加收藏状态提示
- **集成代码**：
```typescript
// chat.uvue 中扩展消息长按菜单
const messageMenuItems = ref([
  { nameKey: 'chat.message.copy', icon: 'copy' },
  { nameKey: 'chat.message.forward', icon: 'forward' },
  { nameKey: 'chat.message.favorite', icon: 'favorite' },  // 新增
  { nameKey: 'chat.message.delete', icon: 'delete' }
])

// 处理消息菜单点击
function handleMessageMenuClick(item: any, menu: any): void {
  if (menu.nameKey === 'chat.message.favorite') {
    handleAddFavorite(item)
  }
  // ... 其他菜单处理
}

// 添加收藏
async function handleAddFavorite(message: any): Promise<void> {
  await favoriteService.addFavorite(message.messageId)
}
```
- **验收标准**：
  - [ ] 菜单项添加成功
  - [ ] 收藏操作正常
  - [ ] 提示信息正确

### 3.3 阶段三：联调测试（1 人天）

#### 任务 3.1：功能测试
- **负责人**：测试工程师
- **完成时间**：Day 4 上午
- **测试用例**：
  - [ ] 长按消息可以添加到收藏
  - [ ] 收藏页面按消息类型分类展示
  - [ ] 支持关键字搜索收藏内容
  - [ ] 点击收藏内容可以查看详情
  - [ ] 支持将收藏内容转发到聊天
  - [ ] 支持删除收藏内容
  - [ ] 收藏操作有成功/失败提示

#### 任务 3.2：性能测试
- **负责人**：测试工程师
- **完成时间**：Day 4 下午
- **测试指标**：
  - [ ] 收藏列表打开时间 < 1 秒
  - [ ] 搜索响应时间 < 500ms
  - [ ] 收藏操作成功率 > 99%
  - [ ] 列表滚动流畅（60fps）

#### 任务 3.3：兼容性测试
- **负责人**：测试工程师
- **完成时间**：Day 5 上午
- **测试平台**：
  - [ ] App 端（Android 10+）正常工作
  - [ ] App 端（iOS 14+）正常工作
  - [ ] H5 端（Chrome/Safari）正常工作
  - [ ] 不同网络环境（WiFi/4G/5G）正常工作

---

## 四、里程碑计划

| 里程碑 | 时间 | 交付物 | 验收标准 |
|--------|------|--------|----------|
| M1：后端支持完成 | Day 2 | 数据库表、收藏接口、服务实现 | 后端接口可正常调用 |
| M2：收藏列表页完成 | Day 3 | favorites.uvue 页面 | 可以查看、搜索、分类收藏 |
| M3：聊天集成完成 | Day 3 | 聊天页面收藏功能 | 可以从聊天添加收藏 |
| M4：测试验收完成 | Day 5 | 测试报告、验收报告 | 所有测试用例通过 |

---

## 五、风险评估

### 5.1 技术风险
| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 收藏数据量过大 | 中 | 中 | 分页加载、索引优化 |
| 搜索性能问题 | 中 | 中 | 搜索防抖、内容索引 |
| 消息格式兼容性 | 低 | 高 | 充分测试、格式转换 |

### 5.2 业务风险
| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| 用户体验不佳 | 中 | 中 | 充分测试、用户反馈 |
| 兼容性问题 | 低 | 中 | 多端测试、渐进增强 |

---

## 六、资源需求

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
- 开发环境：可以调用消息相关接口
- 测试环境：独立部署，配置完整数据

---

## 七、关键文件清单

### 7.1 后端文件
```
shengyu-module-system/.../entity/ImFavorite.java                    # 收藏实体
shengyu-module-system/.../mapper/ImFavoriteMapper.java              # 收藏Mapper
shengyu-module-system/.../service/ImFavoriteService.java             # 收藏服务
shengyu-module-system/.../controller/ImFavoriteController.java         # 收藏控制器
sql/mysql/1.0/im/ddl_im_tables.sql                            # 数据库表结构
```

### 7.2 前端文件
```
shengyu-ui/.../pages/message/favorites.uvue                        # 收藏列表页面
shengyu-ui/.../services/favorite-service.uts                       # 收藏服务
shengyu-ui/.../api/favorite.uts                                    # 收藏API
shengyu-ui/.../pages/message/chat.uvue                             # 聊天页面（扩展）
```

### 7.3 配置文件
```
shengyu-ui/.../pages.json                                          # 页面路由配置
```

---

## 八、验收标准

### 8.1 功能验收
- [ ] 长按消息可以添加到收藏
- [ ] 收藏页面按消息类型分类展示
- [ ] 支持关键字搜索收藏内容
- [ ] 点击收藏内容可以查看详情
- [ ] 支持将收藏内容转发到聊天
- [ ] 支持删除收藏内容
- [ ] 收藏操作有成功/失败提示

### 8.2 性能验收
- [ ] 收藏列表打开时间 < 1 秒
- [ ] 搜索响应时间 < 500ms
- [ ] 收藏操作成功率 > 99%
- [ ] 列表滚动流畅（60fps）

### 8.3 兼容性验收
- [ ] App 端（Android 10+）正常工作
- [ ] App 端（iOS 14+）正常工作
- [ ] H5 端（Chrome/Safari）正常工作
- [ ] 不同网络环境（WiFi/4G/5G）正常工作

---

## 九、上线检查清单

### 9.1 上线前检查
- [ ] 代码审查通过
- [ ] 所有测试用例通过
- [ ] 性能指标达标
- [ ] 无严重 Bug
- [ ] 产品验收通过

### 9.2 上线后验证
- [ ] 生产环境功能验证
- [ ] 监控数据正常
- [ ] 用户反馈收集
- [ ] 性能指标监控

---

## 十、参考资料

- [IM即时通讯架构设计文档-v2.0.md](./IM即时通讯架构设计文档-v2.0.md)
- [IM即时通讯开发任务清单-v2.0.md](./IM即时通讯开发任务清单-v2.0.md)
- [微信收藏功能设计](https://weixin.qq.com/)
- [企业微信收藏功能](https://work.weixin.qq.com/)
- [钉钉收藏功能](https://www.dingtalk.com/)

---

**文档版本**：v2.0.0  
**创建日期**：2026-04-02  
**适用项目**：shengyu-im-saas  
**责任人**：开发团队  
**审核人**：架构师、产品经理
