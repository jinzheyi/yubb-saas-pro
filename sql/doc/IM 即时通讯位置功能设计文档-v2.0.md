# IM 即时通讯 - 位置功能设计文档 v3.0

> **文档版本**: v3.0.0  
> **创建日期**: 2026-04-02  
> **更新日期**: 2026-04-02  
> **项目**: 圣钰 SaaS Pro - IM 位置功能  
> **定位**: 企业内部 IM 位置共享（对标企业微信位置功能）  
> **技术栈**: uni-app x + UTS + 腾讯地图 API  
> **关联文档**: `IM即时通讯架构设计文档-v2.0.md`  
> **性能目标**: 位置选择页面加载 < 1s，搜索响应 < 500ms，地图缩略图加载 < 1s

---

## 1. 核心功能范围

### 1.1 闭环功能需求（必须实现）

#### 1.1.1 位置发送流程
- **触发入口**: 对话页面功能面板中的位置图标（已配置 `icon: '\uea72'`）
- **位置选择**: 地图选择界面，支持搜索和点选
- **消息发送**: 构建位置消息（type=6）并发送
- **本地展示**: 发送后立即在对话页面展示位置卡片

#### 1.1.2 位置接收流程
- **消息渲染**: 接收位置消息后展示为卡片形式
- **地图缩略图**: 使用腾讯地图静态 API 生成预览图
- **详情查看**: 点击卡片打开位置详情页面
- **导航跳转**: 支持跳转到第三方地图应用进行导航

### 1.2 非功能需求（明确排除）
- **实时位置共享**: 不支持实时位置轨迹共享
- **位置历史记录**: 不维护用户位置历史
- **位置标签**: 不支持自定义位置标签
- **位置收藏**: 不支持收藏常用位置
- **后台位置监控**: 不进行后台位置追踪

## 2. 技术架构设计

### 2.1 地图服务选型

#### 2.1.1 腾讯地图 API（主方案）
- **JavaScript GL API**: 地图展示与交互
- **WebService API**: 位置搜索与地理编码
- **静态地图 API**: 缩略图生成
- **免费额度**: 3 万次/日，满足中小企业需求

#### 2.1.2 uni.chooseLocation（备用方案）
- **使用场景**: H5 端降级方案
- **优势**: 跨平台兼容，无需额外 SDK
- **限制**: 自定义能力有限

### 2.2 系统集成架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   uni-app x     │    │  腾讯地图 API   │    │   后端 IM       │
│   前端          │◄──►│  服务           │◄──►│   系统          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ location-picker │    │  搜索 API      │    │ 消息存储        │
│ message-service │    │  静态地图 API   │    │ WebSocket 推送  │
│ location-detail │    │  地图展示       │    │ 消息路由        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 2.3 数据模型设计

#### 2.3.1 位置消息结构（UTS）
```typescript
// 位置消息数据结构
interface LocationMessage {
  type: 'LOCATION'           // 消息类型标识
  latitude: number           // 纬度（GCJ-02 坐标系）
  longitude: number          // 经度（GCJ-02 坐标系）
  locationName: string       // 位置名称
  address: string            // 详细地址
  coordinateSystem: 'GCJ-02' // 坐标系标识
  thumbnailUrl?: string      // 缩略图 URL（可选）
}

// 位置选择结果
interface LocationResult {
  name: string               // 位置名称
  address: string            // 详细地址
  latitude: number           // 纬度
  longitude: number          // 经度
}
```

#### 2.3.2 后端存储结构
```json
// im_messages 表 extra 字段存储格式
{
  "type": "LOCATION",
  "latitude": 28.692345,
  "longitude": 115.856789,
  "name": "江西金控集团",
  "address": "江西省南昌市红谷滩区丰润路",
  "coordinateSystem": "GCJ-02",
  "thumbnailUrl": "https://apis.map.qq.com/ws/staticmap/v1/?...",
  "createdAt": 1712044800000
}
```

#### 2.3.3 数据库表结构验证
```sql
-- 消息表结构（已存在，验证支持）
CREATE TABLE im_messages (
  id BIGINT PRIMARY KEY,
  chat_id VARCHAR(64) NOT NULL,        -- 聊天 ID（string 类型）
  sender_id VARCHAR(64) NOT NULL,      -- 发送者 ID（string 类型）
  receiver_id VARCHAR(64),             -- 接收者 ID（string 类型）
  group_id VARCHAR(64),                -- 群组 ID（string 类型）
  message_type INT NOT NULL,           -- 消息类型：6 = LOCATION
  content TEXT,                        -- 消息内容
  extra JSON,                          -- 扩展字段（存储位置信息）
  sequence BIGINT,                     -- 序列号（string 类型处理）
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_chat_id (chat_id),
  INDEX idx_created_at (created_at)
);
```

