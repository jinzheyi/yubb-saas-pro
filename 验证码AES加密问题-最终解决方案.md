# 验证码 AES 加密问题 - 最终解决方案

## 问题描述

**错误信息**: `{"repCode": "0001","repMsg": "Illegal base64 character 7b","repData": null,"success": false}`

**原因**: 
- 后端期望接收 Base64 编码的 AES 加密数据
- App 端发送的是 JSON 字符串 `{"x":100,"y":5}`
- `7b` 是 `{` 的 ASCII 码，不是合法的 Base64 字符

---

## 为什么不能直接安装 crypto-js？

1. **UniApp X 不支持 npm 包**: UniApp X 使用 UTS 语言，不能直接使用 npm 包
2. **crypto-js 是 JS 库**: 需要转换为 UTS 语法，工作量巨大
3. **性能问题**: JS 转 UTS 可能存在性能问题

---

## 解决方案对比

### 方案一：后端支持不加密（推荐 ⭐⭐⭐⭐⭐）

**优点**:
- ✅ 实现简单，只需修改后端配置
- ✅ 无需修改 App 端代码
- ✅ 适合开发环境快速调试

**缺点**:
- ❌ 安全性降低（仅开发环境可用）

**实现步骤**:

1. 修改后端配置 `application-dev.yml`:
```yaml
aj:
  captcha:
    aes-status: false  # 关闭 AES 加密
```

2. 重启后端服务

3. App 端无需修改，直接发送明文

**适用场景**: 开发环境、测试环境

---

### 方案二：使用原生加密插件（推荐 ⭐⭐⭐⭐）

**优点**:
- ✅ 真正的 AES 加密
- ✅ 性能好
- ✅ 适合生产环境

**缺点**:
- ❌ 需要购买或开发原生插件
- ❌ 配置复杂

**实现步骤**:

1. 在 UniApp 插件市场搜索 "AES 加密"
2. 选择支持 UniApp X 的插件
3. 安装并配置插件
4. 修改 `aes.uts`:

```typescript
import { AES } from '@/uni_modules/xxx-aes'

export function aesEncrypt(word: string, keyWord: string): string {
  return AES.encrypt(word, keyWord, {
    mode: 'ECB',
    padding: 'Pkcs7'
  })
}
```

**适用场景**: 生产环境

---

### 方案三：纯 UTS 实现 AES（不推荐 ⭐⭐）

**优点**:
- ✅ 无需依赖第三方插件

**缺点**:
- ❌ 实现复杂，工作量大
- ❌ 需要将 crypto-js 转换为 UTS
- ❌ 可能存在兼容性问题

**实现难度**: 非常高，不推荐

---

## 推荐方案：后端支持不加密

### 步骤 1: 修改后端配置

找到后端配置文件，通常在以下位置之一：

- `src/main/resources/application.yml`
- `src/main/resources/application-dev.yml`
- `src/main/resources/config/application.yml`

添加或修改以下配置：

```yaml
aj:
  captcha:
    # 验证码类型
    type: default
    # 滑动验证，底图路径
    jigsaw: classpath:images/jigsaw
    # 滑动验证，滑块路径
    pic-click: classpath:images/pic-click
    # 水印
    water-mark: false
    # 请求频率限制
    req-frequency-limit-enable: false
    # ✅ 关闭 AES 加密（重要！）
    aes-status: false
```

### 步骤 2: 验证配置

重启后端服务后，使用 Postman 测试：

```bash
POST http://localhost:48080/admin-api/system/captcha/check
Content-Type: application/json

{
  "captchaType": "blockPuzzle",
  "pointJson": "{\"x\":100,\"y\":5}",  // 明文 JSON
  "token": "xxx"
}
```

**预期响应**:
```json
{
  "repCode": "0000",
  "repMsg": "success",
  "repData": {
    "captchaVerification": "xxx"
  }
}
```

如果返回 `repCode: "0000"`，说明配置成功！

### 步骤 3: App 端测试

运行 App，滑动验证码，查看控制台日志：

```
校验验证码请求参数: {
  captchaType: "blockPuzzle",
  pointJson: "{\"x\":150,\"y\":5}",  // 明文
  token: "xxx"
}

校验验证码响应: {
  repCode: "0000",  // ✅ 成功
  repMsg: "success"
}
```

