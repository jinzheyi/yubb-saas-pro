# uni-app x 客户端升级接口契约草案

## 文档目标

- 本文档用于约束 `shengyu-ui-admin-uniappx` 与平台升级中心的接口字段。
- 目标不是替代主设计文档，而是给客户端和平台端联调时提供明确契约。
- 时间口径：2026-04-21 当前客户端代码实现。

## 当前客户端实现落点

- API：
  - [app-upgrade.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/api/app-upgrade.uts)
- Service：
  - [app-upgrade-service.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/services/app-upgrade-service.uts)
- 手动检查入口：
  - [settings.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/profile/settings.uvue)
- 静默检查入口：
  - [App.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/App.uvue)

## 接口 1：检查更新

### 路径

- `POST /app-api/system/app-upgrade/check`

### 请求体建议字段

```json
{
  "appCode": "shengyu-im-app",
  "platform": "HARMONY",
  "channel": "stable",
  "clientVersion": "1.0.0",
  "clientVersionCode": 100,
  "deviceId": "1710000000000-abc123",
  "deviceType": 3,
  "osName": "harmonyos",
  "osVersion": "5.0.0",
  "manufacturer": "HUAWEI",
  "model": "Pura 70",
  "harmonyApiVersion": 14,
  "harmonyDisplayVersion": "NEXT 5.0.0"
}
```

### 字段说明

- `appCode`
  - 当前客户端默认写死为 `shengyu-im-app`
  - 后续如平台定义了正式 appCode，应与客户端常量同步
- `platform`
  - 当前客户端取值：`ANDROID` / `IOS` / `HARMONY` / `WEB` / `MINI_PROGRAM`
- `channel`
  - 当前客户端默认值：`stable`
  - 后续可扩展灰度、测试、OEM 渠道
- `clientVersion`
  - 读取 `appVersion`
- `clientVersionCode`
  - 优先读取运行时 versionCode
  - 无法读取时，按 `major * 10000 + minor * 100 + patch` 回退
- `deviceType`
  - 当前仍兼容既有登录设备语义
  - HarmonyOS 当前暂归并到移动端类型
- `manufacturer` / `model`
  - 用于平台统计和异常归因
- `harmonyApiVersion` / `harmonyDisplayVersion`
  - 仅鸿蒙有值，其他平台可为空

### 响应体建议字段

```json
{
  "resultCode": "FORCE_UPDATE",
  "title": "发现新版本 1.1.0",
  "content": "修复已知问题并优化鸿蒙体验",
  "releaseNotes": "修复扫码与分享问题",
  "latestVersion": "1.1.0",
  "latestVersionCode": 110,
  "forceUpdate": true,
  "action": "OPEN_APP_GALLERY",
  "downloadUrl": "",
  "storeUrl": "",
  "marketUrl": "appmarket://details?id=xxx",
  "webUrl": "",
  "publishTime": "2026-04-21 10:00:00"
}
```

### `resultCode` 约束

- `NO_UPDATE`
- `OPTIONAL_UPDATE`
- `FORCE_UPDATE`
- `BLOCKED`

说明：

- 客户端已按上述 4 种枚举实现
- 平台端不要返回新的自由文本结果码

### `action` 约束

- `NONE`
- `OPEN_URL`
- `OPEN_STORE`
- `OPEN_APP_GALLERY`
- `REFRESH_WEB`

说明：

- 鸿蒙推荐返回 `OPEN_APP_GALLERY`
- Web 推荐返回 `REFRESH_WEB`
- Android/iOS 可按商店或外链返回

### 客户端行为约束

- `NO_UPDATE`
  - 手动检查：提示“当前已是最新版本”
  - 静默检查：不打扰用户
- `OPTIONAL_UPDATE`
  - 手动检查：弹窗提示，可取消
  - 静默检查：当前客户端默认不弹
- `FORCE_UPDATE`
  - 手动检查：弹窗提示，不应继续忽略
  - 静默检查：直接弹窗
- `BLOCKED`
  - 当前客户端已单独按阻断弹窗处理
  - 不再展示“立即更新”这类误导按钮

## 接口 2：事件回传

### 路径

- `POST /app-api/system/app-upgrade/report-event`

### 请求体建议字段

```json
{
  "appCode": "shengyu-im-app",
  "platform": "HARMONY",
  "eventType": "OPEN_APP_GALLERY",
  "clientVersion": "1.0.0",
  "clientVersionCode": 100,
  "deviceId": "1710000000000-abc123",
  "payload": {
    "trigger": "manual",
    "resultCode": "FORCE_UPDATE",
    "latestVersion": "1.1.0"
  }
}
```

### 当前客户端已上报事件

- `CHECK`
- `SHOW_DIALOG`
- `CLICK_UPDATE`
- `CLICK_CANCEL`
- `OPEN_STORE`
- `OPEN_APP_GALLERY`

### 平台端建议兼容的后续事件

- `CLICK_UPDATE`
- `CLICK_CANCEL`
- `DOWNLOAD_START`
- `DOWNLOAD_SUCCESS`
- `DOWNLOAD_FAIL`
- `INSTALL_START`
- `INSTALL_FAIL`

## 当前客户端默认常量

- `appCode = shengyu-im-app`
- `channel = stable`
- 静默检查节流：`6 小时`
- 可选版本忽略：按 `latestVersionCode` 本地记录一次

这些值当前写在：

- [app-upgrade-service.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/services/app-upgrade-service.uts)

## 联调注意事项

- 客户端已经支持 `platform = HARMONY`
- 客户端已经支持手动检查和静默检查两条链路
- 客户端对 `OPTIONAL_UPDATE` 已支持“本地忽略当前版本”
- 平台端如果暂时没有 `releaseNotes`，至少返回 `content`
- 平台端不要只返回下载地址，必须返回 `action`
- `BLOCKED` 不应与 `OPTIONAL_UPDATE` 混用

## 下一步建议

- 平台端先按本契约补齐 `/check` 与 `/report-event`
- 联调时优先验证：
  - HarmonyOS `FORCE_UPDATE + OPEN_APP_GALLERY`
  - HarmonyOS `BLOCKED`
  - Web `REFRESH_WEB`
  - Android `OPEN_URL / OPEN_STORE`
