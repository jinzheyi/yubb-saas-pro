# uni-app x 鸿蒙支持差距与优化方案

## 文档目标

- 本文档专门回答 `shengyu-ui/shengyu-ui-admin-uniappx` 当前对 HarmonyOS Next 的真实支持情况。
- 文档同时给出“哪些已经能用、哪些不能直接当成已支持、应该怎么改”的企业级落地方案。
- 文档口径以 2026-04-21 的当前工程代码和 `uni-app x` 官方文档为准。
- 配套开工文档：
  - [HarmonyAES原生接入示例草案.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/doc/鸿蒙兼容/HarmonyAES原生接入示例草案.md)
  - [鸿蒙AES与位置能力开工清单.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/doc/鸿蒙兼容/鸿蒙AES与位置能力开工清单.md)
  - [鸿蒙位置能力接入说明.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/doc/鸿蒙兼容/鸿蒙位置能力接入说明.md)

## 一句话结论

- 当前项目不应定义为“已完成鸿蒙适配”。
- 更准确的状态是：
  - `uni-app x` 框架层已具备 HarmonyOS Next 能力基础
  - 当前 IM 项目业务代码仍以 Android、iOS、H5 为中心编写
  - 已存在多处鸿蒙缺口，尤其集中在工程配置、平台识别、扫码、文件能力、分享能力、升级执行链路

## 官方依据

### 1. 鸿蒙开发基础能力

- `uni-app x` 官方鸿蒙开发指南明确：
  - `uni-app x` 从 `4.61+` 起支持纯血鸿蒙 HarmonyOS Next
  - 开发环境要求包括 `HBuilderX 4.61+`
  - `DevEco Studio BuildVersion 5.0.7.210+`
  - 鸿蒙手机系统 `API 14+`
- 官方同时说明：
  - `unpackage/app-harmony` 下会生成鸿蒙原生工程
  - 企业应用场景可走 `.hap` 内部分发

### 2. 设备识别与鸿蒙系统信息

- `uni.getDeviceInfo` 官方文档明确支持 HarmonyOS
- 官方字段中已经提供：
  - `platform = harmonyos`
  - `osName = harmonyos`
  - `osHarmonySDKAPIVersion`
  - `osHarmonyDisplayVersion`
- 这意味着客户端不应该继续只按 `android / ios / h5` 做平台判断

### 3. 当前与鸿蒙直接相关的官方 API 能力

- `uni.chooseFile`
  - 官方兼容表显示 HarmonyOS 已支持
  - 适合替代项目里部分 `chooseMessageFile` 的老分支逻辑
- `uni.downloadFile`
  - 官方兼容表显示 HarmonyOS 已支持
  - 可用于文档、安装包、升级资源下载
- `uni.openDocument`
  - 官方兼容表显示 HarmonyOS 已支持
  - 适合文件预览、聊天文件打开
- `uni.scanCode`
  - 官方兼容表显示 HarmonyOS 已支持
  - 当前项目扫码页仍走 `plus.barcode.create`
  - 这是鸿蒙适配里的关键差距点
- `uni.saveImageToPhotosAlbum`
  - 官方兼容表显示 HarmonyOS 已支持
  - 可用于群二维码、图片保存
- `uni.shareWithSystem`
  - 官方兼容表显示 HarmonyOS 已支持
  - 当前项目还在使用 `uni.share(provider: 'weixin')` 这类 SDK 型分享写法，不适合作为鸿蒙首选方案
- `uni.openLocation`
  - `uni-app x` 官方文档说明 App 端依赖独立 `UTS` 插件 `uni-openlocation`
  - 鸿蒙端还要求在 `manifest` 中声明 `ohos.permission.APPROXIMATELY_LOCATION` 与 `ohos.permission.LOCATION`
  - 这意味着“页面里能调用 `uni.openLocation`”不等于“当前项目已经完成鸿蒙位置查看接入”
