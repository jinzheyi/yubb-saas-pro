# IM 即时通讯 - 位置功能设计补充文档 v2.0

## 一、功能概述

### 1.1 功能描述
在对话页面中添加"位置"功能，用户可以：
- 点击位置图标弹出地图选择界面
- 通过搜索关键字查找目标位置
- 选择位置后以卡片形式发送位置消息
- 接收方点击位置卡片可查看位置详情

### 1.2 UI 交互流程
```
对话页面 → 点击"+"更多 → 点击"位置"图标 
→ 弹出地图选择界面（类似微信）
→ 搜索位置关键字 → 展示位置列表
→ 选择位置 → 确认发送
→ 对话页面显示位置卡片消息
→ 点击卡片 → 查看位置详情（地图预览）
```

## 二、技术方案

### 2.1 地图 SDK 选型（成本优先原则）

#### 推荐方案：腾讯地图（最省钱）
**优势**：
- 个人/中小企业免费商用
- 每日 3 万次免费调用额度
- 无需企业认证和前期费用
- API 集成简单，文档完善
- 提供坐标拾取工具

**免费额度**：
- JavaScript GL API：3 万次/日
- WebService API：3 万次/日
- 超出后按量计费（价格低廉）

#### 备选方案对比

| 服务商 | 免费额度 | 商用费用 | 推荐指数 |
|--------|----------|----------|----------|
| 腾讯地图 | 3 万次/日 | 免费（中小企业） | ⭐⭐⭐⭐⭐ |
| 高德地图 | 10 万次/日 | 5 万/年（认证费） | ⭐⭐⭐ |
| 百度地图 | 30 万次/日 | 5 万/年（认证费） | ⭐⭐⭐ |

**结论**：对于企业级 IM 应用，日活用户<1 万的情况下，腾讯地图完全免费。

### 2.2 技术实现方案

#### 方案 A：使用 uni-app 原生 API（推荐）
```typescript
// 使用 uni.chooseLocation API
uni.chooseLocation({
  success: function (res) {
    // res.name: 位置名称
    // res.address: 详细地址
    // res.latitude: 纬度
    // res.longitude: 经度
    // res.point: 坐标对象
  }
})
```

**优势**：
- 跨平台兼容（H5/App/小程序）
- 无需额外集成 SDK
- 免费使用
- 自动调用平台地图能力

#### 方案 B：集成腾讯地图 JS SDK（H5 端备用）
```html
<!-- 引入腾讯地图 JS SDK -->
<script src="https://map.qq.com/api/gljs?v=1.exp&key=您的 Key"></script>
```

**使用场景**：
- H5 端需要更强大的地图定制能力时
- uni.chooseLocation 无法满足需求时

### 2.3 位置消息数据结构

#### 发送消息结构
```typescript
interface LocationMessage {
  type: 'location' | 6  // 消息类型
  latitude: number      // 纬度（GCJ-02 坐标系）
  longitude: number     // 经度（GCJ-02 坐标系）
  locationName: string  // 位置名称（如：江西金控集团）
  address: string       // 详细地址（如：江西省南昌市红谷滩区丰润路）
  thumbnailUrl?: string // 缩略图 URL（可选，用于地图预览）
}
```

#### 后端存储结构
```sql
-- 消息表 extra 字段存储
{
  "type": "LOCATION",
  "latitude": 28.692345,
  "longitude": 115.856789,
  "name": "江西金控集团",
  "address": "江西省南昌市红谷滩区丰润路",
  "coordinateSystem": "GCJ-02"  // 坐标系标识
}
```

### 2.4 后端消息存储设计

#### 数据库表结构
```sql
-- 消息表 (im_messages)
CREATE TABLE im_messages (
  id BIGINT PRIMARY KEY,
  chat_id VARCHAR(64) NOT NULL,
  sender_id VARCHAR(64) NOT NULL,
  receiver_id VARCHAR(64),
  group_id VARCHAR(64),
  message_type INT NOT NULL,  -- 6 = LOCATION
  content TEXT,
  extra JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_chat_id (chat_id),
  INDEX idx_created_at (created_at)
);
```

#### extra 字段存储规范
```json
{
  "type": "LOCATION",
  "latitude": 28.692345,
  "longitude": 115.856789,
  "name": "江西金控集团",
  "address": "江西省南昌市红谷滩区丰润路",
  "coordinateSystem": "GCJ-02",
  "thumbnailUrl": "https://map.qq.com/api/staticmap?...",
  "createdAt": 1712044800000
}
```

#### 存储优化建议
- 位置坐标使用 DECIMAL(10,6) 精度存储
- 建立地理位置索引加速周边搜索
- 历史位置消息支持归档存储（6 个月后）

