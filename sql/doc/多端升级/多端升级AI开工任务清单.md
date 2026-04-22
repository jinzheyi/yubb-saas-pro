# 多端升级 AI 开工任务清单

## 文档目标

- 本文档是 [多端升级设计任务文档.md](./多端升级设计任务文档.md) 的执行清单版。
- 目标是让 AI 或开发同学可以按顺序直接开工，尽量减少二次推导。
- 本清单按三条主线拆分：
  - 平台后端：`shengyu-module-platform`
  - 平台前端：`shengyu-ui/shengyu-ui-platform-vue3`
  - 移动端客户端：`shengyu-ui/shengyu-ui-admin-uniappx`

## 开工总原则

鸿蒙专项开工前，先阅读：

- [uni-app-x鸿蒙支持差距与优化方案.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/doc/鸿蒙兼容/uni-app-x鸿蒙支持差距与优化方案.md)

### 范围冻结

本清单只覆盖：

- 平台端应用发布中心
- Android / iOS / HarmonyOS / Web 多端升级
- AppGallery Connect 协同建模
- uni-app x 客户端检查更新与执行

本清单不覆盖：

- iOS 企业签名分发
- MDM 企业设备管控
- Android 多厂商商店 API 自动发布
- 推送通知联动
- 发布审批流实现

### 企业级硬约束

- 升级中心必须归属平台端，禁止放到租户端实现。
- 文件仍统一走平台 `infra/file`，禁止新建第二套文件系统。
- 鸿蒙必须作为独立平台建模，禁止只在枚举上补一个 `HARMONY` 就结束。
- 客户端版本比较必须依赖整数版本号，禁止字符串比较。
- 平台灰度与 AppGallery 渠道灰度必须分别建模，最终取交集。

## 开工顺序

必须按以下顺序推进：

1. SQL 与领域模型
2. 平台后端基础 CRUD
3. 平台后端客户端检查接口
4. 平台前端管理页面
5. uni-app x 客户端服务层
6. 设置页接入与启动静默检查
7. 鸿蒙 AppGallery 分支
8. 升级日志与统计

补充要求：

- 在客户端设置页保留“鸿蒙支持状态”观测面板，至少展示：
  - HarmonyOS 版本
  - Harmony API 等级
  - 原生 AES runtime 注入状态
  - 系统分享能力状态
  - 升级入口类型
- 该面板不是演示 UI，而是后续真机联调、测试交付、租户验收的标准诊断入口
- 鸿蒙能力判断应统一收敛到一个 readiness service，禁止在登录页、设置页、启动逻辑里各自散写平台判断

## A1. SQL 与领域模型

### 目标

- 先把表结构、枚举和实体关系固定下来
- 后续接口和页面都基于这套模型实现

### 必须创建的表

- `platform_app_product`
- `platform_app_package`
- `platform_app_release`
- `platform_app_release_scope`
- `platform_app_channel_release`
- `platform_app_upgrade_log`

参考文档：

- [多端升级SQL草案.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/doc/多端升级/多端升级SQL草案.md)

### 后端文件落点

建议新增包：

- `shengyu-module-platform/shengyu-module-platform-biz/src/main/java/com/shengyu/module/platform/dal/dataobject/app`
- `shengyu-module-platform/shengyu-module-platform-biz/src/main/java/com/shengyu/module/platform/dal/mysql/app`
- `shengyu-module-platform/shengyu-module-platform-biz/src/main/java/com/shengyu/module/platform/enums/app`

### 本阶段完成定义

- 表结构已确定
- 所有枚举已定义
- `DO/Mapper` 可编译通过

## A2. 平台后端基础 CRUD

### 目标

- 建成平台端应用发布中心的管理接口

### 建议新增 Controller

- `PlatformAppProductController`
- `PlatformAppPackageController`
- `PlatformAppReleaseController`
- `PlatformAppChannelReleaseController`
- `PlatformAppUpgradeLogController`

建议路径：

- `com.shengyu.module.platform.controller.platform.app`

接口路径建议：

