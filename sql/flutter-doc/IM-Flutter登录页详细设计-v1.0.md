# IM Flutter 登录页详细设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter 登录页的页面结构、登录方式、初始化链路、异常与状态详细设计  

---

## 1. 目标

把登录页设计推进到可直接编码的粒度，并明确登录成功后的初始化责任边界。

---

## 2. 页面职责

`LoginPage` 负责：

- 账号登录
- 手机验证码登录
- 语言切换入口
- 验证码触发
- remember account
- 登录提交与反馈

不负责：

- 主壳初始化编排
- websocket 持久状态管理
- 业务首页跳转策略复杂判断

这些由 `AuthBootstrapCoordinator` 负责。

---

## 3. 页面结构

推荐组件树：

- `LoginScaffold`
  - `LoginTopActions`
  - `LoginHeroSection`
  - `LoginCard`
    - `LoginModeTabs`
    - `AccountLoginForm`
    - `MobileLoginForm`
    - `LoginActionBar`
  - `LanguageBottomSheet`
  - `CaptchaOverlay`
  - `LoginFooter`

---

## 4. 页面状态

### 4.1 `LoginPageState`

建议字段：

- `status`
- `loginMode`
- `username`
- `password`
- `mobile`
- `smsCode`
- `rememberAccount`
- `showLanguageSheet`
- `showCaptcha`
- `captchaRequired`
- `captchaVerification`
- `smsCountdown`
- `languageMode`
- `loadingMessage`
- `errorMessage`

### 4.2 状态枚举

- `idle`
- `validating`
- `captchaRequired`
- `submitting`
- `bootstrapLoading`
- `success`
- `failed`

---

## 5. 登录方式

### 5.1 账号登录

字段：

- `username`
- `password`

规则：

- 任一为空时不可提交
- 可接入滑块验证码

### 5.2 手机验证码登录

字段：

- `mobile`
- `smsCode`

规则：

- 手机号格式校验
- 验证码发送节流
- 倒计时展示

---

## 6. 语言入口

### 6.1 位置

- 登录页顶部右上角

### 6.2 行为

- 打开语言设置底部面板
- 切换语言后立即生效
- 不依赖服务端同步

---

## 7. 验证码策略

### 7.1 设计原则

- 验证码能力为可插拔能力
- 登录页只感知 `CaptchaFacade`
- 不直接感知平台特定实现

### 7.2 页面行为

- 账号登录提交前检查是否需要验证码
- 验证码成功后继续登录链路
- 验证码失败给出轻提示

---

## 8. 登录成功后初始化链路

页面提交成功后只触发：

1. 保存 token
2. 获取 permission info
3. 保存 current user / device info
4. 初始化 badge
5. 建立 websocket
6. 跳转主壳

责任划分：

- `LoginController`：触发登录请求
- `AuthBootstrapCoordinator`：完成 2~6 步

---

## 9. remember account 策略

### 9.1 保留内容

- 只保留账号名

### 9.2 不保留内容

- 不保留明文密码

### 9.3 存储位置

- 本地 KV

---

## 10. controller 设计

### 10.1 `LoginController`

建议动作：

- `switchLoginMode()`
- `inputUsername()`
- `inputPassword()`
- `inputMobile()`
- `inputSmsCode()`
- `toggleRememberAccount()`
- `openLanguageSheet()`
- `closeLanguageSheet()`
- `requestSmsCode()`
- `submitAccountLogin()`
- `submitMobileLogin()`
- `handleCaptchaSuccess()`
- `handleCaptchaFail()`

### 10.2 use case 建议

- `AccountLoginUseCase`
- `SmsLoginUseCase`
- `SendSmsCodeUseCase`
- `LoadRememberedAccountUseCase`
- `PersistRememberedAccountUseCase`
- `AuthBootstrapCoordinator`

---

## 11. 异常处理

### 11.1 表单异常

- 输入缺失
- 手机号格式错误
- 验证码为空

### 11.2 业务异常

- 账号密码错误
- 验证码错误
- token 刷新失败
- permission info 获取失败

### 11.3 连接异常

- 登录成功但 websocket 初始化失败

规则：

- 不在页面层做复杂重试编排
- 统一由 bootstrap coordinator 处理重试与降级

---

## 12. 多端布局

### 12.1 Mobile

- 居中表单卡片
- 语言入口顶部悬浮

### 12.2 Web/Desktop

- 中间对齐登录工作区
- 表单宽度固定上限
- 保持安静、企业工具风格

---

## 13. 验收标准

1. 两种登录方式可切换
2. 登录成功后进入主壳
3. permission info 与 websocket 初始化链路完整
4. 语言切换立即生效
5. remember account 仅保存账号名

