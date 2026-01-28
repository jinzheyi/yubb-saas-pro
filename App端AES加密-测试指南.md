# App 端 AES 加密 - 测试指南

**目标**: 验证 App 端原生 AES 加密是否正常工作  
**平台**: Android（iOS 待实现）  
**预计时间**: 10 分钟

---

## 🚀 快速测试（3 步）

### 步骤 1: 重启后端服务

```bash
# 在 IDEA 中：
# 1. 停止当前运行的 ShengyuServerApplication
# 2. 重新运行 ShengyuServerApplication
# 3. 确认启动成功，无错误日志
```

**为什么要重启？**  
恢复了后端配置，移除了 `aes-status: false`，后端现在期望接收加密数据。

---

### 步骤 2: 编译并运行 App

```bash
# 在 HBuilderX 中：
# 1. 选择项目 shengyu-ui-admin-uniappx
# 2. 点击 "运行" -> "运行到手机或模拟器" -> "运行到 Android App 基座"
# 3. 等待编译完成
```

**重要提示**:
- ⚠️ 必须运行到 **Android 平台**
- ⚠️ iOS 平台的加密尚未实现
- ⚠️ H5 平台不支持 UTS 代码

---

### 步骤 3: 测试验证码

1. **打开登录页面**
   - App 自动打开登录页面
   - 验证码图片应该正常显示

2. **滑动验证码**
   - 滑动滑块到正确位置
   - 观察滑动是否流畅

3. **查看控制台日志**
   - 在 HBuilderX 的控制台查看日志
   - 或使用 `adb logcat` 查看 Android 日志

---

## 📊 预期结果

### ✅ 成功的标志

**控制台日志**:
```
=== 获取验证码 ===
获取验证码成功

=== AES 加密 ===
AES 加密成功 (Android): {
  原文长度: 15,
  密钥长度: 16,
  结果长度: 24
}

=== 校验验证码 ===
校验验证码请求参数: {
  captchaType: "blockPuzzle",
  pointJson: "xxxxx==",  // Base64 加密数据
  token: "abc123..."
}

校验验证码响应: {
  repCode: "0000",  // ✅ 成功！
  repMsg: "success",
  repData: {
    captchaVerification: "xxx"
  }
}

=== 登录 ===
登录成功！
```

**功能表现**:
- ✅ 验证码图片正常显示
- ✅ 滑动流畅
- ✅ 验证成功
- ✅ 自动登录
- ✅ 跳转到首页

---

### ❌ 失败的标志

**场景 1: 加密失败**

```
AES 加密失败 (Android): xxx

校验验证码响应: {
  repCode: "0001",
  repMsg: "Illegal base64 character 7b"
}
```

**原因**: 加密代码有问题，返回了明文

**解决**: 检查 `aes.uts` 的实现

---

**场景 2: 后端未重启**

```
AES 加密成功 (Android): { ... }

校验验证码响应: {
  repCode: "0001",
  repMsg: "验证失败"
}
```

**原因**: 后端仍然期望明文数据（`aes-status: false`）

**解决**: 重启后端服务

---

**场景 3: 平台不支持**

```
当前平台暂不支持原生 AES 加密，请使用 Android 或 iOS 平台

校验验证码响应: {
  repCode: "0001",
  repMsg: "Illegal base64 character 7b"
}
```

**原因**: 运行在 H5 或其他不支持的平台

**解决**: 运行到 Android 平台

---

## 🔍 详细测试步骤

### 1. 验证后端配置

**检查配置文件**: `shengyu-server/src/main/resources/application.yaml`

```yaml
aj:
  captcha:
    # ... 其他配置 ...
    # 确保没有 aes-status: false
```

**查看启动日志**:
```
# 搜索日志中的 captcha 配置
# 确认 aes-status 为 true 或未配置（默认 true）
```

---

### 2. 验证 App 端代码

**检查文件**: `shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts`

**关键代码**:
```typescript
// #ifdef APP-ANDROID
import Cipher from 'javax.crypto.Cipher';
import SecretKeySpec from 'javax.crypto.spec.SecretKeySpec';
import Base64 from 'android.util.Base64';

function aesEncryptAndroid(word: string, keyWord: string): string {
  // ... 加密实现 ...
}
// #endif
```

**确认**:
- ✅ 有 `#ifdef APP-ANDROID` 条件编译
- ✅ 导入了正确的 Android 类
- ✅ 实现了 `aesEncryptAndroid` 函数

---

### 3. 测试加密功能

**方法 A: 使用 App 测试**

1. 运行 App 到 Android 设备
2. 打开登录页面
3. 滑动验证码
4. 查看控制台日志

**方法 B: 使用 Postman 测试**

