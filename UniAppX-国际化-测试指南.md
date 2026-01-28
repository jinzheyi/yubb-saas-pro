# UniApp X 国际化 - 测试指南

**版本**: v1.0.0  
**更新日期**: 2026-01-28

---

## 一、测试前准备

### 1. 确认文件已创建

```
shengyu-ui/shengyu-ui-admin-uniappx/
├── locales/
│   ├── zh-CN.uts          ✅
│   ├── en.uts             ✅
│   └── README.md          ✅
├── store/
│   └── locale.uts         ✅
├── hooks/
│   └── useI18n.uts        ✅
├── App.uvue               ✅ (已修改)
└── pages/login/login.uvue ✅ (已修改)
```

### 2. 确认代码无错误

运行诊断检查：
```bash
# 所有文件应该没有错误
✅ App.uvue: No diagnostics found
✅ hooks/useI18n.uts: No diagnostics found
✅ pages/login/login.uvue: No diagnostics found
✅ store/locale.uts: No diagnostics found
```

---

## 二、功能测试

### 测试 1: 首次启动自动检测系统语言

**步骤**：
1. 清除应用数据（或卸载重装）
2. 设置系统语言为中文
3. 启动应用

**预期结果**：
- ✅ 应用显示中文界面
- ✅ 控制台输出：`App Launch`

**步骤**：
1. 清除应用数据（或卸载重装）
2. 设置系统语言为英文
3. 启动应用

**预期结果**：
- ✅ 应用显示英文界面

---

### 测试 2: 手动切换语言

**步骤**：
1. 启动应用，进入登录页面
2. 点击顶部的 "English" 按钮

**预期结果**：
- ✅ 显示 Toast 提示："Switch Success"
- ✅ 页面文本立即切换为英文
- ✅ "English" 按钮高亮显示

**步骤**：
1. 点击顶部的 "简体中文" 按钮

**预期结果**：
- ✅ 显示 Toast 提示："切换成功"
- ✅ 页面文本立即切换为中文
- ✅ "简体中文" 按钮高亮显示

---

### 测试 3: 语言持久化

**步骤**：
1. 启动应用，切换到英文
2. 完全关闭应用（杀掉进程）
3. 重新启动应用

**预期结果**：
- ✅ 应用仍然显示英文界面
- ✅ "English" 按钮高亮显示

---

### 测试 4: 登录页面文本翻译

#### 中文界面检查

**检查项**：
- ✅ 标题："欢迎使用本系统"
- ✅ 副标题："开箱即用的中后台管理系统"
- ✅ 账号标签："邮箱账号"
- ✅ 密码标签："密码"
- ✅ 账号占位符："请输入邮箱账号"
- ✅ 密码占位符："请输入密码"
- ✅ 记住我："记住我"
- ✅ 登录按钮："登录"
- ✅ 切换方式："手机号登录"

#### 英文界面检查

**检查项**：
- ✅ 标题："Welcome to the system"
- ✅ 副标题："Backstage management system"
- ✅ 账号标签："Email account"
- ✅ 密码标签："Password"
- ✅ 账号占位符："Please Enter Email account"
- ✅ 密码占位符："Please Enter Password"
- ✅ 记住我："Remember me"
- ✅ 登录按钮："Sign in"
- ✅ 切换方式："Mobile sign in"

---

### 测试 5: 手机号登录界面

**步骤**：
1. 点击 "手机号登录"（或 "Mobile sign in"）

#### 中文界面检查
- ✅ 手机号标签："手机号码"
- ✅ 验证码标签："验证码"
- ✅ 手机号占位符："请输入手机号码"
- ✅ 验证码占位符："请输入验证码"
- ✅ 获取验证码按钮："获取验证码"
- ✅ 切换方式："账号密码登录"

#### 英文界面检查
- ✅ 手机号标签："Mobile Number"
- ✅ 验证码标签："Verification code"
- ✅ 手机号占位符："Please Enter Mobile Number"
- ✅ 验证码占位符："Please Enter Verification Code"
- ✅ 获取验证码按钮："Get SMS Code"
- ✅ 切换方式："Account sign in"

---

### 测试 6: Toast 提示国际化

#### 测试 6.1: 空账号提示

**步骤**：
1. 不输入账号，直接点击登录

**预期结果**：
- 中文：显示 "请输入邮箱账号"
- 英文：显示 "Please Enter Email account"

#### 测试 6.2: 空密码提示

**步骤**：
1. 输入账号，不输入密码，点击登录

**预期结果**：
- 中文：显示 "请输入密码"
- 英文：显示 "Please Enter Password"

#### 测试 6.3: 空手机号提示

**步骤**：
1. 切换到手机号登录
2. 不输入手机号，点击获取验证码

