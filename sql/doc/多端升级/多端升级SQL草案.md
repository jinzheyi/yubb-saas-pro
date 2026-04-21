# 多端升级 SQL 草案

## 设计原则

- 版本中心归属平台端
- 包文件继续复用 `infra_file`
- 升级领域与文件领域拆开建模
- 首期支持 Android / iOS / HarmonyOS / Web
- 首期支持平台灰度与外部分发渠道状态协同
- 首期支持全量、租户、用户、渠道灰度
- 所有版本比较统一依赖整数型 `version_code/build_version`

## 一、应用主表 `platform_app_product`

```sql
CREATE TABLE `platform_app_product` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app_code` varchar(64) NOT NULL COMMENT '应用编码，如 shengyu-im-mobile',
  `app_name` varchar(128) NOT NULL COMMENT '应用名称',
  `app_type` varchar(32) NOT NULL COMMENT '应用类型：MOBILE_IM/WEB/H5/OTHER',
  `description` varchar(500) DEFAULT NULL COMMENT '说明',
  `default_platform` varchar(16) DEFAULT NULL COMMENT '默认平台：ANDROID/IOS/HARMONY/WEB',
  `enabled` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否启用',
  `sort` int NOT NULL DEFAULT 0 COMMENT '排序',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_code` (`app_code`),
  KEY `idx_app_type` (`app_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='应用主表';