- `/system/app-product`
- `/system/app-package`
- `/system/app-release`
- `/system/app-channel-release`
- `/system/app-upgrade-log`

### 参考现有风格

可对齐：

- [PlatformTenantController.java](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-platform/shengyu-module-platform-biz/src/main/java/com/shengyu/module/platform/controller/platform/tenant/PlatformTenantController.java)

### 权限点

- `system:app-product:*`
- `system:app-package:*`
- `system:app-release:*`
- `system:app-channel-release:*`
- `system:app-upgrade-log:query`

### Service 层建议

- `PlatformAppProductService`
- `PlatformAppPackageService`
- `PlatformAppReleaseService`
- `PlatformAppChannelReleaseService`
- `PlatformAppUpgradeLogService`

### 核心校验

- Android 包创建时必须校验 `fileId`
- iOS 包创建时必须校验 `storeUrl`
- HarmonyOS 包创建时必须校验 `marketAppId` 或 `marketDetailUrl`
- Web 包创建时必须校验 `buildVersion`
- 发布单创建时必须校验包资产状态为 `READY`

### 本阶段完成定义

- 平台端 CRUD 接口齐全
- Swagger 可见
- 权限注解补齐
- 基础校验已落地

## A3. 平台后端客户端检查接口

### 目标

- 为移动端和 Web 提供统一的检查更新接口

### 必须新增 Controller

- `AppUpgradeController`

建议路径：

- `com.shengyu.module.platform.controller.app.appupgrade`

建议接口：

- `POST /system/app-upgrade/check`
- `POST /system/app-upgrade/report-event`

说明：

- 放在 `controller.app` 包下，交由 `/app-api/**` 自动路由

### 建议新增 VO

- `AppUpgradeCheckReqVO`
- `AppUpgradeCheckRespVO`
- `AppUpgradeReportEventReqVO`

### 核心逻辑

#### 检查更新

- 根据 `appCode + platform + channel` 取可用发布单
- 判断发布范围是否命中
- 若存在 `channel_release`，进一步校验外部渠道状态
- 与客户端版本比较，输出：
  - `NO_UPDATE`
  - `OPTIONAL_UPDATE`
  - `FORCE_UPDATE`
  - `BLOCKED`

#### 鸿蒙特殊逻辑

- 若平台为 `HARMONY`
- 且 `distributionMode=APP_GALLERY`
- 仅当渠道状态为以下之一时返回可更新：
  - `OFFICIAL_RELEASE`
  - `PHASED_RELEASE`
  - `OPEN_TEST` 且在测试范围内

#### 事件回传

- 记录 `CHECK`
- 记录 `SHOW_DIALOG`
- 记录 `CLICK_UPDATE`
- 记录 `OPEN_STORE`
- 记录 `OPEN_APP_GALLERY`
- 记录 `DOWNLOAD_*`

### 本阶段完成定义

- `/app-api/system/app-upgrade/check` 可联调
- `/app-api/system/app-upgrade/report-event` 可落库
- HarmonyOS 分支逻辑已纳入

## A4. 平台前端管理页面

### 目标

- 在 `shengyu-ui-platform-vue3` 建成完整管理页面

### 建议新增 API 目录

- `src/api/system/appManage/product.ts`
- `src/api/system/appManage/package.ts`
- `src/api/system/appManage/release.ts`
- `src/api/system/appManage/channelRelease.ts`
- `src/api/system/appManage/upgradeLog.ts`

### 建议新增页面目录

- `src/views/system/appManage/product/index.vue`
- `src/views/system/appManage/product/ProductForm.vue`
- `src/views/system/appManage/package/index.vue`
- `src/views/system/appManage/package/PackageForm.vue`
- `src/views/system/appManage/release/index.vue`
- `src/views/system/appManage/release/ReleaseForm.vue`
- `src/views/system/appManage/channelRelease/index.vue`
- `src/views/system/appManage/channelRelease/ChannelReleaseForm.vue`
- `src/views/system/appManage/upgradeLog/index.vue`

### 页面参考风格

