# 验证码组件

## 简介

基于 AJ-Captcha 的 UniApp X 验证码组件，支持滑块验证码和点选验证码。

## 功能特性

- ✅ 滑块验证码（blockPuzzle）
- ⏳ 点选验证码（clickWord）- 待实现
- ✅ 触摸滑动交互
- ✅ 验证成功/失败提示
- ✅ 自动刷新机制
- ✅ UUID 持久化
- ✅ 完整的错误处理

## 快速开始

### 1. 引入组件

```vue
<template>
  <view>
    <button @click="showCaptcha">显示验证码</button>
    
    <slider-captcha 
      ref="captchaRef"
      captchaType="blockPuzzle"
      @success="handleSuccess"
      @fail="handleFail"
    />
  </view>
</template>

<script setup lang="uts">
import SliderCaptcha from '@/components/captcha/slider-captcha.uvue'

const captchaRef = ref<any>(null)

function showCaptcha() {
  if (captchaRef.value) {
    captchaRef.value.show()
  }
}

function handleSuccess(data: any) {
  console.log('验证成功', data.captchaVerification)
}

function handleFail() {
  console.log('验证失败')
}
</script>
```

### 2. 配置后端地址

编辑 `config/app.config.uts`:

```typescript
export const BASE_URL = 'http://localhost:48080'
```

### 3. 启用验证码

编辑 `config/app.config.uts`:

```typescript
export const CAPTCHA_ENABLE = 'true'
```

## API

### Props

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| captchaType | String | 'blockPuzzle' | 验证码类型 |

### Events

| 事件名 | 参数 | 说明 |
|--------|------|------|
| success | { captchaVerification: string } | 验证成功回调 |
| fail | - | 验证失败回调 |

### Methods

| 方法名 | 参数 | 说明 |
|--------|------|------|
| show | - | 显示验证码 |
| refresh | - | 刷新验证码 |

## 目录结构

```
components/captcha/
├── slider-captcha.uvue      # 滑块验证码组件
├── utils/
│   ├── aes.uts              # AES 加密工具
│   └── harmony-aes-provider.uts # HarmonyOS AES provider 挂载入口
└── README.md                # 本文件
```

## 注意事项

1. **AES 加密**: Android / iOS / Web 已有现成链路，HarmonyOS 生产环境必须接入真实 ArkTS/原生 AES runtime，不能继续走明文降级
2. **坐标转换**: 滑动距离需要按比例转换为标准坐标（310x155）
3. **UUID 持久化**: 使用 `uni.getStorageSync` 持久化存储，避免频繁生成
4. **触摸事件**: 使用 `@touchstart`、`@touchmove`、`@touchend` 处理滑动

## HarmonyOS 接入

当前鸿蒙链路已经预留了运行时挂载入口，但还需要你们补真实 ArkTS/原生实现。

### 1. App 启动时已自动注册 provider

`App.uvue` 已调用：

```typescript
bootstrapHarmonyAESProvider()
```

### 2. 真实加密实现通过运行时注入

建议在鸿蒙原生层或 ArkTS 桥接完成后调用：

```typescript
import { setHarmonyAESRuntime } from '@/components/captcha/utils/harmony-aes-provider.uts'

setHarmonyAESRuntime({
  encrypt(word: string, keyWord: string): string {
    // 调用 ArkTS / 原生 AES 实现
    return word
  },
  decrypt(word: string, keyWord: string): string {
    // 调用 ArkTS / 原生 AES 实现
    return word
  }
})
```

项目内也已经预留了标准 Harmony UTS 插件落点，后续优先在这里补真实实现：

- [package.json](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/package.json)
- [interface.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/interface.uts)
- [index.uts](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-uniappx/uni_modules/uni-im-harmony-aes/utssdk/app-harmony/index.uts)

### 3. 当前状态说明

- 客户端调用层已经具备 HarmonyOS 分支
- Provider 注册链路已经就位
- 真正缺的是 `encrypt/decrypt` 的原生实现
- `slider-captcha.uvue` 已在 HarmonyOS 下增加 fail-fast 保护
- 未注入 runtime 时，滑块验证码会直接中止并提示“鸿蒙端安全加密未就绪”，不会再提交明文校验数据

## 常见问题

### Q: 验证码不显示？
A: 检查后端接口地址是否正确，查看控制台错误信息

### Q: 滑动不流畅？
A: 检查触摸事件是否正确绑定，确保没有其他元素遮挡

### Q: 验证总是失败？
A: 检查坐标转换是否正确，确认后端接口返回正常

### Q: 加密报错？
A: 如果是 HarmonyOS，这不是普通兼容问题，而是必须补真实 ArkTS/原生 AES 实现，否则滑块验证码不会放行

## 更多文档

- [完整实现总结](../../App端验证码实现完成总结.md)
- [快速使用指南](../../验证码快速使用指南.md)
- [官方文档](https://ajcaptcha.beliefteam.cn/captcha-doc/captchaDoc/uni-app.html)

## License

MIT