**预期结果**：
- 中文：显示 "请输入手机号码"
- 英文：显示 "Please Enter Mobile Number"

#### 测试 6.4: 验证码发送成功

**步骤**：
1. 输入正确的手机号
2. 点击获取验证码

**预期结果**：
- 中文：显示 "验证码已发送"
- 英文：显示 "Code has been sent"

#### 测试 6.5: 登录成功提示

**步骤**：
1. 输入正确的账号密码
2. 完成验证码验证
3. 登录成功

**预期结果**：
- 中文：显示 "登录成功"
- 英文：显示 "Login successful"

#### 测试 6.6: 验证码失败提示

**步骤**：
1. 输入账号密码
2. 验证码验证失败

**预期结果**：
- 中文：显示 "验证失败"
- 英文：显示 "Verification failed"

---

## 三、平台测试

### Android 端测试

**测试环境**：
- 设备：Android 手机/模拟器
- 系统版本：Android 5.0+

**测试项**：
- [ ] 首次启动检测系统语言
- [ ] 手动切换语言
- [ ] 语言持久化
- [ ] 所有文本正确显示
- [ ] Toast 提示正确显示
- [ ] 语言切换器 UI 正常
- [ ] 性能流畅

---

### iOS 端测试

**测试环境**：
- 设备：iPhone/iPad/模拟器
- 系统版本：iOS 10.0+

**测试项**：
- [ ] 首次启动检测系统语言
- [ ] 手动切换语言
- [ ] 语言持久化
- [ ] 所有文本正确显示
- [ ] Toast 提示正确显示
- [ ] 语言切换器 UI 正常
- [ ] 性能流畅

---

### Web 端测试

**测试环境**：
- 浏览器：Chrome、Safari、Firefox
- 设备：PC、平板

**测试项**：
- [ ] 首次启动检测浏览器语言
- [ ] 手动切换语言
- [ ] 语言持久化（localStorage）
- [ ] 所有文本正确显示
- [ ] Toast 提示正确显示
- [ ] 语言切换器 UI 正常
- [ ] 响应式布局正常

---

## 四、UI 测试

### 测试 1: 语言切换器样式

**检查项**：
- ✅ 两个语言按钮水平排列
- ✅ 按钮之间有适当间距
- ✅ 当前语言按钮高亮显示
- ✅ 高亮样式：白色文字 + 半透明白色背景
- ✅ 非高亮样式：半透明白色文字
- ✅ 点击有视觉反馈

### 测试 2: 标题和副标题

**检查项**：
- ✅ 标题字体大小：28px
- ✅ 标题颜色：白色
- ✅ 标题加粗
- ✅ 副标题字体大小：14px
- ✅ 副标题颜色：半透明白色
- ✅ 标题和副标题之间有间距

### 测试 3: 响应式测试

**不同屏幕尺寸**：
- [ ] 小屏手机（320px）
- [ ] 中屏手机（375px）
- [ ] 大屏手机（414px）
- [ ] 平板（768px）
- [ ] PC（1024px+）

**检查项**：
- ✅ 语言切换器不换行
- ✅ 文本不溢出
- ✅ 按钮大小适中
- ✅ 间距合理

---

## 五、性能测试

### 测试 1: 切换语言性能

**步骤**：
1. 快速连续切换语言 10 次

**预期结果**：
- ✅ 每次切换响应时间 < 100ms
- ✅ UI 更新流畅，无卡顿
- ✅ 无内存泄漏

### 测试 2: 翻译函数性能

**步骤**：
1. 在页面中使用 100+ 个翻译键
2. 切换语言

**预期结果**：
- ✅ 页面渲染时间 < 500ms
- ✅ 切换语言后更新时间 < 200ms

---

## 六、边界测试

### 测试 1: 不存在的翻译键

**步骤**：
```typescript
const text = t('custom.nonexistent.key')
```

**预期结果**：
- ✅ 返回键名：`'custom.nonexistent.key'`
- ✅ 不抛出错误

### 测试 2: 使用默认值

**步骤**：
```typescript
const text = t('custom.nonexistent.key', '默认文本')
```

**预期结果**：
- ✅ 返回默认值：`'默认文本'`

### 测试 3: 空字符串键

**步骤**：
```typescript
const text = t('')
```

**预期结果**：
- ✅ 返回空字符串或键名
- ✅ 不抛出错误

---

## 七、兼容性测试

### 测试 1: 旧版本数据迁移

**步骤**：
1. 清除应用数据
2. 手动设置旧版本的语言存储格式
3. 启动应用

**预期结果**：
- ✅ 能够正确读取旧版本数据
- ✅ 或使用默认语言

### 测试 2: 存储数据损坏

**步骤**：
1. 手动设置无效的语言值
2. 启动应用

