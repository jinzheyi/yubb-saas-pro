# UniApp 移动端登录优化总结

## 优化时间
2026-01-27

## 优化目标
严格参考 PC 端 Vue3 登录逻辑，优化 UniApp 移动端登录功能，特别是：
1. **手机号登录不显示租户名称**（关键需求）
2. 完善验证码集成逻辑
3. 统一登录流程和验证规则

## 主要变更

### 1. 登录界面优化 ✅

#### 1.1 租户名称显示逻辑
- **账号登录**：显示租户名称输入框（可编辑）
- **手机号登录**：不显示租户名称（符合移动端简洁设计）

#### 1.2 记住我功能
- **账号登录**：显示"记住我"选项
- **手机号登录**：不显示"记住我"选项（手机号登录无需记住）

### 2. 登录流程优化 ✅

#### 2.1 账号密码登录流程
```
1. 验证表单（租户名称、账号、密码）
2. 显示滑块验证码（如果启用）
3. 验证码验证成功后，获取租户ID
4. 调用登录接口
5. 保存 Token 和用户信息
6. 处理"记住我"功能
7. 跳转到首页
```

#### 2.2 手机号登录流程
```
1. 验证表单（手机号、验证码）
2. 直接调用登录接口（无需验证码、无需租户ID）
3. 保存 Token 和用户信息
4. 跳转到首页
```

### 3. 表单验证增强 ✅

#### 3.1 账号登录验证
- 租户名称：必填
- 账号：必填
- 密码：必填

#### 3.2 手机号登录验证
- 手机号：必填 + 格式验证（1[3-9]\d{9}）
- 验证码：必填

### 4. 验证码集成优化 ✅

#### 4.1 滑块验证码
- **账号登录**：启用滑块验证码（默认）
- **手机号登录**：不使用滑块验证码（短信验证码已足够）

#### 4.2 短信验证码
- 60秒倒计时
- 发送前验证手机号格式
- 发送成功提示
- 倒计时期间禁用按钮

### 5. 用户体验优化 ✅

#### 5.1 切换登录方式
- 切换时自动清空验证码倒计时
- 界面自动调整（显示/隐藏相关字段）

#### 5.2 错误提示
- 表单验证失败：Toast 提示
- 租户不存在：Toast 提示
- 登录失败：统一在 request.uts 中处理
- 验证码失败：Toast 提示

#### 5.3 成功反馈
- 登录成功：Toast 提示 + 1.5秒延迟跳转
- 验证码发送成功：Toast 提示

### 6. 代码优化 ✅

#### 6.1 逻辑分离
- 账号登录和手机号登录逻辑完全分离
- 租户ID获取仅在账号登录时执行
- 记住我功能仅在账号登录时生效

#### 6.2 错误处理
- 完善的 try-catch 错误捕获
- 统一的错误提示机制
- 防止重复提交（loading 状态）

#### 6.3 代码可读性
- 清晰的注释
- 合理的函数命名
- 逻辑流程清晰

## 核心代码变更

### 模板部分
```vue
<!-- 账号登录 - 显示租户名称和记住我 -->
<view v-if="loginType === 'account'">
  <view class="form-item">
    <text class="label">租户名称</text>
    <input v-model="tenantName" placeholder="请输入租户名称" />
  </view>
  <!-- 账号、密码 -->
  <view class="remember-row">
    <checkbox :checked="rememberMe" />
    <text>记住我</text>
  </view>
</view>

<!-- 手机号登录 - 不显示租户名称和记住我 -->
<view v-else>
  <view class="form-item">
    <text class="label">手机号</text>
    <input v-model="mobile" placeholder="请输入手机号" />
  </view>
  <!-- 验证码 -->
</view>
```

