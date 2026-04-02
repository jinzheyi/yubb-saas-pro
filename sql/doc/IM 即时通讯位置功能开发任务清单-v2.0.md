# IM 即时通讯 - 位置功能开发任务清单 v3.0

> **文档版本**: v3.0.0  
> **创建日期**: 2026-04-02  
> **更新日期**: 2026-04-02  
> **项目**: 圣钰 SaaS Pro - IM 位置功能  
> **技术栈**: uni-app x + UTS + 腾讯地图 API  
> **预计工期**: 6 人天（1 周）  
> **优先级**: 高  
> **关联文档**: `sql/doc/IM即时通讯架构设计文档-v2.0.md`  
> **遵循规范**: 必须遵守主架构文档的 Long 精度约束和文档维护规则

---

## 任务概述

### 核心目标
实现企业 IM 位置共享功能，支持用户发送和接收位置消息，对标企业微信位置功能体验。

### 闭环功能范围
- ✅ 位置选择与发送
- ✅ 位置消息接收与展示
- ✅ 位置详情查看与导航
- ❌ 实时位置共享（明确排除）
- ❌ 位置历史记录（明确排除）
- ❌ 位置收藏功能（明确排除）

### 技术约束
- **UTS 强类型**: 所有变量必须初始化，条件语句必须 boolean
- **ID 字段**: 所有 ID 字段使用 string 类型，禁止 number 转换（遵循主架构文档 2.3 节 Long 精度约束）
- **坐标系**: 统一使用 GCJ-02 坐标系
- **API 限制**: 腾讯地图 API 免费额度 3 万次/日
- **消息类型**: 使用 `messageType = 6`（LOCATION），遵循主架构文档 6.4.4 节 Schema 冻结要求
- **权威来源**: 必须遵循主架构文档 2.3.1 节文档维护规则，以 `AppIm*Controller` 路由为权威

---

## 开发任务分解

### 阶段一：环境准备与验证（0.5 人天）

#### 任务 1.1：腾讯地图 API Key 配置
**负责人**: 后端开发  
**完成时间**: Day 1 上午  
**优先级**: 高

