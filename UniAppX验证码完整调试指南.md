# UniApp X 验证码完整调试指南

## 问题描述

UniApp X 项目验证码没有正常调用校验接口。

## 完整流程分析

### 1. 登录流程

```
用户点击登录按钮
    ↓
handleLogin() 函数
    ↓
判断 captchaEnable
    ├─ 'false' → 直接调用 doLogin('')
    └─ 'true' → 调用 captchaRef.value.show()
        ↓
    slider-captcha 组件显示
        ↓
    loadCaptcha() 获取验证码图片
        ↓
    用户滑动验证码
        ↓
    handleTouchEnd() 触发
        ↓
    verifyCaptcha() 校验验证码
        ↓
    checkCaptcha() API 调用
        ↓
    handleSuccess() 或 handleFail()
        ↓
    emit('success', { captchaVerification })
        ↓
    handleCaptchaSuccess() 接收事件
        ↓
    doLogin(captchaVerification) 执行登录
```

### 2. 关键代码检查

#### login.uvue - 登录页面

```typescript
// ✅ 正确：验证码组件引用
const captchaRef = ref<any>(null)

// ✅ 正确：登录按钮点击
async function handleLogin() {
	if (captchaEnable.value === 'false') {
		await doLogin('')
	} else {
		if (captchaRef.value) {
			captchaRef.value.show()  // 显示验证码
		}
	}
}

// ✅ 正确：验证码成功回调
function handleCaptchaSuccess(data: any) {
	captchaVerification.value = data.captchaVerification
	doLogin(data.captchaVerification)
}

// ✅ 正确：模板中的组件
<slider-captcha 
	ref="captchaRef" 
	captchaType="blockPuzzle"
	@success="handleCaptchaSuccess"
	@fail="handleCaptchaFail"
/>
```

#### slider-captcha.uvue - 验证码组件

```typescript
// ✅ 正确：校验验证码
async function verifyCaptcha(distance: number) {
	const pointJson = JSON.stringify({ x: distance, y: 5.0 })
	
	let encryptedPoint = pointJson
	if (secretKey.value) {
		encryptedPoint = aesEncrypt(pointJson, secretKey.value)
	}
	
	const data = {
		captchaType: props.captchaType,
		pointJson: encryptedPoint,
		token: token.value
	}
	
	const result = await checkCaptcha(data)  // ✅ 调用 API
	
	if (result && result.repCode == '0000') {
		handleSuccess()
	} else {
		handleFail()
	}
}

// ✅ 正确：验证成功
function handleSuccess() {
	// ...
	emit('success', { captchaVerification })  // ✅ 触发事件
	visible.value = false
	reset()
}
```

#### login.uts - API 调用

```typescript
// ✅ 正确：校验验证码 API
export function checkCaptcha(data: UTSJSONObject): Promise<any> {
	return new Promise((resolve, reject) => {
		const config = requestInterceptor({
			url: BASE_URL + '/system/captcha/check',
			method: 'POST',
			data: data,
			header: {
				'Content-Type': 'application/json'
			},
			timeout: TIMEOUT
		})
		
		uni.request({
			...config,
			success: (res) => {
				if (res.statusCode == 200) {
					resolve(res.data)
				} else {
					reject(res)
				}
			},
			fail: (err) => {
				uni.showToast({
					title: '网络连接失败',
					icon: 'none'
				})
				reject(err)
			}
		})
	})
}
```

## 调试步骤

### 步骤 1：检查验证码是否开启

在 `config/app.config.uts` 中检查：

```typescript
export const CAPTCHA_ENABLE = 'true'  // ✅ 应该是 'true'
```

### 步骤 2：添加调试日志

在 `slider-captcha.uvue` 的关键位置添加日志：

```typescript
// 在 handleTouchEnd 中
async function handleTouchEnd(e: any) {
	console.log('=== 触摸结束 ===')
	console.log('移动距离:', currentX.value - startX.value)
	
	// ...
	
	await verifyCaptcha(realDistance)
	console.log('=== 验证完成 ===')
}

// 在 verifyCaptcha 中
async function verifyCaptcha(distance: number) {
	console.log('=== 开始校验验证码 ===')
	console.log('距离:', distance)
	console.log('token:', token.value)
	console.log('secretKey:', secretKey.value)
	
	// ...
	
	console.log('发送请求:', data)
	const result = await checkCaptcha(data)
	console.log('收到响应:', result)
	
	// ...
}

// 在 handleSuccess 中
function handleSuccess() {
	console.log('=== 验证成功 ===')
	console.log('准备触发 success 事件')
	
	// ...
	
	emit('success', { captchaVerification })
	console.log('success 事件已触发')
}
```

