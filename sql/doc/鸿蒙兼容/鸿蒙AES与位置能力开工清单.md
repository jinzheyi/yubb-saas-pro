# 鸿蒙 AES 与位置能力开工清单

## 文档目标

- 这份文档只服务于 `shengyu-ui/shengyu-ui-admin-uniappx` 的鸿蒙落地。
- 目标是让后续 AI 或原生同学可以直接按清单开工，而不是再从头梳理现状。

## 当前代码现状

### 1. Harmony AES 业务链路已就位

- 滑块验证码业务层已经具备 Harmony runtime 挂载入口：
  - [harmony-aes-provider.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/harmony-aes-provider.uts)
  - [aes.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts)
  - [slider-captcha.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/slider-captcha.uvue)
- 未注入 AES runtime 时，登录前已经会被安全阻断，不再提交明文验证码数据。

### 2. Harmony AES 的 UTS 插件落点已创建

- 当前插件目录：
  - [package.json](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/package.json)
  - [interface.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/interface.uts)
  - [index.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/app-harmony/index.uts)
  - [config.json](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/app-harmony/config.json)
- 当前状态：
  - 只建好了标准 `uni_modules -> utssdk -> app-harmony` 目录骨架
  - 还没有真实 ArkTS AES 实现
  - 还没有把该插件接入运行时

### 3. 位置能力当前状态

- `openLocation` 当前仍未正式接入 `uni-openlocation`
- 但客户端已经补了三层可观测性：
  - 运行时是否检测到 `openLocation`
  - App 定位权限状态
  - 系统定位总开关状态
- 位置卡片当前兜底行为：
  - 无 `openLocation` 时，允许复制位置名称、地址、经纬度

## 第一块：Harmony AES 开工清单

### 必做项

1. 在 [index.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/app-harmony/index.uts) 中补真实 ArkTS AES 实现。
   当前客户端启动时已经会自动尝试安装该插件 runtime，所以实现完成后不需要再改业务层调用链，只需要让 `isReady()` 返回 `true`。
2. 算法口径必须与现有 Android/iOS/Web 一致：
   - AES
   - ECB
   - PKCS7
   - Base64 输出
   - UTF-8 输入输出
3. 补完后，在客户端新增一个明确的 runtime 注入动作，把插件实现挂到 `setHarmonyAESRuntime(...)`。
4. 用固定明文和固定 key 做 Android / iOS / Web / Harmony 四端对照。
5. 再走一次真实滑块验证码完整链路：
   - `getCaptcha`
   - 前端滑块校验
   - `checkCaptcha`
   - 登录提交 `captchaVerification`

### 暂时不要做错的事

- 不要在 Harmony 下恢复“返回明文”的降级逻辑。
- 不要在没有四端对照前就假定 ArkTS 输出和 Android 一致。
- 不要在业务层直接写鸿蒙专用加密逻辑，应该统一走插件或 runtime 挂载入口。

## 第二块：位置能力开工清单

### 必做项

1. 按 `uni-app x` 官方要求接入 `uni-openlocation` 插件。
2. 在鸿蒙配置里补齐位置权限声明：
   - `ohos.permission.APPROXIMATELY_LOCATION`
   - `ohos.permission.LOCATION`
3. 接完后用设置页的鸿蒙状态区复核三件事：
   - `openLocation` 是否已检测到
   - App 定位权限是否已授权
   - 系统定位开关是否开启
4. 用真机验证三条链路：
   - 位置卡片打开
   - 当前位置获取
   - 地图页选择位置

### 当前现成观测点

- [harmony-readiness-service.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/services/harmony-readiness-service.uts)
- [settings.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/profile/settings.uvue)
- [chat.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat.uvue)

## 建议执行顺序

1. 先完成 Harmony AES 的真实 ArkTS 实现并做四端对照。
2. 再把插件实现挂进 `setHarmonyAESRuntime(...)`，放开鸿蒙滑块验证码。
3. 然后接 `uni-openlocation` 和鸿蒙位置权限。
4. 最后做一轮鸿蒙专项真机回归：
   - 登录
   - 扫码
   - 文件发送
   - 图片保存
   - 视频保存
   - 位置查看
   - 设置页检查更新

## 备注

- 多端升级方案仍然是后续第二阶段工作，不能和这份鸿蒙兼容清单混在一起推进。
- 这份清单只处理“把移动 IM 的鸿蒙支持补齐”。