**具体步骤**：
1. 访问 [腾讯地图开放平台](https://lbs.qq.com/)
2. 创建应用（选择"Web 应用"）
3. 添加 Key（选择"JavaScript GL API"和"WebService API"）
4. 配置白名单（开发环境：*；生产环境：正式域名）
5. 在项目中创建配置文件

**交付物**：
- 腾讯地图 API Key
- `shengyu-ui/shengyu-ui-admin-uniappx/config/map.config.uts` 配置文件

**配置文件模板**：
```typescript
// map.config.uts
export const TENCENT_MAP_KEY = 'your-api-key' // 从环境变量读取
export const MAP_CONFIG = {
  defaultZoom: 15,
  maxZoom: 18,
  minZoom: 10,
  searchRadius: 1000, // 搜索半径（米）
  staticMapSize: '280*150', // 静态地图尺寸
  staticMapScale: 2 // 高清屏适配
}
```

#### 任务 1.2：后端接口兼容性验证
**负责人**: 后端开发  
**完成时间**: Day 1 上午  
**优先级**: 高

**验证步骤**：
1. 验证 `im_messages` 表支持 `message_type=6`（LOCATION）
2. 验证 `extra` 字段能存储 JSON 格式位置信息
3. 测试消息发送接口支持位置消息类型
4. 验证 Long 字段序列化为 string（遵循架构规范 2.3 节）
5. 确认 `AppImMessageController` 路径：`POST /system/im/message/send`

**SQL 验证脚本**：
```sql
-- 验证消息类型枚举
SELECT * FROM im_message_type_enum WHERE type = 6;

-- 测试插入位置消息
INSERT INTO im_messages (chat_id, sender_id, message_type, content, extra)
VALUES ('chat_001', 'user_001', 6, '位置消息', 
  '{"type":"LOCATION","latitude":28.692345,"longitude":115.856789,"name":"江西金控集团","address":"江西省南昌市红谷滩区丰润路","coordinateSystem":"GCJ-02"}');

-- 验证查询
SELECT * FROM im_messages WHERE message_type = 6;
```

**交付物**：
- 后端接口验证报告
- 位置消息测试用例
- 确认 `AppImMessageController` 支持 messageType=6

#### 任务 1.3：前端路由配置
**负责人**: 前端开发  
**完成时间**: Day 1 下午  
**优先级**: 高

**实施步骤**：
1. 在 `pages.json` 中注册新页面
2. 配置页面样式和导航栏
3. 验证路由跳转正常

**pages.json 配置**：
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

### 阶段二：位置选择页面开发（2.5 人天）

#### 任务 2.1：位置选择页面基础框架
**负责人**: 前端开发  
**完成时间**: Day 2  
**优先级**: 高

**实施步骤**：
1. 创建 `pages/message/location-picker.uvue` 文件
2. 实现基础布局（搜索框 + 地图容器 + 位置列表）
3. 添加页面生命周期管理
4. 实现基础样式和响应式布局

**核心模板结构**：
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

<script setup lang="uts">
// 页面状态管理
import { ref, onMounted, onUnmounted } from 'vue'

// 响应式变量
const keyword = ref<string>('')
const locations = ref<LocationResult[]>([])
const selectedIndex = ref<number>(-1)
const mapInstance = ref<any>(null)

// 页面生命周期
onMounted(() => {
  initPage()
})

onUnmounted(() => {
  cleanup()
})
</script>
```

#### 任务 2.2：腾讯地图 SDK 集成
**负责人**: 前端开发  
**完成时间**: Day 2 下午  
**优先级**: 高

**实施步骤**：
1. H5 端引入腾讯地图 JS SDK
2. 初始化地图实例
3. 实现地图基本功能（缩放、拖拽、标记）
4. 添加地图懒加载优化

**地图初始化代码**：
```typescript
// #ifdef H5
import { TENCENT_MAP_KEY } from '../../config/map.config.uts'

function initTencentMap() {
  // 懒加载：地图容器进入视口后初始化
  const mapObserver = uni.createIntersectionObserver()
  mapObserver.observe('.map-container', {
    thresholds: [0.1]
  }).then((res) => {
    if (res.intersectionRatio > 0) {
      createMapInstance()
    }
  })
}

function createMapInstance() {
  const container = document.getElementById('map-container')
  if (!container) return
  
  mapInstance.value = new TMap.Map(container, {
    center: new TMap.LatLng(28.692345, 115.856789), // 南昌默认坐标
    zoom: MAP_CONFIG.defaultZoom,
    viewMode: '2D'
  })
}
// #endif

// #ifdef APP-PLUS
// App 端使用 uni.chooseLocation 作为备用方案
function initAppLocation() {
  // App 端地图初始化逻辑
}
// #endif
```

#### 任务 2.3：位置搜索功能实现
**负责人**: 前端开发  
**完成时间**: Day 3 上午  
**优先级**: 高

**实施步骤**：
1. 实现搜索防抖优化
2. 调用腾讯地图搜索 API
3. 处理搜索结果和错误
4. 实现搜索结果缓存

**搜索功能实现**：
```typescript
// 搜索防抖
let searchTimer: number = 0

function onSearchInput() {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    if (keyword.value.trim()) {
      searchLocations(keyword.value.trim())
    }
  }, 500) // 500ms 防抖
}

// 位置搜索
async function searchLocations(keyword: string): Promise<void> {
  try {
    // 检查缓存
    const cacheKey = `search_${keyword}`
    const cached = uni.getStorageSync(cacheKey)
    if (cached && Date.now() - cached.timestamp < 300000) { // 5 分钟缓存
      locations.value = cached.data
      return
    }
    
    // 调用腾讯地图 API
    const url = `https://apis.map.qq.com/ws/place/v1/search`
    const res = await uni.request({
      url,
      data: {
        keyword,
        key: TENCENT_MAP_KEY,
        boundary: 'region(南昌,0)'
      }
    })
    
    if (res.data.status === 301) {
      // 配额超限
      handleQuotaExceeded()
      return
    }
    
    if (res.data.status === 0 && res.data.data) {
      const results = res.data.data.map((item: any) => ({
        id: item.id,
        name: item.title,
        address: item.address,
        latitude: item.location.lat,
        longitude: item.location.lng
      }))
      
      locations.value = results
      
      // 缓存结果
      uni.setStorageSync(cacheKey, {
        data: results,
        timestamp: Date.now()
      })
    }
  } catch (error) {
    console.error('[LocationSearch] 搜索失败:', error)
    uni.showToast({
      title: '搜索失败，请重试',
      icon: 'none'
    })
  }
}
```

#### 任务 2.4：位置选择与确认功能
**负责人**: 前端开发  
**完成时间**: Day 3 下午  
**优先级**: 高

**实施步骤**：
1. 实现位置列表选择逻辑
2. 地图中心点同步更新
3. 确认按钮状态管理
4. 返回选中位置数据

**选择功能实现**：
```typescript
// 选择位置
function selectLocation(index: number) {
  selectedIndex.value = index
  const location = locations.value[index]
  
  // 更新地图中心点
  if (mapInstance.value && location) {
    mapInstance.value.setCenter(new TMap.LatLng(
      location.latitude,
      location.longitude
    ))
  }
}

