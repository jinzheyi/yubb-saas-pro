# App端验证码完整实现方案

## 一、概述

基于AJ-Captcha验证码库，在UniApp X中使用UTS语言实现完整的验证码功能，包括滑块验证码（blockPuzzle）和点选验证码（clickWord）。

## 二、技术架构

### 2.1 核心组件结构
```
components/captcha/
├── verify.uvue              # 主验证码组件（分发器）
├── verify-slider.uvue       # 滑块验证码组件
├── verify-point.uvue        # 点选验证码组件
└── utils/
    ├── aes.uts             # AES加密工具
    └── request.uts         # 网络请求工具
```

### 2.2 服务端接口
- **获取验证码**: `POST /system/captcha/get`
- **校验验证码**: `POST /system/captcha/check`

## 三、详细实现步骤

### 3.1 主验证码组件 (verify.uvue)

**功能**：
- 根据captchaType切换不同的验证码类型
- 支持弹窗模式(pop)和固定模式(fixed)
- 统一管理验证码的显示和隐藏

**关键代码结构**：
```typescript
<template>
  <view :class="mode=='pop'?'mask':''" v-show="showBox">
    <view :class="mode=='pop'?'verifybox':''">
      <!-- 标题栏 -->
      <view class="verifybox-top" v-if="mode=='pop'">
        请完成安全验证
        <text class="verifybox-close" @click="clickShow = false">×</text>
      </view>
      
      <!-- 验证码容器 -->
      <view class="verifybox-bottom">
        <!-- 滑块验证码 -->
        <view v-if="componentType=='VerifySlide'">
          <VerifySlide 
            @success="success"
            :captchaType="captchaType"
            :imgSize="imgSize"
            ref="instance"
          />
        </view>
        
        <!-- 点选验证码 -->
        <view v-if="componentType=='VerifyPoints'">
          <VerifyPoint 
            :captchaType="captchaType"
            :imgSize="imgSize"
            ref="instance"
          />
        </view>
      </view>
    </view>
  </view>
</template>

<script>
export default {
  props: {
    captchaType: String,  // 'blockPuzzle' 或 'clickWord'
    mode: {
      type: String,
      default: 'pop'  // 'pop' 或 'fixed'
    },
    imgSize: {
      type: Object,
      default: () => ({
        width: '310px',
        height: '155px'
      })
    }
  },
  
  watch: {
    captchaType: {
      immediate: true,
      handler(type) {
        if (type === 'blockPuzzle') {
          this.componentType = 'VerifySlide'
        } else if (type === 'clickWord') {
          this.componentType = 'VerifyPoints'
        }
      }
    }
  },
  
  methods: {
    success(e) {
      this.$emit('success', e)
    },
    
    show() {
      if (this.mode === 'pop') {
        this.clickShow = true
      }
    },
    
    refresh() {
      if (this.instance.refresh) {
        this.instance.refresh()
      }
    }
  }
}
</script>
```

### 3.2 滑块验证码组件 (verify-slider.uvue)

**功能**：
- 显示背景图和滑块图
- 处理触摸拖动事件
- 计算滑动距离并提交验证
- 显示验证结果

**关键实现**：

1. **获取验证码图片**：
```typescript
getPictrue() {
  const data = {
    captchaType: this.captchaType,
    clientUid: uni.getStorageSync('slider'),
    ts: Date.now()
  }
  
  request({
    url: '/system/captcha/get',
    method: 'POST',
    data
  }).then(res => {
    if (res.data.repCode === '0000') {
      this.backImgBase = res.data.repData.originalImageBase64
      this.blockBackImgBase = res.data.repData.jigsawImageBase64
      this.backToken = res.data.repData.token
      this.secretKey = res.data.repData.secretKey
    }
  })
}
```

