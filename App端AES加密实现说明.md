# App 端 AES 加密实现说明

**日期**: 2026-01-27  
**状态**: ✅ 已实现（Android 平台）  
**目标**: 不修改后端配置，App 端实现真正的 AES 加密

---

## 问题背景

之前的方案是关闭后端 AES 加密（`aes-status: false`），让 App 端发送明文数据。但这样会影响 Web 端的加密逻辑，不是最佳方案。

**用户需求**:
- ✅ App 端验证码校验通过
- ✅ 不修改后端配置
- ✅ Web 端逻辑不受影响

---

## 解决方案

### 方案：App 端实现原生 AES 加密

在 `components/captcha/utils/aes.uts` 中实现真正的 AES 加密，使用平台原生 API：

- **Android**: 使用 `javax.crypto.Cipher`
- **iOS**: 使用 `CommonCrypto`（待实现）

这样 App 端和 Web 端都使用加密数据，后端保持原有配置。

---

## 实现细节

### 1. 恢复后端配置

**文件**: `shengyu-server/src/main/resources/application.yaml`

**修改**: 移除了 `aes-status: false` 配置，恢复默认值（加密开启）

```yaml
aj:
  captcha:
    # ... 其他配置 ...
    # aes-status 使用默认值 true（加密开启）
```

### 2. 实现 Android 平台 AES 加密

**文件**: `shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts`

**核心代码**:
```typescript
// #ifdef APP-ANDROID
import Cipher from 'javax.crypto.Cipher';
import SecretKeySpec from 'javax.crypto.spec.SecretKeySpec';
import Base64 from 'android.util.Base64';

function aesEncryptAndroid(word: string, keyWord: string): string {
  // 创建密钥
  const keyBytes = keyWord.toByteArray('utf-8')
  const secretKey = new SecretKeySpec(keyBytes, 'AES')
  
  // 创建加密器 - ECB 模式，PKCS5Padding 填充
  const cipher = Cipher.getInstance('AES/ECB/PKCS5Padding')
  cipher.init(Cipher.ENCRYPT_MODE, secretKey)
  
  // 加密
  const wordBytes = word.toByteArray('utf-8')
  const encrypted = cipher.doFinal(wordBytes)
  
  // 转换为 Base64
  return Base64.encodeToString(encrypted, Base64.NO_WRAP)
}
// #endif
```

**加密参数**:
- 算法: AES
- 模式: ECB
- 填充: PKCS5Padding（等同于 PKCS7Padding）
- 输出: Base64 编码

### 3. 兼容 Web 端逻辑

Web 端使用 crypto-js 的 AES 加密：

```javascript
// Web 端（crypto-js）
import CryptoJS from 'crypto-js'

export function aesEncrypt(word, keyWord) {
  var key = CryptoJS.enc.Utf8.parse(keyWord);
  var srcs = CryptoJS.enc.Utf8.parse(word);
  var encrypted = CryptoJS.AES.encrypt(srcs, key, {
    mode: CryptoJS.mode.ECB,
    padding: CryptoJS.pad.Pkcs7
  });
  return encrypted.toString();
}
```

App 端的实现与 Web 端完全兼容，使用相同的加密参数。

---

## 测试步骤

### 步骤 1: 重启后端服务

由于恢复了配置，需要重启后端：

```bash
# 在 IDEA 中：
# 1. 停止 ShengyuServerApplication
# 2. 重新运行 ShengyuServerApplication
```

### 步骤 2: 编译 App 端

```bash
# 在 HBuilderX 中：
# 1. 清理项目
# 2. 重新编译
# 3. 运行到 Android 设备或模拟器
```

**重要**: 必须运行到 **Android 平台**，因为 iOS 平台的加密尚未实现。

### 步骤 3: 测试验证码

1. **打开登录页面**
   - 验证码图片正常显示

2. **滑动验证码**
   - 滑动滑块到正确位置

3. **查看控制台日志**

**成功的日志**:
```
AES 加密成功 (Android): {
  原文长度: 15,
  密钥长度: 16,
  结果长度: 24
}

校验验证码响应: {
  repCode: "0000",
  repMsg: "success"
}
```

**失败的日志**:
```
AES 加密失败 (Android): xxx
```

或

```
校验验证码响应: {
  repCode: "0001",
  repMsg: "Illegal base64 character 7b"
}
```

### 步骤 4: 验证 Web 端

确保 Web 端的验证码功能仍然正常：

1. 打开 Web 端登录页面
2. 滑动验证码
3. 确认验证成功

---

## 平台支持

### ✅ Android 平台

- **状态**: 已实现
- **API**: javax.crypto.Cipher
- **测试**: 需要在 Android 设备或模拟器上测试

### ⏳ iOS 平台

- **状态**: 待实现
- **API**: CommonCrypto (CCCrypt)
- **实现**: 需要调用 iOS 原生加密 API

### ❌ H5 平台

- **状态**: 不支持
- **原因**: UTS 代码不能在 H5 平台运行
- **替代方案**: H5 平台使用 Web 端的 crypto-js 实现

---

## 技术说明

### UniApp X 的 UTS 语法

UTS (uni type script) 是 UniApp X 的原生语言，可以直接调用平台原生 API：

