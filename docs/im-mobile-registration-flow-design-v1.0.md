# 钰信 App 注册与企业加入流程设计 v1.0

## 1. 目标

钰信 App 当前适合“已由平台或租户后台创建账号后登录”的模式，但客户首次安装 App 后，如果没有账号，就无法创建自己的企业。注册能力需要解决三个问题：

1. 新客户可以在 App 内用邮箱注册主账号，并创建一个属于自己的企业。
2. 一个自然人账号只能拥有一个自己创建/管理的企业，但可以加入多家别人的企业。
3. 已有企业员工可以通过邀请、企业码或管理员审核加入企业；现阶段审核口子预留，默认自动通过。
4. 被邀请的用户登录后，必须主动切换到被邀请企业，才算真正确认加入该企业。

设计原则：账号身份、租户员工身份、平台租户管理要分层，App 注册不能直接暴露平台后台的完整租户创建权限。

## 2. 现有源码结论

### 2.1 身份模型

当前系统已经具备“一人多租户”的基础数据结构：

- `system_saas_user`：全局自然人账号，保存邮箱账号、手机号、密码、默认租户。
- `system_users`：租户内员工账号，保存昵称、部门、状态、头像、租户编号。
- `system_users.saas_user_id` 指向 `system_saas_user.id`，并有 `idx_saas_user_tenant` 索引。

对应代码：

- [SaasUserDO.java](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/dal/dataobject/user/SaasUserDO.java:29)
- [AdminUserDO.java](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/dal/dataobject/user/AdminUserDO.java:25)
- [shengyu-saas.sql](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/mysql/1.0/shengyu-saas.sql:2599)

### 2.2 登录与租户切换

App 登录复用租户端认证服务，但已单独走 `/app-api/system/auth/login`，且 App 登录不受 Web 管理端图形验证码开关影响。

App 已有租户切换接口：

- `GET /app-api/system/user/get-my-tenant-list`
- `POST /app-api/system/auth/to-tenant`

Flutter 端已经实现：

- `AuthRemoteDataSource.getMyTenantList()`
- `AuthRemoteDataSource.toTenant()`
- `TenantSwitchPage` 左侧企业切换面板
- `TenantSwitchPage` 底部已有“创建/加入企业”按钮，但目前是 TODO。

对应代码：

- [AppAuthController.java](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/auth/AppAuthController.java:69)
- [AdminAuthServiceImpl.java](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/auth/AdminAuthServiceImpl.java:114)
- [AppUserController.java](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/user/AppUserController.java:208)
- [auth_remote_data_source.dart](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/auth/auth_remote_data_source.dart:120)
- [tenant_switch_page.dart](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/profile/presentation/pages/tenant_switch_page.dart:186)

### 2.3 Web 租户端现有用户邀请逻辑

租户端用户管理已经支持“拉用户加入企业”的雏形：

- 新增用户时，邮箱账号和手机号二选一；现阶段为了省短信成本，应以邮箱作为主账号，手机号只作为预留字段。
- 新增用户后，`AdminUserServiceImpl.createUser()` 会把租户内 `system_users.status` 设置为 `AWAIT(-1)`，即“等待确认”。
- Web 列表中 `AWAIT` 会显示为“等待确认”，不能直接通过启停开关操作。
- 被邀请用户登录后，租户切换组件 `MyTenant` 调用 `toTenant()`；后端 `setSaasUserInfo()` 会在用户切换进入该租户时把 `AWAIT` 改为 `ENABLE(0)`。

这说明当前系统已有“邀请先占位，用户主动切换确认加入”的业务基础，只是产品文案、状态流转和唯一性校验还不够完整。

对应代码：

- [UserForm.vue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-vue3/src/views/system/user/UserForm.vue:24)
- [index.vue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-vue3/src/views/system/user/index.vue:118)
- [MyTenant.vue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-vue3/src/layout/components/MyTenant/src/MyTenant.vue:27)
- [AdminUserServiceImpl.java](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/user/AdminUserServiceImpl.java:166)
- [AdminAuthServiceImpl.java](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/auth/AdminAuthServiceImpl.java:508)

