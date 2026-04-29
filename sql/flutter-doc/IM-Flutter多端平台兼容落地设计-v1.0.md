# IM Flutter 多端平台兼容落地设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 在 Android、iOS、Web、Windows、macOS 与未来 OpenHarmony/HarmonyOS 的平台兼容落地规则  

---

## 1. 目标

把“支持多端”从口号收敛成可执行的交付边界。

本文件回答三个问题：

1. 当前主交付平台有哪些
2. 每个平台哪些能力必须可用
3. 未来 OpenHarmony / HarmonyOS 如何预留而不污染当前主链路

---

## 2. 当前平台分级与优先顺序

### 2.1 当前优先顺序

当前多端重要排序冻结为：

1. Android
2. iOS
3. OpenHarmony
4. Windows
5. macOS
6. Web
7. HarmonyOS

这个顺序用于：

- 架构设计优先级
- 插件兼容审计优先级
- 测试与回归资源倾斜顺序

### 2.2 P0 主交付平台

首期必须作为正式交付目标的平台：

- Android
- iOS
- OpenHarmony

### 2.3 P1 次级正式交付平台

同样属于正式交付目标，但在实现节奏上晚于移动主平台：

- Windows
- macOS
- Web
- HarmonyOS

### 2.4 冻结结论

当前 Flutter 官方主生态并未把 HarmonyOS / OpenHarmony 作为与 Android/iOS/Web/Desktop 同级的一等官方官方支持目标；现实可行路径主要来自 OpenHarmony SIG 维护的 Flutter 分支与社区插件适配。

这意味着：

1. Harmony / OpenHarmony 可以进入正式交付目标
2. 但必须采用“正式目标 + 平台门槛”模式推进
3. 所有平台差异必须被 `platform facade / adapter` 收口
4. Harmony 交付以插件兼容矩阵通过为前提，不允许口头承诺替代技术验收

这是基于 2026-04-29 的公开资料作出的工程判断。

---

## 3. 平台能力分层

### 3.1 纯 Dart 层

应天然跨端复用：

- domain model
- state machine
- repository contract
- use case
- formatter
- dict facade
- route arg codec

### 3.2 Flutter UI 层

应多端共用主干：

- 页面结构
- 组件组合
- 状态绑定
- 大多数交互编排

### 3.3 平台适配层

必须按平台拆分：

- 文件选择
- 文件上传底层实现
- 音频录制与播放会话
- 相机 / 麦克风权限
- 本地通知 / 离线推送
- 系统分享
- 地图底图
- WebRTC 设备路由

---

## 4. 各端必须具备的主链路

### 4.1 Android / iOS

必须可用：

- 登录 / refresh / reauth
- 会话列表
- 聊天页主链路
- 图片/视频/文件/语音发送
- 文件预览
- 语音播放暂停续播
- emoji / 自定义表情
- 消息菜单
- 群设置 / 单聊设置
- 音视频 1v1
- 离线推送主链路

### 4.2 OpenHarmony

属于移动端正式交付目标，但需要经过平台门槛验收后才可宣告完成。

必须可用：

- 登录 / refresh / reauth
- 会话列表
- 聊天页主链路
- 图片/视频/文件发送
- 语音发送与播放暂停续播
- 文件预览
- emoji / 自定义表情
- 消息菜单
- 群设置 / 单聊设置

允许首阶段暂缓：

- 音视频 1v1
- 离线推送
- 地图位置选择器原生主体验

说明：

1. 若 OpenHarmony 插件兼容矩阵未通过，以上暂缓项不得强行宣告完成。
2. OpenHarmony 首阶段先保证 IM 主链路完整，再补复杂原生能力。

### 4.3 Web

必须可用：

- 登录 / refresh / reauth
- 会话列表
- 聊天页主链路
- 图片/视频/文件发送
- 语音播放
- 文件预览
- 右键菜单
- 多栏布局
- 音视频 1v1

允许降级：

- 系统级来电体验
- 原生文件打开体验
- 录音设备兼容性边缘问题

### 4.4 Windows / macOS

必须可用：

- 登录 / refresh / reauth
- 会话列表
- 聊天页主链路
- 文件拖拽上传
- 图片/视频/文件发送
- 语音播放暂停续播
- 文件预览
- 右键菜单
- 多栏布局
- 音视频 1v1

允许阶段性弱化：

