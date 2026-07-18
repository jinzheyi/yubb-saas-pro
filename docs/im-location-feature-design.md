# IM 位置功能设计文档

## 1. 功能概述

对标微信"位置"功能，实现以下核心能力：

### 1.1 功能清单

| 功能 | 描述 | 优先级 | 状态 |
|------|------|--------|------|
| 发送当前位置 | 获取GPS定位并发送当前位置 | P0 | ✅ 已实现 |
| 选择位置 | 在地图上选择/搜索位置并发送 | P0 | ✅ 已实现 |
| 地图预览 | 位置选择页面显示地图预览 | P0 | ✅ 已实现 |
| 地图缩略图 | 位置消息气泡中显示地图缩略图 | P0 | ✅ 已实现 |
| 查看位置 | 点击位置消息打开地图详情页 | P1 | ✅ 已实现 |
| 位置详情跳转 | 点击位置消息直接跳转详情页（无弹窗确认） | P1 | ✅ 已实现 |
| 拖动选点 | 拖动地图选择精确位置 | P1 | ✅ 已实现 |
| 附近POI | 显示当前位置附近的兴趣点列表 | P1 | ✅ 已实现 |

### 1.2 微信功能对标

```
微信位置功能流程：
1. 点击"+" → "位置"
2. 进入位置选择页面：
   - 顶部：地图预览（显示当前位置，可拖动）
   - 中间：当前位置信息（可点击发送）
   - 底部：附近POI列表（可点击选择）
   - 顶部搜索框：可搜索位置
3. 点击"发送"：
   - 发送当前位置或选择的位置
4. 聊天页面显示位置消息：
   - 显示位置名称
   - 显示地址
   - 显示地图缩略图
5. 点击位置消息：
   - 打开地图详情页
   - 可导航到第三方地图应用
```

## 2. 技术调研

### 2.1 后端已实现（基于腾讯地图）

#### 2.1.1 配置
```yaml
# application.yaml
im:
  location:
    tencent-lbs-key: AU3BZ-QTLHT-GGJXH-VT5Q3-WLGEZ-JRBTA
    static-map-url: https://apis.map.qq.com/ws/staticmap/v2/
    search:
      enabled: true
      provider: tencent
```

#### 2.1.2 API接口

**位置搜索API**
- 接口：`GET /app-api/im/message/location-search`
- 实现：`ImLocationServiceImpl`
- 功能：
  - 关键词搜索：调用腾讯地图 `https://apis.map.qq.com/ws/place/v1/suggestion`
  - 附近搜索：调用腾讯地图逆地理编码 `https://apis.map.qq.com/ws/geocoder/v1/`

**静态地图URL生成**
- 地址：`https://apis.map.qq.com/ws/staticmap/v2/`
- 参数：
  - `center`: 中心点坐标（lat,lng）
  - `zoom`: 缩放级别（1-18）
  - `size`: 图片尺寸（如 600x300）
  - `markers`: 标记点
  - `key`: 腾讯LBS Key

#### 2.1.3 位置消息协议

```protobuf
// im_message.proto
message LocationMessage {
  double latitude = 1;   // 纬度
  double longitude = 2;  // 经度
  string address = 3;    // 地址描述
}
```

### 2.2 前端已实现

#### 2.2.1 已实现功能
- ✅ 位置搜索（调用后端API）
- ✅ POI列表展示（`LocationSearchItem`）
- ✅ 位置消息发送/接收
- ✅ 位置消息气泡（含地图缩略图）
- ✅ 位置打开服务（`ChatLocationOpenerService`，调用第三方地图）
- ✅ GPS定位获取当前位置（`LocationService`）
- ✅ 地图预览区域（WebView 腾讯地图）
- ✅ 地图缩略图显示（静态地图API）
- ✅ 拖动地图选点（地图拖动事件监听）
- ✅ 位置详情页面（`LocationDetailPage`，含导航/复制/分享功能）

#### 2.2.2 缺失功能
- 无（所有功能已实现）

### 2.3 地图SDK选型

由于后端已使用**腾讯地图**，为保持一致性，前端也使用腾讯地图。