### 2.4 现有阻断点

`AdminUserServiceImpl.validateSaasUserIdUnique()` 当前按全局 `saasUserId` 查询 `system_users`，如果该自然人已存在任意租户员工身份，会阻断再次加入其它租户。这与“一个账号切换多个企业”的目标冲突。

需要调整为：

- `system_saas_user.username` 和 `system_saas_user.mobile` 仍保持全局唯一。
- `system_users` 只限制同一 `tenant_id + saas_user_id + deleted` 唯一。
- 同一个 `saas_user_id` 可以在多个租户内存在不同的 `system_users` 记录。
- 同一个 `saas_user_id` 只能拥有一个自己创建的租户；加入别人企业不受该限制。

对应代码：

- [AdminUserServiceImpl.java](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/service/user/AdminUserServiceImpl.java:650)
- [AdminUserMapper.java](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/dal/mysql/user/AdminUserMapper.java:23)

## 3. 注册业务边界

注册不是单一动作，而是三类入口：

1. 创建企业：面向新客户，注册个人账号并自动创建一个租户，当前注册人成为该租户管理员；每个自然人账号只能创建一个自有企业。
2. 加入已有企业：面向员工，通过邀请码、企业码、邀请链接、邮箱匹配等方式申请加入；现阶段默认自动通过，后续可切换为管理员审核。
3. 完善个人账号：面向已被后台预创建但未登录过的员工，首次登录或短信验证后补密码、昵称、头像。

平台层负责默认租户配置、审核策略、全局风控；租户层负责员工审批、部门/角色分配；App 端负责采集信息、展示流程状态和完成登录/切换。

## 4. App 端用户流程

### 4.1 未登录首页

登录页新增三个入口：

- 账号密码登录：保留现状。
- 手机号验证码登录：保留入口和接口能力，现阶段未配置短信时不作为主链路。
- 注册/加入企业：新增。

点击“注册/加入企业”后进入选择页：

- 创建企业试用
- 加入已有企业
- 我已有账号，返回登录

### 4.2 创建企业试用

用户输入：

- 邮箱，必填，作为现阶段主账号和登录账号。
- 邮箱验证码，推荐第一阶段先预留字段；如果邮件发送能力稳定，可直接启用。
- 手机号，可选预留，不参与现阶段注册校验。
- 姓名/昵称，必填。
- 企业名称，必填。
- 规模，可选：1-10、11-50、51-200、200+。
- 行业，可选。
- 密码，可选。若不填，系统创建随机密码并提示后续可在“我的-账号安全”设置。

提交后服务端动作：

1. 校验邮箱格式；如果启用邮箱验证码，则校验邮箱验证码。
2. 根据手机号/邮箱查找或创建 `system_saas_user`。
3. 校验该 `system_saas_user` 是否已经拥有自有企业；如果已有，则不允许再次创建，只能进入该企业或加入别人企业。
4. 创建企业租户，使用平台默认套餐、账号额度 `1000`、到期时间 `2099-12-31 23:59:59`。
5. 在新租户下创建 `system_users` 员工身份，状态为启用。
6. 赋予租户管理员角色，并写入 `tenant.contact_user_id`。
7. 更新 `system_saas_user.default_tenant` 为新租户。
8. 直接签发 App token，返回登录态。

推荐创建企业默认值：

- 套餐：平台配置 `shengyu.app-register.default-package-id`。
- 账号额度：1000。
- 到期时间：`2099-12-31 23:59:59`，由 `shengyu.app-register.default-expire-time` 覆盖。
- 域名：共享官网入口时 `tenant.website` 为空；该字段必须是唯一域名，企业配置独立子域名后再由平台管理员绑定，不能将官网主域名重复写入每个企业。
- 审核：当前自动开通；后续可按手机号、IP、设备、企业名称命中风控后进入人工审核。

### 4.3 被租户管理员邀请加入企业