### 2.5 API 调用额度监控与提示

#### 简化方案：仅客户端提示

**设计思路**：
- 不做后台管理系统的额度监控功能
- 前端在调用腾讯地图 API 时捕获错误
- 当 API 返回额度超限错误时，直接提示用户

**错误处理逻辑**：
```typescript
// 位置选择页面 - API 调用错误处理
async function searchLocation(keyword: string) {
  try {
    const result = await uni.request({
      url: `https://apis.map.qq.com/ws/place/v1/search`,
      data: {
        keyword,
        key: TENCENT_MAP_KEY
      }
    })
    
    if (result.data.status === 301) {
      // 配额超限
      uni.showModal({
        title: '提示',
        content: '地图服务暂时不可用，免费额度已用完，请联系管理员',
        showCancel: false
      })
      return []
    }
    
    return result.data.data || []
  } catch (error) {
    console.error('[LocationSearch] 搜索失败:', error)
    uni.showToast({
      title: '地图服务不可用',
      icon: 'none'
    })
    return []
  }
}
```

**用户提示场景**：
| 场景 | 提示方式 | 提示内容 |
|------|----------|----------|
| API 返回配额超限 (status=301) | 模态框 | 地图服务暂时不可用，免费额度已用完，请联系管理员 |
| API 调用失败（网络错误） | Toast | 地图服务不可用，请检查网络 |
| API Key 无效 | 模态框 | 地图服务配置异常，请联系管理员 |

**降级方案**：
- 额度耗尽时：无法使用地图搜索和预览功能
- 备用方案：仅显示文本位置信息（手动输入经纬度）
- 或者提示用户稍后重试（每日 00:00 自动重置额度）

**技术说明**：
- 腾讯地图 API 配额超限返回 `status: 301`
- 前端无需维护额度计数器
- 后端无需实现额度监控逻辑
- 简单直接，依赖 API 返回状态码

## 三、UI 设计

### 3.1 位置选择界面

**布局结构**：
```
┌─────────────────────────────────┐
│ ←返回        位置       ✓确定  │
├─────────────────────────────────┤
│ 🔍 请输入关键字搜索位置...      │
├─────────────────────────────────┤
│                                 │
│  [地图预览区域 - 占屏 40%]       │
│                                 │
├─────────────────────────────────┤
│ ● 江西金控集团                  │
│   江西省南昌市红谷滩区丰润路    │
├─────────────────────────────────┤
│ ○ 江西金控集团                  │
│   江西省南昌市红谷滩区雅苑路    │
├─────────────────────────────────┤
│ ○ 江西省金控资本管理有限公司    │
│   江西省南昌市红谷滩区金控大厦  │
└─────────────────────────────────┘
```

**交互说明**：
1. 顶部搜索框：支持位置关键字搜索
2. 地图区域：显示当前选中位置的地图预览
3. 位置列表：展示搜索结果或当前位置周边 POI
4. 单选选中：点击列表项选中位置，地图同步移动
5. 确定按钮：发送选中的位置

### 3.2 位置卡片消息样式

**对话页面展示**：
```
┌─────────────────────────────┐
│ 📍 江西金控集团             │
│ 江西省南昌市红谷滩区丰润路  │
│                             │
│ [地图缩略图 - 静态地图图片]  │
└─────────────────────────────┘
```

**点击交互**：
- 点击卡片 → 打开位置详情页
- 位置详情页展示完整地图和导航按钮

## 四、实现步骤

### 4.1 前端实现

#### Step 1: 创建位置选择页面
文件路径：`shengyu-ui/shengyu-ui-admin-uniappx/pages/message/location-picker.uvue`

**核心功能**：
- 地图展示组件
- 搜索输入框
- 位置列表
- 选中状态管理

#### Step 2: 扩展消息发送功能
在 `chat.uvue` 中：
- 已在 featureList 中配置位置图标（icon: '\uea72'）
- 需要在 handleFeature 函数中添加位置处理逻辑

```typescript
function handleFeature(item: any) {
  if (item.nameKey === 'chat.features.location') {
    handleLocationFeature()
  }
  // ... 其他功能
}