- `uni.getAppAuthorizeSetting` / `uni.getSystemSetting`
  - 官方文档已提供 App 授权状态与系统开关读取能力
  - 对鸿蒙定位链路很关键，因为 `openLocation` / `getLocation` 失败时，需要区分：
    - 官方插件未接入
    - App 定位权限未授权
    - 系统定位总开关未开启

## 当前工程真实情况

### 1. 工程配置层缺口

- [manifest.json](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/manifest.json)
  - 当前仅有 `app`、`app-android`、`app-ios`
  - 没有鸿蒙专项配置收口
  - 仓库内也没有完整的 `harmony-config` 目录沉淀

结论：

- 当前仓库尚未形成“可审计、可复现、可持续维护”的鸿蒙工程配置基线。

### 2. 平台识别层缺口

- [utils/device.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/utils/device.uts)
  - 原有逻辑只识别 `ios / android / web / mp-weixin`
  - 没有 `harmonyos` 平台识别
  - 没有读取 `osHarmonySDKAPIVersion`
  - 没有面向升级中心的独立平台编码

影响：

- 升级中心后续无法准确判断当前终端是不是鸿蒙
- 文件、扫码、分享、权限申请都无法做鸿蒙专项分支

### 3. 条件编译层缺口

- [store/locale.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/store/locale.uts)
  - 仍使用 `APP-ANDROID || APP-IOS`
- [components/captcha/utils/aes.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts)
  - 仍以 Android/iOS/H5 三分法编排
  - 鸿蒙没有可用实现

影响：

- 运行到鸿蒙时，部分逻辑不会进入正确分支
- 某些能力可能直接走“不支持”降级

### 4. 扫码能力缺口

- [pages/common/scan.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/common/scan.uvue)
  - 当前扫码页绑定 `plus.barcode.create(...)`
  - 页面也整体围绕 `APP-PLUS` 做交互

问题本质：

- 从 `uni-app x` 官方口径看，鸿蒙可直接使用 `uni.scanCode`
- 但当前项目并没有建立“Android/iOS 保留原方案，HarmonyOS 走 `uni.scanCode`”的双实现

结论：

- 扫码页是当前鸿蒙适配里最明确的功能缺口之一

### 5. 文件能力缺口

- [utils/upload.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/utils/upload.uts)
  - 原先 App 平台文件选择走 `uni.chooseMessageFile`
  - 没有把 HarmonyOS 纳入一等公民口径
- [utils/file.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/utils/file.uts)
  - 已使用 `downloadFile + openDocument`
  - 但未做鸿蒙专项错误归因、权限引导、文件路径兼容校验
- [pages/message/chat-files.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat-files.uvue)
  - 仍然是通用 App/H5 视角

结论：

- 文件上传下载预览不是“完全不支持”，而是“基础 API 有了，但缺少鸿蒙专项治理”

### 6. 分享与保存缺口

- [utils/qrcode.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/utils/qrcode.uts)
  - 保存图片当前用的是 `uni.saveImageToPhotosAlbum`
  - 该能力官方对 HarmonyOS 已支持，方向是对的
  - 但分享仍使用 `uni.share({ provider: 'weixin' })`
- [pages/message/group-qrcode.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/message/group-qrcode.uvue)
  - 也存在同类分享调用

结论：

- 鸿蒙首期不应继续把“微信 SDK 分享”当成唯一分享路径
- 应该新增系统分享优先策略：`uni.shareWithSystem`

### 7. 升级链路缺口

- [pages/profile/settings.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/profile/settings.uvue)
  - 当前“检查更新”只有 toast
  - 还没有真正接平台升级中心

与鸿蒙相关的关键影响：

- 后续鸿蒙更新不能像 Android 一样只靠下载 apk 安装
- 需要平台端返回鸿蒙专用升级策略：
  - 应用市场跳转
  - AppGallery 详情页
  - 开放测试
  - 分阶段发布可见性

## 当前已完成项

### 1. 客户端增加鸿蒙平台识别基础

