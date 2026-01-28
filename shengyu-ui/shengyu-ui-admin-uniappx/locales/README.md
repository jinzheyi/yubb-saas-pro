# UniApp X 国际化使用指南

本目录包含国际化相关的语言包和工具函数。

## 文件结构

```
locales/
├── zh-CN.uts          # 中文语言包
├── en.uts             # 英文语言包
└── README.md          # 本文档

store/
└── locale.uts         # 国际化 Store

hooks/
└── useI18n.uts        # 国际化组合式函数
```

## 快速开始

### 1. 在组件中使用

```vue
<template>
	<view class="container">
		<!-- 直接使用翻译函数 -->
		<text>{{ t('common.login') }}</text>
		
		<!-- 使用默认值 -->
		<text>{{ t('custom.key', '默认文本') }}</text>
		
		<!-- 显示当前语言 -->
		<text>当前语言: {{ locale }}</text>
		
		<!-- 语言切换按钮 -->
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

// 翻译文本
const loginText = t('common.login')  // "登录"

// 使用默认值
const customText = t('custom.key', '默认文本')

// 嵌套路径
const errorMsg = t('sys.api.errorMessage')  // "操作失败,系统异常!"
```

### 3. 切换语言

```typescript
import { switchLocale } from '@/store/locale.uts'

// 切换到英文
switchLocale('en')

// 切换到中文
switchLocale('zh-CN')
```

## API 文档

### store/locale.uts

#### getCurrentLocale()

获取当前语言。

```typescript
import { getCurrentLocale } from '@/store/locale.uts'

const locale = getCurrentLocale()  // 'zh-CN' | 'en'
```

#### setCurrentLocale(locale)

设置当前语言。

```typescript
import { setCurrentLocale } from '@/store/locale.uts'

setCurrentLocale('en')
```

#### getAvailableLocales()

获取可用语言列表。

```typescript
import { getAvailableLocales } from '@/store/locale.uts'

const locales = getAvailableLocales()
// [
//   { lang: 'zh-CN', name: '简体中文' },
//   { lang: 'en', name: 'English' }
// ]
```

#### t(key, defaultValue?)

翻译函数。

```typescript
import { t } from '@/store/locale.uts'

// 基本使用
const text = t('common.login')  // "登录"

// 使用默认值
const text2 = t('custom.key', '默认文本')

// 嵌套路径
const text3 = t('sys.api.errorMessage')
```

#### switchLocale(locale)

切换语言（带提示）。

```typescript
import { switchLocale } from '@/store/locale.uts'

switchLocale('en')  // 显示 Toast 提示
```

#### getSystemLocale()

获取系统语言。

```typescript
import { getSystemLocale } from '@/store/locale.uts'

const systemLocale = getSystemLocale()  // 'zh-CN' | 'en'
```

#### initLocale()

初始化语言（如果没有设置过，则使用系统语言）。

```typescript
import { initLocale } from '@/store/locale.uts'

// 在 App.uvue 的 onLaunch 中调用
onLaunch(() => {
	initLocale()
})
```

### hooks/useI18n.uts

#### useI18n()

国际化组合式函数。

```typescript
import { useI18n } from '@/hooks/useI18n.uts'

const { t, locale, availableLocales, messages, switchLocale, setLocale } = useI18n()

// t: 翻译函数
// locale: 当前语言（响应式）
// availableLocales: 可用语言列表（响应式）
// messages: 当前语言包（响应式）
// switchLocale: 切换语言函数
// setLocale: 设置语言函数
```

## 语言包结构

### zh-CN.uts（中文）

```typescript
export default {
	common: {
		login: '登录',
		loginOut: '退出系统',
		// ...
	},
	login: {
		welcome: '欢迎使用本系统',
		username: '邮箱账号',
		// ...
	},
	sys: {
		api: {
			errorMessage: '操作失败,系统异常!',
			// ...
		}
	}
}
```

### en.uts（英文）

```typescript
export default {
	common: {
		login: 'Login',
		loginOut: 'Login out',
		// ...
	},
	login: {
		welcome: 'Welcome to the system',
		username: 'Email account',
		// ...
	},
	sys: {
		api: {
			errorMessage: 'The operation failed, the system is abnormal!',
			// ...
		}
	}
}
```

## 完整示例

### 登录页面国际化