function handleLocationFeature() {
  uni.navigateTo({
    url: '/pages/message/location-picker'
  })
}
```

#### Step 3: 发送位置消息
在 `message-service.uts` 中添加：

```typescript
async function sendLocationMessage(
  chatId: string,
  receiverId: string,
  groupId: string,
  location: LocationMessage
): Promise<void> {
  const payload = {
    chatId,
    receiverId,
    groupId,
    messageType: 6, // LOCATION 类型
    content: JSON.stringify({
      type: 'LOCATION',
      latitude: location.latitude,
      longitude: location.longitude,
      name: location.locationName,
      address: location.address
    })
  }
  // 调用后端 API 发送消息
}
```

#### Step 4: 位置消息渲染
在 `chat.uvue` 中已有位置消息渲染模板（第 134-140 行）：
```vue
<view v-else-if="msg.type === 'location'" class="message-bubble bubble-location">
  <view class="location-info">
    <text class="location-name">{{ msg.locationName }}</text>
    <text class="location-address">{{ msg.address }}</text>
  </view>
  <image class="location-map" src="/static/images/chat/map-placeholder.png" mode="aspectFill" />
</view>
```

需要优化：
- 地图缩略图使用腾讯地图静态地图 API 生成
- 点击事件处理：`handleLocationOpen(msg)`

#### Step 5: 位置详情查看
创建位置详情页面或使用腾讯地图 JS SDK 展示

### 4.2 后端支持

#### API 接口
后端已有消息发送接口，无需额外开发，只需确保：
1. 支持 messageType=6（LOCATION 类型）
2. extra 字段正确存储位置信息

#### 坐标系说明
- 腾讯地图使用 GCJ-02 坐标系
- 如需转换为 WGS-84，后端提供坐标转换工具类

## 五、成本分析

### 5.1 腾讯地图调用量估算

**场景 1：位置选择**
- 每次选择调用 1 次 JavaScript GL API
- 假设日活 1000 人，每人选择 1 次 = 1000 次/日

**场景 2：静态地图缩略图**
- 每条位置消息展示 1 次静态地图图片
- 假设日发送 100 条位置消息 = 100 次/日

**场景 3：位置搜索**
- 每次搜索调用 WebService API
- 假设日搜索 500 次 = 500 次/日

**总计**：约 1600 次/日 << 3 万次/日（免费额度）

**结论**：对于中小企业，腾讯地图完全免费。

### 5.2 开发成本

| 模块 | 工作量（人天） | 说明 |
|------|---------------|------|
| 位置选择页面 | 3 | 包含地图展示、搜索、列表 |
| 消息发送功能 | 1 | 扩展 message-service |
| 消息渲染优化 | 1 | 地图缩略图生成 |
| 位置详情页 | 1 | 地图预览和导航 |
| 联调测试 | 2 | 前后端联调、多端测试 |
| **总计** | **8 人天** | 约 1.5 周 |

## 六、注意事项

### 6.1 隐私合规
- 需要在隐私政策中说明位置信息收集目的
- 获取用户位置权限前需明确告知
- 位置数据仅用于 IM 消息传递，不用于其他商业用途

### 6.2 坐标系处理
- 腾讯地图使用 GCJ-02 坐标系
- 如需在其他地图（如高德、百度）展示，需要坐标转换
- 建议在消息体中明确标注坐标系类型

### 6.3 多端兼容
- App 端：使用 uni.chooseLocation 调用原生地图
- H5 端：使用腾讯地图 JS SDK
- 小程序端：使用小程序原生地图能力

### 6.4 网络优化
- 静态地图缩略图使用 CDN 加速
- 位置搜索结果本地缓存（5 分钟）
- 地图资源懒加载

## 七、验收标准

### 7.1 功能验收
- [ ] 可以从对话页面进入位置选择界面
- [ ] 支持关键字搜索位置
- [ ] 地图预览和位置列表联动
- [ ] 选中位置后能成功发送
- [ ] 位置卡片消息正确展示
- [ ] 点击卡片能查看位置详情

### 7.2 性能验收
- [ ] 位置选择页面打开时间 < 1 秒
- [ ] 搜索响应时间 < 500ms
- [ ] 地图缩略图加载时间 < 1 秒

### 7.3 兼容性验收
- [ ] App 端（Android/iOS）正常工作
- [ ] H5 端正常工作
- [ ] 不同网络环境（4G/5G/WiFi）正常工作

## 八、参考资料

- [腾讯地图开放平台](https://lbs.qq.com/)
- [uni-app chooseLocation API](https://uniapp.dcloud.net.cn/api/location/chooseLocation.html)
- [腾讯地图 JavaScript GL API 文档](https://lbs.qq.com/webApi/gljs/gljsOverview/gljsGuide)
- [企业微信 H5 应用获取地理位置实战](https://blog.csdn.net/weixin_29015483/article/details/159365831)
- [融云 IM 位置消息实现](https://docs.rongcloud.cn/android-imkit/features/location-message)

---

**文档版本**：v2.0  
**更新日期**：2026-04-02  
**适用项目**：shengyu-im-saas  
**责任人**：开发团队