// 确认选择
function confirmLocation() {
  if (selectedIndex.value >= 0) {
    const selected = locations.value[selectedIndex.value]
    
    // 通过事件总线返回结果
    const eventChannel = getOpenerEventChannel()
    eventChannel.emit('locationSelected', {
      name: selected.name,
      address: selected.address,
      latitude: selected.latitude,
      longitude: selected.longitude
    })
    
    // 返回上一页
    uni.navigateBack()
  } else {
    uni.showToast({
      title: '请先选择位置',
      icon: 'none'
    })
  }
}

// 页面初始化
function initPage() {
  // 初始化地图
  initTencentMap()
  
  // 获取当前位置
  getCurrentLocation()
}

// 获取当前位置
async function getCurrentLocation() {
  try {
    const res = await uni.getLocation({
      type: 'gcj02'
    })
    
    if (mapInstance.value) {
      mapInstance.value.setCenter(new TMap.LatLng(
        res.latitude,
        res.longitude
      ))
    }
  } catch (error) {
    console.error('[Location] 获取当前位置失败:', error)
  }
}
```

### 阶段三：消息发送与集成（1.5 人天）

#### 任务 3.1：位置服务层创建
**负责人**: 前端开发  
**完成时间**: Day 4 上午  
**优先级**: 高

**实施步骤**：
1. 创建 `services/location-service.uts` 文件
2. 实现位置搜索 API 封装
3. 实现静态地图 URL 生成
4. 添加错误处理和降级方案

**位置服务实现**：
```typescript
// services/location-service.uts
import { TENCENT_MAP_KEY, MAP_CONFIG } from '../config/map.config.uts'

// 位置结果接口
export interface LocationResult {
  name: string
  address: string
  latitude: number
  longitude: number
}

// 位置搜索
export async function searchLocations(keyword: string): Promise<LocationResult[]> {
  // 实现搜索逻辑（从 location-picker.uvue 移植）
}

// 生成静态地图 URL
export function buildStaticMapUrl(latitude: number, longitude: number): string {
  const baseUrl = 'https://apis.map.qq.com/ws/staticmap/v1/'
  const params = {
    location: `${latitude},${longitude}`,
    zoom: MAP_CONFIG.defaultZoom,
    size: MAP_CONFIG.staticMapSize,
    scale: MAP_CONFIG.staticMapScale,
    markers: `M,${latitude},${longitude}`,
    key: TENCENT_MAP_KEY,
    format: 'webp' // 使用 WebP 格式优化
  }
  return `${baseUrl}?${new URLSearchParams(params).toString()}`
}

// API 错误处理
export function handleMapApiError(error: any): boolean {
  if (error.data?.status === 301) {
    // 配额超限
    uni.showModal({
      title: '提示',
      content: '地图服务暂时不可用，免费额度已用完，请联系管理员',
      showCancel: false
    })
    return false
  }
  
  if (error.data?.status === 199) {
    // Key 无效
    uni.showModal({
      title: '提示',
      content: '地图服务配置异常，请联系管理员',
      showCancel: false
    })
    return false
  }
  
  return true // 继续处理
}
```

#### 任务 3.2：消息服务扩展
**负责人**: 前端开发  
**完成时间**: Day 4 上午  
**优先级**: 高

**实施步骤**：
1. 在 `services/message-service.uts` 中添加位置消息发送方法
2. 构建符合后端接口要求的位置消息 payload
3. 遵循 UTS 强类型规范和 ID 字段 string 约束

**消息服务扩展**：
```typescript
// services/message-service.uts
import type { LocationResult } from './location-service.uts'