对齐现有平台端页面：

- [tenant/index.vue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-platform-vue3/src/views/system/tenant/index.vue)
- [infra/file/index.vue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-platform-vue3/src/views/infra/file/index.vue)

### 页面职责

#### 应用管理

- 管理应用编码、名称、默认平台、状态

#### 安装包管理

- 上传 Android 包
- 录入 iOS Store URL
- 录入 HarmonyOS AppGallery 信息
- 录入 Web 构建版本

#### 发布管理

- 选择应用和包资产
- 配置强更、阻断、发布时间、生效时间
- 配置灰度

#### 渠道分发管理

- 维护 AppGallery 渠道状态
- 查看开放式测试、分阶段发布、正式发布
- 手动同步渠道状态

#### 升级统计

- 分平台查看检查更新次数
- 查看下载成功率
- 查看鸿蒙市场跳转情况

### 路由与菜单

前端静态路由不一定必须新增，但建议补开发用临时路由，便于联调。

可参考：

- [remaining.ts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-platform-vue3/src/router/modules/remaining.ts)

最终菜单建议由平台菜单管理动态配置。

### 本阶段完成定义

- 平台端可以完整管理应用、包、发布单、渠道分发
- 页面与权限点已对齐
- 与后端 CRUD 完成联调

## A5. uni-app x 客户端服务层

### 目标

- 在移动端建立统一升级服务层

### 建议新增文件

- `shengyu-ui/shengyu-ui-admin-uniappx/api/app-upgrade.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/services/app-upgrade-service.uts`

### `api/app-upgrade.uts` 职责

- 调用 `/system/app-upgrade/check`
- 调用 `/system/app-upgrade/report-event`

### `app-upgrade-service.uts` 职责

- 获取当前平台、版本、设备信息
- 封装手动检查更新
- 封装启动静默检查
- Android 下载与安装
- iOS 跳 App Store
- HarmonyOS 跳 AppGallery
- Web 刷新
- 事件上报

### 设备信息采集

建议上报：

- `appCode`
- `platform`
- `channel`
- `deviceId`
- `deviceType`
- `versionName`
- `versionCode`
- `buildVersion`
- `osVersion`
- `manufacturer`
- `model`
- `harmonyApiVersion`

### 本阶段完成定义

- 服务层已封装完成
- 手动/静默检查都可调用
- 各端执行逻辑分支已存在

当前客户端实际已完成：

- 已新增 `api/app-upgrade.uts`
- 已新增 `services/app-upgrade-service.uts`
- 已支持：
  - 手动检查
  - 前台静默检查
  - HarmonyOS AppGallery 跳转分支
  - Web 刷新分支
  - `CHECK / SHOW_DIALOG / CLICK_UPDATE / CLICK_CANCEL / OPEN_*` 事件上报
  - 可选版本本地忽略策略

当前仍待继续：

- Android 下载与安装真实链路
- 平台端 `/check`、`/report-event` 真联调
- 强更命中后的全局业务拦截页

## A6. 设置页接入与启动静默检查

### 目标

- 让设置页“检查更新”变成真实功能

### 必须修改

- [settings.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/profile/settings.uvue)

### 设置页行为

- 点击“检查更新”
  - 调用 `checkForUpdate({ manual: true })`
  - 无更新提示“当前已是最新版本”
  - 有更新弹出更新说明

### 启动静默检查建议接入点

- App 首页
- 登录成功后
- 冷启动
- 回到前台

### 强更拦截

- 强更时不可继续使用主业务页
- 推荐更新可关闭

### 本阶段完成定义

- 设置页完成真实联调

当前客户端实际已完成：

- 设置页已接真实服务层，不再是 toast 占位
- `App.uvue` 已接前台静默检查
- `BLOCKED` 已按阻断弹窗单独处理

当前仍待继续：

- 冷启动强更页或全局强更层
- 登录成功后专项检查入口
- 与平台发布说明富文本/长文本展示联调
- 启动静默检查生效
- 强更弹层生效

## A7. 鸿蒙 AppGallery 分支

