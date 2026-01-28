# UniApp X Web 端验证码测试指南

## 快速测试步骤

### 1. 启动后端服务

确保后端服务正在运行：
```bash
# 检查后端是否运行
curl http://localhost:48080/admin-api/system/captcha/get
```

### 2. 启动 UniApp X 项目

在 HBuilderX 中：
1. 打开项目：`shengyu-ui/shengyu-ui-admin-uniappx`
2. 点击"运行" -> "运行到浏览器" -> "Chrome"

或使用命令行：
```bash
# 如果项目支持命令行运行
npm run dev:h5
```

### 3. 打开浏览器测试

1. 浏览器会自动打开（通常是 `http://localhost:8080`）
2. 按 F12 打开开发者工具
3. 切换到 Console 标签

### 4. 测试登录流程

1. 在登录页面输入：
   - 账号：`jin_zheyicn@qq.com`
   - 密码：`123456`
2. 点击"登录"按钮
3. 观察验证码弹窗是否出现

### 5. 测试验证码

1. 验证码弹窗应该显示：
   - 背景图片
   - 滑块图片
   - 滑动条
2. 用鼠标拖动滑块向右滑动
3. 松开鼠标

### 6. 查看控制台日志

**成功的日志应该包含**：

```
获取验证码请求参数: {captchaType: "blockPuzzle", ...}
获取验证码响应: {repCode: "0000", repData: {...}}
验证码图片已加载: {hasBackImg: true, hasBlockImg: true, token: "..."}

开始滑动: 100
结束滑动: {startX: 100, currentX: 223, moveDistance: 123, 耗时: "1234ms"}

=== 开始校验验证码 ===
距离: 123
token: "..."
secretKey: "owALgSXrFtj9QVxF"
原始坐标 JSON: {"x":123,"y":5.0}

✅ AES 加密成功: {
  原文: '{"x":123,"y":5.0}',
  密钥: 'owALgSXrFtj9QVxF',
  加密后: 'U2FsdGVkX1+...'
}

校验验证码请求参数: {captchaType: "blockPuzzle", pointJson: "U2FsdGVkX1+...", token: "..."}
校验验证码响应: {repCode: "0000", repMsg: "验证成功"}

✅ 验证成功
准备生成 captchaVerification
✅ success 事件已触发
```

### 7. 查看 Network 请求

切换到 Network 标签，应该看到：

1. **POST /admin-api/system/captcha/get** - 状态码 200
2. **POST /admin-api/system/captcha/check** - 状态码 200
3. **POST /admin-api/system/auth/login** - 状态码 200

## 常见问题快速诊断

### 问题 1：验证码弹窗没有出现

**在控制台执行**：
```javascript
// 检查验证码配置
console.log('CAPTCHA_ENABLE:', 'true')  // 应该是 'true'
```

**解决方案**：
- 检查 `config/app.config.uts` 中的 `CAPTCHA_ENABLE` 值
- 重新编译项目

### 问题 2：crypto-js 未加载

**在控制台执行**：
```javascript
typeof CryptoJS
// 应该输出: "object"
```

**如果输出 "undefined"**：
- 清除浏览器缓存（Ctrl+Shift+Delete）
- 硬刷新页面（Ctrl+F5）
- 检查网络连接

### 问题 3：AES 加密失败

**在控制台执行**：
```javascript
// 测试 AES 加密
const testKey = 'owALgSXrFtj9QVxF'
const testData = '{"x":123,"y":5.0}'
const key = CryptoJS.enc.Utf8.parse(testKey)
const srcs = CryptoJS.enc.Utf8.parse(testData)
const encrypted = CryptoJS.AES.encrypt(srcs, key, {
  mode: CryptoJS.mode.ECB,
  padding: CryptoJS.pad.Pkcs7
})
console.log('加密结果:', encrypted.toString())
// 应该输出 Base64 字符串
```

**如果加密失败**：
- 检查 crypto-js 是否正确加载
- 检查密钥长度（应该是 16 字节）

### 问题 4：验证码校验失败

**查看 Network 标签中的 /system/captcha/check 请求**：

**请求体应该是**：
```json
{
  "captchaType": "blockPuzzle",
  "pointJson": "U2FsdGVkX1+...",  // Base64 字符串
  "token": "..."
}
```

**如果 pointJson 是 `{"x":123,"y":5.0}`（明文）**：
- 说明 AES 加密没有生效
- 检查 `secretKey` 是否有值
- 检查条件编译是否正确

## 预期结果

### 成功标志

1. ✅ 验证码弹窗正常显示
2. ✅ 可以流畅滑动验证码
3. ✅ 控制台显示"✅ AES 加密成功"
4. ✅ Network 中看到 `/system/captcha/check` 请求
5. ✅ 验证码显示"验证成功"
6. ✅ 自动跳转到首页

### 失败标志

1. ❌ 验证码弹窗没有出现
2. ❌ 控制台显示"crypto-js 未加载"
3. ❌ 控制台显示"AES 加密失败"
4. ❌ Network 中没有 `/system/captcha/check` 请求
5. ❌ 验证码显示"验证失败"
6. ❌ 后端返回错误："Illegal base64 character 7b"

## 三端对比测试

### Web 端（H5）

- 使用 crypto-js 进行 AES 加密
- 通过 CDN 引入
- 条件编译：`#ifdef H5`

### Android 端

- 使用 `javax.crypto.Cipher` 进行 AES 加密
- 原生 Java API
- 条件编译：`#ifdef APP-ANDROID`

### iOS 端

- 使用 `CommonCrypto` 进行 AES 加密
- 原生 Swift API
- 条件编译：`#ifdef APP-IOS`

## 完整的测试清单

- [ ] 后端服务正在运行
- [ ] UniApp X 项目已启动
- [ ] 浏览器开发者工具已打开
- [ ] 输入账号密码
- [ ] 点击登录按钮
- [ ] 验证码弹窗出现
- [ ] 滑动验证码
- [ ] 查看控制台日志
- [ ] 查看 Network 请求
- [ ] 验证成功并登录
- [ ] 测试 Android 端
- [ ] 测试 iOS 端

## 如果测试失败

请提供以下信息：

1. **完整的控制台日志**（从点击登录到验证完成）
2. **Network 标签截图**（显示所有请求）
3. **具体的错误信息**
4. **浏览器版本**
5. **操作系统版本**

## 总结

当前实现已经完成：

1. ✅ Web 端 AES 加密（crypto-js）
2. ✅ Android 端 AES 加密（javax.crypto.Cipher）
3. ✅ iOS 端 AES 加密（CommonCrypto）
4. ✅ 三端统一的加密参数（AES-ECB-PKCS5/7）
5. ✅ 详细的调试日志
6. ✅ 移除不必要的租户 ID 获取

理论上，三端验证码都应该能够正常工作。请按照上面的步骤进行测试。

---

**日期**：2026-01-28  
**状态**：待测试  
**测试人员**：用户