// 发送位置消息
export async function sendLocationMessage(
  chatId: string,        // string 类型，遵循架构规范 2.3 节 Long 精度约束
  receiverId: string,    // string 类型
  groupId: string,       // string 类型
  location: LocationResult
): Promise<void> {
  const payload = {
    chatId,               // string 类型
    receiverId,           // string 类型
    groupId,              // string 类型
    messageType: 6,        // LOCATION 类型（遵循架构文档 6.4.4 节 Schema）
    content: JSON.stringify({
      type: 'LOCATION',
      latitude: location.latitude,
      longitude: location.longitude,
      name: location.name,
      address: location.address,
      coordinateSystem: 'GCJ-02'
    }),
    extra: JSON.stringify({
      coordinateSystem: 'GCJ-02',
      thumbnailUrl: locationService.buildStaticMapUrl(
        location.latitude,
        location.longitude
      )
    })
  }
  
  try {
    // 调用权威接口：POST /system/im/message/send（AppImMessageController）
    await request({
      url: '/system/im/message/send',
      method: 'POST',
      data: payload
    })
  } catch (error) {
    console.error('[MessageService] 发送位置消息失败:', error)
    throw error
  }
}
```

#### 任务 3.3：聊天页面功能集成
**负责人**: 前端开发  
**完成时间**: Day 4 下午  
**优先级**: 高

**实施步骤**：
1. 在 `pages/message/chat.uvue` 中添加位置功能处理
2. 实现位置选择页面导航和数据接收
3. 优化位置消息渲染模板
4. 添加位置卡片点击交互

**聊天页面集成**：
```typescript
// pages/message/chat.uvue
import { messageService } from '../../services/message-service.uts'
import type { LocationResult } from '../../services/location-service.uts'

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
      uni.showLoading({ title: '发送中...' })
      
      await messageService.sendLocationMessage(
        chatId.value,        // string 类型
        getReceiverIdForMessage(),
        getGroupIdForMessage(),
        location
      )
      
      uni.hideLoading()
      scrollToBottom()
      
      uni.showToast({
        title: '发送成功',
        icon: 'success'
      })
    }
  } catch (e) {
    uni.hideLoading()
    console.error('[Chat] 发送位置消息失败:', e)
    uni.showToast({ 
      title: '发送失败', 
      icon: 'none' 
    })
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

// 位置消息渲染优化（第 134-140 行）
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

### 阶段四：位置详情与优化（1 人天）

#### 任务 4.1：位置详情页面开发
**负责人**: 前端开发  
**完成时间**: Day 5 上午  
**优先级**: 高

**实施步骤**：
1. 创建 `pages/message/location-detail.uvue` 文件
2. 实现完整地图展示
3. 添加位置信息显示
4. 集成第三方地图导航功能

**位置详情页面实现**：
```vue
<template>
  <view class="location-detail">
    <!-- 位置信息 -->
    <view class="location-info">
      <text class="location-name">{{ locationName }}</text>
      <text class="location-address">{{ address }}</text>
    </view>
    
    <!-- 地图容器 -->
    <view class="map-container" id="detail-map-container">
      <!-- 腾讯地图实例 -->
    </view>
    
    <!-- 导航按钮 -->
    <view class="action-buttons">
      <button class="nav-btn" @tap="openNavigation">
        🧭 导航到这里
      </button>
    </view>
  </view>
</template>

<script setup lang="uts">
import { ref, onMounted, onUnmounted } from 'vue'

// 页面参数
const locationName = ref<string>('')
const address = ref<string>('')
const latitude = ref<number>(0)
const longitude = ref<number>(0)
const mapInstance = ref<any>(null)

// 页面加载
onMounted(() => {
  loadPageParams()
  initDetailMap()
})

// 加载页面参数
function loadPageParams() {
  const pages = getCurrentPages()
  const currentPage = pages[pages.length - 1]
  const options = currentPage.options
  
  locationName.value = options.name || ''
  address.value = options.address || ''
  latitude.value = Number(options.latitude) || 0
  longitude.value = Number(options.longitude) || 0
}

// 初始化详情地图
function initDetailMap() {
  // #ifdef H5
  const container = document.getElementById('detail-map-container')
  if (container && latitude.value && longitude.value) {
    mapInstance.value = new TMap.Map(container, {
      center: new TMap.LatLng(latitude.value, longitude.value),
      zoom: 16,
      viewMode: '2D'
    })
    
    // 添加标记
    new TMap.MultiMarker({
      map: mapInstance.value,
      styles: {
        marker: new TMap.MarkerStyle({
          width: 25,
          height: 35,
          anchor: { x: 16, y: 32 }
        })
      },
      geometries: [{
        id: 'location',
        styleId: 'marker',
        position: new TMap.LatLng(latitude.value, longitude.value),
        properties: {
          title: locationName.value
        }
      }]
    })
  }
  // #endif
}

// 打开导航
function openNavigation() {
  uni.showActionSheet({
    itemList: ['腾讯地图', '高德地图', '百度地图'],
    success: (res) => {
      const lat = latitude.value
      const lng = longitude.value
      const name = locationName.value
      
      if (res.tapIndex === 0) {
        // 腾讯地图
        uni.navigateTo({
          url: `qqmap://map/navi?location=${lat},${lng}&name=${name}`
        })
      } else if (res.tapIndex === 1) {
        // 高德地图
        uni.navigateTo({
          url: `iosamap://navi?latitude=${lat}&longitude=${lng}&name=${name}`
        })
      } else if (res.tapIndex === 2) {
        // 百度地图
        uni.navigateTo({
          url: `baidumap://map/navi?location=${lat},${lng}&name=${name}`
        })
      }
    }
  })
}
</script>
```

#### 任务 4.2：性能优化实施
**负责人**: 前端开发  
**完成时间**: Day 5 下午  
**优先级**: 中

**实施步骤**：
1. 实现地图懒加载优化
2. 添加搜索结果缓存机制
3. 优化静态地图加载
4. 添加内存管理和清理

**性能优化代码**：
```typescript
// 地图懒加载优化
function initLazyLoading() {
  const mapObserver = uni.createIntersectionObserver()
  mapObserver.observe('.map-container', {
    thresholds: [0.1]
  }).then((res) => {
    if (res.intersectionRatio > 0 && !mapInstance.value) {
      createMapInstance()
    }
  })
}

