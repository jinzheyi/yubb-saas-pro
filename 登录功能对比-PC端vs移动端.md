# 登录功能对比：PC 端 vs 移动端

## 概述
本文档对比 PC 端（Vue3）和移动端（UniApp X）的登录实现，确保两端逻辑一致。

## 功能对比表

### 账号密码登录

| 功能项 | PC 端 (Vue3) | 移动端 (UniApp X) | 状态 |
|--------|-------------|------------------|------|
| 租户名称输入 | ✅ 显示 | ✅ 显示 | ✅ 一致 |
| 账号输入 | ✅ 支持 | ✅ 支持 | ✅ 一致 |
| 密码输入 | ✅ 支持 | ✅ 支持 | ✅ 一致 |
| 记住我 | ✅ 支持 | ✅ 支持 | ✅ 一致 |
| 滑块验证码 | ✅ 启用 | ✅ 启用 | ✅ 一致 |
| 获取租户ID | ✅ 自动获取 | ✅ 自动获取 | ✅ 一致 |
| 忘记密码 | ✅ 显示链接 | ❌ 暂不支持 | ⚠️ 待开发 |

### 手机号登录

| 功能项 | PC 端 (Vue3) | 移动端 (UniApp X) | 状态 |
|--------|-------------|------------------|------|
| 租户名称输入 | ❌ 不显示 | ❌ 不显示 | ✅ 一致 |
| 手机号输入 | ✅ 支持 | ✅ 支持 | ✅ 一致 |
| 手机号格式验证 | ✅ 支持 | ✅ 支持 | ✅ 一致 |
| 短信验证码 | ✅ 支持 | ✅ 支持 | ✅ 一致 |
| 倒计时 | ✅ 60秒 | ✅ 60秒 | ✅ 一致 |
| 滑块验证码 | ❌ 不启用 | ❌ 不启用 | ✅ 一致 |
| 记住我 | ❌ 不显示 | ❌ 不显示 | ✅ 一致 |

### 其他功能

| 功能项 | PC 端 (Vue3) | 移动端 (UniApp X) | 状态 |
|--------|-------------|------------------|------|
| 二维码登录 | ✅ 支持 | ❌ 不支持 | ⚠️ 移动端不需要 |
| 社交登录 | ✅ 支持 | ❌ 不支持 | ⚠️ 待开发 |
| 注册入口 | ✅ 显示 | ❌ 不显示 | ⚠️ 移动端不需要 |
| 切换登录方式 | ✅ 支持 | ✅ 支持 | ✅ 一致 |

## 登录流程对比

### 账号密码登录流程

#### PC 端 (LoginForm.vue)
```
1. 用户输入租户名称、账号、密码
2. 点击登录按钮
3. 验证表单
4. 显示滑块验证码（如果启用）
5. 验证码验证成功
6. 获取租户ID（通过租户名称）
7. 调用登录接口
8. 保存 Token
9. 加载用户权限信息
10. 处理"记住我"
11. 跳转到首页
```

#### 移动端 (login.uvue)
```
1. 用户输入租户名称、账号、密码
2. 点击登录按钮
3. 验证表单
4. 显示滑块验证码（如果启用）
5. 验证码验证成功
6. 获取租户ID（通过租户名称）
7. 调用登录接口
8. 保存 Token
9. 加载用户权限信息
10. 处理"记住我"
11. 显示成功提示
12. 跳转到首页
```

**差异**：移动端增加了成功提示和延迟跳转，提升用户体验。

### 手机号登录流程

#### PC 端 (MobileForm.vue)
```
1. 用户输入手机号
2. 点击"获取验证码"
3. 发送短信验证码
4. 60秒倒计时
5. 用户输入验证码
6. 点击登录按钮
7. 验证表单
8. 调用登录接口（无需租户ID）
9. 保存 Token
10. 加载用户权限信息
11. 跳转到首页
```