## 3. 性能优化设计

### 3.1 地图加载性能优化

#### 3.1.1 懒加载策略
- **Intersection Observer**: 地图容器进入视口后才初始化地图
- **占位符设计**: 加载前显示轻量级占位符（< 5KB）
- **渐进式加载**: 三层加载系统（预览→标准→高清）

```typescript
// 地图懒加载实现
const mapObserver = uni.createIntersectionObserver()
mapObserver.observe('.map-container', {
  thresholds: [0.1]
}).then((res) => {
  if (res.intersectionRatio > 0) {
    initTencentMap() // 进入视口后初始化
  }
})
```

#### 3.1.2 地图瓦片优化
- **瓦片压缩**: WebP 格式，256x256 像素，减少 25-30% 文件大小
- **动态质量**: 缩放级别 1-10 使用低分辨率，街道级别使用高清
- **连接速度检测**: 根据网络状况自动调整瓦片质量

#### 3.1.3 缓存策略
- **浏览器缓存**: 地图瓦片 7 天过期
- **本地存储**: localStorage 存储矢量数据，IndexedDB 存储栅格瓦片
- **Service Worker**: 离线缓存常用区域瓦片
- **CDN 边缘缓存**: 基于地理位置的缓存预热

### 3.2 搜索性能优化

#### 3.2.1 防抖与节流
- **搜索防抖**: 输入停止 500ms 后执行搜索
- **请求节流**: 搜索请求频率限制为 1 次/秒
- **结果缓存**: 搜索结果本地缓存 5 分钟

```typescript
// 搜索防抖实现
let searchTimer: number = 0
function debouncedSearch(keyword: string) {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    searchLocations(keyword)
  }, 500)
}
```

#### 3.2.2 移动端优化
- **触控优化**: 按钮最小 44px 高度
- **网络优化**: 移动网络下压缩率提升 70-80%
- **数据监控**: 提供数据使用统计和节省模式

### 3.3 消息渲染优化

#### 3.3.1 静态地图优化
- **尺寸优化**: 280*150 像素，2x 分辨率
- **标记压缩**: 使用 base64 编码的微型标记
- **URL 缓存**: 相同坐标的地图 URL 复用

```typescript
// 静态地图 URL 生成
function buildStaticMapUrl(latitude: number, longitude: number): string {
  const baseUrl = 'https://apis.map.qq.com/ws/staticmap/v1/'
  const params = {
    location: `${latitude},${longitude}`,
    zoom: 15,
    size: '280*150',
    scale: 2,
    markers: `M,${latitude},${longitude}`,
    key: TENCENT_MAP_KEY,
    format: 'webp' // 使用 WebP 格式
  }
  return `${baseUrl}?${new URLSearchParams(params).toString()}`
}
```

#### 3.3.2 列表渲染优化
- **虚拟滚动**: 大量位置消息时使用虚拟滚动
- **图片懒加载**: 位置卡片进入视口后才加载缩略图
- **内存管理**: 页面卸载时清理地图实例

## 4. 前端实现规范

### 4.1 页面路由配置

#### 4.1.1 pages.json 配置
```json
{
  "pages": [
    {
      "path": "pages/message/location-picker",
      "style": {
        "navigationBarTitleText": "位置",
        "navigationBarBackgroundColor": "#ffffff",
        "navigationBarTextStyle": "black",
        "backgroundColor": "#f5f5f5"
      }
    },
    {
      "path": "pages/message/location-detail",
      "style": {
        "navigationBarTitleText": "位置详情",
        "navigationBarBackgroundColor": "#ffffff",
        "navigationBarTextStyle": "black"
      }
    }
  ]
}
```

### 4.2 核心页面实现