- 已更新 [utils/device.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/utils/device.uts)
- 新增内容：
  - `ClientPlatformCode`
  - `getCurrentClientPlatform()`
  - `isHarmonyOS()`
  - `getClientPlatformInfo()`
- 现状策略：
  - 为避免直接冲击当前后端 `deviceType` 语义
  - 设备类型仍暂按现有登录设备体系兼容
  - 但升级中心、平台差异化能力判断已经可以拿到 `HARMONY`

### 2. 系统语言识别纳入鸿蒙编译分支

- 已更新 [store/locale.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/store/locale.uts)
- 让系统语言读取不再把鸿蒙排除在 App 端逻辑之外

### 3. 文件选择能力切换为官方通用 API 口径

- 已更新 [utils/upload.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/utils/upload.uts)
- 关键调整：
  - App/Harmony 文件选择优先改为 `uni.chooseFile`
  - 不再把 App 端固定绑在 `chooseMessageFile`
- 原因：
  - `uni.chooseFile` 官方兼容表已经覆盖 HarmonyOS
  - 更适合作为后续多端统一文件入口

### 4. 工具文档补齐 HarmonyOS 口径

- 已更新 [utils/README.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/utils/README.md)

### 5. 扫码页已切为 Android/iOS 与 HarmonyOS 双实现

- 已更新 [pages/common/scan.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/common/scan.uvue)
- 当前状态：
  - `APP-ANDROID || APP-IOS` 继续保留 `plus.barcode`
  - `APP-HARMONY` 改为 `uni.scanCode`
- 结果：
  - 鸿蒙不再落入“不支持原生扫码”的错误兜底页
  - Android/iOS 现有沉浸式扫码体验不被破坏

### 6. 群二维码分享已收口为鸿蒙系统分享优先

- 已更新 [utils/qrcode.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/utils/qrcode.uts)
- 已更新 [pages/message/group-qrcode.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/message/group-qrcode.uvue)
- 当前策略：
  - HarmonyOS 优先 `shareWithSystem`
  - 其他端保留现有 `uni.share`
- 结果：
  - 鸿蒙不再把微信 SDK 分享当成唯一可用分享路径

### 7. 检查更新已接入客户端服务层与静默检查入口

- 已新增 [api/app-upgrade.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/api/app-upgrade.uts)
- 已新增 [services/app-upgrade-service.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/services/app-upgrade-service.uts)
- 已更新 [pages/profile/settings.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/profile/settings.uvue)
- 已更新 [App.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/App.uvue)
- 当前能力：
  - 设置页支持手动检查更新
  - 前台支持节流后的静默检查
  - 支持 `NO_UPDATE / OPTIONAL_UPDATE / FORCE_UPDATE / BLOCKED`
  - 支持 HarmonyOS 应用市场动作分支
  - 设置页已新增“鸿蒙支持状态”区域，可直接展示：
    - 当前 HarmonyOS 版本
    - Harmony API 等级
    - 原生 AES runtime 是否已注入
    - 位置查看能力是否已接入
    - 系统相册图片/视频保存能力是否已在当前运行时检测到
    - 升级入口当前按 AppGallery / 市场建模

### 8. 鸿蒙工程配置已补 `app-harmony` 收口

- 已更新 [manifest.json](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/manifest.json)
- 当前已补齐：
  - `app-harmony.distribute.modules.uni-location.system`
  - `app-harmony.distribute.modules.uni-map.tencent`
- 这意味着：
  - 鸿蒙端地图/定位模块终于有了正式 manifest 落点
  - 后续 `unpackage/app-harmony` 原生工程生成时，不再完全缺少鸿蒙端模块配置基线

### 9. 位置查看与相册保存改为“按能力检测”，不再写死鸿蒙不支持

