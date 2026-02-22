# 二维码功能实现说明

## 当前实现

当前 `qrcode.uts` 提供了一个简化的二维码生成实现，用于演示功能流程。它使用 Canvas API 绘制一个模拟的二维码图案，但不是真正的可扫描二维码。

## 生产环境建议方案

### 方案1：后端生成二维码（推荐）

**优点**：
- 前端实现简单
- 二维码质量有保证
- 可以统一管理和缓存

**实现步骤**：

1. 后端添加二维码生成接口

```java
// AppImGroupController.java
@GetMapping("/invite/qrcode-image")
@Operation(summary = "获取群邀请二维码图片")
public void getInviteQRCodeImage(
        @RequestParam("code") String code,
        HttpServletResponse response) throws IOException {
    
    // 生成二维码
    String url = "https://app.shengyu.com/group/join?code=" + code;
    BufferedImage qrImage = QRCodeUtil.generateQRCode(url, 300, 300);
    
    // 输出图片
    response.setContentType("image/png");
    ImageIO.write(qrImage, "PNG", response.getOutputStream());
}
```

2. 前端直接使用图片

```typescript
// group-qrcode.uvue
const qrCodeImageUrl = computed(() => {
  return `${baseURL}/system/im/group/invite/qrcode-image?code=${inviteCode.value}`
})

// 模板中使用
<image :src="qrCodeImageUrl" class="qrcode-image" />
```

### 方案2：使用 JS 二维码库

**适用库**：
- qrcode.js
- qrcodejs2
- node-qrcode

**注意**：需要确认 uniappx 对这些库的兼容性

**实现示例**：

```typescript
import QRCode from 'qrcode'

async function generateQRCode() {
  try {
    const url = `https://app.shengyu.com/group/join?code=${inviteCode.value}`
    const dataUrl = await QRCode.toDataURL(url, {
      width: 200,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    })
    
    // 使用 dataUrl 显示二维码
    qrCodeDataUrl.value = dataUrl
  } catch (err) {
    console.error(err)
  }
}
```

### 方案3：原生插件

**优点**：
- 性能最好
- 功能最完整
- 可以自定义样式

**实现步骤**：

1. 开发或使用第三方原生插件
2. 在 manifest.json 中配置插件
3. 调用原生方法生成二维码

```typescript
// 调用原生插件
const qrCodePlugin = uni.requireNativePlugin('QRCodePlugin')

qrCodePlugin.generate({
  text: url,
  size: 200,
  success: (res) => {
    qrCodePath.value = res.path
  }
})
```

## 当前功能说明

### generateQRCode(options)

生成一个模拟的二维码图案到 Canvas。

**参数**：
- `canvasId`: Canvas 元素 ID
- `text`: 二维码内容（URL）
- `size`: 二维码大小（默认 200）
- `margin`: 边距（默认 10）
- `backgroundColor`: 背景色（默认白色）
- `foregroundColor`: 前景色（默认黑色）

**返回**：Promise<string> - 临时文件路径

### saveImageToAlbum(tempFilePath)

保存图片到相册。

**参数**：
- `tempFilePath`: 临时文件路径

**返回**：Promise<boolean>

**注意**：需要相册权限

### shareImage(tempFilePath, title)

分享图片。

**参数**：
- `tempFilePath`: 临时文件路径
- `title`: 分享标题

**返回**：Promise<boolean>

**注意**：不同平台的分享功能可能不同

## 权限配置

### Android

在 `manifest.json` 中添加：

```json
{
  "permissions": {
    "WRITE_EXTERNAL_STORAGE": {
      "desc": "保存二维码到相册"
    }
  }
}
```

### iOS

在 `manifest.json` 中添加：

```json
{
  "NSPhotoLibraryAddUsageDescription": "需要访问您的相册以保存二维码图片"
}
```

## 测试建议

1. **功能测试**
   - 生成二维码
   - 保存到相册
   - 分享功能
   - 权限处理

2. **兼容性测试**
   - Android 不同版本
   - iOS 不同版本
   - 不同屏幕尺寸

3. **性能测试**
   - 生成速度
   - 内存占用
   - 图片质量

## 后续优化

1. **个性化二维码**
   - 添加 Logo
   - 自定义颜色
   - 圆角样式

2. **批量生成**
   - 支持批量生成多个二维码
   - 导出为 ZIP

3. **统计分析**
   - 扫码次数统计
   - 来源分析
   - 转化率追踪

## 参考资料

- [ZXing GitHub](https://github.com/zxing/zxing)
- [qrcode.js](https://github.com/davidshimjs/qrcodejs)
- [node-qrcode](https://github.com/soldair/node-qrcode)
- [uni-app Canvas API](https://uniapp.dcloud.net.cn/api/canvas/createCanvasContext.html)
