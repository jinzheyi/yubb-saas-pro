# UniApp X 国际化 - 快速参考

**版本**: v1.0.0  
**更新日期**: 2026-01-28

---

## 快速开始

### 1. 在组件中使用

```vue
<template>
	<view>
		<text>{{ t('common.login') }}</text>
		<button @click="handleSwitchLocale">切换语言</button>
	</view>
</template>

<script setup lang="uts">
	import { useI18n } from '@/hooks/useI18n.uts'
	
	const { t, locale, switchLocale } = useI18n()
	
	function handleSwitchLocale() {
		const newLocale = locale.value === 'zh-CN' ? 'en' : 'zh-CN'
		switchLocale(newLocale)
	}
</script>
```

### 2. 在脚本中使用

```typescript
import { t } from '@/store/locale.uts'

const text = t('common.login')  // "登录"
```

---

## API 速查

### useI18n()

```typescript
const { t, locale, availableLocales, messages, switchLocale, setLocale } = useI18n()
```

| 属性/方法 | 类型 | 说明 |
|----------|------|------|
| `t` | `(key: string, defaultValue?: string) => string` | 翻译函数 |
| `locale` | `Ref<LocaleType>` | 当前语言（响应式） |
| `availableLocales` | `Ref<LocaleConfig[]>` | 可用语言列表 |
| `messages` | `ComputedRef<any>` | 当前语言包 |
| `switchLocale` | `(locale: LocaleType) => void` | 切换语言（带提示） |
| `setLocale` | `(locale: LocaleType) => void` | 设置语言（无提示） |

### store/locale.uts

| 函数 | 说明 |
|------|------|
| `getCurrentLocale()` | 获取当前语言 |
| `setCurrentLocale(locale)` | 设置当前语言 |
| `getAvailableLocales()` | 获取可用语言列表 |
| `getCurrentMessages()` | 获取当前语言包 |
| `t(key, defaultValue?)` | 翻译函数 |
| `switchLocale(locale)` | 切换语言（带提示） |
| `getSystemLocale()` | 获取系统语言 |
| `initLocale()` | 初始化语言 |

---

## 常用翻译键

### common（通用）
```typescript
t('common.login')          // 登录
t('common.loginOut')       // 退出系统
t('common.back')           // 返回
t('common.ok')             // 确定
t('common.save')           // 保存
t('common.cancel')         // 取消
t('common.success')        // 成功
```

### login（登录）
```typescript
t('login.welcome')                  // 欢迎使用本系统
t('login.username')                 // 邮箱账号
t('login.password')                 // 密码
t('login.usernamePlaceholder')      // 请输入邮箱账号
t('login.passwordPlaceholder')      // 请输入密码
t('login.remember')                 // 记住我
t('login.mobileNumber')             // 手机号码
t('login.getSmsCode')               // 获取验证码
t('login.btnMobile')                // 手机号登录
t('login.btnAccount')               // 账号密码登录
```

### captcha（验证码）
```typescript
t('captcha.verify')         // 验证
t('captcha.verification')   // 请完成安全验证
t('captcha.slide')          // 向右滑动完成验证
t('captcha.success')        // 验证成功
t('captcha.fail')           // 验证失败
```

### sys（系统）
```typescript
t('sys.api.errorMessage')           // 操作失败,系统异常!
t('sys.api.timeoutMessage')         // 登录超时,请重新登录!
t('sys.api.networkException')       // 网络异常
t('sys.login.loginSuccessTitle')    // 登录成功
t('sys.login.loginSuccessDesc')     // 欢迎回来
```

---

## 语言切换器示例