这是现有 Web 租户端“新增用户”的主流程，需要优先完善。

租户管理员在 Web 租户端新增员工：

- 邮箱账号必填或强引导填写，手机号继续保留但不是现阶段主路径。
- 可选择部门、岗位、角色。
- 提交后如果该邮箱不存在 `system_saas_user`，则创建全局账号并发送邀请邮件；如果已存在，则复用该全局账号。
- 在当前租户下创建 `system_users`，状态为 `AWAIT(-1)`。

被邀请用户收到邮件后：

1. 打开 App。
2. 使用邮箱和初始密码登录；如果用户已经有账号，则用原密码登录。
3. 登录成功后，App 的企业列表展示该企业，状态显示为“待确认加入”。
4. 用户点击该企业进行切换。
5. 后端 `toTenant()` 把该企业下的员工状态从 `AWAIT` 改为 `ENABLE`，该动作才算真正加入。
6. App 清理旧租户缓存，保存新 token，进入目标企业会话/通讯录。

该流程的好处：

- 企业管理员可以先配置部门、岗位、角色。
- 用户必须主动进入企业，避免被别人乱拉后立即产生有效身份。
- 不依赖短信，符合现阶段省钱目标。

### 4.4 用户主动申请加入已有企业

加入方式分三种，优先级从易用到可控：

1. 邀请链接/二维码：企业管理员从租户后台生成，App 扫码或打开链接后带 `inviteCode`。
2. 企业码：企业后台展示短码，员工手动输入。
3. 企业名称搜索：只展示允许公开加入的企业，并且默认走申请审批。

员工输入：

- 邮箱账号，必填。
- 邮箱验证码或密码校验，二选一；第一阶段可先用密码校验，验证码口子预留。
- 姓名/昵称，必填。
- 邀请码/企业码/企业名称，三选一。
- 申请说明，可选。

提交后服务端动作：

1. 校验邮箱账号身份。
2. 查找或创建 `system_saas_user`。
3. 判断该 `saas_user_id` 是否已在目标租户存在员工身份。
4. 不存在则创建 `system_users`：
   - 邀请链接允许自动通过时，状态为启用。
   - 企业码或搜索加入默认状态为 `AWAIT`。
5. 生成站内通知/IM 系统通知给租户管理员。
6. 如果自动通过，直接返回目标租户 token；如果待审核，返回申请单状态，不进入企业数据。

现阶段策略：

- 邀请码、企业码、搜索加入都默认自动通过，但仍写入申请/加入来源，方便后续切换为人工审核。
- 自动通过并不代表直接进入目标企业；如果用户当前已登录其它企业，仍应引导用户主动切换到目标企业，切换成功后完成缓存隔离和 WebSocket 重连。

审批通过后：

- 租户管理员在租户 Web 后台或 App 管理入口审批。
- 系统把员工状态改为启用。
- 用户再次打开 App 可看到该企业，或收到通知后点击切换。

## 5. 后端接口设计

### 5.1 App 公开接口

新增 Controller：`AppRegisterController`

路径前缀：`/app-api/system/register`

接口：

- `POST /send-sms-code`：注册/加入企业验证码。
- `POST /send-email-code`：注册/加入企业邮箱验证码，现阶段推荐预留或优先实现。
- `POST /trial-tenant`：创建试用企业并登录。
- `POST /activate-invited-tenant`：登录用户确认加入被邀请企业，本质上可复用 `toTenant()`，但建议提供更明确的业务接口或在 App 层用明确文案包装。
- `POST /join-by-invite`：通过邀请码加入企业。
- `POST /join-by-code`：通过企业码申请加入。
- `GET /join-status`：查询我的加入申请状态。
- `GET /public-tenant/search`：公开企业搜索，可配置是否开放。

这些 URL 要加入 `shengyu.tenant.ignore-urls`，因为注册前还没有租户上下文。

第一阶段为了省成本，可以不启用短信接口，只保留手机号字段和短信接口定义；注册身份校验以邮箱 + 密码/邮箱验证码为准。

