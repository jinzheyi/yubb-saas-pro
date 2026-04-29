# IM Flutter 地图与位置能力设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 的位置发送、位置查看、地点选择、地图供应商抽象层设计  

---

## 1. 目标

为 Flutter IM 定义位置能力主方案，保证：

- 移动端体验可用
- 接入成本可控
- 供应商可替换
- 位置消息链路清晰

---

## 2. 范围

首期只覆盖：

- 位置选择
- 当前位置查看
- 地图点位展示
- POI 搜索
- 地理编码 / 逆地理编码
- 位置消息发送

先不覆盖：

- 路线规划
- 导航
- 围栏
- 轨迹

---

## 3. 方案结论

### 3.1 不自研地图底图与 POI

地图底图、POI、逆地理编码不适合自研。

### 3.2 首期主方案

- 当前建议主方案：百度地图 Flutter 体系

原因：

- 有官方 Flutter 文档入口
- 地图、定位、POI、地理编码等能力较完整
- 适合国内 IM 位置消息场景

### 3.3 备选方案

- 腾讯地图 adapter
- 其他地图 provider adapter

首期保留空实现即可。

---

## 4. 抽象层设计

```text
core/platform/map/
  map_facade.dart
  map_provider.dart
  map_models.dart
  adapters/
    baidu_map_adapter.dart
    reserved_tencent_map_adapter.dart
```

---

## 5. 统一领域模型

### 5.1 `LocationPoint`

- `latitude`
- `longitude`
- `coordType`

### 5.2 `LocationPreview`

- `title`
- `address`
- `point`
- `snapshotUrl`

### 5.3 `PoiItem`

- `poiId`
- `name`
- `address`
- `city`
- `district`
- `point`

---

## 6. 页面协同

### 6.1 `LocationPickerPage`

职责：

- 获取当前位置
- 关键字搜索
- 展示附近 POI
- 选择后返回 `LocationPreview`

### 6.2 `LocationViewPage`

职责：

- 展示消息中的位置
- 提供外部地图打开入口

---

## 7. `MapFacade` 建议接口

- `initialize()`
- `requestLocationPermission()`
- `getCurrentLocation()`
- `reverseGeocode()`
- `searchPoi()`
- `buildStaticPreview()`
- `openExternalMap()`

---

## 8. 消息模型约定

位置消息内容建议包含：

- `title`
- `address`
- `latitude`
- `longitude`
- `coordType`
- `mapProvider`

规则：

- 页面只依赖标准位置消息结构
- 不透出第三方 SDK 原始模型

---

## 9. 降级策略

### 9.1 无定位权限

- 允许只搜索地点
- 允许手动选择位置

### 9.2 地图 SDK 初始化失败

- 回退为文本地址选择
- 位置消息仍可发送

### 9.3 无法显示内嵌地图

- 展示位置卡片
- 提供外部打开

---

## 10. 首期实现边界

只实现：

- 一个主地图 provider adapter
- 一个位置选择页
- 一个位置查看页
- 位置消息模型与渲染

不实现：

- 多地图供应商切换 UI
- 地图高级运营能力

---

## 11. 验收标准

1. 可稳定选择并发送位置消息
2. 接收方可查看位置
3. 无权限和失败路径可降级
4. 地图供应商 SDK 不泄漏到业务页面层