- 已更新 [services/harmony-readiness-service.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/services/harmony-readiness-service.uts)
- 已更新 [pages/message/chat.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat.uvue)
- 已更新 [pages/message/chat-files.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat-files.uvue)
- 已更新 [pages/profile/settings.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/profile/settings.uvue)
- 已更新 [locales/zh-CN.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/locales/zh-CN.uts)
- 已更新 [locales/en.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/locales/en.uts)
- 当前策略：
  - `openLocation` 不再假定一定可用，而是按运行时函数是否存在判断
  - `saveImageToPhotosAlbum` / `saveVideoToPhotosAlbum` 不再提前宣称“鸿蒙不支持”
  - 设置页直接展示当前位置查看/系统相册能力的真实检测结果
  - 设置页额外展示系统定位开关、App 定位授权状态
  - 位置卡片在 `openLocation` 未接入时，会退回“复制位置名称、地址、坐标”的业务兜底
- 这样做的价值：
  - 与 `uni-app x` 官方兼容表保持一致
  - 把“官方 API 已支持”和“当前项目是否已真正接入到位”这两件事明确拆开

### 10. Harmony AES 已补齐 provider 与运行时挂载入口

- 已更新 [components/captcha/utils/aes.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts)
- 已新增 [components/captcha/utils/harmony-aes-provider.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/harmony-aes-provider.uts)
- 已新增 [services/harmony-readiness-service.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/services/harmony-readiness-service.uts)
- 已更新 [components/captcha/slider-captcha.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/slider-captcha.uvue)
- 已更新 [App.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/App.uvue)
- 已更新 [pages/login/login.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/login/login.uvue)
- 当前状态：
  - 主调用链已具备 Harmony 分支
  - Provider 注册与运行时注入入口已就位
  - 已新增 `isHarmonyAESRuntimeReady()` 运行时就绪判断
  - 鸿蒙端滑块验证码在 runtime 缺失时已改为 fail-fast，不再继续发送明文 `pointJson/captchaVerification`
  - 登录页已在弹出滑块前做前置拦截，避免用户先做交互再失败
  - 启动日志、登录页、设置页已统一复用 `harmony-readiness-service.uts` 的诊断口径
  - 仍缺 ArkTS/原生插件的真实加解密实现

### 9. 当前仓库仍未具备可编译的 Harmony 原生工程

- 当前 `shengyu-ui/shengyu-ui-admin-uniappx` 仓库内尚未存在 `unpackage/app-harmony` 或独立提交的鸿蒙原生工程目录
- 这意味着：
  - 现阶段可以先完成 `uni-app x` 业务层差异化修复
  - 但“真实 ArkTS AES 落地”为止，仍需要补一套原生工程承载 `@kit.CryptoArchitectureKit` 或等价插件代码

结论：

- 目前项目状态已经从“鸿蒙验证码会假兼容”推进到“鸿蒙验证码会明确阻断并提示”
- 但还不能定义为“鸿蒙登录链路全部完成”

## 仍需继续施工的高优先级任务

### P0. Harmony AES 真实实现落地

目标：

- 不能让登录、验证码、关键加密链路在鸿蒙走“未支持”

建议文件：

- [components/captcha/utils/aes.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts)

建议方向：

- 新建鸿蒙专用 uts/ArkTS 插件封装 AES
- 将 ArkTS/原生实现通过 `setHarmonyAESRuntime(...)` 或等价方式注入运行时
- 不建议把加密逻辑简单降级到明文
- 建议先在原生工程中提供一组固定向量验收：
  - 明文：`{\"x\":42,\"y\":5}`
  - key：`0123456789abcdef`
  - 与 Android/Web 输出完全一致后，再切验证码真链路

### P0. 升级中心接口与字段正式对齐

目标：

- 将当前客户端服务层与平台端真实接口字段对齐并开始联调

建议文件：

- [api/app-upgrade.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/api/app-upgrade.uts)
- [services/app-upgrade-service.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/services/app-upgrade-service.uts)
- [pages/profile/settings.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/profile/settings.uvue)

联调要求：

- 平台返回 `platform = HARMONY`
- 执行动作为：
  - `OPEN_APP_GALLERY`
  - `OPEN_MARKET_DETAIL`
  - `SHOW_RELEASE_NOTE`
  - `BLOCKED`
