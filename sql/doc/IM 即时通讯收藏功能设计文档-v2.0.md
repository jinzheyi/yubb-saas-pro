# IM 即时通讯 - 收藏功能设计文档 v2.0

> **文档版本**: v2.0.0  
> **创建日期**: 2026-04-02  
> **项目**: 圣钰 SaaS Pro - IM 即时通讯系统  
> **定位**: 企业内部 IM 消息收藏功能  
> **目标体验**: 对齐企业微信/钉钉的收藏管理体验  
> **关联文档**: `sql/doc/IM即时通讯架构设计文档-v2.0.md`

## 一、功能概述

### 1.1 功能描述

在企业 IM 场景中，收藏功能是重要信息快速检索和重用的工具。用户可以：

- **消息收藏**：长按聊天消息（文字、图片、文件、语音、链接）添加到收藏
- **分类浏览**：按消息类型自动分类（全部、文字、图片、文件、链接）
- **快速搜索**：支持关键字搜索收藏内容
- **一键转发**：将收藏内容快速发送到聊天窗口
- **批量管理**：支持批量删除收藏内容

### 1.2 企业应用场景

| 场景 | 典型用途 | 价值 |
|------|----------|------|
| **工作资料** | 收藏重要文档、链接 | 快速查找和重用 |
| **客户沟通** | 收藏客户需求、反馈 | 形成沟通记录库 |
| **团队协作** | 收藏会议要点、决策 | 方便信息同步 |
| **个人备忘** | 收藏重要信息、提醒 | 个人工作助手 |

### 1.3 UI 交互流程

```
聊天页面 → 长按消息 → 弹出菜单 → 点击"收藏"
→ 显示"已收藏"提示
→ 可在"我的收藏"页面查看

我的收藏页面 → 分类筛选 → 点击内容
→ 查看/播放/下载
→ 可转发到聊天、可删除
```

---

## 二、技术方案

### 2.1 收藏数据结构

#### 数据库表设计
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

#### 收藏内容 JSON 结构
```json
{
  "messageId": "string",           // 原消息ID
  "chatId": "string",            // 原聊天ID  
  "messageType": 1,              // 消息类型
  "content": "string",           // 文字内容或文件信息
  "senderId": "string",          // 发送者ID
  "senderName": "string",        // 发送者姓名
  "senderAvatar": "string",      // 发送者头像
  "createTime": "2026-04-02T10:00:00Z"
}
```

### 2.2 API 接口设计

#### 收藏操作接口
```typescript
// POST /system/im/favorite/add
interface FavoriteAddReq {
  messageId: string          // 消息ID
}

// POST /system/im/favorite/delete  
interface FavoriteDeleteReq {
  favoriteId: string        // 收藏ID
}

// GET /system/im/favorite/list
interface FavoriteListReq {
  messageType?: number       // 消息类型筛选（可选）
  keyword?: string         // 搜索关键词（可选）
  pageNo?: number          // 页码
  pageSize?: number        // 每页数量
}

interface FavoriteListResp {
  list: FavoriteItem[]
  total: number
}
```

#### 收藏项数据结构
```typescript
interface FavoriteItem {
  favoriteId: string       // 收藏ID
  messageId: string        // 原消息ID
  chatId: string          // 原聊天ID
  messageType: number      // 消息类型
  content: string         // 收藏内容
  senderId: string       // 发送者ID
  senderName: string     // 发送者姓名
  senderAvatar: string   // 发送者头像
  createTime: string     // 收藏时间
}
```

### 2.3 前端实现方案

#### 收藏页面路由
```json
{
  "path": "pages/message/favorites",
  "style": {
    "navigationBarTitleText": "我的收藏"
  }
}
```

#### 收藏列表页面结构
```vue
<!-- pages/message/favorites.uvue -->
<template>
  <view class="favorites-page">
    <!-- 分类标签栏 -->
    <view class="category-tabs">
      <view 
        v-for="tab in categoryTabs" 
        :key="tab.type"
        class="tab-item"
        :class="{ active: currentType === tab.type }"
        @click="switchCategory(tab.type)"
      >
        <text>{{ tab.name }}</text>
      </view>
    </view>
    
    <!-- 搜索框 -->
    <view class="search-bar">
      <input 
        v-model="keyword"
        placeholder="搜索收藏内容"
        @input="handleSearch"
      />
    </view>
    
    <!-- 收藏列表 -->
    <scroll-view class="favorites-list" scroll-y>
      <view 
        v-for="item in favoriteList" 
        :key="item.favoriteId"
        class="favorite-item"
        @click="handleItemClick(item)"
      >
        <!-- 消息类型图标 -->
        <view class="item-icon">
          <text class="iconfont">{{ getMessageIcon(item.messageType) }}</text>
        </view>
        
        <!-- 内容预览 -->
        <view class="item-content">
          <text class="content-text">{{ formatContent(item.content) }}</text>
          <text class="sender-info">{{ item.senderName }} · {{ formatTime(item.createTime) }}</text>
        </view>
        
        <!-- 操作按钮 -->
        <view class="item-actions">
          <button class="action-btn" @click.stop="handleForward(item)">转发</button>
          <button class="action-btn delete" @click.stop="handleDelete(item)">删除</button>
        </view>
      </view>
    </scroll-view>
  </view>
</template>
```

