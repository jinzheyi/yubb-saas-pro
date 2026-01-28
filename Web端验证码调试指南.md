# Web 端验证码调试指南

## 问题现状

- ✅ **后端已返回 `secretKey`**：`"owALgSXrFtj9QVxF"`
- ❌ **Web 端发送明文**：错误 `"Illegal base64 character 7b"`

## 调试步骤

### 1. 添加调试日志

已在以下文件中添加调试日志：
- `shengyu-ui/shengyu-ui-admin-vue3/src/components/Verifition/src/Verify/VerifySlide.vue`

### 2. 重新编译前端

```bash
cd shengyu-ui/shengyu-ui-admin-vue3
npm run dev
```

### 3. 打开浏览器测试

1. 打开浏览器开发者工具（F12）
2. 切换到 Console 标签
3. 访问登录页面：`http://localhost:80`
4. 点击登录按钮，触发验证码

### 4. 查看控制台日志

#### 获取验证码时的日志

```
=== 获取验证码响应 ===
完整响应: {...}
repCode: 0000
repData: {...}
✅ 设置 secretKey: owALgSXrFtj9QVxF
secretKey 类型: string
token: 8867548b50184f7199f83ac3c1b34dd9
=====================
```

**检查点**：
- `secretKey` 是否有值？
- `secretKey` 类型是否为 `string`？

#### 滑动验证码时的日志

```
=== 验证码加密调试 ===
secretKey: owALgSXrFtj9QVxF
secretKey 类型: string
secretKey 是否为真值: true
原始坐标 JSON: {"x":123,"y":5.0}
加密后的 pointJson: U2FsdGVkX1+...
发送的请求数据: {captchaType: "blockPuzzle", pointJson: "U2FsdGVkX1+...", token: "..."}
=====================
```

**检查点**：
- `secretKey` 是否有值？
- `secretKey 是否为真值` 是否为 `true`？
- `加密后的 pointJson` 是否是 Base64 字符串（不是 `{` 开头）？

### 5. 可能的问题

#### 问题 1：`secretKey` 为空字符串

**症状**：
```
secretKey: ""
secretKey 类型: string
secretKey 是否为真值: false
⚠️ secretKey 为空，发送明文: {"x":123,"y":5.0}
```

**原因**：后端返回的 `secretKey` 是空字符串

**解决方案**：
1. 检查后端配置：`application.yaml` 中 `aes-status: true`
2. 重启后端服务
3. 清除浏览器缓存

#### 问题 2：`secretKey` 为 `undefined`

**症状**：
```
secretKey: undefined
secretKey 类型: undefined
secretKey 是否为真值: false
⚠️ secretKey 为空，发送明文: {"x":123,"y":5.0}
```

**原因**：后端响应中没有 `secretKey` 字段

**解决方案**：
1. 检查后端响应结构
2. 确认后端版本是否支持 `secretKey`
3. 检查后端日志

#### 问题 3：`aesEncrypt` 函数错误

**症状**：
```
secretKey: owALgSXrFtj9QVxF
secretKey 类型: string
secretKey 是否为真值: true
原始坐标 JSON: {"x":123,"y":5.0}
❌ 加密失败，错误: ...
```

**原因**：`aesEncrypt` 函数执行失败

**解决方案**：
1. 检查 `crypto-js` 是否正确安装
2. 检查 `ase.ts` 文件是否存在
3. 重新安装依赖：`npm install`

#### 问题 4：响应数据结构不匹配

**症状**：
```
repData: null
或
repData: {...} (但没有 secretKey 字段)
```

**原因**：后端响应结构与前端期望不一致

**解决方案**：
1. 检查后端 API 版本
2. 确认后端是否正确配置了 `aes-status: true`
3. 使用 Postman 测试后端 API

### 6. 验证成功的标志

#### 控制台日志

```
=== 获取验证码响应 ===
✅ 设置 secretKey: owALgSXrFtj9QVxF
=====================

=== 验证码加密调试 ===
secretKey: owALgSXrFtj9QVxF
secretKey 是否为真值: true
加密后的 pointJson: U2FsdGVkX1+abc123...
=====================
```

#### Network 标签

**GET /system/captcha/get 响应**：
```json
{
  "repCode": "0000",
  "repData": {
    "secretKey": "owALgSXrFtj9QVxF",
    "token": "...",
    "originalImageBase64": "...",
    "jigsawImageBase64": "..."
  }
}
```

**POST /system/captcha/check 请求**：
```json
{
  "captchaType": "blockPuzzle",
  "token": "...",
  "pointJson": "U2FsdGVkX1+..."  // ✅ Base64 字符串
}
```

**POST /system/captcha/check 响应**：
```json
{
  "repCode": "0000",
  "repMsg": "验证成功"
}
```

## 常见问题排查

### Q1: 为什么后端返回了 `secretKey`，但前端还是发送明文？

**可能原因**：
1. 前端缓存了旧的验证码组件代码
2. `secretKey` 是空字符串（`""`）
3. Vue 响应式数据更新延迟

**解决方案**：
1. 清除浏览器缓存（Ctrl+Shift+Delete）
2. 硬刷新页面（Ctrl+F5）
3. 检查控制台日志中的 `secretKey` 值

### Q2: 如何确认 `aesEncrypt` 函数是否正常工作？

**测试方法**：
在浏览器控制台中手动测试：

```javascript
// 导入加密函数（如果可以访问）
import { aesEncrypt } from '@/components/Verifition/src/utils/ase'

// 测试加密
const testKey = 'owALgSXrFtj9QVxF'
const testData = '{"x":123,"y":5.0}'
const encrypted = aesEncrypt(testData, testKey)
console.log('加密结果:', encrypted)
// 应该输出类似：U2FsdGVkX1+...
```

### Q3: 如何验证后端配置是否生效？

**方法 1：使用 Postman**

```bash
POST http://localhost:48080/admin-api/system/captcha/get
Content-Type: application/json

{
  "captchaType": "blockPuzzle"
}
```

**方法 2：使用 curl**

```bash
curl -X POST http://localhost:48080/admin-api/system/captcha/get \
  -H "Content-Type: application/json" \
  -d '{"captchaType":"blockPuzzle"}'
```

**预期响应**：
```json
{
  "repCode": "0000",
  "repData": {
    "secretKey": "XwKsGlMcdPMEhR1B"  // ✅ 必须有值
  }
}
```

## 下一步

1. **重新编译前端**：`npm run dev`
2. **打开浏览器测试**：查看控制台日志
3. **根据日志排查**：使用上面的检查点
4. **如果问题仍然存在**：提供完整的控制台日志

## 移除调试日志

测试完成后，可以移除调试日志：

```bash
# 恢复原始文件
git checkout shengyu-ui/shengyu-ui-admin-vue3/src/components/Verifition/src/Verify/VerifySlide.vue
```

或者手动删除 `console.log` 语句。
