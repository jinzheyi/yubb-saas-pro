# 平台端升级接口与 VO 落地草案

## 文档目标

- 本文档服务于 `shengyu-module-platform` 与 `shengyu-ui-platform-vue3` 的升级中心落地。
- 目标是把当前客户端已实现的升级请求契约，进一步映射到平台后端的 Controller、VO、枚举、日志字段和前端 API。
- 文档口径以当前工程结构和客户端现状为准。

## 适用范围

- 平台后端：
  - `shengyu-module-platform/shengyu-module-platform-biz`
- 平台前端：
  - `shengyu-ui/shengyu-ui-platform-vue3`
- 客户端对接参考：
  - [uni-app-x客户端升级接口契约草案.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/doc/多端升级/uni-app-x客户端升级接口契约草案.md)
  - [app-upgrade-service.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/services/app-upgrade-service.uts)

## 后端建议落点

### Controller

- 平台管理端：
  - `com.shengyu.module.platform.controller.platform.app.PlatformAppProductController`
  - `com.shengyu.module.platform.controller.platform.app.PlatformAppPackageController`
  - `com.shengyu.module.platform.controller.platform.app.PlatformAppReleaseController`
  - `com.shengyu.module.platform.controller.platform.app.PlatformAppChannelReleaseController`
  - `com.shengyu.module.platform.controller.platform.app.PlatformAppUpgradeLogController`
- 客户端接口：
  - `com.shengyu.module.platform.controller.app.appupgrade.AppUpgradeController`

### Service

- `PlatformAppProductService`
- `PlatformAppPackageService`
- `PlatformAppReleaseService`
- `PlatformAppChannelReleaseService`
- `PlatformAppUpgradeLogService`
- `AppUpgradeService`

### VO 包路径建议

- 平台管理 VO：
  - `com.shengyu.module.platform.controller.platform.app.vo`
- 客户端升级 VO：
  - `com.shengyu.module.platform.controller.app.appupgrade.vo`

## 客户端接口

### 1. 检查更新

- 路径：
  - `POST /app-api/system/app-upgrade/check`

建议 VO：

- `AppUpgradeCheckReqVO`
- `AppUpgradeCheckRespVO`

#### `AppUpgradeCheckReqVO` 建议字段

```java
public class AppUpgradeCheckReqVO {
    @NotBlank
    private String appCode;
    @NotBlank
    private String platform;
    @NotBlank
    private String channel;
    @NotBlank
    private String clientVersion;
    @NotNull
    private Integer clientVersionCode;
    @NotBlank
    private String deviceId;
    private Integer deviceType;
    private String osName;
    private String osVersion;
    private String manufacturer;
    private String model;
    private Integer harmonyApiVersion;
    private String harmonyDisplayVersion;
}
```

#### `AppUpgradeCheckRespVO` 建议字段

```java
public class AppUpgradeCheckRespVO {
    private String resultCode;
    private String title;
    private String content;
    private String releaseNotes;
    private String latestVersion;
    private Integer latestVersionCode;
    private Boolean forceUpdate;
    private String action;
    private String downloadUrl;
    private String storeUrl;
    private String marketUrl;
    private String webUrl;
    private LocalDateTime publishTime;
    private Long releaseId;
    private Long packageId;
    private Long channelReleaseId;
}
```

### 2. 升级事件回传

- 路径：
  - `POST /app-api/system/app-upgrade/report-event`

建议 VO：

- `AppUpgradeReportEventReqVO`

#### `AppUpgradeReportEventReqVO` 建议字段

```java
public class AppUpgradeReportEventReqVO {
    @NotBlank
    private String appCode;
    @NotBlank
    private String platform;
    @NotBlank
    private String eventType;
    @NotBlank
    private String clientVersion;
    @NotNull
    private Integer clientVersionCode;
    @NotBlank
    private String deviceId;
    private Map<String, Object> payload;
}
```

## 枚举建议

### 平台枚举 `AppPlatformEnum`

- `ANDROID`
- `IOS`
- `HARMONY`
- `WEB`
- `MINI_PROGRAM`

### 检查结果枚举 `AppUpgradeResultCodeEnum`

- `NO_UPDATE`
- `OPTIONAL_UPDATE`
- `FORCE_UPDATE`
- `BLOCKED`