2. **处理拖动事件**：
```typescript
// 开始拖动
start(e) {
  this.startMoveTime = Date.now()
  if (!this.isEnd) {
    this.status = true
    this.moveBlockBackgroundColor = '#337ab7'
  }
}

// 拖动中
move(e) {
  if (this.status && !this.isEnd) {
    const x = e.touches[0].pageX
    const moveBlockLeft = x - this.barAreaLeft
    
    // 限制拖动范围
    if (moveBlockLeft >= this.barAreaWidth - 20) {
      moveBlockLeft = this.barAreaWidth - 20
    }
    if (moveBlockLeft <= 0) {
      moveBlockLeft = 0
    }
    
    this.moveBlockLeft = moveBlockLeft + 'px'
    this.leftBarWidth = moveBlockLeft + 'px'
  }
}

// 结束拖动
end() {
  this.endMovetime = Date.now()
  
  if (this.status && !this.isEnd) {
    // 计算移动距离（需要按比例转换）
    let moveLeftDistance = parseInt(this.moveBlockLeft)
    moveLeftDistance = moveLeftDistance * 310 / parseInt(this.imgSize.width)
    
    // 提交验证
    const data = {
      captchaType: this.captchaType,
      pointJson: this.secretKey ? 
        aesEncrypt(JSON.stringify({x: moveLeftDistance, y: 5.0}), this.secretKey) :
        JSON.stringify({x: moveLeftDistance, y: 5.0}),
      token: this.backToken
    }
    
    request({
      url: '/system/captcha/check',
      method: 'POST',
      data
    }).then(res => {
      if (res.data.repCode === '0000') {
        // 验证成功
        this.showSuccess()
      } else {
        // 验证失败
        this.showError()
      }
    })
  }
  
  this.status = false
}
```

### 3.3 点选验证码组件 (verify-point.uvue)

**功能**：
- 显示包含文字的背景图
- 处理用户点击事件
- 记录点击坐标
- 提交验证

**关键实现**：

1. **获取验证码**：
```typescript
getPictrue() {
  const data = {
    captchaType: this.captchaType,
    clientUid: uni.getStorageSync('point'),
    ts: Date.now()
  }
  
  request({
    url: '/system/captcha/get',
    method: 'POST',
    data
  }).then(res => {
    if (res.data.repCode === '0000') {
      this.pointBackImgBase = res.data.repData.originalImageBase64
      this.backToken = res.data.repData.token
      this.secretKey = res.data.repData.secretKey
      this.poinTextList = res.data.repData.wordList
      this.text = '请依次点击【' + this.poinTextList.join(',') + '】'
    }
  })
}
```

2. **处理点击事件**：
```typescript
canvasClick(e) {
  // 获取图片位置
  uni.createSelectorQuery().in(this)
    .select('#image')
    .boundingClientRect(data => {
      this.imgLeft = Math.ceil(data.left)
      this.imgTop = Math.ceil(data.top)
      
      // 计算点击坐标
      const position = {
        x: Math.ceil(e.detail.x) - this.imgLeft,
        y: Math.ceil(e.detail.y) - this.imgTop
      }
      
      this.checkPosArr.push(position)
      this.tempPoints.push(position)
      this.num++
      
      // 如果点击次数达到要求，提交验证
      if (this.num === this.checkNum) {
        this.submitVerify()
      }
    }).exec()
}

submitVerify() {
  // 坐标转换（适配不同屏幕尺寸）
  const transformedPoints = this.checkPosArr.map(p => ({
    x: Math.round(310 * p.x / parseInt(this.imgSize.width)),
    y: Math.round(155 * p.y / parseInt(this.imgSize.height))
  }))
  
  const data = {
    captchaType: this.captchaType,
    pointJson: this.secretKey ?
      aesEncrypt(JSON.stringify(transformedPoints), this.secretKey) :
      JSON.stringify(transformedPoints),
    token: this.backToken
  }
  
  request({
    url: '/system/captcha/check',
    method: 'POST',
    data
  }).then(res => {
    if (res.data.repCode === '0000') {
      this.showSuccess()
    } else {
      this.showError()
    }
  })
}
```

### 3.4 AES加密工具 (aes.uts)

```typescript
import CryptoJS from 'crypto-js'

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

### 3.5 UUID生成

```typescript
function generateUUID(): string {
  const s = []
  const hexDigits = '0123456789abcdef'
  
  for (let i = 0; i < 36; i++) {
    s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1)
  }
  
  s[14] = '4'
  s[19] = hexDigits.substr((s[19] & 0x3) | 0x8, 1)
  s[8] = s[13] = s[18] = s[23] = '-'
  
  return s.join('')
}

