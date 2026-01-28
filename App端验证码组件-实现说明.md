# App端验证码组件实现说明

## 一、已完成的工作

### 1. 核心组件创建

#### 1.1 主验证码组件 (verify.uvue)
- **位置**: `shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/verify.uvue`
- **功能**: 
  - 根据 `captchaType` 自动切换滑块验证码和点选验证码
  - 支持弹窗模式 (`pop`) 和固定模式 (`fixed`)
  - 统一管理验证码的显示和隐藏
  - 提供 `show()` 和 `refresh()` 方法供外部调用

#### 1.2 AES加密工具 (aes.uts)
- **位置**: `shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts`
- **功能**:
  - UUID生成和存储
  - AES加密接口（待实现真正的加密）
  - 提供 `initUUID()` 和 `getUUID()` 方法

### 2. 现有滑块验证码组件
- **位置**: `shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/slider-captcha.uvue`
- **状态**: 已实现基本功能，需要重构以适配新架构

## 二、待完成的工作

### 1. 重构滑块验证码组件
**文件**: `shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/verify-slider.uvue`

**需要实现的功能**:
```typescript
// 1. 获取验证码图片
getPictrue() {
  const data = {
    captchaType: this.captchaType,
    clientUid: getUUID('slider'),
    ts: Date.now()
  }
  // 调用 /system/captcha/get 接口
}

// 2. 处理触摸事件
handleTouchStart(e) {
  // 记录开始时间和位置
}

handleTouchMove(e) {
  // 计算滑动距离，更新UI
}

handleTouchEnd(e) {
  // 计算最终位置，提交验证
  // 调用 /system/captcha/check 接口
}

// 3. 坐标转换
// 将实际滑动距离转换为标准尺寸（310x155）
moveLeftDistance = moveLeftDistance * 310 / parseInt(this.imgSize.width)
```

### 2. 创建点选验证码组件
**文件**: `shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/verify-point.uvue`

**需要实现的功能**:
```typescript
// 1. 获取验证码
getPictrue() {
  const data = {
    captchaType: this.captchaType,
    clientUid: getUUID('point'),
    ts: Date.now()
  }
  // 获取背景图和文字列表
}

// 2. 处理点击事件
canvasClick(e) {
  // 获取点击坐标
  // 记录到数组
  // 达到要求数量后提交验证
}

// 3. 坐标转换
pointTransfrom(pointArr, imgSize) {
  return pointArr.map(p => ({
    x: Math.round(310 * p.x / parseInt(imgSize.width)),
    y: Math.round(155 * p.y / parseInt(imgSize.height))
  }))
}
```

### 3. 实现真正的AES加密
**文件**: `shengyu-ui/shengyu-ui-admin-uniappx/components/captcha/utils/aes.uts`

**当前状态**: 临时实现，直接返回原文
**需要**: 引入加密库或使用原生加密API

**参考实现**:
```typescript
// 需要引入 crypto-js 或类似库
export function aesEncrypt(word: string, keyStr: string): string {
  const key = CryptoJS.enc.Utf8.parse(keyStr)
  const srcs = CryptoJS.enc.Utf8.parse(word)
  
  const encrypted = CryptoJS.AES.encrypt(srcs, key, {
    mode: CryptoJS.mode.ECB,
    padding: CryptoJS.pad.Pkcs7
  })
  
  return encrypted.toString()
}
```

### 4. 更新登录页面集成
**文件**: `shengyu-ui/shengyu-ui-admin-uniappx/pages/login/login.uvue`

**需要修改**:
```vue
<template>
  <!-- 账号登录 -->
  <view v-if="loginType === 'account'">
    <!-- 使用新的验证码组件 -->
    <verify
      v-if="captchaEnable === 'true'"
      ref="verifyRef"
      :captchaType="'blockPuzzle'"
      :mode="'fixed'"
      @success="handleCaptchaSuccess"
    />
  </view>
</template>

<script>
// 导入新组件
import verify from '@/components/captcha/verify.uvue'

// 处理验证成功
function handleCaptchaSuccess(e) {
  captchaVerification.value = e.captchaVerification
}
</script>
```

