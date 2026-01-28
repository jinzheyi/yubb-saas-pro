# 国际化实现对比 - PC 端 vs 移动端

**更新日期**: 2026-01-28  
**版本**: v1.0.0

---

## 一、整体对比

| 项目 | PC 端（Vue3） | 移动端（UniApp X） |
|------|--------------|-------------------|
| **实现方式** | Vue I18n 库 | 自定义实现 |
| **语言包格式** | TypeScript 对象 | UTS 对象 |
| **存储方式** | localStorage | uni.storage |
| **响应式** | Vue I18n 内置 | 自定义 ref/computed |
| **API 风格** | `const { t } = useI18n()` | `const { t } = useI18n()` |
| **平台支持** | Web | Android、iOS、Web |

---

## 二、文件结构对比

### PC 端
```
shengyu-ui/shengyu-ui-admin-vue3/src/
├── locales/
│   ├── zh-CN.ts           # 中文语言包
│   ├── en.ts              # 英文语言包
│   └── index.ts           # 导出配置
└── store/modules/
    └── locale.ts          # locale store
```

### 移动端
```
shengyu-ui/shengyu-ui-admin-uniappx/
├── locales/
│   ├── zh-CN.uts          # 中文语言包
│   ├── en.uts             # 英文语言包
│   └── README.md          # 使用文档
├── store/
│   └── locale.uts         # 国际化 Store
└── hooks/
    └── useI18n.uts        # 国际化组合式函数
```

---

## 三、语言包结构对比

### PC 端（zh-CN.ts）

```typescript
export default {
  common: {
    inputText: '请输入',
    selectText: '请选择',
    login: '登录',
    loginOut: '退出系统',
    // ...
  },
  login: {
    welcome: '欢迎使用本系统',
    message: '开箱即用的中后台管理系统',
    username: '邮箱账号',
    password: '密码',
    // ...
  },
  // ...
}
```

### 移动端（zh-CN.uts）

```typescript
export default {
	common: {
		inputText: '请输入',
		selectText: '请选择',
		login: '登录',
		loginOut: '退出系统',
		// ...
	},
	login: {
		welcome: '欢迎使用本系统',
		message: '开箱即用的中后台管理系统',
		username: '邮箱账号',
		password: '密码',
		// ...
	},
	// ...
}
```

**结论**: ✅ 结构完全一致，只是文件扩展名不同（.ts vs .uts）

---

## 四、API 对比

### 1. 翻译函数

#### PC 端
```typescript
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
const text = t('common.login')  // "登录"
```

#### 移动端
```typescript
import { useI18n } from '@/hooks/useI18n.uts'

const { t } = useI18n()
const text = t('common.login')  // "登录"
```

**结论**: ✅ API 完全一致

---

### 2. 获取当前语言

#### PC 端
```typescript
import { useI18n } from 'vue-i18n'

const { locale } = useI18n()
console.log(locale.value)  // 'zh-CN'
```

#### 移动端
```typescript
import { useI18n } from '@/hooks/useI18n.uts'

const { locale } = useI18n()
console.log(locale.value)  // 'zh-CN'
```

**结论**: ✅ API 完全一致

---

### 3. 切换语言

#### PC 端
```typescript
import { useLocaleStore } from '@/store/modules/locale'

const localeStore = useLocaleStore()
localeStore.setCurrentLocale('en')
```

#### 移动端
```typescript
import { switchLocale } from '@/store/locale.uts'

switchLocale('en')
```

**结论**: ⚠️ API 略有不同，但功能一致

---

### 4. 获取可用语言列表

#### PC 端
```typescript
import { useLocaleStore } from '@/store/modules/locale'

const localeStore = useLocaleStore()
const locales = localeStore.getAvailableLocales()
```

#### 移动端
```typescript
import { getAvailableLocales } from '@/store/locale.uts'

const locales = getAvailableLocales()
```

**结论**: ⚠️ API 略有不同，但功能一致

---

## 五、使用方式对比

### 1. 在组件中使用

#### PC 端
```vue
<template>
	<div>
		<span>{{ t('common.login') }}</span>
		<button @click="handleSwitchLocale">切换语言</button>
	</div>
</template>

<script setup lang="ts">
	import { useI18n } from 'vue-i18n'
	import { useLocaleStore } from '@/store/modules/locale'
	
	const { t, locale } = useI18n()
	const localeStore = useLocaleStore()
	
	function handleSwitchLocale() {
		const newLocale = locale.value === 'zh-CN' ? 'en' : 'zh-CN'
		localeStore.setCurrentLocale(newLocale)
	}
</script>
```