- 移动端式系统通知体验
- 部分移动专属权限交互

### 4.5 HarmonyOS

当前排在 Web 之后。

定位：

- 正式交付目标
- 但优先级低于 Android / iOS / OpenHarmony / Windows / macOS / Web

要求：

1. 继续保留 adapter / facade 架构兼容
2. 待 OpenHarmony 移动主链路稳定后，再推进 HarmonyOS 的独立适配与验收

---

## 5. 高风险平台差异点

### 5.1 输入与菜单

- Mobile：长按 action sheet
- Web/Desktop：右键 context menu

规则：

同一业务动作由同一 action coordinator 触发，UI 入口可以不同。

### 5.2 语音播放

- Mobile：前后台切换、听筒/扬声器、系统音频焦点
- Web/Desktop：暂停续播、并发播放限制、窗口焦点变化

### 5.3 文件选择与上传

- Mobile：相册/相机/文件选择
- Desktop：本地文件系统与拖拽
- Web：浏览器文件选择与 Blob 上传

### 5.4 通知与推送

- iOS：APNs
- Android：聚合推送
- Desktop/Web：不作为首期离线推送主平台
- Harmony：未来 adapter 扩展

### 5.5 地图与位置

- Mobile：地图 SDK 主体验
- Desktop/Web：位置查看可降级为静态卡片 + 外链

---

## 6. Harmony / OpenHarmony 适配策略

### 6.1 当前工程判断

如果进入 OpenHarmony / HarmonyOS：

1. 纯 Dart 层可最大化复用
2. 需要重做或补做的平台插件较多
3. Android / iOS 插件不可假定天然兼容
4. 现有社区路径主要依赖 OpenHarmony SIG 维护分支与适配插件，而不是 Flutter 官方主线直接支持

### 6.2 当前文档要求

为避免未来返工，当前所有依赖原生能力的模块必须做到：

1. 页面不直接 import 平台 SDK
2. feature 层不直接依赖 Android/iOS 插件细节
3. 所有原生能力必须先过 `core/platform/*`

### 6.3 OpenHarmony 正式交付门槛

OpenHarmony 作为移动端正式交付目标，必须满足以下门槛：

1. Flutter runtime 与构建链路可稳定跑通
2. 以下插件或替代能力存在可用实现：
   - secure storage
   - device id
   - file picker
   - image/video picker
   - audio record / audio playback
   - websocket
   - file download / open
   - wakelock
3. 无法复用的插件要有自研 adapter 方案
4. 需形成独立 `ohos plugin compatibility board`

### 6.4 HarmonyOS 的排位结论

HarmonyOS 继续保留正式交付目标身份，但当前优先级排在 Web 之后。

原因：

1. 当前首先要保证移动主链路能在 Android / iOS / OpenHarmony 收敛
2. HarmonyOS 不应挤占更成熟平台的首轮落地资源
3. 其完成定义同样依赖平台门槛与插件兼容矩阵

---

## 7. 平台验收基线

### 7.1 Android / iOS

验收通过条件：

1. 主聊天链路闭环
2. 文件与语音链路稳定
3. 1v1 音视频可呼出可接听
4. 推送主链路可用

### 7.2 Web / Desktop

验收通过条件：

1. 多栏布局稳定
2. 右键菜单可用
3. 文件拖拽或浏览器选择上传可用
4. 文件预览和下载可用
5. 音视频主链路可用

### 7.3 OpenHarmony / HarmonyOS 验收

通过条件：

1. 登录、会话、聊天、文件主链路可跑通
2. 菜单、emoji、自定义表情、语音暂停续播可用
3. 平台依赖都在 adapter/facade 后
4. 已形成插件兼容矩阵与缺口清单
5. 未完成能力有明确降级说明

---

## 8. 结论

当前文档体系对 Android/iOS/Web/Windows/macOS 已具备较完整的目标态约束。

对 OpenHarmony / HarmonyOS：

- 两者都属于正式交付目标
- OpenHarmony 作为手机端优先级更高
- HarmonyOS 当前排在 Web 之后
- 两者都采用“带门槛的正式交付”模式

进一步落地时，以以下文档为准：

- `IM-FlutterOpenHarmony-HarmonyOS插件兼容矩阵-v1.0.md`
- `IM-FlutterOpenHarmony-HarmonyOS适配缺口清单-v1.0.md`

这是当前最务实的工程边界。