#### 移动端 (login.uvue)
```
1. 用户输入手机号
2. 验证手机号格式
3. 点击"获取验证码"
4. 发送短信验证码
5. 60秒倒计时
6. 用户输入验证码
7. 点击登录按钮
8. 验证表单
9. 调用登录接口（无需租户ID）
10. 保存 Token
11. 加载用户权限信息
12. 显示成功提示
13. 跳转到首页
```

**差异**：移动端增加了手机号格式验证和成功提示。

## 代码结构对比

### PC 端 (Vue3)

#### LoginForm.vue（账号登录）
```vue
<template>
  <el-form>
    <!-- 租户名称 -->
    <el-form-item>
      <LoginFormTitle />
    </el-form-item>
    
    <!-- 账号 -->
    <el-form-item prop="username">
      <el-input v-model="loginForm.username" />
    </el-form-item>
    
    <!-- 密码 -->
    <el-form-item prop="password">
      <el-input v-model="loginForm.password" type="password" />
    </el-form-item>
    
    <!-- 记住我 -->
    <el-checkbox v-model="loginForm.rememberMe">记住我</el-checkbox>
    
    <!-- 登录按钮 -->
    <XButton @click="getCode()">登录</XButton>
    
    <!-- 验证码组件 -->
    <Verify ref="verify" @success="handleLogin" />
  </el-form>
</template>
```

#### MobileForm.vue（手机号登录）
```vue
<template>
  <el-form>
    <!-- 标题 -->
    <el-form-item>
      <LoginFormTitle />
    </el-form-item>
    
    <!-- 手机号 -->
    <el-form-item prop="mobileNumber">
      <el-input v-model="loginForm.mobileNumber" />
    </el-form-item>
    
    <!-- 验证码 -->
    <el-form-item prop="code">
      <el-input v-model="loginForm.code">
        <template #append>
          <span @click="getSmsCode">获取验证码</span>
        </template>
      </el-input>
    </el-form-item>
    
    <!-- 登录按钮 -->
    <XButton @click="signIn()">登录</XButton>
  </el-form>
</template>
```

### 移动端 (UniApp X)

#### login.uvue（统一登录页）
```vue
<template>
  <view class="login-container">
    <!-- 账号登录 -->
    <view v-if="loginType === 'account'">
      <!-- 租户名称 -->
      <input v-model="tenantName" />
      
      <!-- 账号 -->
      <input v-model="username" />
      
      <!-- 密码 -->
      <input v-model="password" type="password" />
      
      <!-- 记住我 -->
      <checkbox :checked="rememberMe" />
    </view>
    
    <!-- 手机号登录 -->
    <view v-else>
      <!-- 手机号 -->
      <input v-model="mobile" type="number" />
      
      <!-- 验证码 -->
      <input v-model="smsCode" type="number" />
      <button @click="handleSendCode">获取验证码</button>
    </view>
    
    <!-- 登录按钮 -->
    <button @click="handleLogin">登录</button>
    
    <!-- 切换登录方式 -->
    <text @click="switchLoginType">
      {{ loginType === 'account' ? '手机号登录' : '账号密码登录' }}
    </text>
    
    <!-- 验证码组件 -->
    <slider-captcha ref="captchaRef" @success="handleCaptchaSuccess" />
  </view>
</template>
```

## 关键差异说明

### 1. 租户名称显示逻辑 ⭐

#### PC 端
- **LoginForm.vue**（账号登录）：显示租户名称
- **MobileForm.vue**（手机号登录）：不显示租户名称

#### 移动端
- **账号登录**：显示租户名称
- **手机号登录**：不显示租户名称

**结论**：✅ 完全一致

### 2. 验证码使用 ⭐

#### PC 端
- **账号登录**：使用滑块验证码（Verify 组件）
- **手机号登录**：使用短信验证码

#### 移动端
- **账号登录**：使用滑块验证码（slider-captcha 组件）
- **手机号登录**：使用短信验证码

