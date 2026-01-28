# UniApp X Web 端验证码问题排查

## 问题描述

用户反馈：UniApp X 项目在 Web 端运行时，验证码没有正常调用校验接口。

## 已完成的工作

1. ✅ 在 `aes.uts` 中添加了 Web 端 AES 加密支持（使用 crypto-js）
2. ✅ 在 `index.html` 中引入了 crypto-js CDN
3. ✅ 在 `slider-captcha.uvue` 中添加了详细的调试日志
4. ✅ 移除了不必要的租户 ID 获取逻辑

## 当前状态

### 文件检查

1. **index.html** - ✅ 已引入 crypto-js
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.1.1/crypto-js.min.js"></script>
```

2. **app.config.uts** - ✅ 验证码已启用
```typescript
export const CAPTCHA_ENABLE = 'true'
```

3. **aes.uts** - ✅ 已添加 Web 端支持
```typescript
// #ifdef H5
function aesEncryptWeb(word: string, keyWord: string): string {
	// 使用 crypto-js 加密
}
// #endif
```

4. **slider-captcha.uvue** - ✅ 已添加调试日志和 AES 加密
```typescript
async function verifyCaptcha(distance: number) {
	console.log('=== 开始校验验证码 ===')
	// ... AES 加密逻辑
	const result = await checkCaptcha(data)
	// ...
}
```

5. **login.uvue** - ✅ 已移除租户 ID 获取逻辑
```typescript
async function handleLogin() {
	if (captchaEnable.value === 'false') {
		await doLogin('')
	} else {
		if (captchaRef.value) {
			captchaRef.value.show()
		}
	}
}
```

## 测试步骤

### 步骤 1：启动项目

在 HBuilderX 中：
1. 打开项目：`shengyu-ui/shengyu-ui-admin-uniappx`
2. 运行 -> 运行到浏览器 -> Chrome

### 步骤 2：打开开发者工具

1. 按 F12 打开开发者工具
2. 切换到 Console 标签
3. 切换到 Network 标签

### 步骤 3：测试登录流程

1. 访问登录页面
2. 输入账号：`jin_zheyicn@qq.com`
3. 输入密码：`123456`
4. 点击"登录"按钮

### 步骤 4：观察验证码弹窗

**预期行为**：
- 验证码弹窗应该出现
- 显示背景图和滑块图
- 可以滑动验证码

**如果验证码没有出现**：
- 检查控制台是否有错误
- 检查 `captchaRef.value` 是否为 null
- 检查 `captchaEnable` 的值

### 步骤 5：滑动验证码

1. 按住滑块
2. 向右滑动
3. 松开滑块

### 步骤 6：查看控制台日志

**预期日志输出**：

```
=== 开始滑动 ===
startX: 100

=== 结束滑动 ===
{
  startX: 100,
  currentX: 223,
  moveDistance: 123,
  耗时: "1234ms"
}

=== 开始校验验证码 ===
距离: 123
token: "8867548b50184f7199f83ac3c1b34dd9"
secretKey: "owALgSXrFtj9QVxF"
原始坐标 JSON: {"x":123,"y":5.0}

✅ AES 加密成功: {
  原文: '{"x":123,"y":5.0}',
  密钥: 'owALgSXrFtj9QVxF',
  加密后: 'U2FsdGVkX1+...'
}

校验验证码请求参数: {
  captchaType: "blockPuzzle",
  pointJson: "U2FsdGVkX1+...",
  token: "8867548b50184f7199f83ac3c1b34dd9"
}

校验验证码响应: {
  repCode: "0000",
  repMsg: "验证成功"
}

✅ 验证成功

