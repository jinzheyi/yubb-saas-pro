# IM 即时通讯 - 位置功能开发任务清单 v2.0

## 任务概述

**任务目标**：在对话页面实现"位置"功能，支持用户发送和接收位置消息

**优先级**：高

**预计工期**：8 人天（1.5 周）

**技术选型**：
- 地图 SDK：腾讯地图（免费商用，3 万次/日额度）
- 前端 API：uni.chooseLocation（跨平台）
- 消息类型：LOCATION（type=6）

---

## 开发任务分解

### 阶段一：准备工作（0.5 人天）

#### 任务 1.1：申请腾讯地图 API Key
- **负责人**：后端开发
- **完成时间**：Day 1 上午
- **任务详情**：
  1. 访问 [腾讯地图开放平台](https://lbs.qq.com/)
  2. 注册开发者账号
  3. 创建应用（选择"Web 应用"）
  4. 添加 Key（选择"JavaScript GL API"和"WebService API"）
  5. 配置白名单（开发环境：*；生产环境：正式域名）
- **交付物**：
  - 腾讯地图 API Key
  - Key 配置文档（包含白名单信息）
- **注意事项**：
  - Key 需要妥善保管，不要提交到代码仓库
  - 记录每日调用量，避免超出免费额度

#### 任务 1.2：配置前端环境变量
- **负责人**：前端开发
- **完成时间**：Day 1 下午
- **任务详情**：
  1. 在 `shengyu-ui/shengyu-ui-admin-uniappx/config/` 创建 `map.config.uts`
  2. 配置腾讯地图 API Key
  3. 配置地图相关常量
- **代码示例**：
```typescript
// map.config.uts
export const TENCENT_MAP_KEY = '你的 Key' // 从环境变量读取
export const MAP_CONFIG = {
  defaultZoom: 15,
  maxZoom: 18,
  minZoom: 10,
  searchRadius: 1000 // 搜索半径（米）
}
```

#### 任务 1.3：后端消息存储验证（新增）
- **负责人**：后端开发
- **完成时间**：Day 1 下午
- **任务详情**：
  1. 验证 `im_messages` 表支持 message_type=6（LOCATION）
  2. 验证 extra 字段能存储 JSON 格式位置信息
  3. 测试消息发送接口支持位置消息类型
- **后端接口**：
  - POST `/im/message/send` - 发送位置消息
  - GET `/im/message/list-by-chat` - 获取聊天记录（包含位置消息）
- **存储结构验证**：
  ```sql
  -- 验证消息类型枚举
  SELECT * FROM im_message_type_enum WHERE type = 6;
  
  -- 测试插入位置消息
  INSERT INTO im_messages (chat_id, sender_id, message_type, content, extra)
  VALUES ('chat_001', 'user_001', 6, '位置消息', 
    '{"type":"LOCATION","latitude":28.692345,"longitude":115.856789,"name":"江西金控集团","address":"江西省南昌市红谷滩区丰润路"}');
  ```
- **交付物**：
  - 消息存储验证报告
  - 位置消息测试用例

---

### 阶段二：位置选择页面开发（3 人天）

#### 任务 2.1：创建位置选择页面框架
- **负责人**：前端开发
- **完成时间**：Day 2
- **任务详情**：
  1. 创建文件：`pages/message/location-picker.uvue`
  2. 实现基础布局（搜索框 + 地图 + 列表）
  3. 配置页面路由
- **页面结构**：
```vue
<template>
  <view class="location-picker">
    <!-- 顶部搜索框 -->
    <view class="search-bar">
      <input v-model="keyword" placeholder="请输入关键字搜索位置" />
    </view>
    
    <!-- 地图预览区域 -->
    <view class="map-container">
      <!-- 腾讯地图组件 -->
    </view>
    
    <!-- 位置列表 -->
    <scroll-view class="location-list" scroll-y>
      <view v-for="item in locations" :key="item.id" class="location-item">
        <text class="location-name">{{ item.name }}</text>
        <text class="location-address">{{ item.address }}</text>
      </view>
    </scroll-view>
  </view>
</template>
```

#### 任务 2.2：集成腾讯地图 SDK
- **负责人**：前端开发
- **完成时间**：Day 3 上午
- **任务详情**：
  1. H5 端引入腾讯地图 JS SDK
  2. 初始化地图实例
  3. 实现地图基本功能（缩放、拖拽、标记）
- **代码示例**：
```typescript
// #ifdef H5
import { TENCENT_MAP_KEY } from '../../config/map.config.uts'

let mapInstance: any = null

function initMap() {
  mapInstance = new TMap.Map(document.getElementById('map-container'), {
    center: new TMap.LatLng(28.692345, 115.856789), // 南昌默认坐标
    zoom: 15,
    viewMode: '3D'
  })
}
// #endif
```

#### 任务 2.3：实现位置搜索功能
- **负责人**：前端开发
- **完成时间**：Day 3 下午
- **任务详情**：
  1. 调用腾讯地图搜索 API
  2. 展示搜索结果列表
  3. 实现防抖优化（输入停止 500ms 后搜索）
- **API 调用**：
```typescript
async function searchLocations(keyword: string) {
  const url = `https://apis.map.qq.com/ws/place/v1/search?keyword=${encodeURIComponent(keyword)}&key=${TENCENT_MAP_KEY}`
  const res = await uni.request({ url })
  return res.data.data
}
```

#### 任务 2.4：实现位置选择与确认
- **负责人**：前端开发
- **完成时间**：Day 4 上午
- **任务详情**：
  1. 点击列表项选中位置
  2. 地图移动到选中位置
  3. 右上角确认按钮可用
  4. 返回选中的位置信息
- **返回数据格式**：
```typescript
interface LocationResult {
  name: string      // 位置名称
  address: string   // 详细地址
  latitude: number  // 纬度
  longitude: number // 经度
}
```

---

### 阶段三：消息发送功能（1 人天）

#### 任务 3.1：扩展消息服务
- **负责人**：前端开发
- **完成时间**：Day 4 下午
- **任务详情**：
  1. 在 `message-service.uts` 中添加 `sendLocationMessage` 方法
  2. 构建位置消息 payload
  3. 调用后端消息发送接口
- **代码示例**：
```typescript
async function sendLocationMessage(
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
      address: location.address
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

#### 任务 3.2：在 chat.uvue 中添加位置功能入口
- **负责人**：前端开发
- **完成时间**：Day 4 下午
- **任务详情**：
  1. 在 `featureList` 中已有位置图标（icon: '\uea72'）
  2. 在 `handleFeature` 函数中添加位置处理逻辑
  3. 跳转到位置选择页面
  4. 接收返回的位置信息并发送
- **代码示例**：
```typescript
function handleFeature(item: any) {
  if (item.nameKey === 'chat.features.location') {
    handleLocationFeature()
  }
  // ... 其他功能
}

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

---

### 阶段四：消息渲染优化（1 人天）

#### 任务 4.1：优化位置消息卡片样式
- **负责人**：前端开发
- **完成时间**：Day 5 上午
- **任务详情**：
  1. 现有模板已有基础样式（第 134-140 行）
  2. 添加地图缩略图（使用腾讯地图静态地图 API）
  3. 优化卡片布局和交互效果
- **静态地图 API**：
```typescript
function buildStaticMapUrl(latitude: number, longitude: number): string {
  const baseUrl = 'https://apis.map.qq.com/ws/staticmap/v1/'
  const params = {
    location: `${latitude},${longitude}`,
    zoom: 15,
    size: '280*150',
    scale: 2, // 高清屏
    markers: `M,${latitude},${longitude}`,
    key: TENCENT_MAP_KEY
  }
  return `${baseUrl}?${new URLSearchParams(params).toString()}`
}
```

#### 任务 4.2：实现位置卡片点击交互
- **负责人**：前端开发
- **完成时间**：Day 5 下午
- **任务详情**：
  1. 在 `chat.uvue` 中实现 `handleLocationOpen` 方法
  2. 点击卡片打开位置详情页
  3. 位置详情页展示地图和导航按钮
- **代码示例**：
```typescript
function handleLocationOpen(msg: MessageItem) {
  uni.navigateTo({
    url: `/pages/message/location-detail?latitude=${msg.latitude}&longitude=${msg.longitude}&name=${encodeURIComponent(msg.locationName)}&address=${encodeURIComponent(msg.address)}`
  })
}
```

#### 任务 4.3：创建位置详情页面
- **负责人**：前端开发
- **完成时间**：Day 5 下午
- **任务详情**：
  1. 创建文件：`pages/message/location-detail.uvue`
  2. 展示完整地图
  3. 提供"导航到这里"按钮（调用第三方地图 App）
- **导航功能**：
```typescript
function openNavigation(latitude: number, longitude: number, name: string) {
  uni.showActionSheet({
    itemList: ['腾讯地图', '高德地图', '百度地图'],
    success: (res) => {
      if (res.tapIndex === 0) {
        // 腾讯地图
        uni.navigateTo({
          url: `qqmap://map/navi?location=${latitude},${longitude}&name=${name}`
        })
      } else if (res.tapIndex === 1) {
        // 高德地图
        uni.navigateTo({
          url: `iosamap://navi?latitude=${latitude}&longitude=${longitude}&name=${name}`
        })
      } else if (res.tapIndex === 2) {
        // 百度地图
        uni.navigateTo({
          url: `baidumap://map/navi?location=${latitude},${longitude}&name=${name}`
        })
      }
    }
  })
}
```

---

### 阶段五：后端支持（1 人天）

#### 任务 5.1：验证后端接口支持
- **负责人**：后端开发
- **完成时间**：Day 6 上午
- **任务详情**：
  1. 确认消息发送接口支持 messageType=6
  2. 验证 extra 字段能正确存储位置信息
  3. 测试位置消息的接收和存储
- **测试用例**：
```java
@Test
public void testSendLocationMessage() {
    LocationMessage message = new LocationMessage();
    message.setType("LOCATION");
    message.setLatitude(28.692345);
    message.setLongitude(115.856789);
    message.setName("江西金控集团");
    message.setAddress("江西省南昌市红谷滩区丰润路");
    
    // 调用发送接口
    Result result = imMessageController.sendMessage(message);
    
    // 验证返回结果
    Assert.assertEquals(200, result.getCode());
}
```

#### 任务 5.2：坐标转换工具（可选）
- **负责人**：后端开发
- **完成时间**：Day 6 下午
- **任务详情**：
  1. 创建坐标转换工具类
  2. 支持 GCJ-02 转 WGS-84
  3. 支持 GCJ-02 转百度 BD-09
- **代码示例**：
```java
public class CoordinateConverter {
    /**
     * GCJ-02 转 WGS-84
     */
    public static Coordinate gcj2wgs(double lat, double lon) {
        // 实现转换算法
        return new Coordinate(wgsLat, wgsLon);
    }
    
    /**
     * GCJ-02 转百度 BD-09
     */
    public static Coordinate gcj2bd09(double lat, double lon) {
        // 实现转换算法
        return new Coordinate(bdLat, bdLon);
    }
}
```

---

### 阶段六：联调测试（2 人天）

#### 任务 6.1：功能测试
- **负责人**：测试工程师
- **完成时间**：Day 7 上午
- **测试用例**：
  1. [ ] 从对话页面进入位置选择界面
  2. [ ] 搜索位置关键字
  3. [ ] 选择位置并发送
  4. [ ] 接收位置消息并展示
  5. [ ] 点击位置卡片查看详情
  6. [ ] 使用导航功能
- **Bug 修复**：
  - 前端开发负责修复 UI 问题
  - 后端开发负责修复接口问题

#### 任务 6.2：性能测试
- **负责人**：测试工程师
- **完成时间**：Day 7 下午
- **测试指标**：
  1. [ ] 位置选择页面打开时间 < 1 秒
  2. [ ] 搜索响应时间 < 500ms
  3. [ ] 地图缩略图加载时间 < 1 秒
  4. [ ] 消息发送成功率 > 99%
- **优化建议**：
  - 搜索结果本地缓存
  - 地图资源懒加载
  - CDN 加速

#### 任务 6.3：兼容性测试
- **负责人**：测试工程师
- **完成时间**：Day 8 上午
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

#### 任务 6.4：客户端额度提示测试（简化）
- **负责人**：测试工程师
- **完成时间**：Day 8 上午
- **测试用例**：
  1. [ ] 模拟 API 返回 status=301（配额超限）时客户端正确提示
  2. [ ] 验证用户提示内容："地图服务暂时不可用，免费额度已用完，请联系管理员"
  3. [ ] 验证提示为模态框（不可点击取消）
  4. [ ] 模拟网络错误时显示"地图服务不可用，请检查网络"
  5. [ ] 模拟 API Key 无效时显示"地图服务配置异常，请联系管理员"
- **降级方案验证**：
  - 额度耗尽时无法使用地图搜索功能
  - 额度耗尽时无法预览地图
  - 提示框显示后用户只能点击"确定"
- **说明**：
  - 不做后台额度监控功能
  - 仅测试客户端对 API 返回错误的处理
  - 依赖腾讯地图 API 返回的 status 码

#### 任务 6.5：验收评审
- **负责人**：产品经理
- **完成时间**：Day 8 下午
- **验收标准**：
  1. [ ] 所有功能测试用例通过
  2. [ ] 性能指标达标
  3. [ ] 兼容性测试通过
  4. [ ] UI/UX 符合设计稿
  5. [ ] 无严重 Bug
  6. [ ] 客户端额度提示功能正常
- **交付物**：
  - 测试报告
  - 验收报告
  - 上线清单

---

## 里程碑计划

| 里程碑 | 时间 | 交付物 | 验收标准 |
|--------|------|--------|----------|
| M1：准备工作完成 | Day 1 | API Key、环境配置、后端存储验证 | 可以正常调用腾讯地图 API，后端支持位置消息存储 |
| M2：位置选择页面完成 | Day 4 | location-picker.uvue | 可以搜索、选择、返回位置 |
| M3：消息发送功能完成 | Day 4 | sendLocationMessage | 可以成功发送位置消息 |
| M4：消息渲染完成 | Day 5 | 位置卡片样式、详情页 | 位置消息正确展示和交互 |
| M5：后端支持完成 | Day 6 | 接口验证、坐标转换 | 后端支持位置消息存储和转发 |
| M6：测试验收完成 | Day 8 | 测试报告、验收报告 | 所有测试用例通过（包含客户端额度提示测试） |

---

## 风险评估

### 风险 1：腾讯地图 API 调用失败
- **概率**：低
- **影响**：高
- **应对措施**：
  1. 使用 uni.chooseLocation 作为备用方案
  2. 添加错误重试机制
  3. 降级为纯文本位置信息

### 风险 2：坐标系不兼容
- **概率**：中
- **影响**：中
- **应对措施**：
  1. 统一使用 GCJ-02 坐标系
  2. 提供坐标转换工具
  3. 在消息体中标注坐标系类型

### 风险 3：H5 端地图展示异常
- **概率**：中
- **影响**：中
- **应对措施**：
  1. 优先使用 uni.chooseLocation
  2. H5 端单独适配腾讯地图 JS SDK
  3. 提供降级方案（纯列表选择）

### 风险 4：超出免费额度（简化处理）
- **概率**：低（日活<1 万时）
- **影响**：中
- **应对措施**：
  1. 客户端捕获 API 返回的 status=301（配额超限）错误
  2. 额度耗尽时显示友好提示："地图服务暂时不可用，免费额度已用完，请联系管理员"
  3. 降级方案：无法使用地图搜索和预览功能
  4. 每日 00:00 腾讯地图 API 自动重置额度
  5. 不做后台监控，依赖 API 返回状态码
- **技术说明**：
  - 腾讯地图 API 配额超限返回 `status: 301`
  - 前端无需维护额度计数器
  - 后端无需实现额度监控逻辑

### 风险 5：后端消息存储失败（新增）
- **概率**：低
- **影响**：高
- **应对措施**：
  1. 提前验证 im_messages 表支持 message_type=6
  2. 验证 extra 字段能正确存储 JSON 格式位置信息
  3. 测试消息发送接口支持位置消息类型
  4. 添加消息存储失败的异常处理和日志记录

---

## 资源需求

### 人力资源
- 前端开发：1 人（6 人天）
- 后端开发：1 人（1.5 人天）
- 测试工程师：1 人（1.5 人天）
- 产品经理：0.5 人天（验收）

### 技术资源
- 腾讯地图 API Key（已申请）
- 测试设备（Android/iOS 真机）
- 测试账号（多个用户账号）

### 环境资源
- 开发环境：可以调用腾讯地图 API
- 测试环境：独立部署，配置 API Key
- 生产环境：配置 API Key 和域名白名单

---

## 上线检查清单

### 上线前检查
- [ ] 代码审查通过
- [ ] 所有测试用例通过
- [ ] 性能指标达标
- [ ] 无严重 Bug
- [ ] 产品验收通过
- [ ] 腾讯地图 API Key 已配置到生产环境
- [ ] 域名白名单已添加生产域名
- [ ] 监控告警已配置

### 上线后验证
- [ ] 生产环境功能验证
- [ ] 监控数据正常
- [ ] 用户反馈收集
- [ ] 性能指标监控

---

## 参考资料

- [设计文档](./IM 即时通讯位置功能设计文档-v2.0.md)
- [腾讯地图开放平台](https://lbs.qq.com/)
- [uni-app chooseLocation API](https://uniapp.dcloud.net.cn/api/location/chooseLocation.html)
- [腾讯地图 JavaScript GL API 文档](https://lbs.qq.com/webApi/gljs/gljsOverview/gljsGuide)

---

**文档版本**：v2.0  
**创建日期**：2026-04-02  
**更新日期**：2026-04-02  
**适用项目**：shengyu-im-saas  
**责任人**：开发团队