| 方案 | 优点 | 缺点 | 推荐 |
|------|------|------|------|
| 腾讯地图Flutter SDK | 与后端一致，API统一 | 需要申请ApiKey | ✅ 推荐 |
| 高德地图 | 国内覆盖好 | 与后端不一致 | - |
| flutter_map + OSM | 开源免费 | 国内覆盖差，无POI | - |

**推荐方案：腾讯地图Flutter SDK**

#### 2.3.1 Flutter依赖

```yaml
dependencies:
  # 腾讯地图
  tencent_map_flutter: ^1.0.0  # 地图展示
  tencent_location_flutter: ^1.0.0  # 定位服务
  
  # 定位权限
  permission_handler: ^11.0.0
```

#### 2.3.2 腾讯地图ApiKey申请

需要在[腾讯位置服务](https://lbs.qq.com/)申请：
1. Web服务API Key（后端已配置）
2. Android SDK Key
3. iOS SDK Key

## 3. 页面设计

### 3.1 位置选择页面（SelectLocationPage）

```
┌─────────────────────────────────────┐
│ ← 选择位置                    ✓ 发送 │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │                                 │ │
│ │         地图预览区域             │ │
│ │      （显示当前位置标记）         │ │
│ │      （可拖动地图选点）          │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📍 当前位置                      │ │
│ │ 北京市朝阳区xxx街道xxx号          │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ 🔍 搜索位置                         │
├─────────────────────────────────────┤
│ 附近位置                             │
│ ┌─────────────────────────────────┐ │
│ │ 📍 xxx大厦                      │ │
│ │ 北京市朝阳区xxx路xxx号           │ │
│ ├─────────────────────────────────┤ │
│ │ 📍 xxx商场                      │ │
│ │ 北京市朝阳区xxx路xxx号           │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 3.2 位置消息气泡

```
┌──────────────────────┐
│ xxx大厦              │
│ 北京市朝阳区xxx路     │
├──────────────────────┤
│ ┌──────────────────┐ │
│ │                  │ │
│ │   地图缩略图      │ │
│ │   (静态图)       │ │
│ │                  │ │
│ └──────────────────┘ │
└──────────────────────┘
```

### 3.3 位置详情页面

```
┌─────────────────────────────────────┐
│ ← 位置详情                          │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │                                 │ │
│ │         全屏地图                 │ │
│ │      （显示位置标记）            │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ xxx大厦                             │
│ 北京市朝阳区xxx路xxx号              │
│                                     │
│ [导航到此处]  [复制地址]  [分享]     │
└─────────────────────────────────────┘
```

## 4. 实现计划

### 阶段一：基础功能（P0）

#### 4.1 集成腾讯地图SDK
- [x] 申请腾讯地图Android/iOS SDK Key（使用Web API Key：AU3BZ-QTLHT-GGJXH-VT5Q3-WLGEZ-JRBTA）
- [x] 添加依赖到 pubspec.yaml（geolocator、webview_flutter、cached_network_image）
- [x] 配置 Android/iOS ApiKey（AndroidManifest.xml、Info.plist）
- [x] 创建地图服务封装类（MapService、LocationService）

**实现说明**：采用 WebView + 腾讯地图 JavaScript API 方式，而非原生 SDK，避免申请 Android/iOS SDK Key 的复杂流程。

#### 4.2 实现定位功能
- [x] 创建定位服务（LocationService）
- [x] 请求定位权限（Android/iOS 权限配置）
- [x] 获取当前位置坐标（Geolocator）
- [x] 调用后端逆地理编码API获取地址（通过 POI 搜索实现）

#### 4.3 重构位置选择页面
- [x] 添加地图预览区域（WebView 地图组件）
- [x] 显示当前位置标记（中心标记点）
- [x] 实现地图拖动选点（JavaScript 通道通信）
- [x] 联动更新附近POI列表（拖动后重新加载 POI）

#### 4.4 实现地图缩略图
- [x] 调用后端静态地图API生成缩略图URL（MapService.generateThumbnailUrl）
- [x] 在位置消息气泡中显示缩略图（CachedNetworkImage）

### 阶段二：增强功能（P1）

#### 4.5 位置详情页面
- [x] 创建位置详情页面（LocationDetailPage）
- [x] 显示全屏地图（WebView 全屏地图）
- [x] 支持导航到第三方地图（调用系统地图应用）
- [x] 复制地址功能
- [x] 分享位置功能（生成腾讯地图链接）

#### 4.6 优化体验
- [x] 加载状态优化（地图加载指示器）
- [x] 错误处理完善（权限拒绝、服务不可用等场景）
- [ ] 缓存优化（地图缩略图缓存，已通过 CachedNetworkImage 实现）

## 5. 数据模型

### 5.1 位置消息结构

```dart
class LocationSharePayload {
  final String name;        // 位置名称
  final String address;     // 详细地址
  final double latitude;    // 纬度
  final double longitude;   // 经度
  final String provider;    // 地图提供商（tencent）
  final String poiId;       // POI ID
}
```

### 5.2 静态地图URL生成

```dart
// 调用后端API生成静态地图URL
// 后端实现：使用腾讯地图静态图API
String generateStaticMapUrl({
  required double latitude,
  required double longitude,
  int zoom = 15,
  int width = 400,
  int height = 200,
}) {
  // 后端API: GET /app-api/im/message/static-map
  // 参数: lat, lng, zoom, width, height
  return '${AppConfig.apiBaseUrl}/im/message/static-map'
      '?lat=$latitude&lng=$longitude'
      '&zoom=$zoom&width=$width&height=$height';
}
```

## 6. 权限配置

### 6.1 Android

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 6.2 iOS

```xml
<!-- Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要获取您的位置以发送位置信息</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>需要获取您的位置以发送位置信息</string>
```

## 7. 关键代码结构

### 7.1 服务层

```
lib/
├── core/
│   └── platform/
│       ├── location_service.dart          # 定位服务接口
│       └── tencent_location_service.dart  # 腾讯定位实现
├── features/im/chat/
│   ├── application/services/
│   │   └── map_service.dart               # 地图服务（静态图等）
│   └── presentation/pages/
│       ├── select_location_page.dart      # 位置选择页（重构）
│       └── location_detail_page.dart      # 位置详情页（新增）
```

### 7.2 核心类

```dart
// 定位服务
abstract class LocationService {
  Future<LocationResult?> getCurrentLocation();
  Future<String?> reverseGeocode(double lat, double lng);
  Stream<LocationResult?> watchLocation();
}

// 地图服务
class MapService {
  String generateStaticMapUrl(double lat, double lng, {int zoom = 15});
  Future<List<POI>> searchNearby(double lat, double lng, {int radius = 1000});
}
```

## 8. 后端API补充

### 8.1 静态地图API

需要在后端新增静态地图API：

```java
// AppImMessageController
@GetMapping("/message/static-map")
@Operation(summary = "获取位置静态地图")
public CommonResult<String> getStaticMapUrl(
    @RequestParam("lat") Double latitude,
    @RequestParam("lng") Double longitude,
    @RequestParam(value = "zoom", defaultValue = "15") Integer zoom,
    @RequestParam(value = "width", defaultValue = "400") Integer width,
    @RequestParam(value = "height", defaultValue = "200") Integer height
) {
    String url = tencentStaticMapService.generateUrl(latitude, longitude, zoom, width, height);
    return success(url);
}
```

## 9. 风险与注意事项

1. **ApiKey安全**：腾讯地图ApiKey需要妥善保管，避免泄露
2. **权限处理**：需要优雅处理用户拒绝定位权限的情况
3. **网络依赖**：地图和定位需要网络，需要处理离线情况
4. **性能优化**：地图渲染可能影响性能，需要优化
5. **商用授权**：腾讯地图商用需要购买授权
6. **坐标系**：腾讯地图使用GCJ-02坐标系，需要确保前后端一致

## 10. 下一步行动

所有核心功能已实现，后续可考虑以下优化：

1. **性能优化**：
   - 地图缩略图缓存策略优化
   - WebView 内存占用优化

2. **功能增强**：
   - 支持实时位置共享（动态更新位置）
   - 支持路线规划功能

3. **体验优化**：
   - 离线地图支持
   - 更精细的定位精度控制

---

**文档版本**：v3.0
**创建日期**：2026-07-15
**更新日期**：2026-07-15
**状态**：✅ 已完成实现