- 事件上报至少覆盖：
  - `CHECK`
  - `SHOW_DIALOG`
  - `OPEN_APP_GALLERY`
  - `OPEN_STORE`

### P1. 鸿蒙工程配置基线入库

目标：

- 把编译鸿蒙所需配置沉淀到仓库，而不是只存在某台开发机里

建议新增：

- `manifest.json` 内鸿蒙专项配置补齐
- DevEco 打包、签名、证书、内部测试说明文档
- 原生工程目录或可追踪的 `app-harmony` 接入基线

### P1. 文件能力专项验证

重点验证：

- 聊天文件选择
- 聊天文件上传
- 文件下载
- 文档打开
- 图片保存
- 视频保存
- 大文件异常处理
- `content://`、临时路径、App 沙箱路径兼容性

### P1. 鸿蒙真机专项验证

重点验证：

- 扫码页进入与取消返回
- 群二维码系统分享
- 检查更新手动检查
- 检查更新静默检查
- 验证码获取与校验
- Harmony AES runtime 注入后加解密结果一致性

## 企业级改造建议

### 1. 平台建模必须把鸿蒙当成独立平台

- 禁止仅在枚举里补一个 `HARMONY` 就结束
- 必须同时具备：
  - 包资产类型
  - 渠道分发方式
  - 市场链接
  - AppGallery 状态
  - 开放测试/分阶段发布状态

参考：

- [多端升级设计任务文档.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/doc/多端升级/多端升级设计任务文档.md)
- [多端升级AI开工任务清单.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/doc/多端升级/多端升级AI开工任务清单.md)

### 2. 客户端判断平台要和“设备类型”分层

- `deviceType`
  - 服务于在线状态、设备列表、会话 Presence
- `clientPlatform`
  - 服务于升级中心、文件能力、扫码能力、分享能力、权限能力

这两个维度不能再混用。

### 3. 鸿蒙首期升级策略不要做成“Android 翻版”

- Android：
  - 可直接下载 apk 安装
- iOS：
  - App Store 跳转
- HarmonyOS：
  - 以 AppGallery / 市场详情页 / 测试通道为主

结论：

- 升级中心返回值必须是“动作模型”，不是简单的下载链接

## 建议验收清单

- 能在鸿蒙真机上正确识别 `platformCode = HARMONY`
- 能读到 `osHarmonySDKAPIVersion`
- 设置页“鸿蒙支持状态”展示与真机实际状态一致
- 设置页“检查更新”能走到平台接口
- 聊天文件可选、可传、可下、可打开
- 群二维码可保存到系统相册
- 分享至少存在一个不依赖微信 SDK 的可用链路
- 扫码页在鸿蒙上有可用方案，不出现空白页或不可用遮罩
- 登录、验证码、加密链路在鸿蒙不走降级明文

## 外部参考

- DCloud `uni-app x` 鸿蒙开发指南：
  - https://doc.dcloud.net.cn/uni-app-x/app-harmony/
- DCloud `uni.getDeviceInfo`：
  - https://doc.dcloud.net.cn/uni-app-x/api/get-device-info.html
- DCloud `uni.chooseFile`：
  - https://doc.dcloud.net.cn/uni-app-x/api/choose-file.html
- DCloud `uni.downloadFile`：
  - https://doc.dcloud.net.cn/uni-app-x/api/download-file.html
- DCloud `uni.openDocument`：
  - https://doc.dcloud.net.cn/uni-app-x/api/open-document.html
- DCloud `uni.scanCode`：
  - https://doc.dcloud.net.cn/uni-app-x/api/scan-code.html
- DCloud `uni.saveImageToPhotosAlbum`：
  - https://doc.dcloud.net.cn/uni-app-x/api/save-image-to-photos-album.html
- DCloud `uni.shareWithSystem`：
  - https://doc.dcloud.net.cn/uni-app-x/api/share-with-system.html