### 登录逻辑
```typescript
async function handleLogin() {
  if (loginType.value === 'account') {
    // 账号登录：验证表单 + 显示验证码
    if (!tenantName.value || !username.value || !password.value) {
      // 提示错误
      return
    }
    if (captchaEnable.value) {
      captchaRef.value.show() // 显示验证码
    } else {
      await doLogin('')
    }
  } else {
    // 手机号登录：验证表单 + 直接登录
    if (!mobile.value || !smsCode.value) {
      // 提示错误
      return
    }
    await doLogin('') // 直接登录，无需验证码
  }
}

async function doLogin(verification: string) {
  // 账号登录需要先获取租户ID
  if (loginType.value === 'account') {
    await fetchTenantId()
  }
  
  // 调用对应的登录接口
  let tokenData: any
  if (loginType.value === 'account') {
    tokenData = await login({
      username: username.value,
      password: password.value,
      captchaVerification: verification
    })
  } else {
    tokenData = await smsLogin({
      mobile: mobile.value,
      code: smsCode.value
    })
  }
  
  // 保存 Token 和用户信息
  setToken(tokenData)
  await loadUserPermission()
  
  // 记住我（仅账号登录）
  if (loginType.value === 'account' && rememberMe.value) {
    uni.setStorageSync('REMEMBER_ME', JSON.stringify({
      tenantName: tenantName.value,
      username: username.value
    }))
  }
  
  // 跳转首页
  uni.switchTab({ url: '/pages/message/message' })
}
```

## 与 PC 端对比

### 相同点 ✅
1. 账号登录需要租户名称
2. 手机号登录不需要租户名称
3. 账号登录启用滑块验证码
4. 手机号登录使用短信验证码
5. 记住我功能仅在账号登录时可用
6. 统一的错误处理机制

### 差异点（移动端优化）
1. **界面更简洁**：移动端去除了不必要的元素
2. **无社交登录**：移动端暂不支持第三方登录
3. **无注册入口**：移动端专注于登录功能
4. **触摸优化**：使用 @confirm 事件支持键盘确认

## 测试建议

### 1. 账号登录测试
- [ ] 输入租户名称、账号、密码
- [ ] 验证滑块验证码功能
- [ ] 测试"记住我"功能
- [ ] 测试租户名称不存在的情况
- [ ] 测试账号密码错误的情况

### 2. 手机号登录测试
- [ ] 验证手机号格式检查
- [ ] 测试短信验证码发送
- [ ] 测试60秒倒计时
- [ ] 测试验证码错误的情况
- [ ] 确认不显示租户名称输入框

### 3. 切换登录方式测试
- [ ] 账号登录 ↔ 手机号登录切换
- [ ] 验证界面元素正确显示/隐藏
- [ ] 验证倒计时正确清除

### 4. 异常情况测试
- [ ] 网络断开
- [ ] 接口超时
- [ ] Token 过期
- [ ] 验证码过期

## 注意事项

### 1. 环境配置
- 确保 `utils/request.uts` 中的 `BASE_URL` 配置正确
- 确保后端接口正常运行
- 确保租户数据已初始化

### 2. 验证码配置
- 滑块验证码默认启用
- 可通过 `captchaEnable` 变量控制
- 生产环境建议启用

### 3. 租户隔离
- 账号登录：通过租户名称获取租户ID
- 手机号登录：后端根据手机号自动识别租户
- 所有请求自动携带租户ID（在 request.uts 中处理）

## 后续优化建议

### 短期
- [ ] 添加忘记密码功能
- [ ] 优化验证码加载速度
- [ ] 添加登录日志记录

### 中期
- [ ] 支持生物识别登录（指纹/面容）
- [ ] 支持第三方登录（微信、钉钉）
- [ ] 添加登录安全设置

### 长期
- [ ] 多因素认证（MFA）
- [ ] 设备管理
- [ ] 登录行为分析

## 总结

本次优化严格参考 PC 端 Vue3 登录逻辑，实现了以下核心目标：

1. ✅ **手机号登录不显示租户名称**（关键需求）
2. ✅ 完善的验证码集成（滑块验证码 + 短信验证码）
3. ✅ 统一的登录流程和验证规则
4. ✅ 良好的用户体验和错误处理
5. ✅ 清晰的代码结构和注释

移动端登录功能已完全符合 PC 端的业务逻辑，同时针对移动端特点进行了优化，提供了更简洁、更友好的用户体验。