=== handleSuccess 被调用 ===
准备生成 captchaVerification
token: "8867548b50184f7199f83ac3c1b34dd9"
secretKey: "owALgSXrFtj9QVxF"
移动距离: 123
captchaVerification: "U2FsdGVkX1+..."
准备触发 success 事件
✅ success 事件已触发
```

### 步骤 7：查看 Network 请求

**应该看到以下请求**：

1. **POST /admin-api/system/captcha/get**
   - 请求体：`{ captchaType: "blockPuzzle", clientUid: "...", ts: ... }`
   - 响应：`{ repCode: "0000", repData: { secretKey: "...", token: "...", ... } }`

2. **POST /admin-api/system/captcha/check**
   - 请求体：`{ captchaType: "blockPuzzle", pointJson: "U2FsdGVkX1+...", token: "..." }`
   - 响应：`{ repCode: "0000", repMsg: "验证成功" }`

3. **POST /admin-api/system/auth/login**
   - 请求体：`{ username: "...", password: "...", captchaVerification: "..." }`
   - 响应：`{ code: 0, data: { accessToken: "...", ... } }`

## 可能的问题和解决方案

### 问题 1：验证码弹窗没有出现

**症状**：点击登录按钮后，没有看到验证码弹窗

**排查**：
```typescript
// 在 login.uvue 的 handleLogin 中添加日志
console.log('captchaEnable:', captchaEnable.value)
console.log('captchaRef:', captchaRef.value)
```

**可能原因**：
1. `captchaEnable` 的值不是 `'true'`（字符串）
2. `captchaRef.value` 为 null（组件引用失败）
3. 组件没有正确导入

**解决方案**：
- 检查 `app.config.uts` 中的 `CAPTCHA_ENABLE` 值
- 检查 `<slider-captcha ref="captchaRef" />` 是否正确
- 重新编译项目

### 问题 2：滑动后没有调用 checkCaptcha API

**症状**：滑动验证码后，Network 标签中没有看到 `/system/captcha/check` 请求

**排查**：
```typescript
// 检查 handleTouchEnd 是否被调用
console.log('=== handleTouchEnd 被调用 ===')
console.log('isSliding:', isSliding.value)
console.log('moveDistance:', currentX.value - startX.value)
```

**可能原因**：
1. `handleTouchEnd` 没有被触发
2. `isSliding` 状态不正确
3. 滑动距离太小（< 10px）
4. `verifyCaptcha` 函数抛出异常

**解决方案**：
- 检查触摸事件是否正确绑定
- 增加滑动距离
- 查看控制台是否有错误

### 问题 3：crypto-js 未加载

**症状**：
```
❌ AES 加密失败: crypto-js 未加载
```

**排查**：
在浏览器控制台中输入：
```javascript
typeof CryptoJS
// 应该输出: "object"
```

**可能原因**：
1. CDN 无法访问
2. 浏览器缓存问题
3. 网络问题

**解决方案**：
- 检查网络连接
- 清除浏览器缓存
- 尝试使用备用 CDN
- 硬刷新页面（Ctrl+F5）

### 问题 4：AES 加密失败

**症状**：
```
❌ AES 加密失败 (Web): ...
```

**排查**：
```typescript
console.log('secretKey:', secretKey.value)
console.log('secretKey 类型:', typeof secretKey.value)
console.log('pointJson:', pointJson)
```

**可能原因**：
1. `secretKey` 为空
2. `secretKey` 格式不正确
3. `crypto-js` 版本问题

**解决方案**：
- 检查后端是否返回 `secretKey`
- 检查 `secretKey` 的长度（应该是 16 字节）
- 更新 crypto-js 版本

### 问题 5：验证成功但没有触发登录

**症状**：验证码显示"验证成功"，但没有调用登录接口

**排查**：
```typescript
// 在 handleSuccess 中添加日志
console.log('=== handleSuccess 被调用 ===')
console.log('准备触发 success 事件')
emit('success', { captchaVerification })
console.log('success 事件已触发')
```

**可能原因**：
1. `emit('success')` 没有正确触发
2. 父组件没有监听 `@success` 事件
3. `handleCaptchaSuccess` 函数没有被调用

**解决方案**：
- 检查组件的 `@success` 事件绑定
- 检查 `handleCaptchaSuccess` 函数是否存在
- 查看控制台是否有错误

## 快速诊断命令

在浏览器控制台中执行以下命令：

```javascript
// 1. 检查 crypto-js 是否加载
typeof CryptoJS
// 预期输出: "object"

// 2. 测试 AES 加密
const testKey = 'owALgSXrFtj9QVxF'
const testData = '{"x":123,"y":5.0}'
const key = CryptoJS.enc.Utf8.parse(testKey)
const srcs = CryptoJS.enc.Utf8.parse(testData)
const encrypted = CryptoJS.AES.encrypt(srcs, key, {
  mode: CryptoJS.mode.ECB,
  padding: CryptoJS.pad.Pkcs7
})
console.log('加密结果:', encrypted.toString())
// 预期输出: Base64 字符串（不是 { 开头）

// 3. 检查验证码配置
// 在 Vue DevTools 中查看 login 组件的 data
// captchaEnable 应该是 'true'（字符串）
```

## 下一步行动

1. **立即测试**：
   - 在 HBuilderX 中运行项目到浏览器
   - 按照上面的测试步骤操作
   - 记录控制台日志和 Network 请求

2. **如果验证码正常工作**：
   - 测试 Android 端
   - 测试 iOS 端
   - 确认三端都能正常工作

3. **如果仍有问题**：
   - 提供完整的控制台日志
   - 提供 Network 请求截图
   - 说明具体的错误现象

## 总结

当前代码已经完成了以下工作：

1. ✅ Web 端 AES 加密支持（使用 crypto-js）
2. ✅ 详细的调试日志
3. ✅ 移除不必要的租户 ID 获取
4. ✅ 三端统一的加密参数

理论上，Web 端验证码应该能够正常工作。如果仍有问题，请按照上面的测试步骤进行排查。

---

**日期**：2026-01-28  
**状态**：待测试  
**下一步**：在浏览器中测试并提供日志
