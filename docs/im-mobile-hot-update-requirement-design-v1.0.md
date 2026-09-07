# 钰信 Flutter 正式用户热更新需求设计 v1.0

## 1. 背景

钰信 Flutter 客户端当前在设置页已有“关于钰信”入口，并且角标系统中已预留 `settingsVersionUpdate`。这个入口的产品初衷是承载正式用户版本更新能力，让用户不必频繁连接电脑或重新索要安装包，也能收到新版本提示、安装包更新或轻量补丁更新。

本设计面向正式用户，不是开发阶段的 Flutter hot reload。Flutter 官方 hot reload 只适用于 debug 开发调试，线上正式用户不能依赖它。正式用户更新应设计为“版本更新中心”，由平台层统一管理发布记录，Flutter App 查询平台接口后展示更新、下载安装或提示重启生效。

## 2. 核心结论

采用“平台层版本发布 + App 更新中心”的最小可用闭环：

1. **平台层管理**
   - 在 platform 对应的服务端实现版本发布、更新检查接口。
   - 在 platform 对应的 Vue 管理后台实现版本发布页面。
   - 这是全平台能力，面向所有租户，不放在某个租户业务后台里。

2. **Flutter App 展示与执行**
   - “设置 -> 关于钰信”进入更新中心。
   - App 调用 platform 更新检查接口，获得是否有更新、是否强制、更新类型、下载地址、更新日志等信息。
   - Android 优先支持整包下载更新。
   - iOS / 鸿蒙先展示更新信息并跳转指定分发地址。
   - Dart OTA 热更新作为二期能力接入，优先调研 Shorebird。

3. **先做必要能力，旁系能力暂不做**
   - 第一期不做复杂统计报表。
   - 第一期不做按租户定向发布。
   - 第一期不做多应用市场渠道包管理。
   - 第一期不做复杂审批流。
   - 保留最基础的发布人、发布时间、状态字段，方便追溯即可。

## 3. 目标

1. 正式用户可以在“设置 -> 关于钰信”中检查更新。
2. 有新版本时，App 能展示版本号、更新内容、是否强制、下载或跳转入口。
3. 支持强制更新，低于最低可用版本时必须更新后继续使用。
4. 支持 Android 整包更新闭环：检查、下载、校验、唤起安装。
5. 支持 iOS / 鸿蒙通过配置的分发地址跳转更新。
6. 平台管理后台可以新增、发布、暂停版本记录。
7. 平台服务端可以按平台、版本号、构建号判断是否需要更新。
8. 为后续 Dart OTA 补丁保留字段和客户端入口。

## 4. 非目标

1. 不实现开发期 hot reload。
2. 第一期不接入复杂灰度、租户定向、多渠道包管理、统计大盘。
3. 第一期不做自动回滚系统，只支持后台暂停某个版本发布记录。
4. 不承诺所有变更都能热更新。原生代码、权限、插件、资源、Flutter 引擎版本变化仍需整包更新。
5. 不绕过 iOS、安卓、鸿蒙分发平台规则。

## 5. 更新类型

| 类型 | 一期是否实现 | 说明 |
| --- | --- | --- |
| `FULL` 整包更新 | 是 | Android 下载 APK；iOS / 鸿蒙跳转分发地址。 |
| `PATCH` Dart OTA 补丁 | 二期 | 用于 Dart 层修复，优先调研 Shorebird。 |
| `NONE` 无更新 | 是 | 当前版本已是最新或没有命中发布记录。 |

## 6. 技术边界

### 6.1 可走 OTA 补丁的变更

1. Flutter `lib/` 下 Dart 业务代码修复。
2. UI、文案、页面逻辑、状态管理、接口错误处理等 Dart 层修复。
3. 纯 Dart 依赖和生成代码变更，前提是不引入原生代码变化。

### 6.2 必须走整包更新的变更

1. Android `android/` 或 iOS `ios/` 下原生代码变更。
2. 新增或变更原生插件、权限、manifest、plist、scheme、entitlement。
3. 图片、字体、音频等 assets 资源新增、删除或替换。
4. Flutter SDK 或 Flutter engine 版本变化。
5. 包名、签名、证书、应用图标、启动屏、安装权限相关变更。
6. 鸿蒙 HAP / APP 包产物变更。