---

## 如果后端无法修改配置

### 方案 A: 修改后端代码

编辑 `CaptchaServiceImpl.java` 或类似文件：

```java
@Override
public ResponseModel check(CaptchaVO captchaVO) {
    String pointJson = captchaVO.getPointJson();
    String secretKey = captchaVO.getSecretKey();
    
    // 判断是否需要解密
    if (StringUtils.isNotBlank(secretKey)) {
        try {
            // 尝试解密
            pointJson = AESUtil.aesDecrypt(pointJson, secretKey);
        } catch (Exception e) {
            // 解密失败，可能是明文，直接使用
            logger.warn("解密失败，使用明文: " + e.getMessage());
            // 不抛出异常，继续使用原始 pointJson
        }
    }
    
    // 继续验证逻辑...
    return verify(pointJson, token);
}
```

### 方案 B: 使用 WebView

如果实在无法解决，可以使用 WebView 加载 H5 验证码：

```vue
<template>
  <web-view :src="captchaUrl"></web-view>
</template>

<script>
const captchaUrl = ref('https://your-domain.com/captcha.html')
</script>
```

---

## 不同环境的配置建议

### 开发环境
```yaml
# application-dev.yml
aj:
  captcha:
    aes-status: false  # ✅ 关闭加密，方便调试
```

### 测试环境
```yaml
# application-test.yml
aj:
  captcha:
    aes-status: false  # ✅ 关闭加密，方便测试
```

### 生产环境
```yaml
# application-prod.yml
aj:
  captcha:
    aes-status: true  # ✅ 开启加密，保证安全
```

然后 App 端使用原生加密插件。

---

## 常见问题

### Q1: 关闭加密后安全吗？

A: 
- **开发环境**: 可以关闭，方便调试
- **生产环境**: 必须开启，配合 HTTPS 使用
- **建议**: 开发环境关闭，生产环境使用原生插件

### Q2: 如何判断后端是否支持不加密？

A: 
1. 发送明文数据到 `/captcha/check` 接口
2. 如果返回 `repCode: "0000"` 说明支持
3. 如果返回加密错误说明不支持

### Q3: 原生加密插件推荐？

A: 
- 搜索 UniApp 插件市场 "AES 加密"
- 选择支持 UniApp X 的插件
- 确保支持 ECB 模式和 Pkcs7 填充
- 查看评价和更新时间

### Q4: 为什么不能用 Base64 代替 AES？

A: 
- Base64 是编码，不是加密
- 后端期望的是 AES 加密后再 Base64 编码
- 直接 Base64 编码会导致 "Illegal base64 character" 错误

---

## 验证配置是否成功

### 成功的标志

1. **控制台日志**:
```
校验验证码响应: {
  repCode: "0000",  // ✅
  repMsg: "success"
}
```

2. **验证码功能**:
- ✅ 滑动流畅
- ✅ 验证成功
- ✅ 自动登录

### 失败的标志

1. **控制台日志**:
```
校验验证码响应: {
  repCode: "0001",  // ❌
  repMsg: "Illegal base64 character 7b"
}
```

或

```
校验验证码响应: {
  repCode: "0001",  // ❌
  repMsg: "Input length must be multiple of 16..."
}
```

2. **验证码功能**:
- ❌ 验证总是失败
- ❌ 提示加密错误

---

## 总结

### 最佳实践

1. **开发环境**: 关闭后端 AES 加密（`aes-status: false`）
2. **生产环境**: 使用原生加密插件 + 开启后端加密
3. **安全性**: 生产环境必须使用 HTTPS + AES 加密

### 快速解决步骤

1. 修改后端配置 `aes-status: false`
2. 重启后端服务
3. 测试 App 验证码功能
4. 查看控制台日志确认成功

### 长期方案

1. 购买或开发原生 AES 加密插件
2. 集成到 App 端
3. 生产环境开启后端加密
4. 完整的安全方案：HTTPS + AES + Token

---

**更新时间**: 2026-01-27  
**版本**: v1.3.0  
**推荐方案**: 后端关闭 AES 加密（开发环境）