**预期结果**：
- ✅ 使用默认语言（中文）
- ✅ 不抛出错误

---

## 八、测试清单

### 功能测试
- [ ] 首次启动自动检测系统语言
- [ ] 手动切换语言
- [ ] 语言持久化
- [ ] 登录页面文本翻译（中文）
- [ ] 登录页面文本翻译（英文）
- [ ] 手机号登录界面翻译
- [ ] Toast 提示国际化

### 平台测试
- [ ] Android 端完整测试
- [ ] iOS 端完整测试
- [ ] Web 端完整测试

### UI 测试
- [ ] 语言切换器样式
- [ ] 标题和副标题样式
- [ ] 响应式布局

### 性能测试
- [ ] 切换语言性能
- [ ] 翻译函数性能

### 边界测试
- [ ] 不存在的翻译键
- [ ] 使用默认值
- [ ] 空字符串键

### 兼容性测试
- [ ] 旧版本数据迁移
- [ ] 存储数据损坏

---

## 九、测试报告模板

### 测试信息
- **测试日期**: YYYY-MM-DD
- **测试人员**: [姓名]
- **测试版本**: v1.0.0
- **测试平台**: Android / iOS / Web

### 测试结果

| 测试项 | 状态 | 备注 |
|--------|------|------|
| 首次启动检测系统语言 | ✅ / ❌ | |
| 手动切换语言 | ✅ / ❌ | |
| 语言持久化 | ✅ / ❌ | |
| 登录页面翻译 | ✅ / ❌ | |
| Toast 提示国际化 | ✅ / ❌ | |
| UI 样式 | ✅ / ❌ | |
| 性能 | ✅ / ❌ | |

### 发现的问题

| 问题编号 | 问题描述 | 严重程度 | 状态 |
|----------|----------|----------|------|
| 1 | | 高/中/低 | 待修复/已修复 |

### 测试结论
- [ ] 通过
- [ ] 不通过（需要修复）

---

## 十、常见问题排查

### 问题 1: 切换语言后文本没有更新

**可能原因**：
- 使用了 `import { t } from '@/store/locale.uts'` 而不是 `useI18n()`

**解决方案**：
```typescript
// ❌ 不推荐
import { t } from '@/store/locale.uts'

// ✅ 推荐
import { useI18n } from '@/hooks/useI18n.uts'
const { t } = useI18n()
```

### 问题 2: 首次启动没有检测系统语言

**可能原因**：
- `App.uvue` 中没有调用 `initLocale()`

**解决方案**：
```typescript
import { initLocale } from './store/locale.uts'

onLaunch(() => {
	initLocale()
})
```

### 问题 3: 语言设置没有持久化

**可能原因**：
- 存储权限问题
- 使用了 `setLocale()` 而不是 `switchLocale()`

**解决方案**：
```typescript
// 确保使用 switchLocale 或 setCurrentLocale
import { switchLocale } from '@/store/locale.uts'
switchLocale('en')
```

### 问题 4: 翻译键返回键名而不是翻译文本

**可能原因**：
- 翻译键不存在
- 语言包结构错误

**解决方案**：
1. 检查翻译键是否存在
2. 使用默认值：`t('key', '默认文本')`

---

## 十一、测试工具

### 控制台调试

```typescript
// 查看当前语言
console.log('当前语言:', getCurrentLocale())

// 查看可用语言
console.log('可用语言:', getAvailableLocales())

// 查看当前语言包
console.log('当前语言包:', getCurrentMessages())

// 测试翻译
console.log('翻译结果:', t('common.login'))
```

### 存储调试

```typescript
// 查看存储的语言
const locale = uni.getStorageSync('LOCALE')
console.log('存储的语言:', locale)

// 清除语言设置
uni.removeStorageSync('LOCALE')
```

---

## 十二、自动化测试建议

### 单元测试

```typescript
// 测试翻译函数
describe('t()', () => {
	it('should return translated text', () => {
		expect(t('common.login')).toBe('登录')
	})
	
	it('should return default value if key not found', () => {
		expect(t('custom.key', '默认')).toBe('默认')
	})
})

// 测试语言切换
describe('switchLocale()', () => {
	it('should switch locale', () => {
		switchLocale('en')
		expect(getCurrentLocale()).toBe('en')
	})
})
```

### E2E 测试

```typescript
// 测试登录页面国际化
describe('Login Page i18n', () => {
	it('should display Chinese text by default', () => {
		expect(page.title).toBe('欢迎使用本系统')
	})
	
	it('should switch to English', () => {
		page.clickLocaleSwitch('en')
		expect(page.title).toBe('Welcome to the system')
	})
})
```

---

**更新日期**: 2026-01-28  
**版本**: v1.0.0