**结论**：✅ 完全一致

### 3. 记住我功能 ⭐

#### PC 端
- **账号登录**：显示"记住我"选项
- **手机号登录**：不显示"记住我"选项

#### 移动端
- **账号登录**：显示"记住我"选项
- **手机号登录**：不显示"记住我"选项

**结论**：✅ 完全一致

### 4. 表单验证

#### PC 端
```typescript
// 账号登录
const LoginRules = {
  tenantName: [required],
  username: [required],
  password: [required]
}

// 手机号登录
const rules = {
  mobileNumber: [required],
  code: [required]
}
```

#### 移动端
```typescript
// 账号登录
if (!tenantName.value || !username.value || !password.value) {
  // 提示错误
}

// 手机号登录
if (!mobile.value || !smsCode.value) {
  // 提示错误
}

// 手机号格式验证
const phoneReg = /^1[3-9]\d{9}$/
if (!phoneReg.test(mobile.value)) {
  // 提示错误
}
```

**结论**：✅ 逻辑一致，移动端增加了手机号格式验证

## API 接口对比

### 账号登录

#### PC 端
```typescript
// api/login/index.ts
export const login = (data: any) => {
  return request.post({ url: '/system/auth/login', data })
}
```

#### 移动端
```typescript
// api/login.uts
export function login(data: UTSJSONObject): Promise<any> {
  return post('/system/auth/login', data)
}
```

**结论**：✅ 接口一致

### 手机号登录

#### PC 端
```typescript
// api/login/index.ts
export const smsLogin = (data: any) => {
  return request.post({ url: '/system/auth/sms-login', data })
}
```

#### 移动端
```typescript
// api/login.uts
export function smsLogin(data: UTSJSONObject): Promise<any> {
  return post('/system/auth/sms-login', data)
}
```

**结论**：✅ 接口一致

### 发送验证码

#### PC 端
```typescript
// api/login/index.ts
export const sendSmsCode = (data: any) => {
  return request.post({ url: '/system/auth/send-sms-code', data })
}
```

#### 移动端
```typescript
// api/login.uts
export function sendSmsCode(data: UTSJSONObject): Promise<any> {
  return post('/system/auth/send-sms-code', data)
}
```

**结论**：✅ 接口一致

### 获取租户ID

#### PC 端
```typescript
// api/login/index.ts
export const getTenantIdByName = (name: string) => {
  return request.get({ url: '/system/tenant/get-id-by-name?name=' + name })
}
```

#### 移动端
```typescript
// api/login.uts
export function getTenantIdByName(name: string): Promise<any> {
  return get('/system/tenant/get-id-by-name?name=' + name)
}
```

**结论**：✅ 接口一致

## 用户体验对比

### PC 端
- Element Plus 组件库，UI 统一
- 表单验证提示清晰
- 验证码弹窗体验好
- 支持键盘回车登录

### 移动端
- 原生组件，性能更好
- Toast 提示简洁明了
- 验证码全屏显示，操作方便
- 支持键盘确认登录
- 增加成功提示和延迟跳转

## 总结

### ✅ 已实现的一致性
1. 账号登录显示租户名称，手机号登录不显示
2. 账号登录使用滑块验证码，手机号登录使用短信验证码
3. 记住我功能仅在账号登录时可用
4. 登录流程和验证逻辑完全一致
5. API 接口调用完全一致

### ⚠️ 合理的差异
1. UI 组件库不同（Element Plus vs 原生组件）
2. 移动端不支持二维码登录（不需要）
3. 移动端不支持社交登录（待开发）
4. 移动端增加了手机号格式验证（优化）
5. 移动端增加了成功提示（优化）

### 🎯 核心目标达成
**手机号登录不显示租户名称** ✅

PC 端和移动端的登录逻辑已完全统一，符合业务需求和用户体验标准。
