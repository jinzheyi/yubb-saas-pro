# iOS 端 AES 加密实现指南

**日期**: 2026-01-27  
**状态**: ✅ 代码已完成，需要集成到项目  
**平台**: iOS (UniApp X)

---

## 概述

iOS 端的 AES 加密使用 Apple 的 CommonCrypto 框架实现，与 Android 端和 Web 端使用相同的加密参数（AES-ECB-PKCS7），确保完全兼容。

---

## 实现方案

### 方案：Swift + CommonCrypto

由于 UTS 对 iOS 原生 API 的直接调用较为复杂，我们采用以下方案：

1. **创建 Swift 类** - `AESCryptor.swift`，封装 CommonCrypto 的 AES 加密
2. **UTS 调用 Swift** - 通过 UTS 的 iOS 桥接机制调用 Swift 方法
3. **Bridging Header** - 导入 CommonCrypto 框架

---

## 文件结构

```
shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/
├── aes.uts                          # UTS 加密工具（已更新）
├── AESCryptor.swift                 # iOS Swift 加密实现（新增）
└── AESCryptor-Bridging-Header.h     # Bridging Header（新增）
```

---

## 实现步骤

### 步骤 1: 查看已创建的文件

我已经创建了以下文件：

#### 1.1 `AESCryptor.swift`

**位置**: `components/captcha/utils/AESCryptor.swift`

**功能**: 
- 使用 CommonCrypto 实现 AES-ECB-PKCS7 加密
- 提供 `encryptString:withKey:` 和 `decryptString:withKey:` 方法
- 兼容 Objective-C 调用

**核心代码**:
```swift
@objc public class AESCryptor: NSObject {
    @objc public static func encryptString(_ plainText: String, withKey key: String) -> String? {
        // 使用 CCCrypt 进行 AES-ECB-PKCS7 加密
        // 返回 Base64 编码的密文
    }
    
    @objc public static func decryptString(_ cipherText: String, withKey key: String) -> String? {
        // 使用 CCCrypt 进行 AES-ECB-PKCS7 解密
        // 返回明文
    }
}
```

#### 1.2 `AESCryptor-Bridging-Header.h`

**位置**: `components/captcha/utils/AESCryptor-Bridging-Header.h`

**功能**: 导入 CommonCrypto 框架

**内容**:
```objc
#import <CommonCrypto/CommonCrypto.h>
```

#### 1.3 `aes.uts` (已更新)

**位置**: `components/captcha/utils/aes.uts`

**iOS 部分代码**:
```typescript
// #ifdef APP-IOS
function aesEncryptIOS(word: string, keyWord: string): string {
    const encrypted = UTSiOS.invokeMethod(
        'AESCryptor',
        'encryptString:withKey:',
        [word, keyWord]
    )
    return encrypted as string
}
// #endif
```

---

### 步骤 2: 集成到 UniApp X 项目

#### 2.1 添加 Swift 文件到项目

在 HBuilderX 中：

1. **打开项目目录**
   ```
   shengyu-ui/shengyu-ui-admin-uniappx/
   ```

2. **找到 iOS 原生目录**（如果不存在，需要创建）
   ```
   nativeplugins/
   └── AES-Crypto/
       ├── ios/
       │   ├── AESCryptor.swift
       │   └── AESCryptor-Bridging-Header.h
       └── package.json
   ```

3. **创建插件配置** `package.json`
   ```json
   {
     "name": "AES-Crypto",
     "id": "AES-Crypto",
     "version": "1.0.0",
     "description": "AES 加密插件",
     "_dp_type": "nativeplugin",
     "_dp_nativeplugin": {
       "ios": {
         "plugins": ["AES-Crypto"],
         "integrateType": "framework"
       }
     }
   }
   ```

#### 2.2 配置 Bridging Header

在 Xcode 项目中（如果使用云打包，可能需要在 manifest.json 中配置）：

1. **打开 Xcode 项目**
2. **添加 Bridging Header**
   - Build Settings → Swift Compiler - General
   - Objective-C Bridging Header: `$(PROJECT_DIR)/AESCryptor-Bridging-Header.h`