## 7. 当前项目落点

1. `shengyu-ui/shengyu-ui-admin-flutter/lib/features/profile/presentation/pages/settings_page.dart`
   - 当前“关于钰信”是静态 `_SettingsNavTile`，只展示版本文案。
   - 需要改为点击进入“关于钰信/版本更新”页面。

2. `shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/badge/badge_service.dart`
   - 已预留 `BadgeMenuIds.settingsVersionUpdate = 'settingsVersionUpdate'`。
   - 后续由更新检查结果控制设置页红点。

3. `shengyu-ui/shengyu-ui-admin-flutter/lib/shared/widgets/badge_widgets.dart`
   - 注释已包含“设置‘关于钰信’有版本更新”。
   - 后续可复用现有角标组件。

## 8. 用户流程

### 8.1 App 启动自动检查

1. App 启动或登录成功后调用更新检查接口。
2. 如果无更新，不打扰用户。
3. 如果有可选更新，在设置页“关于钰信”显示红点。
4. 如果有强制更新，进入强制更新弹窗。

### 8.2 用户手动检查

1. 用户进入“设置 -> 关于钰信”。
2. 页面展示当前版本、构建号、平台。
3. 用户点击“检查更新”。
4. App 调用 platform 更新检查接口。
5. 根据接口结果展示“已是最新版本”或更新信息。

### 8.3 Android 整包更新

1. App 获取 `packageUrl`、`sha256`、`packageSize`。
2. 用户点击“立即更新”。
3. App 下载 APK。
4. 下载完成后校验 SHA-256。
5. 校验通过后唤起系统安装器。
6. 校验失败提示“安装包校验失败，请重试”。

### 8.4 iOS / 鸿蒙更新

1. App 获取 `packageUrl`。
2. 用户点击“立即更新”。
3. 打开 App Store、TestFlight、企业分发页、鸿蒙分发页或平台配置的下载页。
4. App 内不直接安装 iOS / 鸿蒙包。

### 8.5 强制更新

1. 当前 `versionCode < minSupportedVersionCode` 时触发强制更新。
2. 强制更新弹窗不可跳过。
3. 用户只能点击“立即更新”。
4. 更新失败时允许重试。
5. 不在语音/视频通话中突然弹出强制遮挡；通话结束或下次进入主流程时再阻断。

## 9. Flutter 客户端设计

### 9.1 建议模块

```text
lib/features/update/
  data/
    update_api.dart
    update_repository_impl.dart
  domain/
    app_update_info.dart
    update_repository.dart
  presentation/
    about_app_page.dart
    update_dialog.dart
    update_controller.dart
  services/
    update_check_service.dart
    update_download_service.dart
```

二期接入 Dart OTA 时再增加：

```text
lib/features/update/services/shorebird_update_gateway.dart
```

### 9.2 检查时机

1. 登录成功后检查一次。
2. App 冷启动进入主页面后检查一次。
3. App 从后台回到前台时可检查，但 6 小时内最多自动检查一次。
4. 用户在“关于钰信”手动检查时不受节流限制。
5. 通话中、文件上传中不弹阻断式更新提示。

### 9.3 本地状态

一期只保存必要状态：

1. `last_update_check_at`：最近自动检查时间。
2. `ignored_version_code`：用户选择稍后的版本。
3. `downloaded_package_path`：Android 已下载 APK 路径。

二期 OTA 再增加：

1. `pending_patch_version`：已下载待生效补丁版本。
2. `patch_applied_at`：补丁生效时间。

## 10. Platform 服务端设计

### 10.1 所属模块

版本更新能力属于平台层：

1. 服务端实现位置：platform 对应服务端模块。
2. 前端实现位置：platform 对应 Vue 管理后台。
3. 数据作用范围：所有租户共享。
4. 一期不做按租户定向发布，所有租户统一使用同一套 App 版本策略。

### 10.2 更新检查接口

