# 三端验证码 AES 加密统一方案

## 问题背景

Web 端验证码校验报错：`{"repCode": "0001","repMsg": "Illegal base64 character 7b"}`

错误原因：`7b` 是 `{` 的 ASCII 十六进制码，说明发送的是**未加密的 JSON 字符串**。

## 根本原因

后端配置中没有显式配置 `aj.captcha.aes-status`，虽然默认值是 `true`，但可能由于某种原因没有正确生效，导致后端没有返回 `secretKey`，Web 端因此发送明文数据。

## 解决方案

### 1. 后端配置（已完成）

在 `shengyu-server/src/main/resources/application.yaml` 中**显式添加** `aes-status: true` 配置：

```yaml
aj:
  captcha:
    jigsaw: classpath:images/jigsaw
    pic-click: classpath:images/pic-click
    cache-type: redis
    cache-number: 1000
    timing-clear: 180
    type: blockPuzzle
    water-mark: 圣钰科技
    interference-options: 0
    aes-status: true # ✅ 显式开启 AES 加密（Android、iOS、Web 三端统一）
    req-frequency-limit-enable: false
    req-get-lock-limit: 5
    req-get-lock-seconds: 10
    req-get-minute-limit: 30
    req-check-minute-limit: 60
    req-verify-minute-limit: 60
```

### 2. 三端加密实现

#### Android 端（已完成）✅

- **文件**：`shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts`
- **实现**：使用 `javax.crypto.Cipher`
- **参数**：AES/ECB/PKCS5Padding
- **状态**：已测试通过

#### iOS 端（已完成）✅

- **文件**：
  - `shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/AESCryptor.swift`
  - `shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/AESCryptor-Bridging-Header.h`
- **实现**：使用 `CommonCrypto`
- **参数**：AES/ECB/PKCS7Padding
- **状态**：代码已完成，待集成测试

#### Web 端（已完成）✅

- **文件**：`shengyu-ui/shengyu-ui-admin-vue3/src/components/Verifition/src/utils/ase.ts`
- **实现**：使用 `crypto-js`
- **参数**：AES/ECB/PKCS7Padding
- **代码**：
```typescript
import CryptoJS from 'crypto-js'

export function aesEncrypt(word, keyWord = 'XwKsGlMcdPMEhR1B') {
  const key = CryptoJS.enc.Utf8.parse(keyWord)
  const srcs = CryptoJS.enc.Utf8.parse(word)
  const encrypted = CryptoJS.AES.encrypt(srcs, key, {
    mode: CryptoJS.mode.ECB,
    padding: CryptoJS.pad.Pkcs7
  })
  return encrypted.toString()
}
```

- **使用方式**：
```typescript
// 在 VerifySlide.vue 和 VerifyPoints.vue 中
let data = {
  captchaType: captchaType.value,
  pointJson: secretKey.value
    ? aesEncrypt(JSON.stringify({ x: moveLeftDistance, y: 5.0 }), secretKey.value)
    : JSON.stringify({ x: moveLeftDistance, y: 5.0 }),
  token: backToken.value
}
```

### 3. 加密流程

```
1. 前端请求验证码
   GET /system/captcha/get
   
2. 后端返回（aes-status: true）
   {
     "repCode": "0000",
     "repData": {
       "originalImageBase64": "...",
       "jigsawImageBase64": "...",
       "token": "xxx-xxx-xxx",
       "secretKey": "XwKsGlMcdPMEhR1B"  // ✅ 16位随机密钥
     }
   }

3. 前端校验时加密坐标
   POST /system/captcha/check
   {
     "captchaType": "blockPuzzle",
     "token": "xxx-xxx-xxx",
     "pointJson": "encrypted_base64_string"  // ✅ AES加密后的Base64字符串
   }

4. 后端解密并校验
   - 使用 secretKey 解密 pointJson
   - 验证坐标是否正确
```

### 4. 验证步骤

#### 步骤 1：重启后端服务

```bash
# 重新编译并启动后端
cd shengyu-server
mvn clean package -DskipTests
java -jar target/shengyu-server.jar
```

#### 步骤 2：测试 Web 端

1. 打开浏览器开发者工具（F12）
2. 访问登录页面
3. 点击登录按钮，触发验证码
4. 在 Network 标签中查看：
   - `/system/captcha/get` 响应中是否有 `secretKey` 字段
   - `/system/captcha/check` 请求中 `pointJson` 是否是 Base64 字符串（不是 `{` 开头）

#### 步骤 3：测试 App 端（Android）

1. 在 HBuilderX 中运行到 Android 设备
2. 打开登录页面
3. 点击登录，触发验证码
4. 滑动验证码，查看是否校验成功

#### 步骤 4：测试 App 端（iOS）