## 三、服务端接口

### 1. 获取验证码
**接口**: `POST /system/captcha/get`

**请求参数**:
```json
{
  "captchaType": "blockPuzzle",  // 或 "clickWord"
  "clientUid": "slider-uuid",
  "ts": 1234567890
}
```

**响应数据**:
```json
{
  "repCode": "0000",
  "repData": {
    "originalImageBase64": "...",  // 背景图
    "jigsawImageBase64": "...",    // 滑块图（仅滑块验证码）
    "token": "...",
    "secretKey": "...",
    "wordList": ["文", "字"]       // 文字列表（仅点选验证码）
  }
}
```

### 2. 校验验证码
**接口**: `POST /system/captcha/check`

**请求参数**:
```json
{
  "captchaType": "blockPuzzle",
  "pointJson": "加密后的坐标JSON",
  "token": "..."
}
```

**响应数据**:
```json
{
  "repCode": "0000",
  "repData": {
    "captchaVerification": "验证凭证"
  }
}
```

## 四、关键技术点

### 1. 坐标转换
不同屏幕尺寸需要将坐标转换为标准尺寸（310x155）:
```typescript
// 滑块验证码
const moveLeftDistance = parseInt(this.moveBlockLeft) * 310 / parseInt(this.imgSize.width)

// 点选验证码
const transformedPoints = checkPosArr.map(p => ({
  x: Math.round(310 * p.x / parseInt(imgSize.width)),
  y: Math.round(155 * p.y / parseInt(imgSize.height))
}))
```

### 2. UUID持久化
使用 `uni.setStorageSync` 保存UUID，避免频繁生成:
```typescript
initUUID('slider')  // 初始化滑块UUID
initUUID('point')   // 初始化点选UUID
```

### 3. 触摸事件处理
```typescript
// 获取元素位置
uni.createSelectorQuery().in(this)
  .select('#element')
  .boundingClientRect(data => {
    const left = Math.ceil(data.left)
    const top = Math.ceil(data.top)
    // 计算相对坐标
  }).exec()
```

### 4. 验证流程
1. 组件加载时调用 `getPictrue()` 获取验证码图片
2. 用户操作（滑动/点击）
3. 计算坐标并转换为标准尺寸
4. 使用 `secretKey` 加密坐标数据
5. 调用 `check` 接口验证
6. 根据结果显示成功/失败提示
7. 成功后触发 `success` 事件，传递 `captchaVerification`

## 五、测试要点

### 功能测试
- [ ] 滑块验证码正常显示和拖动
- [ ] 点选验证码正常显示和点击
- [ ] 验证成功/失败提示正确
- [ ] 刷新功能正常
- [ ] 弹窗模式和固定模式切换正常

### 兼容性测试
- [ ] Android设备测试
- [ ] iOS设备测试
- [ ] 不同屏幕尺寸适配
- [ ] 触摸事件响应正常

### 安全性测试
- [ ] AES加密正常工作
- [ ] Token机制正常
- [ ] 防止重放攻击

## 六、下一步计划

1. **立即执行**:
   - 重构 `verify-slider.uvue` 组件
   - 创建 `verify-point.uvue` 组件
   - 实现真正的AES加密

2. **后续优化**:
   - 添加错误处理和重试机制
   - 优化用户体验（动画效果）
   - 添加更多配置选项
   - 性能优化

## 七、参考资料

- UniApp验证码文档: https://ajcaptcha.beliefteam.cn/captcha-doc/captchaDoc/uni-app.html
- 服务端接口: `CaptchaController.java`
- 示例代码: `shengyu-ui/captcha-dev/view/uni-app`
- 实现方案: `App端验证码完整实现方案.md`