### 动作枚举 `AppUpgradeActionEnum`

- `NONE`
- `OPEN_URL`
- `OPEN_STORE`
- `OPEN_APP_GALLERY`
- `REFRESH_WEB`

### 事件枚举 `AppUpgradeEventTypeEnum`

当前客户端已覆盖：

- `CHECK`
- `SHOW_DIALOG`
- `CLICK_UPDATE`
- `CLICK_CANCEL`
- `OPEN_STORE`
- `OPEN_APP_GALLERY`

平台端建议预留：

- `DOWNLOAD_START`
- `DOWNLOAD_SUCCESS`
- `DOWNLOAD_FAIL`
- `INSTALL_START`
- `INSTALL_FAIL`

## Controller 草案

### `AppUpgradeController`

```java
@Tag(name = "App 端 - 升级中心")
@RestController
@RequestMapping("/system/app-upgrade")
public class AppUpgradeController {

    @Resource
    private AppUpgradeService appUpgradeService;

    @PostMapping("/check")
    @Operation(summary = "检查更新")
    public CommonResult<AppUpgradeCheckRespVO> check(@Valid @RequestBody AppUpgradeCheckReqVO reqVO) {
        return success(appUpgradeService.check(reqVO));
    }

    @PostMapping("/report-event")
    @Operation(summary = "回传升级事件")
    public CommonResult<Boolean> reportEvent(@Valid @RequestBody AppUpgradeReportEventReqVO reqVO) {
        appUpgradeService.reportEvent(reqVO);
        return success(true);
    }
}
```

## Service 关键逻辑

### `check(reqVO)` 应做的事

1. 校验 `appCode + platform + channel`
2. 查询当前可见发布单
3. 过滤无效发布单：
   - 状态不是 `PUBLISHED`
   - 不在生效时间窗
   - 包资产不是 `READY`
4. 命中范围：
   - `ALL / TENANT / USER / CHANNEL / PERCENT`
5. 若平台为 `HARMONY`
   - 需要叠加渠道分发表状态
   - 仅当 `OFFICIAL_RELEASE / PHASED_RELEASE / OPEN_TEST` 满足条件时返回
6. 比较客户端版本
7. 输出：
   - `resultCode`
   - `action`
   - `latestVersion`
   - `releaseNotes`
   - `releaseId / packageId / channelReleaseId`

### `reportEvent(reqVO)` 应做的事

1. 记录升级日志
2. 尝试根据 `payload` 反查命中的 `releaseId`
3. 记录平台、版本、设备、事件类型
4. 保证失败不影响客户端主流程

## 升级日志表字段建议

结合现有 SQL 草案，建议在 `platform_app_upgrade_log.extra_json` 中重点记录：

- `trigger`
  - `manual` / `silent`
- `resultCode`
- `latestVersion`
- `action`
- `targetUrl`
- `releaseId`
- `packageId`
- `channelReleaseId`

## 平台前端 API 建议

建议新增目录：

- `shengyu-ui/shengyu-ui-platform-vue3/src/api/system/appManage`

建议文件：

- `product.ts`
- `package.ts`
- `release.ts`
- `channelRelease.ts`
- `upgradeLog.ts`

其中 `upgradeLog.ts` 至少支持：

- 分页查询日志
- 按 `platform / eventType / appCode / clientVersion / createTime` 过滤

## 与客户端当前实现的对齐说明

客户端当前已固定的行为：

- 手动检查：
  - `NO_UPDATE` toast
  - `OPTIONAL_UPDATE / FORCE_UPDATE` 弹窗
  - `BLOCKED` 阻断弹窗
- 静默检查：
  - 只处理 `FORCE_UPDATE / BLOCKED`
- 可选更新：
  - 支持按 `latestVersionCode` 本地忽略
- 事件：
  - `CHECK / SHOW_DIALOG / CLICK_UPDATE / CLICK_CANCEL / OPEN_*`

平台端不要与上述行为模型冲突。

## 平台后端第一阶段完成定义

- `/app-api/system/app-upgrade/check` 可返回标准结果码与动作
- `/app-api/system/app-upgrade/report-event` 可落库
- HarmonyOS 返回值支持 `OPEN_APP_GALLERY`
- 升级日志页能查到客户端事件