#### 4.2.1 位置选择页面（location-picker.uvue）
**文件路径**: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/location-picker.uvue`

**核心功能**：
- 搜索框与防抖处理
- 地图展示与交互
- 位置列表与选择
- 确认按钮与返回数据

**关键实现点**：
```vue
<template>
  <view class="location-picker">
    <!-- 搜索框 -->
    <view class="search-bar">
      <input 
        v-model="keyword" 
        placeholder="请输入关键字搜索位置"
        @input="onSearchInput"
      />
    </view>
    
    <!-- 地图容器 -->
    <view class="map-container" id="map-container">
      <!-- 腾讯地图实例 -->
    </view>
    
    <!-- 位置列表 -->
    <scroll-view class="location-list" scroll-y>
      <view 
        v-for="(item, index) in locations" 
        :key="item.id || index"
        :class="['location-item', { active: selectedIndex === index }]"
        @tap="selectLocation(index)"
      >
        <text class="location-name">{{ item.name }}</text>
        <text class="location-address">{{ item.address }}</text>
      </view>
    </scroll-view>
  </view>
</template>
```

#### 4.2.2 位置详情页面（location-detail.uvue）
**文件路径**: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/location-detail.uvue`

**核心功能**：
- 完整地图展示
- 位置信息显示
- 导航功能集成

### 4.3 服务层扩展

#### 4.3.1 消息服务扩展
**文件路径**: `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`

**新增方法**：
```typescript
// 发送位置消息
export async function sendLocationMessage(
  chatId: string,
  receiverId: string,
  groupId: string,
  location: LocationResult
): Promise<void> {
  const payload = {
    chatId,
    receiverId,
    groupId,
    messageType: 6, // LOCATION
    content: JSON.stringify({
      type: 'LOCATION',
      latitude: location.latitude,
      longitude: location.longitude,
      name: location.name,
      address: location.address,
      coordinateSystem: 'GCJ-02'
    }),
    extra: JSON.stringify({
      coordinateSystem: 'GCJ-02'
    })
  }
  
  await request({
    url: '/im/message/send',
    method: 'POST',
    data: payload
  })
}
```

#### 4.3.2 位置服务创建
**文件路径**: `shengyu-ui/shengyu-ui-admin-uniappx/services/location-service.uts`

**核心方法**：
```typescript
// 位置搜索
export async function searchLocations(keyword: string): Promise<LocationResult[]> {
  // 实现腾讯地图 API 调用
}

// 生成静态地图 URL
export function buildStaticMapUrl(latitude: number, longitude: number): string {
  // 实现静态地图 URL 生成
}

// 坐标转换（如需要）
export function convertCoordinate(lat: number, lng: number): {lat: number, lng: number} {
  // 实现 GCJ-02 到其他坐标系的转换
}
```

### 4.4 聊天页面集成

#### 4.4.1 功能入口处理
**文件路径**: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat.uvue`

**修改点**：
```typescript
// handleFeature 函数中添加位置处理
function handleFeature(item: any) {
  if (item.nameKey === 'chat.features.location') {
    handleLocationFeature()
  }
  // ... 其他功能处理
}

// 位置功能处理
async function handleLocationFeature() {
  try {
    const location = await navigateToLocationPicker()
    if (location) {
      await messageService.sendLocationMessage(
        chatId.value,
        getReceiverIdForMessage(),
        getGroupIdForMessage(),
        location
      )
      scrollToBottom()
    }
  } catch (e) {
    console.error('[Chat] 发送位置消息失败:', e)
    uni.showToast({ title: '发送失败', icon: 'none' })
  }
}

// 导航到位置选择页面
function navigateToLocationPicker(): Promise<LocationResult> {
  return new Promise((resolve, reject) => {
    uni.navigateTo({
      url: '/pages/message/location-picker',
      events: {
        locationSelected: (location: LocationResult) => {
          resolve(location)
        }
      },
      fail: (err) => reject(err)
    })
  })
}
```

#### 4.4.2 位置消息渲染优化
**现有模板优化**（第 134-140 行）：
```vue
<view v-else-if="msg.type === 'location'" class="message-bubble bubble-location">
  <view class="location-info" @tap="handleLocationOpen(msg)">
    <text class="location-name">{{ msg.locationName }}</text>
    <text class="location-address">{{ msg.address }}</text>
  </view>
  <image 
    class="location-map" 
    :src="getLocationThumbnailUrl(msg)" 
    mode="aspectFill"
    @error="handleImageError"
    @load="handleImageLoad"
  />
</view>
```

**辅助方法**：
```typescript
// 获取位置缩略图 URL
function getLocationThumbnailUrl(msg: MessageItem): string {
  if (msg.latitude && msg.longitude) {
    return locationService.buildStaticMapUrl(msg.latitude, msg.longitude)
  }
  return '/static/images/chat/map-placeholder.png'
}