### 目标

- 把鸿蒙做成独立升级主链路，而不是 Android 兼容分支

### 平台后端必须实现

- `platform=HARMONY`
- `distributionMode=APP_GALLERY`
- `platform_app_channel_release`
- AppGallery 状态校验

### 平台前端必须实现

- 鸿蒙包资产录入表单
- AppGallery 应用 ID / 详情页 / 外部状态字段
- 渠道分发管理页

### 客户端必须实现

- HarmonyOS 平台识别
- 点击更新时跳 AppGallery
- 上报 `OPEN_APP_GALLERY`

### 鸿蒙专属 DoD

- 平台能创建鸿蒙应用
- 平台能录入鸿蒙市场包
- 平台能维护 AppGallery 渠道状态
- 客户端命中鸿蒙更新后跳到市场
- 平台日志能看到鸿蒙命中和市场跳转

## A8. 升级日志与统计

### 目标

- 企业级能力必须具备可观测性

### 后端

- 汇总升级日志
- 提供分页查询
- 提供简单统计接口

### 前端

- 查询日志列表
- 按平台/应用/事件类型筛选
- 查看失败原因

### 至少要能看见

- 检查更新次数
- 命中次数
- Android 下载成功率
- iOS 商店跳转次数
- HarmonyOS AppGallery 跳转次数
- Web 刷新次数

## B1. 后端文件清单

建议新增：

- `.../controller/platform/app/PlatformAppProductController.java`
- `.../controller/platform/app/PlatformAppPackageController.java`
- `.../controller/platform/app/PlatformAppReleaseController.java`
- `.../controller/platform/app/PlatformAppChannelReleaseController.java`
- `.../controller/platform/app/PlatformAppUpgradeLogController.java`
- `.../controller/app/appupgrade/AppUpgradeController.java`

- `.../service/app/PlatformAppProductService.java`
- `.../service/app/PlatformAppPackageService.java`
- `.../service/app/PlatformAppReleaseService.java`
- `.../service/app/PlatformAppChannelReleaseService.java`
- `.../service/app/PlatformAppUpgradeLogService.java`
- `.../service/app/AppUpgradeService.java`

- `.../dal/dataobject/app/*`
- `.../dal/mysql/app/*`
- `.../controller/platform/app/vo/*`
- `.../controller/app/appupgrade/vo/*`
- `.../convert/app/*`
- `.../enums/app/*`

## B2. 平台前端文件清单

建议新增：

- `src/api/system/appManage/product.ts`
- `src/api/system/appManage/package.ts`
- `src/api/system/appManage/release.ts`
- `src/api/system/appManage/channelRelease.ts`
- `src/api/system/appManage/upgradeLog.ts`

- `src/views/system/appManage/product/index.vue`
- `src/views/system/appManage/product/ProductForm.vue`
- `src/views/system/appManage/package/index.vue`
- `src/views/system/appManage/package/PackageForm.vue`
- `src/views/system/appManage/release/index.vue`
- `src/views/system/appManage/release/ReleaseForm.vue`
- `src/views/system/appManage/channelRelease/index.vue`
- `src/views/system/appManage/channelRelease/ChannelReleaseForm.vue`
- `src/views/system/appManage/upgradeLog/index.vue`

## B3. 移动端文件清单

建议新增：

- `shengyu-ui/shengyu-ui-admin-uniappx/api/app-upgrade.uts`
- `shengyu-ui/shengyu-ui-admin-uniappx/services/app-upgrade-service.uts`

必须修改：

- [settings.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/profile/settings.uvue)
- 可能涉及启动页或首页入口文件

## DoD

只有同时满足以下条件，本期升级中心才算完成：

1. 平台端能管理应用、安装包、发布单、渠道分发和升级日志
2. Android 可整包升级
3. iOS 可跳 App Store
4. HarmonyOS 可跳 AppGallery，且命中逻辑受渠道状态约束
5. Web 可识别版本并刷新
6. 强更能够阻断继续使用
7. 平台侧能看到终端升级日志