#### 移动端
```vue
<template>
	<view>
		<text>{{ t('common.login') }}</text>
		<button @click="handleSwitchLocale">切换语言</button>
	</view>
</template>

<script setup lang="uts">
	import { useI18n } from '@/hooks/useI18n.uts'
	import type { LocaleType } from '@/store/locale.uts'
	
	const { t, locale, switchLocale } = useI18n()
	
	function handleSwitchLocale() {
		const newLocale = locale.value === 'zh-CN' ? 'en' : 'zh-CN'
		switchLocale(newLocale as LocaleType)
	}
</script>
```

**结论**: ✅ 使用方式基本一致，只是导入路径和类型定义略有不同

---

### 2. 在脚本中使用

#### PC 端
```typescript
import { i18n } from '@/plugins/vueI18n'

const text = i18n.global.t('common.login')
```

#### 移动端
```typescript
import { t } from '@/store/locale.uts'

const text = t('common.login')
```

**结论**: ⚠️ API 不同，但功能一致

---

## 六、初始化对比

### PC 端

#### 1. 创建 i18n 实例（plugins/vueI18n.ts）
```typescript
import { createI18n } from 'vue-i18n'
import zhCN from '@/locales/zh-CN'
import en from '@/locales/en'

export const i18n = createI18n({
	legacy: false,
	locale: 'zh-CN',
	messages: {
		'zh-CN': zhCN,
		'en': en
	}
})
```

#### 2. 在 main.ts 中注册
```typescript
import { i18n } from '@/plugins/vueI18n'

app.use(i18n)
```

### 移动端

#### 在 App.uvue 中初始化
```typescript
import { initLocale } from './store/locale.uts'

onLaunch(() => {
	initLocale()
})
```

**结论**: ⚠️ 初始化方式不同
- PC 端：使用 Vue I18n 插件
- 移动端：在 App.uvue 中调用初始化函数

---

## 七、存储方式对比

### PC 端
```typescript
// 保存语言
localStorage.setItem('locale', 'en')

// 读取语言
const locale = localStorage.getItem('locale')
```

### 移动端
```typescript
// 保存语言
uni.setStorageSync('LOCALE', 'en')

// 读取语言
const locale = uni.getStorageSync('LOCALE')
```

**结论**: ⚠️ 存储 API 不同
- PC 端：localStorage（仅 Web）
- 移动端：uni.storage（跨平台）

---

## 八、系统语言检测对比

### PC 端
```typescript
// 获取浏览器语言
const language = navigator.language || navigator.userLanguage
if (language.indexOf('zh') !== -1) {
	return 'zh-CN'
} else if (language.indexOf('en') !== -1) {
	return 'en'
}
```

### 移动端
```typescript
// Android/iOS
const systemInfo = uni.getSystemInfoSync()
const language = systemInfo.language

// Web
const language = navigator.language || navigator.userLanguage

if (language.indexOf('zh') !== -1) {
	return 'zh-CN'
} else if (language.indexOf('en') !== -1) {
	return 'en'
}
```

**结论**: ✅ 逻辑一致，移动端支持更多平台

---

## 九、响应式实现对比

### PC 端
```typescript
// Vue I18n 内置响应式
const { t, locale } = useI18n()

// locale 是响应式的
watch(locale, (newLocale) => {
	console.log('语言切换:', newLocale)
})
```

### 移动端
```typescript
// 自定义响应式
const locale = ref<LocaleType>(getCurrentLocale())

// 切换语言时更新 ref
const switchLocale = (newLocale: LocaleType) => {
	switchLang(newLocale)
	locale.value = newLocale
}
```

**结论**: ⚠️ 实现方式不同
- PC 端：Vue I18n 内置响应式
- 移动端：自定义 ref/computed

---

## 十、功能对比

| 功能 | PC 端 | 移动端 | 说明 |
|------|-------|--------|------|
| **基础翻译** | ✅ | ✅ | 完全一致 |
| **嵌套路径** | ✅ | ✅ | 如 `common.login` |
| **默认值** | ✅ | ✅ | `t('key', 'default')` |
| **语言切换** | ✅ | ✅ | 功能一致 |
| **语言持久化** | ✅ | ✅ | 存储方式不同 |
| **系统语言检测** | ✅ | ✅ | 移动端支持更多平台 |
| **响应式更新** | ✅ | ✅ | 实现方式不同 |
| **插值** | ✅ | ❌ | 移动端未实现 |
| **复数** | ✅ | ❌ | 移动端未实现 |
| **日期格式化** | ✅ | ❌ | 移动端未实现 |
| **数字格式化** | ✅ | ❌ | 移动端未实现 |

---

## 十一、性能对比

### PC 端
- **优势**：Vue I18n 高度优化，性能极佳
- **劣势**：需要加载额外的库

