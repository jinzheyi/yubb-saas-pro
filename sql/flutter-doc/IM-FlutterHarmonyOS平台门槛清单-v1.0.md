# IM Flutter HarmonyOS 平台门槛清单 v1.0

> 文档日期：2026-04-29  
> 文档定位：HarmonyOS 作为低于 Web 优先级的正式目标时的跟随门槛与最小差异控制清单

---

## 1. 目标

HarmonyOS 当前不是首批最高优先级平台，但也不是“完全不管”的保留位。

本文件定义：

1. HarmonyOS 何时进入实现
2. 进入实现时必须遵守什么边界
3. 如何避免为了兼容 HarmonyOS 反向污染主工程

---

## 2. 平台定位

当前优先顺序冻结为：

1. Android
2. iOS
3. OpenHarmony
4. Windows
5. macOS
6. Web
7. HarmonyOS

因此 HarmonyOS 的推进原则是：

1. 先跟随 Android / iOS / OpenHarmony / Desktop / Web 的主干方案
2. 不单独抢占首轮核心资源
3. 只有在主干已稳定后才进入独立验收

---

## 3. 必须满足的前置条件

HarmonyOS 要进入独立实现，至少先满足：

1. `core/platform/*` 抽象已经稳定
2. OpenHarmony P0 adapter 已有实现或验证结论
3. Web 已经不再阻塞主交付节奏
4. 聊天、上传、文件预览、语音播放主链路在其他正式平台已收敛

如果以上条件不满足，HarmonyOS 只保留文档级跟随状态，不启动独立实现。

---

## 4. 最小实现策略

### 4.1 必须遵守

1. 优先复用 `core/platform/*` 同一套 service contract
2. 优先复用 OpenHarmony adapter 设计
3. 若需要平台分叉，只允许新增 adapter 层
4. 禁止在 feature/controller/use case 中写 HarmonyOS 条件分支

### 4.2 允许新增

- `core/platform/harmony/*adapter.dart`
- `HarmonyPlatformBridge`
- `HarmonyCapabilities`

### 4.3 禁止新增

- 页面级平台直连 SDK
- 聊天页内部硬编码平台分支
- 上传或预览逻辑内散落平台特判

---

## 5. 首轮门槛

HarmonyOS 首轮不追求超出 OpenHarmony 的能力集合。

必须通过：

1. 登录 / refresh / socket reauth
2. 会话列表
3. 文本聊天
4. 图片 / 文件 / 视频发送
5. 语音发送
6. 语音播放暂停续播
7. 文件预览或下载降级
8. 长按菜单与消息菜单

允许暂缓：

1. 音视频通话
2. 离线推送
3. 地图原生体验
4. 扫码

---

## 6. 与 OpenHarmony 的关系

HarmonyOS 当前不是第二套设计体系。

它和 OpenHarmony 的关系应当是：

1. 共享同一业务协议层
2. 共享同一应用层和页面层
3. 尽量共享同一平台 contract
4. 只有在平台桥和 adapter 层做差异处理

---

## 7. 交付判断

截至 2026-04-29：

1. HarmonyOS 当前状态应视为 `analyzing`
2. 还不建议宣告 `ready_for_codegen`
3. 等 OpenHarmony 真机链路验证完一轮后，再升级其状态

---

## 8. 结论

HarmonyOS 当前最合理的工程策略不是抢先实现，而是：

1. 先把主干抽象做正确
2. 先让 OpenHarmony 成为移动端平台样板
3. 再用同一抽象承接 HarmonyOS