### 5.2 租户端管理接口

新增或扩展租户端接口：

- `GET /admin-api/system/tenant-join/page`：待审批员工申请。
- `POST /admin-api/system/tenant-join/approve`：通过申请。
- `POST /admin-api/system/tenant-join/reject`：拒绝申请。
- `POST /admin-api/system/tenant-invite/create`：创建企业邀请码/邀请链接。
- `POST /admin-api/system/tenant-invite/disable`：停用邀请码。

权限建议：

- `system:tenant-join:query`
- `system:tenant-join:audit`
- `system:tenant-invite:create`
- `system:tenant-invite:update`

### 5.3 平台端配置接口

平台层新增“App 注册配置”页面，先做最小闭环：

- 是否允许 App 自助注册。
- 默认试用套餐。
- 默认试用天数。
- 默认账号数。
- 每个自然人账号是否只能创建一个自有企业，默认是。
- 是否需要平台人工审核试用企业。
- 是否允许公开搜索企业。
- 默认加入审批策略：邀请自动通过、企业码需审批、搜索需审批。

这部分放在 `platform` 对应服务端和 Vue 平台端实现，不放到租户端。

## 6. 数据库设计

### 6.1 新增平台配置表

`platform_app_register_config`

核心字段：

- `id`
- `enabled`
- `default_package_id`
- `trial_days`
- `account_count`
- `trial_audit_required`
- `one_owned_tenant_per_saas_user`
- `public_tenant_search_enabled`
- `invite_auto_approve_enabled`
- `tenant_code_join_audit_required`
- `remark`

也可以第一阶段先走 `infra_config`，减少表数量；企业级长期建议独立表。

### 6.2 新增企业邀请码表

`system_tenant_invite`

租户表，带 `tenant_id`：

- `id`
- `invite_code`
- `name`
- `expire_time`
- `max_use_count`
- `used_count`
- `auto_approve`
- `default_dept_id`
- `default_role_ids`
- `status`
- `creator`
- `create_time`

唯一索引：`tenant_id + invite_code + deleted`

### 6.3 新增加入申请表

`system_tenant_join_request`

租户表，带 `tenant_id`：

- `id`
- `saas_user_id`
- `user_id`
- `mobile`
- `username`
- `nickname`
- `source`
- `invite_code`
- `apply_reason`
- `status`
- `audit_user_id`
- `audit_time`
- `reject_reason`
- `create_time`

唯一约束建议：同一租户、同一 `saas_user_id` 只能存在一个未完成申请。

### 6.4 新增自有企业归属字段

为了表达“一个用户只能拥有一个属于自己的企业”，建议二选一：

方案 A：在 `tenant` 表新增 `owner_saas_user_id`

- 查询简单，平台端筛选试用企业方便。
- 创建租户时直接写入 owner。
- 校验 `owner_saas_user_id + deleted` 唯一即可。

方案 B：新增 `platform_tenant_owner`

- 结构更清晰，后续支持转让、多个共有人、销售线索归属。
- 第一阶段开发量稍多。

推荐第一阶段用方案 A，后续商业化复杂后再迁移到独立表。

### 6.5 调整现有唯一校验

必须把 `validateSaasUserIdUnique()` 调整为租户内校验：

- 新增 `AdminUserMapper.selectByTenantIdAndSaasUserId(Long tenantId, Long saasUserId)`。
- 创建用户时只判断当前 `TenantContextHolder.getTenantId()` 下是否已存在。
- SQL 增加唯一索引 `uk_tenant_saas_user_deleted(tenant_id, saas_user_id, deleted)`，避免并发重复加入。
- 创建试用租户时校验 `tenant.owner_saas_user_id`，确保同一全局账号只能创建一个自有企业。

## 7. Flutter App 端设计

### 7.1 页面结构

新增 feature：`features/register`

页面：