// 初始化UUID
if (!uni.getStorageSync('slider')) {
  uni.setStorageSync('slider', 'slider-' + generateUUID())
}
if (!uni.getStorageSync('point')) {
  uni.setStorageSync('point', 'point-' + generateUUID())
}
```

## 四、集成到登录页面

### 4.1 在login.uvue中使用

```typescript
<template>
  <view>
    <!-- 账号登录表单 -->
    <view v-if="loginType === 'account'">
      <!-- ... 其他表单字段 ... -->
      
      <!-- 滑块验证码 -->
      <verify
        v-if="captchaEnable === 'true'"
        ref="verify"
        :captchaType="'blockPuzzle'"
        :mode="'fixed'"
        @success="handleCaptchaSuccess"
      />
      
      <button @click="handleLogin">登录</button>
    </view>
  </view>
</template>

<script>
export default {
  data() {
    return {
      captchaEnable: 'true',
      captchaVerification: ''
    }
  },
  
  methods: {
    handleCaptchaSuccess(e) {
      this.captchaVerification = e.captchaVerification
    },
    
    handleLogin() {
      if (this.captchaEnable === 'true' && !this.captchaVerification) {
        uni.showToast({
          title: '请完成验证码验证',
          icon: 'none'
        })
        return
      }
      
      // 提交登录请求
      const data = {
        username: this.username,
        password: this.password,
        captchaVerification: this.captchaVerification
      }
      
      // ... 登录逻辑 ...
    }
  }
}
</script>
```

## 五、样式设计

### 5.1 核心样式

```css
/* 遮罩层 */
.mask {
  position: fixed;
  top: 0;
  left: 0;
  z-index: 1001;
  width: 100%;
  height: 100vh;
  background: rgba(0,0,0,.3);
}

/* 验证码容器 */
.verifybox {
  position: relative;
  box-sizing: border-box;
  border-radius: 2px;
  border: 1px solid #e4e7eb;
  background-color: #fff;
  box-shadow: 0 0 10px rgba(0,0,0,.3);
  left: 50%;
  top: 50%;
  transform: translate(-50%,-50%);
}

/* 滑动条 */
.verify-bar-area {
  position: relative;
  background: #FFFFFF;
  text-align: center;
  border: 1px solid #ddd;
  border-radius: 4px;
}

/* 滑块 */
.verify-move-block {
  position: absolute;
  top: 0;
  left: 0;
  background: #fff;
  cursor: pointer;
  box-shadow: 0 0 2px #888888;
  border-radius: 1px;
}

/* 点选标记 */
.point-area {
  background-color: #1abd6c;
  color: #fff;
  z-index: 9999;
  width: 20px;
  height: 20px;
  text-align: center;
  line-height: 20px;
  border-radius: 50%;
  position: absolute;
}
```

## 六、测试要点

### 6.1 功能测试
- [ ] 滑块验证码正常显示
- [ ] 滑块可以正常拖动
- [ ] 验证成功/失败提示正确
- [ ] 点选验证码正常显示
- [ ] 点击坐标记录正确
- [ ] 刷新功能正常
- [ ] 弹窗模式和固定模式切换正常

### 6.2 兼容性测试
- [ ] Android设备测试
- [ ] iOS设备测试
- [ ] 不同屏幕尺寸适配
- [ ] 触摸事件响应正常

### 6.3 安全性测试
- [ ] AES加密正常工作
- [ ] Token机制正常
- [ ] 防止重放攻击

## 七、注意事项

1. **坐标转换**：不同屏幕尺寸需要将坐标转换为标准尺寸（310x155）
2. **UUID持久化**：使用uni.setStorageSync保存UUID，避免频繁生成
3. **错误处理**：网络请求失败时要有友好提示
4. **性能优化**：图片使用base64格式，注意内存占用
5. **用户体验**：验证失败后自动刷新，成功后自动关闭

## 八、参考资料

- UniApp验证码文档：https://ajcaptcha.beliefteam.cn/captcha-doc/captchaDoc/uni-app.html
- 服务端接口：`CaptchaController.java`
- 示例代码：`shengyu-ui/captcha-dev/view/uni-app`