建议新增：

```http
GET /app-api/system/app-update/check
```

请求参数：

| 参数 | 必填 | 示例 | 说明 |
| --- | --- | --- | --- |
| `appKey` | 是 | `yuxin` | 应用标识。 |
| `platform` | 是 | `android` / `ios` / `harmony` | 平台。 |
| `versionName` | 是 | `1.0.3` | 当前版本名。 |
| `versionCode` | 是 | `103` | 当前构建号。 |
| `channel` | 否 | `prod` | 渠道，一期默认 `prod`。 |

响应示例：

```json
{
  "code": 0,
  "data": {
    "hasUpdate": true,
    "updateType": "FULL",
    "forceUpdate": false,
    "versionName": "1.0.4",
    "versionCode": 104,
    "minSupportedVersionCode": 100,
    "title": "钰信更新",
    "changelog": "修复语音通话和会话稳定性问题",
    "packageUrl": "https://preview.shengyukj.top/app/yuxin-1.0.4.apk",
    "packageSize": 73400320,
    "sha256": "待发布时生成",
    "promptStrategy": "NORMAL"
  },
  "msg": ""
}
```

当无更新时：

```json
{
  "code": 0,
  "data": {
    "hasUpdate": false,
    "updateType": "NONE"
  },
  "msg": ""
}
```

### 10.3 数据表设计

一期只建一张核心表：

`platform_app_release`：

| 字段 | 说明 |
| --- | --- |
| `id` | 主键。 |
| `app_key` | 应用标识，如 `yuxin`。 |
| `platform` | android / ios / harmony。 |
| `channel` | 一期默认 prod。 |
| `version_name` | 版本名。 |
| `version_code` | 构建号，用于比较新旧。 |
| `min_supported_version_code` | 最低可用构建号，低于此值强制更新。 |
| `update_type` | FULL / PATCH。 |
| `force_update` | 是否强制。 |
| `title` | 更新标题。 |
| `changelog` | 更新日志。 |
| `package_url` | APK、商店、TestFlight、鸿蒙分发地址。 |
| `package_size` | 包大小。 |
| `sha256` | Android APK 校验值。 |
| `status` | DRAFT / PUBLISHED / PAUSED。 |
| `remark` | 内部备注。 |
| `creator` | 创建人。 |
| `create_time` | 创建时间。 |
| `updater` | 更新人。 |
| `update_time` | 更新时间。 |

二期接入 OTA 时再补充字段：

| 字段 | 说明 |
| --- | --- |
| `patch_provider` | shorebird / none。 |
| `patch_release_id` | 补丁基线版本。 |
| `patch_no` | 补丁号。 |

### 10.4 更新判断规则

1. 查询 `app_key + platform + channel + status=PUBLISHED` 的最高 `version_code` 记录。
2. 如果没有记录，返回无更新。
3. 如果当前 `version_code >= 发布记录 version_code`，返回无更新。
4. 如果当前 `version_code < min_supported_version_code`，返回强制更新。
5. 其它情况返回可选更新。
6. 如果发布记录被设置为 `PAUSED`，不再返回给客户端。

## 11. Platform Vue 管理后台设计

### 11.1 菜单位置

建议在 platform 管理后台新增：

```text
系统管理 / 应用版本
```

或：

```text
平台运维 / 应用版本
```

该菜单属于平台管理能力，不属于租户业务菜单。

### 11.2 页面能力

一期只做必要能力：

1. 版本列表。
2. 新增版本。
3. 编辑未发布版本。
4. 发布版本。
5. 暂停版本。
6. 删除草稿版本。

### 11.3 表单字段

新增/编辑版本表单：

1. 应用标识：默认 `yuxin`。
2. 平台：Android / iOS / 鸿蒙。
3. 版本名。
4. 构建号。
5. 最低可用构建号。
6. 更新类型：整包更新 / OTA 补丁。
7. 是否强制更新。
8. 更新标题。
9. 更新日志。
10. 下载或跳转地址。
11. 包大小。
12. SHA-256。
13. 内部备注。

### 11.4 一期暂不做