```vue
<template>
	<view class="login-container">
		<!-- 标题 -->
		<text class="title">{{ t('login.welcome') }}</text>
		
		<!-- 表单 -->
		<view class="form">
			<view class="form-item">
				<text class="label">{{ t('login.username') }}</text>
				<input 
					class="input" 
					v-model="username" 
					:placeholder="t('login.usernamePlaceholder')"
				/>
			</view>
			
			<view class="form-item">
				<text class="label">{{ t('login.password') }}</text>
				<input 
					class="input" 
					v-model="password" 
					type="password"
					:placeholder="t('login.passwordPlaceholder')"
				/>
			</view>
			
			<button class="login-btn" @click="handleLogin">
				{{ t('common.login') }}
			</button>
		</view>
		
		<!-- 语言切换 -->
		<view class="locale-switch">
			<text 
				v-for="item in availableLocales" 
				:key="item.lang"
				@click="handleSwitchLocale(item.lang)"
				:class="{ active: locale === item.lang }"
			>
				{{ item.name }}
			</text>
		</view>
	</view>
</template>

<script setup lang="uts">
	import { useI18n } from '@/hooks/useI18n.uts'
	import type { LocaleType } from '@/store/locale.uts'
	
	const { t, locale, availableLocales, switchLocale } = useI18n()
	
	const username = ref<string>('')
	const password = ref<string>('')
	
	function handleLogin() {
		if (!username.value) {
			uni.showToast({
				title: t('login.usernamePlaceholder'),
				icon: 'none'
			})
			return
		}
		
		if (!password.value) {
			uni.showToast({
				title: t('login.passwordPlaceholder'),
				icon: 'none'
			})
			return
		}
		
		// 登录逻辑...
	}
	
	function handleSwitchLocale(newLocale: LocaleType) {
		switchLocale(newLocale)
	}
</script>
```

### 在 App.uvue 中初始化

```vue
<script setup lang="uts">
	import { initLocale } from '@/store/locale.uts'
	
	onLaunch(() => {
		// 初始化语言（如果没有设置过，则使用系统语言）
		initLocale()
	})
</script>
```

## 添加新语言

### 1. 创建语言包文件

创建 `locales/ja.uts`（日语）：

```typescript
export default {
	common: {
		login: 'ログイン',
		loginOut: 'ログアウト',
		// ...
	},
	// ...
}
```

### 2. 更新 locale.uts

在 `store/locale.uts` 中添加：

```typescript
import ja from '../locales/ja.uts'

const localeMap: Map<LocaleType, any> = new Map([
	['zh-CN', zhCN],
	['en', en],
	['ja', ja]  // 添加日语
])

const availableLocales: LocaleConfig[] = [
	{ lang: 'zh-CN', name: '简体中文' },
	{ lang: 'en', name: 'English' },
	{ lang: 'ja', name: '日本語' }  // 添加日语
]
```

### 3. 更新类型定义

```typescript
export type LocaleType = 'zh-CN' | 'en' | 'ja'
```

## 平台兼容性

| 功能 | Android | iOS | Web |
|------|---------|-----|-----|
| 语言切换 | ✅ | ✅ | ✅ |
| 翻译函数 | ✅ | ✅ | ✅ |
| 系统语言检测 | ✅ | ✅ | ✅ |
| 语言持久化 | ✅ | ✅ | ✅ |

## 注意事项

1. **语言包结构**：保持与 PC 端一致的结构，便于维护
2. **默认语言**：默认使用中文（zh-CN）
3. **系统语言**：首次启动时自动检测系统语言
4. **语言持久化**：语言设置会保存到本地存储
5. **翻译键**：使用点号分隔的路径（如 `common.login`）

## 最佳实践

### 1. 统一使用翻译函数

```typescript
// ✅ 推荐
const text = t('common.login')

// ❌ 不推荐
const text = '登录'
```

### 2. 提供默认值

```typescript
// ✅ 推荐（防止翻译键不存在）
const text = t('custom.key', '默认文本')

// ⚠️ 可能返回键名
const text = t('custom.key')
```

### 3. 在组件中使用 useI18n

```typescript
// ✅ 推荐（响应式）
const { t, locale } = useI18n()

// ⚠️ 不推荐（非响应式）
import { t } from '@/store/locale.uts'
```

### 4. 初始化语言

```typescript
// 在 App.uvue 的 onLaunch 中
onLaunch(() => {
	initLocale()
})
```

## 参考资料

- PC 端国际化实现：`shengyu-ui/shengyu-ui-admin-vue3/src/locales`
- PC 端 locale store：`shengyu-ui/shengyu-ui-admin-vue3/src/store/modules/locale.ts`

---

**更新日期**：2026-01-28  
**版本**：v1.0.0