3. **确保 CommonCrypto 可用**
   - CommonCrypto 是 iOS 系统框架，无需额外导入

---

### 步骤 3: 测试 iOS 端

#### 3.1 编译项目

```bash
# 在 HBuilderX 中：
# 1. 选择 "运行" -> "运行到手机或模拟器"
# 2. 选择 "运行到 iOS 模拟器" 或 "运行到 iOS 设备"
# 3. 等待编译完成
```

#### 3.2 测试验证码

1. **打开登录页面**
2. **滑动验证码**
3. **查看控制台日志**

**成功的日志**:
```
AES 加密成功 (iOS): {
  原文长度: 15,
  密钥长度: 16,
  结果长度: 24
}

校验验证码响应: {
  repCode: "0000",
  repMsg: "success"
}
```

---

## 替代方案（如果 UTS 桥接不工作）

### 方案 A: 使用 UniApp 插件市场

1. **搜索插件**
   - 访问 [UniApp 插件市场](https://ext.dcloud.net.cn/)
   - 搜索 "AES 加密 iOS"
   - 选择支持 UniApp X 的插件

2. **安装插件**
   - 下载并导入到项目
   - 按照插件文档配置

3. **修改 `aes.uts`**
   ```typescript
   // #ifdef APP-IOS
   import { AESPlugin } from '@/uni_modules/xxx-aes'
   
   function aesEncryptIOS(word: string, keyWord: string): string {
       return AESPlugin.encrypt(word, keyWord)
   }
   // #endif
   ```

---

### 方案 B: 使用 CryptoKit (iOS 13+)

如果只需要支持 iOS 13 及以上版本，可以使用 Apple 的 CryptoKit 框架：

```swift
import CryptoKit

@available(iOS 13.0, *)
@objc public class AESCryptorKit: NSObject {
    @objc public static func encrypt(_ plainText: String, withKey key: String) -> String? {
        // 使用 CryptoKit 的 AES.GCM 或其他模式
        // 注意：CryptoKit 不直接支持 ECB 模式
        // 可能需要使用 CBC 模式并手动处理
    }
}
```

**注意**: CryptoKit 不直接支持 ECB 模式，建议继续使用 CommonCrypto。

---

### 方案 C: 临时关闭 iOS 加密

如果暂时无法实现 iOS 加密，可以临时让 iOS 返回明文，并在后端支持：

```typescript
// #ifdef APP-IOS
function aesEncryptIOS(word: string, keyWord: string): string {
    console.warn('iOS 平台 AES 加密暂未实现，返回明文')
    return word  // 返回明文
}
// #endif
```

**然后修改后端配置**（仅 iOS 测试时）:
```yaml
aj:
  captcha:
    aes-status: false  # 临时关闭加密
```

---

## 技术细节

### CommonCrypto 参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 算法 | `kCCAlgorithmAES` | AES 算法 |
| 模式 | `kCCOptionECBMode` | ECB 模式 |
| 填充 | `kCCOptionPKCS7Padding` | PKCS7 填充 |
| 密钥长度 | 16 字节 | AES-128 |
| 输出 | Base64 | 便于传输 |

### 与其他平台对比

| 平台 | 实现方式 | API |
|------|---------|-----|
| Web | crypto-js | `CryptoJS.AES.encrypt` |
| Android | javax.crypto | `Cipher.getInstance("AES/ECB/PKCS5Padding")` |
| iOS | CommonCrypto | `CCCrypt(kCCAlgorithmAES, kCCOptionECBMode)` |

**兼容性**: 三个平台使用相同的加密参数，完全兼容。

---

## 常见问题

### Q1: 为什么不直接在 UTS 中调用 CommonCrypto？

**A**: UTS 对 iOS 原生 API 的直接调用较为复杂，需要处理指针、内存管理等底层细节。使用 Swift 封装更简单、更安全。

### Q2: Bridging Header 是什么？

**A**: Bridging Header 是 Swift 和 Objective-C 之间的桥梁，用于在 Swift 中使用 C/Objective-C 库（如 CommonCrypto）。

### Q3: 如何调试 iOS 加密？

**A**: 
1. 在 Xcode 中打开项目
2. 在 `AESCryptor.swift` 中添加断点
3. 运行项目并触发加密
4. 查看变量值和执行流程

### Q4: 如果编译失败怎么办？

**A**: 
1. 检查 Bridging Header 路径是否正确
2. 确认 Swift 文件已添加到项目
3. 清理项目并重新编译
4. 查看 Xcode 的错误日志

### Q5: 可以使用第三方库吗？

**A**: 可以，但 CommonCrypto 是 iOS 系统自带的，无需额外依赖，更轻量、更可靠。

---

## 测试检查清单

### iOS 端检查

- [ ] `AESCryptor.swift` 已添加到项目
- [ ] `AESCryptor-Bridging-Header.h` 已配置
- [ ] Bridging Header 路径正确
- [ ] 项目编译成功
- [ ] 运行到 iOS 设备或模拟器

### 功能检查

- [ ] 验证码图片正常显示
- [ ] 滑块可以流畅滑动
- [ ] 控制台显示 "AES 加密成功 (iOS)"
- [ ] 控制台显示 `repCode: "0000"`
- [ ] 验证成功后可以登录

### 兼容性检查

- [ ] Android 端功能正常
- [ ] iOS 端功能正常
- [ ] Web 端功能正常
- [ ] 后端配置未修改

---

## 下一步工作

### 短期（必须）

1. **集成 Swift 文件到项目** ⚠️
   - 创建原生插件目录
   - 添加 Swift 文件
   - 配置 Bridging Header

2. **测试 iOS 端** ⚠️
   - 编译项目
   - 运行到 iOS 设备
   - 测试验证码功能

### 中期（优化）

1. **错误处理优化**
   - 更详细的错误日志
   - 更好的降级方案
   - 用户友好的提示

2. **性能优化**
   - 加密性能测试
   - 内存使用优化

### 长期（建议）

1. **使用成熟插件**
   - 搜索 UniApp 插件市场
   - 选择成熟的 AES 加密插件
   - 替换当前实现

2. **支持更多加密模式**
   - CBC 模式
   - GCM 模式
   - 更灵活的配置

---

## 相关文件

### 新增文件

1. **components/captcha/utils/AESCryptor.swift**
   - iOS Swift 加密实现

2. **components/captcha/utils/AESCryptor-Bridging-Header.h**
   - Bridging Header

3. **iOS端AES加密实现指南.md**（本文件）
   - iOS 实现指南

### 修改文件

1. **components/captcha/utils/aes.uts**
   - 更新了 iOS 加密调用逻辑

---

## 参考资料

### Apple 官方文档

- [CommonCrypto](https://developer.apple.com/library/archive/documentation/Security/Conceptual/cryptoservices/GeneralPurposeCrypto/GeneralPurposeCrypto.html)
- [CryptoKit](https://developer.apple.com/documentation/cryptokit)
- [Swift Bridging Header](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_objective-c_into_swift)

### 社区资源

- [Pure Swift CommonCrypto AES Encryption](https://www.splinter.com.au/2019/06/09/pure-swift-common-crypto-aes-encryption/)
- [AES 256 in Swift 4](https://gist.github.com/hfossli/7165dc023a10046e2322b0ce74c596f8)

---

## 总结

### 完成情况

- ✅ Swift 加密类已创建
- ✅ Bridging Header 已创建
- ✅ UTS 调用逻辑已更新
- ⏳ 需要集成到项目并测试

### 技术亮点

1. **使用系统框架** - CommonCrypto 是 iOS 自带的，无需额外依赖
2. **完全兼容** - 与 Android 和 Web 端使用相同的加密参数
3. **易于维护** - Swift 代码清晰，易于理解和修改

### 注意事项

1. ⚠️ **需要手动集成** - Swift 文件需要添加到 iOS 项目
2. ⚠️ **需要配置 Bridging Header** - 确保路径正确
3. ⚠️ **需要测试验证** - 在真机或模拟器上测试

---

**更新时间**: 2026-01-27  
**版本**: v1.0.0  
**状态**: ✅ 代码完成，待集成测试  

**下一步**: 集成 Swift 文件到项目并测试！🚀
