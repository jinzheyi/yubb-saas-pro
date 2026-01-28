# Web 端验证码问题 - 调试中

## 问题现状

### 已确认的事实

1. ✅ **后端配置正确**：
   - `application.yaml` 中已添加 `aes-status: true`
   - 后端成功返回 `secretKey`：`"owALgSXrFtj9QVxF"`

2. ✅ **后端响应正常**：
```json
{
  "repCode": "0000",
  "repData": {
    "secretKey": "owALgSXrFtj9QVxF",
    "token": "8867548b50184f7199f83ac3c1b34dd9",
    "originalImageBase64": "...",
    "jigsawImageBase64": "..."
  }
}
```

3. ❌ **Web 端发送明文**：
```json
// 校验接口响应
{
  "repCode": "0001",
  "repMsg": "Illegal base64 character 7b"
}
```

错误 `"Illegal base64 character 7b"` 说明发送的是 `{` 开头的 JSON 字符串（`7b` 是 `{` 的十六进制）。

## 问题分析

### 代码逻辑

Web 端验证码组件的加密逻辑：

```typescript
// VerifySlide.vue
let data = {
  captchaType: captchaType.value,
  pointJson: secretKey.value
    ? aesEncrypt(JSON.stringify({ x: moveLeftDistance, y: 5.0 }), secretKey.value)
    : JSON.stringify({ x: moveLeftDistance, y: 5.0 }),
  token: backToken.value
}
```

**逻辑正确**：如果 `secretKey.value` 有值，就加密；否则发送明文。

### 可能的原因

1. **`secretKey.value` 为空字符串**：
   - 虽然后端返回了 `"secretKey": "owALgSXrFtj9QVxF"`
   - 但前端可能接收到的是空字符串 `""`
   - 空字符串在 JavaScript 中是 falsy 值

2. **Vue 响应式数据延迟**：
   - `secretKey.value` 在滑动验证码时还未更新
   - 异步数据更新问题

3. **前端缓存**：
   - 浏览器缓存了旧的验证码组件代码
   - 需要清除缓存或硬刷新

4. **数据结构不匹配**：
   - 前端期望的字段名与后端返回的不一致
   - 例如：前端期望 `secretKey`，后端返回 `secret_key`

## 已采取的措施

### 1. 添加调试日志

在 `VerifySlide.vue` 中添加了详细的调试日志：

#### 获取验证码时
```typescript
const getPictrue = async () => {
  const res = await getCode(data)
  
  console.log('=== 获取验证码响应 ===')
  console.log('完整响应:', res)
  console.log('✅ 设置 secretKey:', secretKey.value)
  console.log('=====================')
}
```

#### 滑动验证码时
```typescript
const end = () => {
  console.log('=== 验证码加密调试 ===')
  console.log('secretKey:', secretKey.value)
  console.log('secretKey 是否为真值:', !!secretKey.value)
  console.log('原始坐标 JSON:', pointJsonStr)
  console.log('加密后的 pointJson:', encryptedPointJson)
  console.log('=====================')
}
```

### 2. 创建调试指南

创建了 `Web端验证码调试指南.md`，包含：
- 详细的调试步骤
- 控制台日志检查点
- 常见问题排查方法

## 下一步操作

### 立即执行

1. **重新编译前端**：
```bash
cd shengyu-ui/shengyu-ui-admin-vue3
npm run dev
```

2. **打开浏览器测试**：
   - 打开开发者工具（F12）
   - 切换到 Console 标签
   - 访问登录页面
   - 点击登录，触发验证码
   - 滑动验证码

3. **查看控制台日志**：
   - 检查 `secretKey` 的值
   - 检查 `secretKey` 的类型
   - 检查加密后的 `pointJson`

### 根据日志排查

#### 情况 1：`secretKey` 为空字符串

**日志**：
```
secretKey: ""
secretKey 是否为真值: false
⚠️ secretKey 为空，发送明文
```

**解决方案**：
- 检查后端响应数据结构
- 确认后端是否真的返回了非空的 `secretKey`
- 使用 Postman 直接测试后端 API

#### 情况 2：`secretKey` 有值但加密失败

**日志**：
```
secretKey: owALgSXrFtj9QVxF
secretKey 是否为真值: true
❌ 加密失败，错误: ...
```

**解决方案**：
- 检查 `crypto-js` 是否正确安装
- 检查 `ase.ts` 文件是否存在
- 重新安装依赖：`npm install`

#### 情况 3：`secretKey` 有值且加密成功

**日志**：
```
secretKey: owALgSXrFtj9QVxF
secretKey 是否为真值: true
加密后的 pointJson: U2FsdGVkX1+...
```

**但仍然报错**：
- 检查 Network 标签中实际发送的请求
- 确认请求中的 `pointJson` 是否真的是加密后的值
- 可能是请求拦截器修改了数据

## 预期结果

### 成功的日志

```
=== 获取验证码响应 ===
✅ 设置 secretKey: owALgSXrFtj9QVxF
secretKey 类型: string
=====================

=== 验证码加密调试 ===
secretKey: owALgSXrFtj9QVxF
secretKey 是否为真值: true
原始坐标 JSON: {"x":123,"y":5.0}
加密后的 pointJson: U2FsdGVkX1+abc123...
发送的请求数据: {captchaType: "blockPuzzle", pointJson: "U2FsdGVkX1+...", token: "..."}
=====================
```

### 成功的响应

```json
{
  "repCode": "0000",
  "repMsg": "验证成功"
}
```

## 备用方案

如果调试后发现问题无法解决，可以考虑：

### 方案 1：强制使用加密

修改代码，即使 `secretKey` 为空也使用默认密钥：

```typescript
const defaultKey = 'XwKsGlMcdPMEhR1B'
const encryptKey = secretKey.value || defaultKey

let data = {
  captchaType: captchaType.value,
  pointJson: aesEncrypt(JSON.stringify({ x: moveLeftDistance, y: 5.0 }), encryptKey),
  token: backToken.value
}
```

### 方案 2：检查响应拦截器

检查是否有响应拦截器修改了 `secretKey`：

```typescript
// 在 request.ts 或类似文件中
axios.interceptors.response.use(
  response => {
    // 检查是否修改了 secretKey
    console.log('响应拦截器:', response.data)
    return response
  }
)
```

### 方案 3：临时关闭加密

如果急需上线，可以临时关闭后端加密：

```yaml
# application.yaml
aj:
  captcha:
    aes-status: false  # 临时关闭
```

**注意**：这会导致 App 端也无法使用加密，不推荐。

## 总结

1. ✅ 后端配置正确，已返回 `secretKey`
2. ❌ Web 端仍然发送明文
3. 🔍 已添加调试日志，等待测试结果
4. 📋 根据日志结果进行下一步排查

**关键**：查看浏览器控制台日志，确认 `secretKey` 的值和类型。