#### 收藏功能核心逻辑
```typescript
// services/favorite-service.uts
export class FavoriteService {
  private favoriteList: FavoriteItem[] = []
  
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
  ): Promise<FavoriteItem[]> {
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
      
      // 更新本地列表
      favoriteList.value = favoriteList.value.filter(item => item.favoriteId !== favoriteId)
      
      uni.showToast({ title: '已删除', icon: 'success' })
    } catch (error) {
      console.error('[Favorite] 删除收藏失败:', error)
      uni.showToast({ title: '删除失败', icon: 'none' })
    }
  }
  
  // 转发收藏内容
  async function forwardFavorite(item: FavoriteItem, targetChatId: string): Promise<void> {
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

---

## 三、组件复用策略

### 3.1 现有可复用组件

#### 消息列表组件
- **文件**：`components/message-list/message-list.uvue`
- **复用方式**：直接用于收藏列表展示
- **适配修改**：添加收藏操作按钮

#### 搜索组件
- **文件**：`components/search-bar/search-bar.uvue`
- **复用方式**：直接嵌入收藏页面
- **功能**：支持防抖搜索

#### 分类标签组件
- **文件**：`components/category-tabs/category-tabs.uvue`
- **复用方式**：直接用于消息类型筛选
- **配置**：动态加载分类选项

### 3.2 现有可复用 API

#### 消息相关 API
- **文件**：`api/message.uts`
- **复用接口**：`getMessageDetail()`, `sendMessage()`
- **扩展接口**：添加收藏相关接口

#### 用户信息 API
- **文件**：`api/user.uts`
- **复用接口**：`getUserInfo()`
- **用途**：获取发送者信息

---

## 四、性能优化

### 4.1 前端性能优化

#### 列表优化
- **分页加载**：每页 20 条，避免一次性加载大量数据
- **虚拟滚动**：大列表使用虚拟滚动技术
- **搜索防抖**：500ms 防抖，减少频繁请求

#### 内存管理
- **及时清理**：页面卸载时清理定时器和事件监听
- **图片懒加载**：滚动到可视区域才加载图片

### 4.2 后端性能优化

#### 数据库优化
- **索引优化**：用户ID、消息类型、创建时间建立复合索引
- **分页查询**：使用 LIMIT 分页，避免全表扫描
- **内容压缩**：大文件内容只存储引用，不存完整内容

---

## 五、技术约束

### 5.1 UTS 开发规范
- **强类型约束**：所有变量必须初始化，避免 undefined
- **条件语句**：必须使用 boolean 类型，避免 truthy/falsy
- **ID 处理**：所有 ID 字段使用 string 类型，避免精度丢失

### 5.2 组件复用原则
- **最大化复用**：优先使用现有组件和 API
- **最小化修改**：现有组件只做必要的功能扩展
- **保持一致**：UI 交互风格与现有功能保持一致

### 5.3 数据一致性
- **消息格式**：收藏内容与原消息保持相同格式
- **类型映射**：消息类型枚举与现有系统保持一致
- **权限控制**：遵循现有的租户隔离机制

---

## 六、验收标准

### 6.1 功能验收
- [ ] 长按消息可以添加到收藏
- [ ] 收藏页面按消息类型分类展示
- [ ] 支持关键字搜索收藏内容
- [ ] 点击收藏内容可以查看详情
- [ ] 支持将收藏内容转发到聊天
- [ ] 支持删除收藏内容
- [ ] 收藏操作有成功/失败提示

### 6.2 性能验收
- [ ] 收藏列表打开时间 < 1 秒
- [ ] 搜索响应时间 < 500ms
- [ ] 收藏操作成功率 > 99%
- [ ] 列表滚动流畅（60fps）

### 6.3 兼容性验收
- [ ] App 端（Android 10+）正常工作
- [ ] App 端（iOS 14+）正常工作
- [ ] H5 端（Chrome/Safari）正常工作

---

## 七、参考资料

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