```bash
# 1. 获取验证码
POST http://localhost:48080/admin-api/system/captcha/get
Content-Type: application/json

{
  "captchaType": "blockPuzzle"
}

# 响应：
{
  "repCode": "0000",
  "repData": {
    "token": "abc123...",
    "secretKey": "XwKsGlMcdPMEhR1B"
  }
}

# 2. 手动加密测试数据
# 使用在线 AES 加密工具：https://tool.oschina.net/encrypt
# 算法：AES
# 模式：ECB
# 填充：PKCS5Padding
# 密钥：XwKsGlMcdPMEhR1B
# 明文：{"x":100,"y":5}
# 结果：xxxxx==（Base64）

# 3. 校验验证码
POST http://localhost:48080/admin-api/system/captcha/check
Content-Type: application/json

{
  "captchaType": "blockPuzzle",
  "pointJson": "xxxxx==",  // 使用加密后的数据
  "token": "abc123..."
}

# 预期响应：
{
  "repCode": "0000",
  "repMsg": "success"
}
```

---

### 4. 对比 Web 端

**测试 Web 端**:

1. 打开 Web 端登录页面
2. 滑动验证码
3. 确认验证成功

**对比**:
- ✅ Web 端和 App 端都能验证成功
- ✅ 后端配置相同
- ✅ 加密参数相同

---

## 🛠️ 问题排查

### 问题 1: 编译错误

**错误信息**:
```
Cannot find symbol: Cipher
Cannot find symbol: SecretKeySpec
```

**原因**: UTS 语法错误或导入错误

**解决**:
1. 检查 import 语句
2. 确认使用了条件编译 `#ifdef APP-ANDROID`
3. 清理项目并重新编译

---

### 问题 2: 运行时错误

**错误信息**:
```
AES 加密失败 (Android): xxx
```

**原因**: 加密代码执行失败

**解决**:
1. 查看完整的错误信息
2. 检查密钥长度（必须是 16 字节）
3. 检查数据格式

---

### 问题 3: 验证失败

**错误信息**:
```
repCode: "0001"
repMsg: "验证失败"
```

**可能原因**:
1. 滑动位置不准确
2. Token 过期
3. 加密数据格式错误

**解决**:
1. 多试几次，确保滑动到正确位置
2. 刷新验证码重新获取
3. 检查加密输出是否为 Base64 格式

---

### 问题 4: 平台不支持

**错误信息**:
```
当前平台暂不支持原生 AES 加密
```

**原因**: 运行在不支持的平台（H5、小程序等）

**解决**: 运行到 Android 平台

---

## 📋 测试检查清单

### 后端检查

- [ ] 后端配置已恢复（移除 `aes-status: false`）
- [ ] 后端服务已重启
- [ ] 启动日志无错误
- [ ] 验证码接口可访问

### App 端检查

- [ ] 代码已更新到最新版本
- [ ] 项目已清理并重新编译
- [ ] 运行到 Android 平台
- [ ] 控制台无编译错误

### 功能检查

- [ ] 验证码图片正常显示
- [ ] 滑块可以流畅滑动
- [ ] 控制台显示 "AES 加密成功"
- [ ] 控制台显示 `repCode: "0000"`
- [ ] 验证成功后可以登录

### Web 端检查

- [ ] Web 端验证码功能正常
- [ ] Web 端登录功能正常
- [ ] 与 App 端行为一致

---

## 🎯 成功标准

### 必须满足

1. ✅ App 端验证码验证成功（`repCode: "0000"`）
2. ✅ Web 端验证码验证成功
3. ✅ 后端配置未修改（加密开启）
4. ✅ 控制台显示 "AES 加密成功"

### 可选满足

1. ✅ iOS 平台也能正常工作（待实现）
2. ✅ 加密性能良好（< 100ms）
3. ✅ 错误处理完善

---

## 📝 测试报告模板

```markdown
## 测试报告

**测试日期**: 2026-01-27  
**测试人员**: xxx  
**测试平台**: Android  

### 测试结果

- [ ] 后端服务正常启动
- [ ] App 编译成功
- [ ] 验证码图片显示正常
- [ ] AES 加密成功
- [ ] 验证码校验成功（repCode: "0000"）
- [ ] 登录功能正常
- [ ] Web 端功能正常

### 问题记录

1. 问题描述：xxx
   - 错误信息：xxx
   - 解决方案：xxx

### 结论

- [ ] 测试通过 ✅
- [ ] 测试失败 ❌（原因：xxx）
```

---

## 🆘 需要帮助？

### 查看文档

- `App端AES加密实现说明.md` - 详细的实现说明
- `验证码AES加密问题-最终解决方案.md` - 原始问题分析

### 查看日志

**Android 日志**:
```bash
# 使用 adb 查看日志
adb logcat | grep -i "aes\|captcha\|encrypt"
```

**HBuilderX 控制台**:
- 查看 "运行" 面板的日志输出

### 调试技巧

1. **添加更多日志**:
```typescript
console.log('加密前:', word)
console.log('密钥:', keyWord)
console.log('加密后:', result)
```

2. **使用在线工具验证**:
- [AES 在线加密](https://tool.oschina.net/encrypt)
- 对比在线工具和 App 的加密结果

3. **对比 Web 端**:
- 查看 Web 端的加密结果
- 确保 App 端和 Web 端结果一致

---

**更新时间**: 2026-01-27  
**版本**: v1.0.0  
**状态**: 📝 测试指南已完成  

**下一步**: 开始测试！🚀