- `RegisterEntryPage`：创建企业 / 加入企业选择。
- `TrialTenantRegisterPage`：试用企业注册表单。
- `JoinTenantPage`：加入企业表单。
- `JoinTenantStatusPage`：申请处理中、被拒绝、已通过。
- `InvitedTenantConfirmPage`：待确认加入企业，展示企业名、邀请来源、确认加入按钮。

路由：

- `/register`
- `/register/trial-tenant`
- `/register/join-tenant`
- `/register/join-status`

入口：

- 登录页底部新增“注册/加入企业”。
- 租户切换页底部“创建/加入企业”跳转到 `/register`，登录态存在时可复用当前账号信息。
- 企业列表中 `AWAIT` 状态企业展示“待确认加入”，点击时弹出确认页，确认后再调用 `toTenant()`。

### 7.2 状态处理

未登录注册成功：

- 后端返回 `AuthLoginRespVO`。
- App 复用 `AuthSessionController.saveSession()`。
- 复用登录后的 `warmStart()`、推送设备注册、WebSocket 认证。

已登录加入新企业：

- 如果返回 token，直接调用租户切换保存逻辑。
- 如果返回待审核状态，只刷新租户列表，不清理当前租户会话。
- 如果返回待确认状态，企业列表显示“待确认加入”，用户主动切换后才正式加入。

注册失败：

- 统一走现有 `AppErrorMapper`，展示服务端业务错误信息。

### 7.3 本地数据隔离

创建企业或切换到新企业后，沿用 `TenantSwitchService._clearTenantScopedData()` 的策略：

- 清空本地 IM 数据库。
- 清空会话、联系人、群组等租户作用域缓存。
- 重新保存 token。
- 重新连接 WebSocket。

## 8. Web 管理端设计

### 8.1 租户端

租户 Web 后台新增：

- 企业邀请：生成邀请二维码、邀请链接、企业码；第一阶段可先保留现有“新增用户”表单，只优化为“邀请成员”语义。
- 加入审批：审批来自 App 的员工申请。
- 默认部门/角色：邀请配置中可选，减少管理员后续操作。

第一阶段建议：

- 把“用户管理-新增”文案改为“邀请成员”或在弹窗说明“成员登录并切换到本企业后才正式加入”。
- 邮箱作为主账号字段，手机号标记为选填预留。
- 保留 `AWAIT` 状态，并在列表中增加“重新发送邀请邮件”“取消邀请”两个动作。
- 加入审批页面和二维码后续再做，现阶段审核口子预留、默认自动通过。

### 8.2 平台端

平台 Web 后台新增：

- App 注册配置。
- 试用企业列表筛选。
- 可疑注册记录查看。

为了控制 AI token 和开发成本，第一阶段不做复杂 CRM 线索管理、不做付费套餐购买闭环、不做短信供应商后台配置扩展；手机号与短信能力只保留口子，待后续真实配置短信服务后再启用。

## 9. 安全与风控

必须做：

- 邮箱主账号唯一性校验。
- 邮箱验证码或密码校验；如果邮箱发送能力暂未稳定，先使用密码校验。
- 手机号字段预留，不作为现阶段强校验。
- 同设备、同 IP 注册频率限制。
- 企业名称敏感词/重复校验。
- 邀请码过期、使用次数、停用状态校验。
- 注册接口不接受前端传入任意 `packageId`、`accountCount`、`expireTime`，这些只能由平台配置决定。
- 同一 `saas_user_id` 只能创建一个自有企业。

暂不做：

- 复杂实名认证。
- 对公打款认证。
- 商店支付。
- 多级渠道分销。

## 10. 推荐落地顺序

第一阶段：最小可用试用闭环

1. 修复 `saasUserId` 多租户唯一校验。
2. 增加自有企业归属校验，限制一个账号只能创建一个企业。
3. 后端新增 App 注册 Controller 和 Service，主账号使用邮箱。
4. 平台配置先使用 `infra_config` 或固定配置项。
5. App 增加“注册/加入企业”入口和创建试用企业流程。
6. 注册成功后自动登录进入会话页。
7. 租户端“新增用户”文案调整为邀请成员，明确“对方切换到企业后才正式加入”。