在 `login.uvue` 中添加日志：

```typescript
function handleCaptchaSuccess(data: any) {
	console.log('=== 收到验证码成功事件 ===')
	console.log('data:', data)
	console.log('captchaVerification:', data.captchaVerification)
	
	captchaVerification.value = data.captchaVerification
	doLogin(data.captchaVerification)
}

async function doLogin(verification: string) {
	console.log('=== 开始登录 ===')
	console.log('verification:', verification)
	
	// ...
}
```

### 步骤 3：检查网络请求

在浏览器开发者工具的 Network 标签中查看：

1. **GET /system/captcha/get** - 获取验证码
   - 请求参数：`{ captchaType: "blockPuzzle", clientUid: "...", ts: ... }`
   - 响应：`{ repCode: "0000", repData: { secretKey: "...", token: "...", ... } }`

2. **POST /system/captcha/check** - 校验验证码
   - 请求参数：`{ captchaType: "blockPuzzle", pointJson: "...", token: "..." }`
   - 响应：`{ repCode: "0000", repMsg: "验证成功" }`

### 步骤 4：检查常见问题

#### 问题 1：验证码组件没有显示

**症状**：点击登录按钮后，验证码弹窗没有出现

**排查**：
```typescript
// 在 handleLogin 中添加日志
async function handleLogin() {
	console.log('captchaEnable:', captchaEnable.value)
	console.log('captchaRef:', captchaRef.value)
	
	if (captchaEnable.value === 'false') {
		console.log('验证码未开启，直接登录')
		await doLogin('')
	} else {
		console.log('验证码已开启，显示验证码')
		if (captchaRef.value) {
			console.log('调用 captchaRef.value.show()')
			captchaRef.value.show()
		} else {
			console.error('❌ captchaRef.value 为 null')
		}
	}
}
```

**解决方案**：
- 检查 `captchaEnable` 的值是否为 `'true'`（字符串）
- 检查 `captchaRef` 是否正确绑定到组件

#### 问题 2：滑动后没有调用 API

**症状**：滑动验证码后，没有看到 `/system/captcha/check` 请求

**排查**：
```typescript
// 在 handleTouchEnd 中添加日志
async function handleTouchEnd(e: any) {
	console.log('=== handleTouchEnd 被调用 ===')
	console.log('isSliding:', isSliding.value)
	console.log('moveDistance:', currentX.value - startX.value)
	
	if (isSliding.value) {
		// ...
		console.log('准备调用 verifyCaptcha')
		await verifyCaptcha(realDistance)
		console.log('verifyCaptcha 调用完成')
	} else {
		console.log('❌ isSliding 为 false，不执行验证')
	}
}
```

**可能原因**：
1. `isSliding` 状态没有正确设置
2. 滑动距离太小（< 10px）
3. `verifyCaptcha` 函数抛出异常

#### 问题 3：API 调用失败

**症状**：看到 `/system/captcha/check` 请求，但返回错误

**排查**：
```typescript
// 在 checkCaptcha 中添加日志
export function checkCaptcha(data: UTSJSONObject): Promise<any> {
	console.log('=== checkCaptcha 被调用 ===')
	console.log('请求数据:', data)
	console.log('请求 URL:', BASE_URL + '/system/captcha/check')
	
	return new Promise((resolve, reject) => {
		// ...
		uni.request({
			...config,
			success: (res) => {
				console.log('请求成功:', res)
				if (res.statusCode == 200) {
					resolve(res.data)
				} else {
					console.error('状态码错误:', res.statusCode)
					reject(res)
				}
			},
			fail: (err) => {
				console.error('请求失败:', err)
				uni.showToast({
					title: '网络连接失败',
					icon: 'none'
				})
				reject(err)
			}
		})
	})
}
```

