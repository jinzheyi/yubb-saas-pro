# IM Flutter OpenHarmony / HarmonyOS 插件兼容矩阵 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 在 OpenHarmony / HarmonyOS 方向的插件兼容矩阵、主链路阻塞点与替代策略  

---

## 1. 目标

把 `OpenHarmony / HarmonyOS` 的平台风险收敛成工程可执行清单。

本矩阵不承诺某个第三方 Flutter 插件“天然可用”，而是回答：

1. 这项能力是否必须
2. 当前是否可优先复用跨平台插件
3. 若不能直接复用，是否要通过 adapter 自研补位

---

## 2. 状态定义

- `green`
  - 可优先尝试复用现有 Flutter 生态方案
  - 预期阻碍低
- `yellow`
  - 可做，但要先验证分支 / 插件适配
  - 有中等实现风险
- `red`
  - 当前不应假设现成可用
  - 需要自研 adapter、平台桥接或功能降级

---

## 3. 核心矩阵

| 能力 | Flutter 主方案/依赖 | OpenHarmony | HarmonyOS | 风险级别 | 备注 |
|---|---|---|---|---|---|
| 纯 Dart domain/usecase/state | 无插件 | 可复用 | 可复用 | `green` | 无平台阻碍 |
| HTTP / Dio | `dio` | 预期可行 | 预期可行 | `green` | 网络栈优先验证即可 |
| WebSocket | `web_socket_channel` | 预期可行 | 预期可行 | `green` | 先验证 binary/text 行为 |
| JSON/codegen/freezed | 纯 Dart | 可复用 | 可复用 | `green` | 无平台阻碍 |
| secure storage | `flutter_secure_storage` | 需验证替代实现 | 需验证替代实现 | `yellow` | 必须允许 adapter 替换 |
| shared preferences / KV | `shared_preferences` | 需验证 | 需验证 | `yellow` | 可先落本地简单实现 adapter |
| 路径/临时目录 | `path_provider` | 需验证 | 需验证 | `yellow` | 上传/下载缓存依赖 |
| 文件选择 | `file_picker` | 高风险 | 高风险 | `red` | 必须预留 `file_picker_service` 自研桥接 |
| 图片/视频选择 | `image_picker` | 高风险 | 高风险 | `red` | 相册/相机能力需单独桥接 |
| 拍照 | `image_picker`/camera | 高风险 | 高风险 | `red` | 不应假定现成插件可用 |
| 录音 | `record` | 高风险 | 高风险 | `red` | 录音权限与音频采集需自研 adapter |
| 音频播放 | `just_audio` | 中高风险 | 中高风险 | `yellow` | 先保播放/暂停/续播，系统焦点后补 |
| 视频播放 | `video_player` | 中高风险 | 中高风险 | `yellow` | 先保主链路播放，复杂解码另验 |
| 文件下载 | 自研 + `dio` | 可做 | 可做 | `yellow` | 打开系统文件能力需桥接 |
| 文件打开 | system opener | 高风险 | 高风险 | `red` | 必须走 `external_opener_adapter` |
| 权限申请 | `permission_handler` | 高风险 | 高风险 | `red` | 必须有平台权限 facade |
| wakelock | `wakelock_plus` | 需验证 | 需验证 | `yellow` | 通话场景依赖 |
| audio session | `audio_session` | 高风险 | 高风险 | `red` | 移动音频焦点需自研补位 |
| 本地通知 | 平台 adapter | 高风险 | 高风险 | `red` | 不视为首轮必达 |
| 离线推送 | APNs/个推 adapter | 暂不作为首轮必达 | 暂不作为首轮必达 | `red` | 需单独厂商生态接入 |
| 系统分享 | `share_plus` 或 adapter | 中高风险 | 中高风险 | `yellow` | 可后补 |
| 地图 | provider adapter | 高风险 | 高风险 | `red` | 首轮 OpenHarmony 可降级文本地址 |
| 扫码 | `mobile_scanner` | 高风险 | 高风险 | `red` | 非主链路，后补 |
| WebRTC | `flutter_webrtc` | 高风险 | 高风险 | `red` | 不应承诺首轮 OHOS 通话能力 |

---

## 4. 业务主链路阻塞判断

### 4.1 OpenHarmony 首轮可开工主链路

在不依赖高风险原生插件的前提下，以下链路可以作为 OpenHarmony 首轮目标：

- 登录 / refresh / reauth
- 会话列表
- 文本聊天
- emoji / 自定义表情展示与发送
- 文件消息展示
- 服务端文件预览策略消费
- 基础菜单交互

### 4.2 OpenHarmony 首轮阻塞点

当前最可能阻塞首轮移动完整体验的点：

1. 文件选择
2. 图片/视频选择
3. 录音
4. 权限申请
5. 系统文件打开

### 4.3 HarmonyOS 当前阻塞判断

HarmonyOS 当前优先级更低，因此同样按上述阻塞点处理，不应单独新建一条更激进的技术路线。

---

## 5. 平台 adapter 建议

必须明确提供抽象层的能力：

```text
core/platform/
  picker/
    file_picker_service.dart
    image_picker_service.dart
  media/
    recorder_service.dart
    audio_player_service.dart
    video_player_service.dart
    audio_focus_service.dart
  permission/
    permission_service.dart
  file/
    external_opener_service.dart
    download_service.dart
  notification/
    local_notification_service.dart
  share/
    share_service.dart
  rtc/
    rtc_device_service.dart
```

---

## 6. 首轮推荐降级策略

### 6.1 OpenHarmony

允许首轮降级：

- 位置选择器降级为文本地址 / 外部跳转
- 音视频通话暂不纳入首轮完成标准
- 离线推送暂不纳入首轮完成标准
- 文件外部打开失败时退回下载

### 6.2 HarmonyOS

允许更保守的降级：

- 首轮只要求跟随 OpenHarmony 主链路能力
- 高风险插件能力全部列入后补清单

---

## 7. 推荐实现顺序

### Phase 1

- Dio / WebSocket / auth
- shared preferences / secure storage adapter 审计

### Phase 2

- file picker / image picker / permission adapter
- 文件上传与文件预览主链路

### Phase 3

- audio play / record adapter
- 语音消息主链路

### Phase 4

- video / map / share / scan

### Phase 5

- push / rtc

---

## 8. 结论

当前对 `OpenHarmony / HarmonyOS` 的真实工程判断是：

1. 纯 Dart 层与协议层没有本质阻碍
2. 风险主要集中在原生插件生态
3. OpenHarmony 可以作为移动端正式目标推进
4. 但必须先补齐 `picker / permission / audio / opener` 这几类 adapter
5. HarmonyOS 继续跟随同一矩阵，但优先级晚于 Web