```typescript
// 导入 Android 原生类
import Cipher from 'javax.crypto.Cipher';
import SecretKeySpec from 'javax.crypto.spec.SecretKeySpec';

// 使用条件编译
// #ifdef APP-ANDROID
// Android 平台代码
// #endif

// #ifdef APP-IOS
// iOS 平台代码
// #endif
```

### AES 加密参数说明

**ECB 模式**:
- Electronic Codebook（电子密码本）
- 最简单的加密模式
- 不需要初始化向量（IV）
- 相同的明文块会产生相同的密文块

**PKCS5Padding / PKCS7Padding**:
- PKCS5Padding 是 PKCS7Padding 的子集
- Java 中使用 PKCS5Padding
- JavaScript (crypto-js) 中使用 PKCS7Padding
- 两者在 AES 加密中是等价的

**Base64 编码**:
- 将二进制数据转换为可打印字符
- 便于在 JSON 中传输
- 使用 `NO_WRAP` 标志避免换行符

---

## 常见问题

### Q1: 为什么不使用 crypto-js？

**A**: UniApp X 使用 UTS 语言，不支持 npm 包。crypto-js 是纯 JavaScript 库，无法在 UTS 中使用。

### Q2: 为什么 iOS 平台没有实现？

**A**: iOS 平台的加密需要调用 CommonCrypto 库，实现相对复杂。当前优先实现 Android 平台。

### Q3: H5 平台怎么办？

**A**: H5 平台应该使用 Web 端的实现（crypto-js），不需要使用 UTS 代码。

### Q4: 如何验证加密是否正确？

**A**: 
1. 查看控制台日志，确认 "AES 加密成功"
2. 查看校验响应，确认 `repCode: "0000"`
3. 对比 Web 端和 App 端的加密结果

### Q5: 如果加密失败会怎样？

**A**: 代码中有降级方案，会返回明文。但这样会导致后端校验失败（如果后端开启了加密）。

---

## 对比：修改前 vs 修改后

### 修改前（关闭后端加密）

**后端配置**:
```yaml
aj:
  captcha:
    aes-status: false  # 关闭加密
```

**App 端**:
```typescript
export function aesEncrypt(word: string, keyWord: string): string {
  return word  // 返回明文
}
```

**优点**:
- ✅ 实现简单
- ✅ 无需原生 API

**缺点**:
- ❌ 影响 Web 端
- ❌ 安全性降低
- ❌ 需要修改后端配置

### 修改后（App 端原生加密）

**后端配置**:
```yaml
aj:
  captcha:
    # aes-status 使用默认值 true
```

**App 端**:
```typescript
export function aesEncrypt(word: string, keyWord: string): string {
  // 使用原生 AES 加密
  return aesEncryptAndroid(word, keyWord)
}
```

**优点**:
- ✅ 不影响 Web 端
- ✅ 不修改后端配置
- ✅ 真正的 AES 加密
- ✅ 安全性高

**缺点**:
- ⚠️ 需要原生 API
- ⚠️ iOS 平台待实现
- ⚠️ 实现相对复杂

---

## 下一步工作

### 短期（可选）

1. **测试 Android 平台**
   - 在真机或模拟器上测试
   - 确认加密功能正常
   - 验证与 Web 端兼容

2. **实现 iOS 平台**（如果需要）
   - 调用 CommonCrypto API
   - 实现 CCCrypt 加密
   - 测试验证

### 长期（建议）

1. **使用 UniApp 插件**
   - 搜索 UniApp 插件市场
   - 选择成熟的 AES 加密插件
   - 替换当前实现

2. **优化错误处理**
   - 更详细的错误日志
   - 更好的降级方案
   - 用户友好的提示

---

## 相关文件

### 修改的文件

1. **shengyu-server/src/main/resources/application.yaml**
   - 恢复了默认配置（移除 `aes-status: false`）

2. **shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts**
   - 实现了 Android 平台的原生 AES 加密
   - 使用 javax.crypto.Cipher API

### 参考文件

1. **shengyu-ui/shengyu-ui-admin-vue3/src/views/Login/components/LoginForm.vue**
   - Web 端的验证码实现

2. **shengyu-ui/captcha-dev/view/uni-app/src/pages/verify/utils/ase.js**
   - UniApp (非 X) 的 AES 加密实现（使用 crypto-js）

---

## 总结

### 核心改进

1. ✅ **不修改后端配置** - 后端保持加密开启
2. ✅ **不影响 Web 端** - Web 端逻辑完全不变
3. ✅ **真正的 AES 加密** - App 端使用原生加密 API
4. ✅ **与 Web 端兼容** - 使用相同的加密参数

### 技术亮点

1. **平台原生 API** - 直接调用 Android 的 javax.crypto.Cipher
2. **条件编译** - 使用 `#ifdef` 区分不同平台
3. **错误处理** - 加密失败时有降级方案
4. **日志输出** - 便于调试和问题排查

### 注意事项

1. ⚠️ **必须在 Android 平台测试** - iOS 平台尚未实现
2. ⚠️ **需要重启后端** - 恢复了配置
3. ⚠️ **需要重新编译 App** - UTS 代码需要编译

---

**更新时间**: 2026-01-27  
**版本**: v3.0.0  
**状态**: ✅ Android 平台已实现，iOS 平台待实现  

**下一步**: 在 Android 设备上测试验证码功能！