**可能原因**：
1. `pointJson` 格式错误（应该是 Base64 字符串）
2. `token` 为空
3. 后端返回错误（如 `"Illegal base64 character 7b"`）

#### 问题 4：验证成功但没有触发登录

**症状**：验证码显示成功，但没有调用登录接口

**排查**：
```typescript
// 在 handleSuccess 中添加日志
function handleSuccess() {
	console.log('=== handleSuccess 被调用 ===')
	
	buttonColor.value = '#5cb85c'
	sliderIcon.value = '✓'
	tipSuccess.value = true
	tipText.value = `验证成功`
	
	setTimeout(() => {
		console.log('准备生成 captchaVerification')
		const captchaVerification = secretKey.value ? 
			aesEncrypt(token.value + '---' + JSON.stringify({ x: currentX.value - startX.value, y: 5.0 }), secretKey.value) :
			token.value + '---' + JSON.stringify({ x: currentX.value - startX.value, y: 5.0 })
		
		console.log('captchaVerification:', captchaVerification)
		console.log('准备触发 success 事件')
		
		emit('success', { captchaVerification })
		
		console.log('success 事件已触发')
		visible.value = false
		reset()
	}, 1000)
}
```

**可能原因**：
1. `emit('success')` 没有正确触发
2. 父组件没有监听 `@success` 事件
3. `handleCaptchaSuccess` 函数没有被调用

### 步骤 5：完整的测试流程

1. **清除缓存**：
```typescript
// 在浏览器控制台执行
localStorage.clear()
sessionStorage.clear()
```

2. **重新编译项目**：
   - 在 HBuilderX 中：运行 -> 运行到浏览器 -> Chrome

3. **打开开发者工具**：
   - 按 F12
   - 切换到 Console 标签

4. **测试登录**：
   - 输入账号密码
   - 点击登录按钮
   - 观察控制台日志

5. **查看日志输出**：
```
captchaEnable: true
captchaRef: [object Object]
验证码已开启，显示验证码
调用 captchaRef.value.show()
=== 获取验证码请求参数 ===
=== 获取验证码响应 ===
=== 触摸结束 ===
=== 开始校验验证码 ===
=== checkCaptcha 被调用 ===
请求成功: {...}
=== 验证成功 ===
success 事件已触发
=== 收到验证码成功事件 ===
=== 开始登录 ===
```

## 常见错误和解决方案

### 错误 1：`captchaRef.value` 为 null

**原因**：组件引用没有正确绑定

**解决方案**：
```vue
<!-- 确保 ref 属性正确 -->
<slider-captcha 
	ref="captchaRef"  <!-- ✅ 必须有 ref -->
	captchaType="blockPuzzle"
	@success="handleCaptchaSuccess"
	@fail="handleCaptchaFail"
/>
```

### 错误 2：`aesEncrypt is not a function`

**原因**：AES 加密函数导入失败

**解决方案**：
```typescript
// 检查导入语句
import { aesEncrypt } from './utils/aes.uts'

// 或者在使用时动态导入
const { aesEncrypt } = require('./utils/aes.uts')
```

### 错误 3：`Illegal base64 character 7b`

**原因**：发送了明文 JSON 而不是加密后的 Base64

**解决方案**：
- 检查 `secretKey` 是否有值
- 检查 `aesEncrypt` 函数是否正确执行
- 查看控制台日志中的 `加密后` 字段

### 错误 4：验证码图片不显示

**原因**：Base64 图片数据为空

**解决方案**：
```typescript
// 检查 loadCaptcha 的响应
console.log('backImgBase:', backImgBase.value)
console.log('blockImgBase:', blockImgBase.value)

// 确保响应数据正确
if (result && result.repCode == '0000') {
	console.log('repData:', result.repData)
	backImgBase.value = result.repData.originalImageBase64
	blockImgBase.value = result.repData.jigsawImageBase64
}
```

## 总结

UniApp X 验证码的完整流程包括：

1. ✅ 用户点击登录
2. ✅ 显示验证码组件
3. ✅ 获取验证码图片
4. ✅ 用户滑动验证码
5. ✅ 调用校验 API
6. ✅ 触发 success 事件
7. ✅ 执行登录

如果某个环节出现问题，请按照上面的调试步骤逐步排查。