// 搜索结果缓存优化
function getCachedSearchResult(keyword: string): LocationResult[] | null {
  const cacheKey = `search_${keyword}`
  const cached = uni.getStorageSync(cacheKey)
  
  if (cached && Date.now() - cached.timestamp < 300000) { // 5 分钟缓存
    return cached.data
  }
  
  return null
}

function cacheSearchResult(keyword: string, data: LocationResult[]) {
  const cacheKey = `search_${keyword}`
  uni.setStorageSync(cacheKey, {
    data,
    timestamp: Date.now()
  })
}

// 内存管理
function cleanup() {
  // 清理地图实例
  if (mapInstance.value) {
    mapInstance.value.destroy()
    mapInstance.value = null
  }
  
  // 清理定时器
  if (searchTimer) {
    clearTimeout(searchTimer)
    searchTimer = 0
  }
  
  // 清理观察器
  if (mapObserver) {
    mapObserver.disconnect()
  }
}
```

---

### 阶段五：测试与验收（1 人天）

#### 任务 5.1：功能测试
**负责人**: 测试工程师  
**完成时间**: Day 6 上午  
**优先级**: 高

**测试用例**：
1. [ ] 从对话页面进入位置选择界面
2. [ ] 搜索位置关键字并显示结果
3. [ ] 选择位置后地图同步更新
4. [ ] 确认发送后消息立即显示
5. [ ] 位置卡片包含缩略图和详细信息
6. [ ] 接收位置消息正确渲染为卡片
7. [ ] 点击卡片打开位置详情页面
8. [ ] 详情页面显示完整地图
9. [ ] 导航功能正常调用第三方地图

**自动化测试脚本**：
```typescript
// 位置功能自动化测试
export async function testLocationFeature() {
  try {
    // 1. 进入位置选择页面
    const location = await navigateToLocationPicker()
    console.log('✅ 位置选择页面导航成功')
    
    // 2. 模拟位置选择
    const mockLocation = {
      name: '江西金控集团',
      address: '江西省南昌市红谷滩区丰润路',
      latitude: 28.692345,
      longitude: 115.856789
    }
    
    // 3. 发送位置消息
    await messageService.sendLocationMessage(
      'test_chat_id',
      'test_receiver_id',
      'test_group_id',
      mockLocation
    )
    console.log('✅ 位置消息发送成功')
    
    // 4. 验证消息渲染
    const messages = await getChatMessages('test_chat_id')
    const locationMsg = messages.find(msg => msg.type === 'location')
    
    if (locationMsg) {
      console.log('✅ 位置消息渲染成功')
    } else {
      throw new Error('位置消息未找到')
    }
    
    return true
  } catch (error) {
    console.error('❌ 位置功能测试失败:', error)
    return false
  }
}
```

#### 任务 5.2：性能测试
**负责人**: 测试工程师  
**完成时间**: Day 6 下午  
**优先级**: 中

**性能指标测试**：
1. [ ] 位置选择页面打开时间 < 1 秒
2. [ ] 搜索响应时间 < 500ms
3. [ ] 地图缩略图加载时间 < 1 秒
4. [ ] 消息发送成功率 > 99%
5. [ ] 内存使用量稳定（无内存泄漏）

**性能测试脚本**：
```typescript
// 性能测试工具
export class LocationPerformanceTest {
  // 测试页面加载性能
  static async testPageLoadPerformance(): Promise<boolean> {
    const startTime = Date.now()
    
    await navigateToLocationPicker()
    
    const endTime = Date.now()
    const loadTime = endTime - startTime
    
    console.log(`位置选择页面加载时间: ${loadTime}ms`)
    return loadTime < 1000 // 小于 1 秒
  }
  