1. 暂不做租户定向。
2. 暂不做复杂灰度比例。
3. 暂不做多渠道包管理。
4. 暂不做统计大盘。
5. 暂不做复杂审批流。

## 12. 安全要求

1. 更新检查接口必须走 HTTPS。
2. Android APK 必须校验 SHA-256。
3. Android APK 必须保持包名一致、版本号递增、签名一致。
4. 客户端不得执行服务端返回的脚本。
5. 服务端不得返回低于当前版本的普通更新。
6. 下载地址优先使用 HTTPS。
7. 生产版本发布前必须完成真机测试。

## 13. 最小上线流程

### 13.1 发布 Android 整包

1. 打包 Android 正式 APK。
2. 生成 APK 的 SHA-256。
3. 上传 APK 到 Nginx 可访问目录或对象存储。
4. 在 platform Vue 管理后台新增 Android 版本记录。
5. 填写版本号、构建号、下载地址、SHA-256、更新日志。
6. 设置是否强制更新。
7. 发布版本。
8. Flutter App 检查到更新后下载并唤起安装。

### 13.2 发布 iOS / 鸿蒙版本

1. 打包并上传到对应分发平台。
2. 获取可跳转的分发地址。
3. 在 platform Vue 管理后台新增版本记录。
4. 填写版本号、构建号、跳转地址、更新日志。
5. 发布版本。
6. Flutter App 检查到更新后跳转对应地址。

### 13.3 暂停问题版本

1. 在 platform Vue 管理后台找到已发布版本。
2. 点击暂停。
3. 服务端更新检查接口不再返回该版本。
4. 如已经有用户安装问题版本，需要发布更高版本修复。

## 14. 验收标准

1. “设置 -> 关于钰信”可进入版本更新页面。
2. 页面能展示当前版本、构建号、平台。
3. 点击“检查更新”能调用 platform 更新检查接口。
4. 无更新时显示“已是最新版本”。
5. 有可选更新时展示更新日志，并支持稍后处理。
6. 有强制更新时不可跳过。
7. Android 能下载 APK、校验 SHA-256、唤起安装。
8. iOS / 鸿蒙能跳转后台配置的更新地址。
9. platform Vue 后台能新增、发布、暂停版本记录。
10. 暂停后的版本不再返回给客户端。
11. 通话中、上传中不弹阻断式更新提示。

## 15. 分阶段实施

### 阶段 1：最小可用闭环

1. Platform 服务端新增版本表和更新检查接口。
2. Platform Vue 后台新增应用版本页面。
3. Flutter 新增“关于钰信/版本更新”页面。
4. Android 支持整包下载、SHA-256 校验、唤起安装。
5. iOS / 鸿蒙支持跳转更新地址。

### 阶段 2：Dart OTA 补丁

1. 调研并接入 Shorebird。
2. 增加 PATCH 类型发布字段。
3. Flutter 接入补丁检查、下载、重启后生效提示。
4. 明确 OTA 可用边界：只用于 Dart 层修复。

### 阶段 3：增强能力，按需再做

1. 灰度比例。
2. 租户定向。
3. 用户/设备定向。
4. 统计报表。
5. 发布审批流。
6. 多渠道包管理。

## 16. 待确认事项

1. iOS 最终使用 App Store、TestFlight 还是企业分发。
2. 鸿蒙最终使用哪个分发平台。
3. Android APK 下载地址使用当前服务器 Nginx 目录还是对象存储。
4. Shorebird 在国内网络、费用、合规上的可用性。

## 17. 参考资料

1. Flutter hot reload 官方文档：https://docs.flutter.dev/tools/hot-reload
2. Shorebird Code Push 概览：https://docs.shorebird.dev/code-push/
3. Shorebird Patch 文档：https://docs.shorebird.dev/code-push/patch/
4. Shorebird FAQ 与商店合规说明：https://docs.shorebird.dev/code-push/faq/
5. Apple App Review Guidelines：https://developer.apple.com/app-store/review/guidelines/
6. Google Play 更新应用要求：https://support.google.com/googleplay/android-developer/answer/9859350