```

## 二、安装包资产表 `platform_app_package`

```sql
CREATE TABLE `platform_app_package` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app_code` varchar(64) NOT NULL COMMENT '应用编码',
  `platform` varchar(16) NOT NULL COMMENT '平台：ANDROID/IOS/HARMONY/WEB',
  `channel` varchar(32) NOT NULL DEFAULT 'official' COMMENT '渠道：official/huawei/xiaomi/test/enterprise',
  `package_type` varchar(24) NOT NULL COMMENT '包类型：APK/STORE/HARMONY_APP_GALLERY/HARMONY_APP_BUNDLE/WEB_BUILD',
  `distribution_mode` varchar(24) NOT NULL DEFAULT 'DIRECT' COMMENT '分发模式：DIRECT/APP_STORE/APP_GALLERY/WEB_REFRESH',
  `package_name` varchar(128) DEFAULT NULL COMMENT '包名/应用标识',
  `version_name` varchar(32) NOT NULL COMMENT '版本名称',
  `version_code` int NOT NULL COMMENT '版本号',
  `build_version` bigint DEFAULT NULL COMMENT '构建号，Web 必填，App 可选',
  `os_version_min` varchar(32) DEFAULT NULL COMMENT '最低系统版本要求',
  `store_url` varchar(512) DEFAULT NULL COMMENT 'App Store 地址或外部分发地址',
  `market_app_id` varchar(128) DEFAULT NULL COMMENT '外部市场应用ID，如 AppGallery App ID',
  `market_package_name` varchar(128) DEFAULT NULL COMMENT '市场包名/Bundle Name',
  `market_detail_url` varchar(512) DEFAULT NULL COMMENT '市场详情页地址',
  `file_id` bigint DEFAULT NULL COMMENT '关联 infra_file.id',
  `file_url` varchar(512) DEFAULT NULL COMMENT '文件访问地址冗余',
  `file_name` varchar(255) DEFAULT NULL COMMENT '文件名',
  `file_size` bigint DEFAULT NULL COMMENT '文件大小',
  `file_md5` varchar(64) DEFAULT NULL COMMENT 'MD5',
  `file_sha256` varchar(128) DEFAULT NULL COMMENT 'SHA256',
  `status` varchar(16) NOT NULL DEFAULT 'READY' COMMENT '状态：DRAFT/READY/DISABLED',
  `ext_json` json DEFAULT NULL COMMENT '扩展字段',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_app_platform_channel` (`app_code`, `platform`, `channel`),
  KEY `idx_version_code` (`version_code`),
  KEY `idx_build_version` (`build_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='安装包资产表';
```

## 三、发布单表 `platform_app_release`

```sql
CREATE TABLE `platform_app_release` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app_code` varchar(64) NOT NULL COMMENT '应用编码',
  `package_id` bigint NOT NULL COMMENT '安装包资产ID',
  `release_no` varchar(64) NOT NULL COMMENT '发布单号',
  `platform` varchar(16) NOT NULL COMMENT '平台',
  `channel` varchar(32) NOT NULL DEFAULT 'official' COMMENT '渠道',
  `release_title` varchar(128) NOT NULL COMMENT '发布标题',
  `release_notes` text COMMENT '发布说明',
  `force_update` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否强制更新',
  `block_use` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否阻断使用',
  `silent_update` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否静默更新，预留',
  `min_support_version_code` int DEFAULT NULL COMMENT '最低支持版本，小于该版本需升级',
  `status` varchar(16) NOT NULL DEFAULT 'DRAFT' COMMENT '状态：DRAFT/SCHEDULED/PUBLISHED/OFFLINE/ROLLED_BACK',
  `publish_time` datetime DEFAULT NULL COMMENT '发布时间',
  `effective_time` datetime DEFAULT NULL COMMENT '生效时间',
  `offline_time` datetime DEFAULT NULL COMMENT '下线时间',
  `priority` int NOT NULL DEFAULT 0 COMMENT '优先级，越大越优先',
  `rollback_target_release_id` bigint DEFAULT NULL COMMENT '回滚目标发布单',
  `channel_sync_required` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否要求渠道状态同步后才可对外生效',
  `ext_json` json DEFAULT NULL COMMENT '扩展字段',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_release_no` (`release_no`),
  KEY `idx_app_platform_channel_status` (`app_code`, `platform`, `channel`, `status`),
  KEY `idx_effective_time` (`effective_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='发布单表';
```

## 四、发布范围表 `platform_app_release_scope`

```sql
CREATE TABLE `platform_app_release_scope` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `release_id` bigint NOT NULL COMMENT '发布单ID',
  `scope_type` varchar(16) NOT NULL COMMENT '范围类型：ALL/TENANT/USER/CHANNEL/PERCENT',
  `scope_value` varchar(128) DEFAULT NULL COMMENT '范围值：tenantId/userId/channel',
  `percent_value` int DEFAULT NULL COMMENT '百分比灰度 0-100',
  `sort` int NOT NULL DEFAULT 0 COMMENT '排序',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_release_id` (`release_id`),
  KEY `idx_scope_type_value` (`scope_type`, `scope_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='发布范围表';
```

## 五、渠道分发表 `platform_app_channel_release`

```sql
CREATE TABLE `platform_app_channel_release` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `release_id` bigint NOT NULL COMMENT '发布单ID',
  `channel_type` varchar(24) NOT NULL COMMENT '渠道类型：APP_STORE/APP_GALLERY/ANDROID_MARKET/INTERNAL',
  `external_app_id` varchar(128) DEFAULT NULL COMMENT '外部应用ID',
  `external_release_id` varchar(128) DEFAULT NULL COMMENT '外部版本/发布ID',
  `external_release_no` varchar(128) DEFAULT NULL COMMENT '外部发布单号',
  `external_status` varchar(32) DEFAULT NULL COMMENT '外部状态：OPEN_TEST/PHASED_RELEASE/OFFICIAL_RELEASE/PAUSED/REJECTED',
  `distribution_mode` varchar(24) NOT NULL COMMENT '分发模式：STORE_TEST/STORE_PHASED/STORE_OFFICIAL/DIRECT',
  `open_testing` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否开放式测试',
  `phased_release` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否分阶段发布',
  `phased_percent` int DEFAULT NULL COMMENT '分阶段发布比例 0-100',
  `sync_status` varchar(16) NOT NULL DEFAULT 'PENDING' COMMENT '同步状态：PENDING/SYNCED/FAILED',
  `last_sync_time` datetime DEFAULT NULL COMMENT '最近同步时间',
  `sync_message` varchar(500) DEFAULT NULL COMMENT '同步消息',
  `ext_json` json DEFAULT NULL COMMENT '扩展字段',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_release_id` (`release_id`),
  KEY `idx_channel_type_status` (`channel_type`, `external_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='渠道分发表';
```

## 六、升级事件日志表 `platform_app_upgrade_log`

```sql
CREATE TABLE `platform_app_upgrade_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `app_code` varchar(64) NOT NULL COMMENT '应用编码',
  `platform` varchar(16) NOT NULL COMMENT '平台',
  `channel` varchar(32) DEFAULT NULL COMMENT '渠道',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户ID',
  `user_id` bigint DEFAULT NULL COMMENT '用户ID',
  `device_id` varchar(128) DEFAULT NULL COMMENT '设备ID',
  `device_type` int DEFAULT NULL COMMENT '设备类型',
  `os_version` varchar(64) DEFAULT NULL COMMENT '系统版本',
  `manufacturer` varchar(64) DEFAULT NULL COMMENT '厂商',
  `model` varchar(128) DEFAULT NULL COMMENT '机型',
  `current_version_name` varchar(32) DEFAULT NULL COMMENT '当前版本名',
  `current_version_code` int DEFAULT NULL COMMENT '当前版本号',
  `current_build_version` bigint DEFAULT NULL COMMENT '当前构建号',
  `release_id` bigint DEFAULT NULL COMMENT '命中的发布单ID',
  `package_id` bigint DEFAULT NULL COMMENT '命中的安装包ID',
  `channel_release_id` bigint DEFAULT NULL COMMENT '命中的渠道分发记录ID',
  `event_type` varchar(32) NOT NULL COMMENT '事件类型',
  `success` bit(1) NOT NULL DEFAULT b'1' COMMENT '是否成功',
  `message` varchar(500) DEFAULT NULL COMMENT '结果消息',
  `extra_json` json DEFAULT NULL COMMENT '扩展信息',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_app_platform_time` (`app_code`, `platform`, `create_time`),
  KEY `idx_tenant_user` (`tenant_id`, `user_id`),
  KEY `idx_release_event` (`release_id`, `event_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='升级事件日志表';
```

## 七、可选审批表 `platform_app_release_approval`

如果后续要做“发布审批流”，建议预留该表。

```sql
CREATE TABLE `platform_app_release_approval` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `release_id` bigint NOT NULL COMMENT '发布单ID',
  `status` varchar(16) NOT NULL DEFAULT 'PENDING' COMMENT '状态：PENDING/APPROVED/REJECTED',
  `approver_user_id` bigint DEFAULT NULL COMMENT '审批人',
  `approve_time` datetime DEFAULT NULL COMMENT '审批时间',
  `approve_remark` varchar(500) DEFAULT NULL COMMENT '审批备注',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_release_id` (`release_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='发布审批表';
```

## 数据关系说明

- `platform_app_product` 1:N `platform_app_package`
- `platform_app_package` 1:N `platform_app_release`
- `platform_app_release` 1:N `platform_app_release_scope`
- `platform_app_release` 1:N `platform_app_channel_release`
- `platform_app_release` 1:N `platform_app_upgrade_log`
- `platform_app_package.file_id` -> `infra_file.id`

## 关键约束建议

### 包资产约束

- 同一 `app_code + platform + channel + version_code + build_version` 不建议重复
- Android 包必须有 `file_id`
- iOS 商店包必须有 `store_url`
- HarmonyOS AppGallery 包必须有 `market_app_id` 或 `market_detail_url`
- Web 构建包必须有 `build_version`

### 发布约束

- 只有 `READY` 状态的包资产可以创建发布单
- 一个发布单发布后，若同范围存在更高优先级发布单，需要按优先级返回
- 强更发布单建议必须填写 `min_support_version_code`
- 若 `distribution_mode in ('APP_STORE', 'APP_GALLERY')`，建议同时存在对应 `platform_app_channel_release`

## 推荐初始化数据

### 初始化应用

```sql
INSERT INTO `platform_app_product`
(`app_code`, `app_name`, `app_type`, `default_platform`, `enabled`, `sort`)
VALUES
('shengyu-im-mobile', '圣钰IM移动端', 'MOBILE_IM', 'ANDROID', b'1', 100),
('shengyu-im-harmony', '圣钰IM鸿蒙端', 'MOBILE_IM', 'HARMONY', b'1', 95),
('shengyu-im-web', '圣钰IM Web端', 'WEB', 'WEB', b'1', 90);
```

### 初始化 Android 包资产示例

```sql
INSERT INTO `platform_app_package`
(`app_code`, `platform`, `channel`, `package_type`, `distribution_mode`, `package_name`, `version_name`, `version_code`,
 `file_id`, `file_url`, `file_name`, `file_size`, `file_md5`, `status`)
VALUES
('shengyu-im-mobile', 'ANDROID', 'official', 'APK', 'DIRECT', 'com.shengyu.im', '1.0.1', 101,
 10001, 'https://cdn.example.com/im/1.0.1/app.apk', 'shengyu-im-1.0.1.apk', 52428800,
 'd41d8cd98f00b204e9800998ecf8427e', 'READY');
```

### 初始化 HarmonyOS 市场资产示例

```sql
INSERT INTO `platform_app_package`
(`app_code`, `platform`, `channel`, `package_type`, `distribution_mode`, `package_name`,
 `version_name`, `version_code`, `market_app_id`, `market_package_name`, `market_detail_url`, `status`)
VALUES
('shengyu-im-harmony', 'HARMONY', 'official', 'HARMONY_APP_GALLERY', 'APP_GALLERY',
 'com.shengyu.im', '1.0.1', 101, 'appgallery-100001', 'com.shengyu.im',
 'https://appgallery.huawei.com/app/detail?id=appgallery-100001', 'READY');
```

### 初始化发布单示例

```sql
INSERT INTO `platform_app_release`
(`app_code`, `package_id`, `release_no`, `platform`, `channel`, `release_title`, `release_notes`,
 `force_update`, `block_use`, `min_support_version_code`, `status`, `publish_time`, `effective_time`, `priority`, `channel_sync_required`)
VALUES
('shengyu-im-mobile', 1, 'REL202604210001', 'ANDROID', 'official', '1.0.1版本发布',
 '修复若干已知问题，优化会话同步与文件发送体验', b'0', b'0', 100,
 'PUBLISHED', NOW(), NOW(), 100, b'0'),
('shengyu-im-harmony', 2, 'REL202604210002', 'HARMONY', 'official', '1.0.1鸿蒙版本发布',
 '鸿蒙版本首发，修复会话列表刷新与文件发送稳定性问题', b'0', b'0', 100,
 'PUBLISHED', NOW(), NOW(), 100, b'1');
```

### 初始化全量范围

```sql
INSERT INTO `platform_app_release_scope`
(`release_id`, `scope_type`, `scope_value`, `percent_value`, `sort`)
VALUES
(1, 'ALL', NULL, NULL, 100),
(2, 'ALL', NULL, NULL, 100);
```

### 初始化 HarmonyOS 渠道分发示例

```sql
INSERT INTO `platform_app_channel_release`
(`release_id`, `channel_type`, `external_app_id`, `external_release_id`, `external_status`,
 `distribution_mode`, `open_testing`, `phased_release`, `phased_percent`, `sync_status`, `last_sync_time`)
VALUES
(2, 'APP_GALLERY', 'appgallery-100001', 'harmony-release-20260421', 'OFFICIAL_RELEASE',
 'STORE_OFFICIAL', b'0', b'0', NULL, 'SYNCED', NOW());
```

## 检查更新查询口径

建议后端按以下顺序处理：

1. 根据 `app_code + platform + channel` 查询发布单
2. 过滤 `status in ('PUBLISHED')`
3. 过滤 `effective_time <= NOW()`
4. 过滤 `offline_time is null or offline_time > NOW()`
5. 根据发布范围表判断是否命中：
   - USER
   - TENANT
   - CHANNEL
   - PERCENT
   - ALL
6. 按 `priority desc`、包版本 `version_code desc / build_version desc` 排序
7. 取第一条作为命中结果
8. 若该发布单存在渠道分发记录，则继续判断外部状态是否可分发
9. 与客户端当前版本比较，返回：
   - `NO_UPDATE`
   - `OPTIONAL_UPDATE`
   - `FORCE_UPDATE`
   - `BLOCKED`

对 HarmonyOS 建议增加：

- 当 `channel_type='APP_GALLERY'` 时，仅在以下状态下允许向客户端返回可升级结果：
  - `OFFICIAL_RELEASE`
  - `PHASED_RELEASE`
  - `OPEN_TEST` 且当前用户在测试范围内

## 事件类型建议

`platform_app_upgrade_log.event_type` 建议枚举：

- `CHECK`
- `HIT_UPDATE`
- `SHOW_DIALOG`
- `CLICK_UPDATE`
- `DOWNLOAD_START`
- `DOWNLOAD_SUCCESS`
- `DOWNLOAD_FAIL`
- `INSTALL_TRIGGER`
- `OPEN_STORE`
- `OPEN_APP_GALLERY`
- `REFRESH_TRIGGER`
- `UPGRADE_CANCEL`

## 与当前工程的衔接建议

### 后端

- 表放平台域
- Controller 放 `shengyu-module-platform`
- 文件上传继续调用平台侧 `infra/file`
- 鸿蒙市场分发信息单独建渠道分发表，不塞在发布单备注中

### 平台前端

- 文件选择/上传可直接复用现有 `src/api/infra/file/index.ts`
- 页面风格复用现有 `system/tenant`、`infra/file` 的列表 + 表单模式

### 移动端

- 检查更新接口走 `/app-api/system/app-upgrade/check`
- 不直接操作平台端管理接口
- 鸿蒙客户端建议消费：
  - `market_app_id`
  - `market_detail_url`
  - `channel_release_id`

## 后续增强表

如果后续需要更强运营能力，可追加：

- `platform_app_download_token`
  - 下载令牌表，用于受控下载
- `platform_app_release_tenant_snapshot`
  - 发布时展开租户快照，提升匹配性能
- `platform_app_upgrade_daily_stat`
  - 日维度聚合统计表
- `platform_app_market_sync_log`
  - 市场状态同步日志，尤其用于鸿蒙 AppGallery 状态回写

## 联网参考资料

- DCloud 升级中心
  - https://doc.dcloud.net.cn/uniCloud/upgrade-center
- uni-app x 鸿蒙开发指南
  - https://doc.dcloud.net.cn/uni-app-x/app-harmony/
- HTML5+ Runtime API
  - https://www.html5plus.org/doc/zh_cn/runtime.html
- 华为 AppGallery Connect
  - https://developer.huawei.com/consumer/en/agconnect/
- 华为分阶段发布
  - https://developer.huawei.com/consumer/cn/agconnect/phased-release
- 华为开放式测试
  - https://developer.huawei.com/consumer/cn/agconnect/open-test/
