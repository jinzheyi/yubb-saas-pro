# HarmonyAES 原生接入示例草案

## 文档目标

- 本文档用于指导鸿蒙原生或 ArkTS 实现如何接入当前 `uni-app x` 客户端的 AES provider。
- 目标是减少后续原生同学和客户端同学之间的接口扯皮。

## 当前客户端入口

- Provider 注册：
  - [aes.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts)
- Runtime 挂载入口：
  - [harmony-aes-provider.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/harmony-aes-provider.uts)
- App 启动挂载：
  - [App.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/App.uvue)
- 已预留的 Harmony UTS 插件目录：
  - [package.json](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/package.json)
  - [interface.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/interface.uts)
  - [index.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/app-harmony/index.uts)
  - [module.json5](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/app-harmony/module.json5)
  - [string.json](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/app-harmony/resources/base/element/string.json)

## 当前调用链

1. `App.uvue` 启动时调用 `bootstrapHarmonyAESProvider()`
2. `bootstrapHarmonyAESProvider()` 会优先尝试安装 `uni-im-harmony-aes` UTS 插件实现
3. `aes.uts` 在 `APP-HARMONY` 分支里调用 provider
4. provider 再从 `setHarmonyAESRuntime(...)` 挂入的 runtime 中取：
   - `encrypt(word, keyWord)`
   - `decrypt(word, keyWord)`
5. [slider-captcha.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/slider-captcha.uvue) 在 HarmonyOS 下会先检查 runtime 是否就绪，缺失时直接 fail-fast

## 当前可观测性

- 设置页鸿蒙状态区现在会展示：
  - AES 是否已注入
  - AES 来源是：
    - `Harmony UTS 插件`
    - `外部运行时注入`
    - `待接入`
- 对应实现位置：
  - [harmony-aes-provider.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/harmony-aes-provider.uts)
  - [harmony-readiness-service.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/services/harmony-readiness-service.uts)
  - [settings.uvue](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/pages/profile/settings.uvue)

## 客户端期望的 runtime 结构

```typescript
type HarmonyAESRuntime = {
  encrypt?: (word: string, keyWord: string) => string
  decrypt?: (word: string, keyWord: string) => string
}
```

## 建议接入方式

### 方案 A：优先走项目内 UTS 插件

- 直接在 [index.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/app-harmony/index.uts) 中补真实实现
- 插件基础工程模板已经具备：
  - `module.json5`
  - `resources/base/element/string.json`
- 让 `harmonyAesApi.isReady()` 在实现完成后返回 `true`
- 当前客户端启动时已会自动尝试安装该插件 runtime，无需再改业务调用层

### 方案 B：继续走外部 runtime 注入

如果后续仍要在鸿蒙原生层或 ArkTS 桥接初始化完成后手动注入，也可以调用：

```typescript
import { setHarmonyAESRuntime } from '@/components/captcha/utils/harmony-aes-provider.uts'

setHarmonyAESRuntime({
  encrypt(word: string, keyWord: string): string {
    // 调用 ArkTS / Native AES
    return word
  },
  decrypt(word: string, keyWord: string): string {
    // 调用 ArkTS / Native AES
    return word
  }
})
```

## 业务约束

- 这不是“可优化项”，而是当前滑块验证码在 HarmonyOS 上的必需项。
- 原因很直接：
  - `getCaptcha` 返回了 `secretKey`
  - `checkCaptcha` 需要提交加密后的 `pointJson`
  - 登录成功后还要继续生成加密后的 `captchaVerification`
- 如果 HarmonyOS 没有真实 AES 实现：
  - 旧逻辑会错误地发送明文
  - 服务端大概率直接判定校验失败
  - 现在客户端已改成 fail-fast，避免假兼容

## 建议原生工程放置方式

- 当前项目已经先在 `uni_modules/uni-im-harmony-aes/utssdk/app-harmony` 建了标准落点。
- 建议优先在该插件目录内补齐 ArkTS 实现，再决定是否需要下沉到 `unpackage/app-harmony` 做更深一层桥接。
- 如果后续必须下沉到鸿蒙原生工程，仍建议保持职责拆分：
  - `AesRuntime.ets` 负责 ArkTS AES ECB/PKCS7/Base64 实现
  - `UniHarmonyBridge.ets` 负责在应用启动后把 runtime 注入到 `setHarmonyAESRuntime(...)`

## 建议算法口径

客户端现有 Android / iOS / Web 口径是：

- AES
- ECB
- PKCS5 / PKCS7 Padding
- 结果字符串为 Base64

鸿蒙实现必须与现有口径一致，否则验证码验签会失败。

## ArkTS 实现骨架

下面给的是“可直接给原生同学开工”的实现骨架，真实项目里应放到鸿蒙原生工程，而不是直接放在 `uni-app x` 业务目录下：

```typescript
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { util } from '@kit.ArkTS'

function utf8Bytes(value: string): Uint8Array {
  const encoder = new util.TextEncoder()
  return encoder.encodeInto(value)
}

function utf8String(bytes: Uint8Array): string {
  const decoder = new util.TextDecoder('utf-8', { ignoreBOM: true })
  return decoder.decodeWithStream(bytes, { stream: false })
}

function buildAesParams(): cryptoFramework.IvParamsSpec {
  return { algName: 'AES128|ECB|PKCS7' }
}

export class HarmonyAesRuntime {
  static encrypt(word: string, keyWord: string): string {
    const cipher = cryptoFramework.createCipher('AES128|ECB|PKCS7')
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128')
    const keyData = utf8Bytes(keyWord)
    const symKey = symKeyGenerator.convertKey(keyData)
    cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, buildAesParams())
    const encrypted = cipher.doFinalSync(utf8Bytes(word))
    return util.Base64Helper.encodeToStringSync(encrypted)
  }

  static decrypt(word: string, keyWord: string): string {
    const cipher = cryptoFramework.createCipher('AES128|ECB|PKCS7')
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128')
    const keyData = utf8Bytes(keyWord)
    const symKey = symKeyGenerator.convertKey(keyData)
    cipher.initSync(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, buildAesParams())
    const raw = util.Base64Helper.decodeSync(word)
    const decrypted = cipher.doFinalSync(raw)
    return utf8String(decrypted)
  }
}
```

说明：

- 上述 API 名称需要以最终接入时的 HarmonyOS SDK 版本做一次校对
- 但设计要点不变：
  - `AES128|ECB|PKCS7`
  - UTF-8 输入输出
  - Base64 字符串返回
  - 通过桥接挂到 `setHarmonyAESRuntime(...)`

## 建议验收项

- 同一 `word + keyWord` 在 Android / iOS / HarmonyOS / Web 输出一致
- HarmonyOS `encrypt` 输出可被现有后端正常识别
- HarmonyOS `decrypt` 可还原现有客户端生成的数据
- 未注入 runtime 时，客户端应明确阻断验证码提交并提示加密环境未就绪

## 联调建议

- 先使用固定明文和固定 key 做跨端对照
- 再用真实验证码接口走一次完整链路
- 最后做真机登录和验证码校验