  // 测试搜索性能
  static async testSearchPerformance(): Promise<boolean> {
    const startTime = Date.now()
    
    await searchLocations('江西金控集团')
    
    const endTime = Date.now()
    const searchTime = endTime - startTime
    
    console.log(`搜索响应时间: ${searchTime}ms`)
    return searchTime < 500 // 小于 500ms
  }
  
  // 测试地图加载性能
  static async testMapLoadPerformance(): Promise<boolean> {
    const startTime = Date.now()
    
    const mapUrl = locationService.buildStaticMapUrl(28.692345, 115.856789)
    
    const endTime = Date.now()
    const loadTime = endTime - startTime
    
    console.log(`静态地图加载时间: ${loadTime}ms`)
    return loadTime < 1000 // 小于 1 秒
  }
}
```

#### 任务 5.3：兼容性测试
**负责人**: 测试工程师  
**完成时间**: Day 6 下午  
**优先级**: 中

**测试平台**：
1. [ ] App 端（Android 10+）
2. [ ] App 端（iOS 14+）
3. [ ] H5 端（Chrome）
4. [ ] H5 端（Safari）
5. [ ] H5 端（微信内置浏览器）

**测试网络环境**：
1. [ ] 4G 网络
2. [ ] 5G 网络
3. [ ] WiFi
4. [ ] 弱网环境（2G/3G）

#### 任务 5.4：错误处理测试
**负责人**: 测试工程师  
**完成时间**: Day 6 下午  
**优先级**: 中

**错误场景测试**：
1. [ ] API 返回配额超限 (status=301) 时客户端正确提示
2. [ ] 验证用户提示内容："地图服务暂时不可用，免费额度已用完，请联系管理员"
3. [ ] 验证提示为模态框（不可点击取消）
4. [ ] 模拟网络错误时显示"地图服务不可用，请检查网络"
5. [ ] 模拟 API Key 无效时显示"地图服务配置异常，请联系管理员"
6. [ ] 验证降级方案在异常情况下正常工作

---

## 里程碑计划

| 里程碑 | 时间 | 交付物 | 验收标准 | 责任人 |
|--------|------|--------|----------|--------|
| M1：环境准备完成 | Day 1 | API Key 配置、后端验证、路由配置 | 可以正常调用腾讯地图 API，后端支持位置消息存储 | 后端+前端 |
| M2：位置选择页面完成 | Day 3 | location-picker.uvue | 可以搜索、选择、返回位置，地图交互正常 | 前端 |
| M3：消息发送功能完成 | Day 4 | 位置服务、消息服务扩展 | 可以成功发送位置消息，聊天页面集成完成 | 前端 |
| M4：位置详情页面完成 | Day 5 | location-detail.uvue | 可以查看位置详情，导航功能正常 | 前端 |
| M5：测试验收完成 | Day 6 | 测试报告、性能报告 | 所有测试用例通过，性能指标达标 | 测试 |

---

## 风险评估与应对

### 风险 1：腾讯地图 API 调用失败
- **概率**: 低
- **影响**: 高
- **应对措施**:
  1. 使用 uni.chooseLocation 作为备用方案
  2. 添加错误重试机制
  3. 降级为纯文本位置信息

### 风险 2：API 额度超限
- **概率**: 低（日活<1 万时）
- **影响**: 中
- **应对措施**:
  1. 客户端捕获 API 返回的 status=301 错误
  2. 额度耗尽时显示友好提示
  3. 依赖 API 返回状态码，不做后台监控

### 风险 3：UTS 类型约束违反
- **概率**: 中
- **影响**: 高
- **应对措施**:
  1. 严格遵循 UTS 强类型规范
  2. 所有 ID 字段使用 string 类型
  3. 条件语句必须使用 boolean 类型

### 风险 4：性能不达标
- **概率**: 中
- **影响**: 中
- **应对措施**:
  1. 实施地图懒加载和缓存优化
  2. 使用 WebP 格式优化图片加载
  3. 添加内存管理和清理机制

---

## 资源需求

### 人力资源
- **前端开发**: 1 人（4 人天）
- **后端开发**: 0.5 人天（验证和配置）
- **测试工程师**: 1 人（1.5 人天）
- **总计**: 6 人天

### 技术资源
- **腾讯地图 API Key**: 需申请和配置
- **测试设备**: Android/iOS 真机
- **测试账号**: 多个用户账号

### 环境资源
- **开发环境**: 可以调用腾讯地图 API
- **测试环境**: 独立部署，配置 API Key
- **生产环境**: 配置 API Key 和域名白名单

---

## 上线检查清单

### 代码质量检查
- [ ] 代码审查通过
- [ ] UTS 类型检查通过
- [ ] 性能测试通过
- [ ] 无严重 Bug

### 功能验收检查
- [ ] 所有功能测试用例通过
- [ ] 性能指标达标
- [ ] 兼容性测试通过
- [ ] 错误处理测试通过

### 配置检查
- [ ] 腾讯地图 API Key 已配置到生产环境
- [ ] 域名白名单已添加生产域名
- [ ] pages.json 路由配置正确
- [ ] 监控告警已配置

### 上线后验证
- [ ] 生产环境功能验证
- [ ] 监控数据正常
- [ ] 用户反馈收集
- [ ] 性能指标监控

---

## 关键约束与规范

### 主架构文档约束（必须遵守）

#### Long 精度约束（架构文档 2.3 节）
- 所有涉及 ID / 序列号的 `Long` 字段（`messageId`、`chatId`、`groupId`、`userId`、`tenantId` 等），在 **前端与 JSON 传输层必须按 `string` 处理**
- 禁止按 JS `number` 持久化或参与去重/索引
- 后端 Response VO 中，所有 `Long` 字段必须使用 `@JsonSerialize(using = ToStringSerializer.class)` 输出为字符串

#### 文档维护规则（架构文档 2.3.1 节）
- **权威来源优先级**（从高到低）：
  - module-system 的 Controller 路由（`AppIm*Controller`）
  - uniappx 的 `api/*.uts`（端侧权威调用口径）
  - uniappx 的 `services/*.uts`（只允许做缓存/聚合，不允许自维护 URL）
- 任一接口/字段在文档中出现时，必须同时给出：
  - 后端路由（URL + Method + 入参形态）
  - 端侧唯一调用点（`api/*.uts` 的函数名）
  - 关键不变式

#### 消息类型 Schema（架构文档 6.4.4 节）
- `LOCATION` 消息类型冻结 Schema：
  - `lat: number` / `lng: number`
  - `address: string`
  - `name?: string`（POI 名称）
- 新增字段只能"可选追加"，不得改名/改语义
- 端侧必须忽略未知字段

### UTS 强类型约束
- 所有变量必须初始化（可用 null）
- 条件语句必须使用 boolean 类型
- 禁止使用 undefined
- Map/Set key 必须使用 string

### ID 字段约束
- 所有 ID 字段（chatId、userId、groupId 等）使用 string 类型
- 禁止使用 Number、parseInt、+id 转换
- 请求/响应/路由/storage 全链路 string 化

### 性能约束
- 位置选择页面加载 < 1 秒
- 搜索响应 < 500ms
- 地图缩略图加载 < 1 秒
- 内存使用稳定，无泄漏

---

**文档版本**: v3.0.0  
**创建日期**: 2026-04-02  
**更新日期**: 2026-04-02  
**适用项目**: shengyu-im-saas  
**责任人**: 开发团队