### 移动端
- **优势**：轻量级，无需额外库
- **劣势**：功能相对简单

---

## 十二、扩展性对比

### PC 端
- ✅ 支持插件扩展
- ✅ 支持自定义格式化
- ✅ 支持消息编译
- ✅ 社区生态丰富

### 移动端
- ✅ 易于添加新语言
- ✅ 易于自定义功能
- ⚠️ 需要手动实现高级功能
- ⚠️ 无现成插件

---

## 十三、优缺点总结

### PC 端

#### 优点
1. ✅ 功能强大（插值、复数、格式化等）
2. ✅ 性能优秀
3. ✅ 社区支持好
4. ✅ 文档完善
5. ✅ 开箱即用

#### 缺点
1. ❌ 需要额外依赖
2. ❌ 学习曲线稍陡
3. ❌ 仅支持 Web

### 移动端

#### 优点
1. ✅ 轻量级，无额外依赖
2. ✅ 跨平台（Android、iOS、Web）
3. ✅ 易于理解和维护
4. ✅ 完全可控
5. ✅ 与 PC 端 API 保持一致

#### 缺点
1. ❌ 功能相对简单
2. ❌ 需要手动实现高级功能
3. ❌ 无现成插件
4. ❌ 需要自己维护

---

## 十四、迁移指南

### 从 PC 端迁移到移动端

#### 1. 语言包迁移
```bash
# 复制语言包文件
cp src/locales/zh-CN.ts locales/zh-CN.uts
cp src/locales/en.ts locales/en.uts

# 修改文件扩展名和语法
# .ts -> .uts
# export default { ... } 保持不变
```

#### 2. 代码迁移

**PC 端代码**：
```typescript
import { useI18n } from 'vue-i18n'
import { useLocaleStore } from '@/store/modules/locale'

const { t, locale } = useI18n()
const localeStore = useLocaleStore()

// 切换语言
localeStore.setCurrentLocale('en')
```

**移动端代码**：
```typescript
import { useI18n } from '@/hooks/useI18n.uts'

const { t, locale, switchLocale } = useI18n()

// 切换语言
switchLocale('en')
```

#### 3. 初始化迁移

**PC 端**：
```typescript
// main.ts
import { i18n } from '@/plugins/vueI18n'
app.use(i18n)
```

**移动端**：
```typescript
// App.uvue
import { initLocale } from './store/locale.uts'
onLaunch(() => {
	initLocale()
})
```

---

## 十五、最佳实践

### 共同的最佳实践

1. **统一使用翻译函数**
   ```typescript
   // ✅ 推荐
   const text = t('common.login')
   
   // ❌ 不推荐
   const text = '登录'
   ```

2. **提供默认值**
   ```typescript
   const text = t('custom.key', '默认文本')
   ```

3. **保持语言包结构一致**
   ```typescript
   {
     common: { ... },
     login: { ... },
     sys: { ... }
   }
   ```

4. **使用嵌套路径**
   ```typescript
   t('common.login')
   t('sys.api.errorMessage')
   ```

### PC 端特有

1. **使用 Vue I18n 的高级功能**
   ```typescript
   // 插值
   t('welcome', { name: 'John' })
   
   // 复数
   t('items', { count: 5 })
   ```

### 移动端特有

1. **使用 useI18n 确保响应式**
   ```typescript
   // ✅ 推荐
   const { t, locale } = useI18n()
   
   // ❌ 不推荐（非响应式）
   import { t } from '@/store/locale.uts'
   ```

2. **在 App.uvue 中初始化**
   ```typescript
   onLaunch(() => {
     initLocale()
   })
   ```

---

## 十六、总结

### 相同点
1. ✅ 语言包结构完全一致
2. ✅ 翻译键路径完全一致
3. ✅ 基础 API 保持一致（`t()`, `locale`）
4. ✅ 支持中英文切换
5. ✅ 自动检测系统语言
6. ✅ 语言持久化

### 差异点
1. ⚠️ 实现方式不同（Vue I18n vs 自定义）
2. ⚠️ 存储方式不同（localStorage vs uni.storage）
3. ⚠️ 初始化方式不同（插件 vs 函数调用）
4. ⚠️ 功能丰富度不同（PC 端更强大）
5. ⚠️ 平台支持不同（PC 端仅 Web，移动端跨平台）

### 建议
1. **保持 API 一致性**：尽量让两端的使用方式保持一致
2. **共享语言包**：语言包结构完全一致，便于维护
3. **文档同步**：两端的文档保持同步更新
4. **功能对齐**：根据需要，逐步在移动端实现 PC 端的高级功能

---

**更新日期**: 2026-01-28  
**版本**: v1.0.0