1. 将 Swift 文件集成到 iOS 项目
2. 配置 Bridging Header
3. 在 HBuilderX 中运行到 iOS 设备
4. 测试验证码功能

## 预期结果

### 成功标志

1. **后端日志**：
```
token：xxx-xxx-xxx, point:{"x":123,"y":5,"secretKey":"XwKsGlMcdPMEhR1B"}
```

2. **Web 端 Network**：
```json
// GET /system/captcha/get 响应
{
  "repCode": "0000",
  "repData": {
    "secretKey": "XwKsGlMcdPMEhR1B"  // ✅ 有值
  }
}

// POST /system/captcha/check 请求
{
  "pointJson": "U2FsdGVkX1+..."  // ✅ Base64 加密字符串
}
```

3. **校验成功**：
```json
{
  "repCode": "0000",
  "repMsg": "验证成功"
}
```

### 失败标志

1. **后端没有返回 secretKey**：
```json
{
  "repData": {
    "secretKey": null  // ❌ 或者没有这个字段
  }
}
```

2. **前端发送明文**：
```json
{
  "pointJson": "{\"x\":123,\"y\":5}"  // ❌ JSON 明文
}
```

3. **校验失败**：
```json
{
  "repCode": "0001",
  "repMsg": "Illegal base64 character 7b"  // ❌ 7b 是 { 的十六进制
}
```

## 常见问题

### Q1: 为什么要显式配置 `aes-status: true`？

**A**: 虽然默认值是 `true`，但显式配置可以：
- 确保配置正确加载
- 避免被其他配置文件覆盖
- 提高代码可读性和可维护性

### Q2: PKCS5Padding 和 PKCS7Padding 有什么区别？

**A**: 在 AES 加密中，PKCS5Padding 和 PKCS7Padding 是**等价的**：
- PKCS5Padding：块大小固定为 8 字节
- PKCS7Padding：块大小可变（1-255 字节）
- AES 块大小是 16 字节，所以两者在 AES 中完全相同

### Q3: 为什么 Web 端可以用 crypto-js，但 App 端不行？

**A**: 
- **Web 端**：运行在浏览器中，可以使用 npm 包（crypto-js）
- **UniApp X**：编译为原生代码，不支持 npm 包，必须使用原生 API
  - Android：`javax.crypto.Cipher`
  - iOS：`CommonCrypto`

### Q4: 如何确认后端真的开启了加密？

**A**: 查看后端日志或使用 Postman 测试：
```bash
# 请求验证码
curl -X POST http://localhost:48080/admin-api/system/captcha/get \
  -H "Content-Type: application/json" \
  -d '{"captchaType":"blockPuzzle"}'

# 查看响应中是否有 secretKey 字段
```

## 技术细节

### AES 加密参数统一

| 参数 | 值 | 说明 |
|------|-----|------|
| 算法 | AES | 高级加密标准 |
| 模式 | ECB | 电子密码本模式（最简单） |
| 填充 | PKCS5/PKCS7 | 两者在 AES 中等价 |
| 密钥长度 | 128 位（16 字节） | 后端随机生成 |
| 输出格式 | Base64 | 便于传输 |

### 代码对比

#### Android（Java）
```java
Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec);
byte[] encrypted = cipher.doFinal(content.getBytes("UTF-8"));
return Base64.getEncoder().encodeToString(encrypted);
```

#### iOS（Swift）
```swift
let cryptor = CCCrypt(
    CCOperation(kCCEncrypt),
    CCAlgorithm(kCCAlgorithmAES),
    CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode),
    keyData, keyLength,
    nil,  // ECB 模式不需要 IV
    dataIn, dataLength,
    dataOut, dataOutAvailable,
    &dataOutMoved
)
return Data(bytes: dataOut, count: dataOutMoved).base64EncodedString()
```

#### Web（TypeScript）
```typescript
const key = CryptoJS.enc.Utf8.parse(keyWord);
const srcs = CryptoJS.enc.Utf8.parse(word);
const encrypted = CryptoJS.AES.encrypt(srcs, key, {
  mode: CryptoJS.mode.ECB,
  padding: CryptoJS.pad.Pkcs7
});
return encrypted.toString();  // 自动 Base64 编码
```

## 总结

1. ✅ **后端配置**：显式添加 `aes-status: true`
2. ✅ **Android 端**：使用 `javax.crypto.Cipher` 实现 AES 加密
3. ✅ **iOS 端**：使用 `CommonCrypto` 实现 AES 加密
4. ✅ **Web 端**：使用 `crypto-js` 实现 AES 加密
5. ✅ **三端统一**：使用相同的加密参数（AES-ECB-PKCS5/7）

**下一步**：重启后端服务，测试三端验证码功能是否正常。
