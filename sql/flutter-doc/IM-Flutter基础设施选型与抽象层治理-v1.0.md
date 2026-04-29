# IM Flutter 基础设施选型与抽象层治理 v1.0

> 文档日期：2026-04-29  
> 文档定位：第三方基础设施能力的主方案、抽象层和替换边界规则  

---

## 1. 目标

在保证个人开发者成本可控的前提下，定义 Flutter IM 对外部能力的统一治理方式。

核心原则：

- 核心对话与通话业务尽量自研
- 优先完全开源、可自部署、可控方案
- 不能合理自研的能力允许依赖第三方
- 只实现主方案，其余先空实现

---

## 2. 分级规则

### 2.1 A 类：核心自控能力

必须掌握在自己手里：

- IM HTTP 业务接口
- IM WebSocket 协议
- 会话增量同步
- 消息状态机
- 聊天页交互编排
- 通话业务状态机

### 2.2 B 类：优先开源可自部署

优先采用开源主方案：

- WebRTC Flutter SDK
- SFU
- TURN
- 文档转换服务

### 2.3 C 类：允许供应商基础设施

允许依赖第三方：

- 地图底图与 POI
- 移动端离线推送
- 部分系统级通知通道

前提：

- 成本低
- 可稳定使用
- 替换边界清晰

---

## 3. 抽象层规则

### 3.1 必须使用 `adapter / facade`

每一类外部能力都应拆成：

1. domain contract
2. facade
3. provider adapter
4. optional stub adapter

### 3.2 页面层禁止

- 直接 import 第三方 provider SDK
- 直接构造第三方 request object
- 直接处理第三方 callback model

### 3.3 业务层允许感知的只有

- 抽象接口
- 统一结果模型
- 统一错误模型

---

## 4. 当前冻结主方案

### 4.1 音视频

- Flutter SDK：`flutter_webrtc`
- SFU：Janus
- TURN：coturn

### 4.2 离线推送

- iOS：APNs
- Android 国内：聚合推送主方案
- 其余厂商通道：保留空实现

### 4.3 地图与位置

- 当前只实现一个主地图 provider adapter
- 其余 provider 保留空实现

### 4.4 文件预览

- Flutter 原生预览
- 服务端 `open-strategy`
- 服务端转换链路优先
- 嵌入式文档服务仅作保留扩展

---

## 5. 主方案落地策略

1. 优先把抽象接口定义完整
2. 只接入一个主方案 adapter
3. 备选 adapter 只建壳，不落实现
4. 所有 provider 配置从 `core/platform` 或 `core/config` 读取

---

## 6. 空实现策略

### 6.1 允许的空实现

- `NoopPushVendorAdapter`
- `ReservedMapProviderAdapter`
- `ReservedRtcCallKitAdapter`

### 6.2 空实现要求

- 能编译
- 明确返回 unsupported / notConfigured
- 不静默吞错
- 不污染主链路逻辑

---

## 7. 成本控制规则

1. 不为了“理论最全”同时接多家供应商
2. 不为了“企业级想象”把首期复杂度拉满
3. 先做可卖、可维护、可演进的单主方案
4. 备选只保留替换边界

---

## 8. 代码组织建议

```text
core/
  platform/
    push/
      push_facade.dart
      push_provider.dart
      adapters/
    map/
      map_facade.dart
      map_provider.dart
      adapters/
    rtc/
      rtc_facade.dart
      rtc_gateway.dart
      adapters/
```

---

## 9. 验收规则

1. 业务层无供应商 SDK 泄漏
2. 主方案切换不影响页面层
3. 空实现可被注入测试
4. 失败场景有统一错误码或异常类型