第二阶段：加入企业闭环

1. 新增企业邀请码表和加入申请表。
2. 租户后台增加邀请码和审批页面，但审批默认自动通过。
3. App 增加入企业、申请状态、确认加入与切换企业。

第三阶段：商业化增强

1. 平台端 App 注册配置页。
2. 试用企业转正式客户管理。
3. 官网/销售入口联动。
4. 邀请二维码、分享链接、注册来源统计。

## 11. 与现有上线体系的关系

该功能涉及后端、Flutter、租户 Vue、平台 Vue、SQL 四处变更。后续实施时需要同步：

- `shengyu-server`
- `shengyu-ui-admin-flutter`
- `shengyu-ui-admin-vue3`
- `shengyu-ui-platform-vue3`
- `sql/mysql/1.0/shengyu-saas.sql`
- `sql/mysql/1.0/shengyu-saas-dev.sql`
- `sql/mysql/1.0/prod_add.sql`
- 最终上线部署说明

上线前需要验证：

- 新邮箱创建试用企业并自动登录。
- 已有邮箱再次创建试用企业时被拦截，并提示只能加入其它企业或进入自己的企业。
- 已有邮箱被租户管理员邀请后，登录能看到“待确认加入”的企业。
- 用户主动切换到被邀请企业后，`system_users.status` 从 `AWAIT` 变为 `ENABLE`。
- 已有邮箱通过邀请码加入企业。
- 待审核员工不能读取目标租户数据。
- 审批通过后 App 可看到新企业并切换。
- 旧租户会话、本地缓存不会串到新租户。

## 12. 当前落地记录

### 12.0 站点定位说明（2026-09-09）

当前站点用于产品演示，但系统业务模型保持企业级通用语义：App 的“创建企业”创建标准租户，默认不设置到期时间。站点定位不进入接口、表结构或产品文案；付费、CRM 等商业运营能力不属于当前注册与加入链路。

本次第一阶段已按“最小可用试用闭环”完成落地：

- 后端新增 App 公开注册接口 `POST /app-api/system/register/trial-tenant`，以邮箱作为主账号，注册成功后自动创建试用租户并返回 App 登录态。
- 后端新增 `tenant.owner_saas_user_id`，用于限制同一个自然人账号只能创建一个自有企业。
- 后端调整 `system_users` 的 SaaS 用户唯一校验为租户内唯一，支持同一个账号加入多家企业。
- 租户管理员在 Web 端邀请成员时，邮箱账号改为主路径，手机号保留为预留字段；被邀请成员保持“待确认加入”，登录后主动切换企业才正式加入。
- App 登录页新增“注册/加入企业”入口，新增试用企业注册页；企业切换页支持展示并确认“待确认加入”的企业。
- 全量开源 SQL `shengyu-saas.sql` 已同步新字段和索引，生产增量脚本 `prod_add.sql` 已追加幂等升级语句。

当前阶段刻意不做以下旁系能力，避免功能面过大：

- 不做短信验证码注册，手机号仅预留。
- 不做企业码、邀请码、二维码和加入申请审批页面。
- 不做平台 CRM 线索、实名认证、支付购买闭环。
- 不开放前端传入套餐、账号数、试用天数；这些只从服务端配置读取。

后续第二阶段继续做“主动加入已有企业”时，应优先补：

- 企业邀请码/邀请链接表。
- 加入申请表与审批状态。
- 租户端审批列表。
- App 端扫码、输入企业码、查看申请状态。

### 12.1 第二阶段发布记录（2026-09-09）

- 已完成邀请码创建、停用、有效期/次数校验和自动通过开关；不做二维码，App 采用邀请码输入。
- 已完成加入申请、管理员通过/拒绝和用户主动切换企业确认加入的状态闭环。
- 租户 Web 后台入口为“系统管理 -> 企业邀请”，仅租户管理员通过现有用户邀请权限操作。
- 未实现独立审计、公开企业搜索、短信/邮箱验证码和运营统计；这些不影响当前企业加入主链路。