```vue
<template>
	<view class="locale-switch">
		<text 
			v-for="item in availableLocales" 
			:key="item.lang"
			@click="handleSwitchLocale(item.lang)"
			:class="['locale-item', { active: locale === item.lang }]"
		>
			{{ item.name }}
		</text>
	</view>
</template>

<script setup lang="uts">
	import { useI18n } from '@/hooks/useI18n.uts'
	import type { LocaleType } from '@/store/locale.uts'
	
	const { locale, availableLocales, switchLocale } = useI18n()
	
	function handleSwitchLocale(newLocale: LocaleType) {
		switchLocale(newLocale)
	}
</script>

<style>
	.locale-switch {
		display: flex;
		gap: 20px;
	}
	
	.locale-item {
		padding: 5px 15px;
		border-radius: 15px;
		color: rgba(255, 255, 255, 0.7);
	}
	
	.locale-item.active {
		color: #ffffff;
		background: rgba(255, 255, 255, 0.2);
		font-weight: bold;
	}
</style>
```

---

## Toast 提示国际化

```typescript
// ❌ 不推荐
uni.showToast({
	title: '登录成功',
	icon: 'success'
})

// ✅ 推荐
uni.showToast({
	title: t('sys.login.loginSuccessTitle'),
	icon: 'success'
})
```

---

## 添加新语言

### 1. 创建语言包
创建 `locales/ja.uts`：

```typescript
export default {
	common: {
		login: 'ログイン',
		// ...
	},
	// ...
}
```

### 2. 更新 locale.uts

```typescript
import ja from '../locales/ja.uts'

// 更新类型
export type LocaleType = 'zh-CN' | 'en' | 'ja'

// 添加到映射
const localeMap: Map<LocaleType, any> = new Map([
	['zh-CN', zhCN],
	['en', en],
	['ja', ja]
])

// 添加到列表
const availableLocales: LocaleConfig[] = [
	{ lang: 'zh-CN', name: '简体中文' },
	{ lang: 'en', name: 'English' },
	{ lang: 'ja', name: '日本語' }
]
```

---

## 平台兼容性

| 功能 | Android | iOS | Web |
|------|---------|-----|-----|
| 语言切换 | ✅ | ✅ | ✅ |
| 翻译函数 | ✅ | ✅ | ✅ |
| 系统语言检测 | ✅ | ✅ | ✅ |
| 语言持久化 | ✅ | ✅ | ✅ |

---

## 最佳实践

### ✅ 推荐

```typescript
// 1. 使用 useI18n（响应式）
const { t, locale } = useI18n()

// 2. 提供默认值
const text = t('custom.key', '默认文本')

// 3. 统一使用翻译函数
const loginText = t('common.login')
```

### ❌ 不推荐

```typescript
// 1. 直接导入 t（非响应式）
import { t } from '@/store/locale.uts'

// 2. 不提供默认值
const text = t('custom.key')  // 可能返回键名

// 3. 硬编码文本
const loginText = '登录'
```

---

## 常见问题

### Q1: 如何在 App.uvue 中初始化？

```typescript
import { initLocale } from './store/locale.uts'

onLaunch(() => {
	initLocale()
})
```

### Q2: 如何切换语言？

```typescript
import { switchLocale } from '@/store/locale.uts'

switchLocale('en')  // 切换到英文
```

### Q3: 如何获取当前语言？

```typescript
import { getCurrentLocale } from '@/store/locale.uts'

const locale = getCurrentLocale()  // 'zh-CN' | 'en'
```

### Q4: 翻译键不存在怎么办？

```typescript
// 提供默认值
const text = t('custom.key', '默认文本')
```

### Q5: 如何在非组件中使用？

```typescript
import { t } from '@/store/locale.uts'

const text = t('common.login')
```

---

## 文件位置

```
shengyu-ui/shengyu-ui-admin-uniappx/
├── locales/
│   ├── zh-CN.uts          # 中文语言包
│   ├── en.uts             # 英文语言包
│   └── README.md          # 详细文档
├── store/
│   └── locale.uts         # 国际化 Store
├── hooks/
│   └── useI18n.uts        # 国际化组合式函数
└── App.uvue               # 初始化国际化
```

---

## 参考资料

- 详细文档：`locales/README.md`
- PC 端实现：`shengyu-ui/shengyu-ui-admin-vue3/src/locales`
- 完成总结：`今日工作完成-2026-01-28-UniAppX国际化实现.md`

---

**更新日期**: 2026-01-28  
**版本**: v1.0.0