// 处理位置卡片点击
function handleLocationOpen(msg: MessageItem) {
  uni.navigateTo({
    url: `/pages/message/location-detail?latitude=${msg.latitude}&longitude=${msg.longitude}&name=${encodeURIComponent(msg.locationName)}&address=${encodeURIComponent(msg.address)}`
  })
}
```

## 5. 后端集成规范

### 5.1 接口验证要求

#### 5.1.1 消息发送接口验证
- **接口路径**: `POST /im/message/send`
- **验证点**: 确保 `messageType=6`（LOCATION）正常支持
- **存储验证**: `extra` 字段能正确存储位置信息 JSON
- **返回格式**: 遵循现有消息发送返回格式

#### 5.1.2 消息查询接口验证
- **接口路径**: `GET /im/message/list-by-chat`
- **验证点**: 位置消息在消息列表中正确返回
- **字段映射**: extra 字段中的位置信息正确解析

### 5.2 数据库兼容性

#### 5.2.1 表结构验证
```sql
-- 验证消息类型枚举支持
SELECT * FROM im_message_type_enum WHERE type = 6;

-- 测试位置消息插入
INSERT INTO im_messages (chat_id, sender_id, message_type, content, extra)
VALUES ('chat_001', 'user_001', 6, '位置消息', 
  '{"type":"LOCATION","latitude":28.692345,"longitude":115.856789,"name":"江西金控集团","address":"江西省南昌市红谷滩区丰润路","coordinateSystem":"GCJ-02"}');
```

### 5.3 错误处理与降级

#### 5.3.1 API 额度管理
```typescript
// 客户端错误处理
async function handleMapApiError(error: any) {
  if (error.data?.status === 301) {
    // 配额超限
    uni.showModal({
      title: '提示',
      content: '地图服务暂时不可用，免费额度已用完，请联系管理员',
      showCancel: false
    })
    return null
  }
  
  if (error.data?.status === 199) {
    // Key 无效
    uni.showModal({
      title: '提示', 
      content: '地图服务配置异常，请联系管理员',
      showCancel: false
    })
    return null
  }
  
  // 网络错误
  uni.showToast({
    title: '地图服务不可用，请检查网络',
    icon: 'none'
  })
  return null
}
```

## 6. 性能指标与验收标准

### 6.1 性能指标

#### 6.1.1 加载性能
- **位置选择页面**: 首屏加载 < 1 秒
- **地图初始化**: 地图容器可见后 < 800ms 完成初始化
- **搜索响应**: 关键字搜索响应 < 500ms
- **缩略图生成**: 静态地图图片加载 < 1 秒

#### 6.1.2 用户体验
- **触控响应**: 按钮点击响应 < 200ms
- **列表滚动**: 位置列表滚动流畅（60fps）
- **地图交互**: 地图缩放、拖拽响应 < 100ms

### 6.2 功能验收标准

#### 6.2.1 发送流程验收
- [ ] 从对话页面进入位置选择界面
- [ ] 搜索位置关键字并显示结果
- [ ] 选择位置后地图同步更新
- [ ] 确认发送后消息立即显示
- [ ] 位置卡片包含缩略图和详细信息

#### 6.2.2 接收流程验收
- [ ] 接收位置消息正确渲染为卡片
- [ ] 点击卡片打开位置详情页面
- [ ] 详情页面显示完整地图
- [ ] 导航功能正常调用第三方地图

#### 6.2.3 兼容性验收
- [ ] App 端（Android 10+）正常工作
- [ ] App 端（iOS 14+）正常工作
- [ ] H5 端（Chrome/Safari）正常工作
- [ ] 不同网络环境（4G/5G/WiFi）正常工作

### 6.3 错误处理验收
- [ ] API 额度超限时显示正确提示
- [ ] 网络错误时显示友好错误信息
- [ ] API Key 异常时显示配置错误提示
- [ ] 降级方案在异常情况下正常工作

---

> **文档版本**: v3.0.0  
> **创建日期**: 2026-04-02  
> **更新日期**: 2026-04-02  
> **适用项目**: shengyu-im-saas  
> **责任人**: 开发团队  
> **关联文档**: `sql/doc/IM即时通讯架构设计文档-v2.0.md`  
> **遵循规范**: 必须遵守主架构文档的 Long 精度约束和文档维护规则
