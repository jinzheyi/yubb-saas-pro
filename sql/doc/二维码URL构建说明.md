# 二维码 URL 构建说明

## 设计原则

**二维码包含前端页面路径，用户扫码后跳转到前端页面**
- 二维码中的 URL 是前端应用的完整地址
- 用户扫码后跳转到前端的"加入群聊"页面
- 前端页面解析 URL 参数，调用后端 API 完成加入

## 配置说明

### 两个重要的域名配置

在 `app.config.uts` 中有两个域名配置：

1. **BASE_URL**：后端 API 地址
   - 用于前端调用后端接口
   - 例如：`http://localhost:48080`

2. **ADMIN_APP_DOMAIN**：移动端应用域名
   - 用于生成二维码、分享链接等场景
   - 用户扫码后跳转到此域名
   - 例如：`http://192.168.1.100:48080`（开发环境）
   - 例如：`https://app.shengyu.com`（生产环境）

### 为什么需要两个域名？

- **BASE_URL**：前端应用访问后端 API 的地址
  - 开发环境可以是 `localhost`
  - 因为是前端应用内部调用，不需要其他设备访问

- **ADMIN_APP_DOMAIN**：其他用户扫码后访问的地址
  - 开发环境不能是 `localhost`（其他设备无法访问）
  - 必须是可以被其他设备访问的地址（如本机 IP）
  - 生产环境是公网域名

## 交互流程

```
1. 用户扫描二维码
   ↓
   二维码内容：http://localhost:48080/pages/message/join-group?code=xxx&groupId=xxx

2. 跳转到前端页面
   ↓
   页面：/pages/message/join-group
   参数：code=xxx, groupId=xxx

3. 前端页面自动验证邀请码
   ↓
   调用 API：GET /app-api/system/im/group/invite/verify?code=xxx

4. 显示群信息
   ↓
   群名称、成员数、有效期等

5. 用户点击"加入群聊"
   ↓
   调用 API：POST /app-api/system/im/group/invite/join
   参数：{ inviteCode: "xxx" }

6. 加入成功
   ↓
   跳转到聊天页面：/pages/message/chat?targetId=xxx&targetType=2
```

## 实现方案

### 1. 前端配置

**文件**：`shengyu-ui/shengyu-ui-admin-uniappx/config/app.config.uts`

```typescript
/**
 * API 基础地址（后端接口地址）
 */
export const BASE_URL = 'http://localhost:48080'

/**
 * 移动端应用域名（前端页面地址）
 * 用于生成二维码、分享链接等场景
 * 
 * 开发环境：使用本机 IP 地址，如 'http://192.168.1.100:48080'
 * 测试环境：使用测试域名，如 'https://app-test.shengyu.com'
 * 生产环境：使用生产域名，如 'https://app.shengyu.com'
 */
export const ADMIN_APP_DOMAIN = 'http://192.168.1.100:48080'
```

### 2. 后端生成二维码内容

**文件**：`ImGroupServiceImpl.java`

```java
/**
 * 构建邀请码响应VO
 */
private AppImGroupInviteRespVO buildInviteRespVO(ImGroupInviteDO invite, Long groupId) {
    AppImGroupInviteRespVO respVO = new AppImGroupInviteRespVO();
    respVO.setInviteCode(invite.getInviteCode());
    // 返回前端页面路径（uniapp 页面路径）
    respVO.setQrCodeUrl(String.format("/pages/message/join-group?code=%s&groupId=%d",
            invite.getInviteCode(), groupId));
    respVO.setExpireTime(invite.getExpireTime());
    respVO.setUsedCount(invite.getUsedCount());
    respVO.setMaxUseCount(invite.getMaxUseCount());
    return respVO;
}

@Override
public String getQRCodeContentByInviteCode(String inviteCode, Long groupId) {
    // 1. 查询邀请码信息
    ImGroupInviteDO invite = groupInviteMapper.selectByInviteCode(inviteCode);
    if (invite == null) {
        throw exception(GROUP_INVITE_CODE_NOT_EXISTS);
    }

    // 2. 使用邀请码对应的群组ID（如果参数没有传）
    if (groupId == null) {
        groupId = invite.getGroupId();
    }

    // 3. 返回前端页面路径（uniapp 页面路径）
    return String.format("/pages/message/join-group?code=%s&groupId=%d", inviteCode, groupId);
}
```

### 3. 后端生成二维码图片

**文件**：`AppImGroupController.java`

```java
@GetMapping("/invite/qrcode-image")
public void getInviteQRCodeImage(
        @RequestParam("code") String code,
        @RequestParam(value = "groupId", required = false) Long groupId,
        @RequestParam("baseUrl") String baseUrl,
        HttpServletResponse response) throws IOException {
    
    // 1. 验证邀请码
    AppImGroupInviteVerifyRespVO verifyResult = groupService.verifyInviteCode(code);
    if (!verifyResult.getValid()) {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "邀请码无效或已过期");
        return;
    }
    
    // 2. 获取前端页面路径
    String pagePath = groupService.getQRCodeContentByInviteCode(code, groupId);
    // 结果：/pages/message/join-group?code=xxx&groupId=xxx
    
    // 3. 拼接完整 URL
    String qrContent = baseUrl + pagePath;
    // 结果：http://localhost:48080/pages/message/join-group?code=xxx&groupId=xxx
    
    // 4. 生成二维码
    byte[] qrCodeBytes = QRCodeUtil.generateQRCodeBytes(qrContent, 300, 300);
    
    // 5. 设置响应头（浏览器缓存12小时）
    response.setContentType("image/png");
    response.setHeader("Cache-Control", "public, max-age=43200");
    
    // 6. 输出图片
    response.getOutputStream().write(qrCodeBytes);
}
```

### 4. 前端请求二维码

**文件**：`group-qrcode.uvue`

```typescript
import { BASE_URL, ADMIN_APP_DOMAIN } from '../../config/app.config.uts'

async function generateQRCode() {
    // 请求二维码图片，传递 ADMIN_APP_DOMAIN 参数
    // BASE_URL: 后端 API 地址
    // ADMIN_APP_DOMAIN: 移动端应用域名（用于二维码中的 URL）
    qrCodeImageUrl.value = `${BASE_URL}/app-api/system/im/group/invite/qrcode-image?code=${inviteCode.value}&groupId=${groupId.value}&baseUrl=${encodeURIComponent(ADMIN_APP_DOMAIN)}`
}
```

**请求示例**：
```
http://localhost:48080/app-api/system/im/group/invite/qrcode-image?code=GRPxxx&groupId=123&baseUrl=http%3A%2F%2F192.168.1.100%3A48080
```

### 5. 前端加入群聊页面

**文件**：`join-group.uvue`

```typescript
onLoad((options : any) => {
    // 获取邀请码
    if (options['code']) {
        inviteCode.value = options['code'] as string
    }

    // 获取群组ID（可选）
    if (options['groupId']) {
        groupId.value = options['groupId'] as string
    }
})

onMounted(async () => {
    // 验证邀请码
    await verifyCode()
})

async function handleJoinGroup() {
    // 调用后端 API 加入群聊
    await joinGroupByInvite(inviteCode.value)
    
    // 跳转到聊天页面
    uni.redirectTo({
        url: `/pages/message/chat?targetId=${groupId.value}&targetType=2`
    })
}
```

## 工作流程

```
1. 前端配置
   ↓
   BASE_URL = 'http://localhost:48080'  (后端 API 地址)
   ADMIN_APP_DOMAIN = 'http://192.168.1.100:48080'  (移动端应用域名)

2. 前端请求二维码
   ↓
   GET http://localhost:48080/app-api/system/im/group/invite/qrcode-image
   参数：code=xxx&groupId=xxx&baseUrl=http://192.168.1.100:48080

3. 后端生成二维码内容
   ↓
   pagePath = "/pages/message/join-group?code=xxx&groupId=xxx"
   qrContent = baseUrl + pagePath
   qrContent = "http://192.168.1.100:48080/pages/message/join-group?code=xxx&groupId=xxx"

4. 后端生成二维码图片
   ↓
   返回 PNG 图片

5. 用户扫描二维码
   ↓
   跳转到：http://192.168.1.100:48080/pages/message/join-group?code=xxx&groupId=xxx

6. 前端页面加载
   ↓
   解析参数：code=xxx, groupId=xxx
   调用 API 验证邀请码（使用 BASE_URL）

7. 用户点击"加入群聊"
   ↓
   调用 API：POST http://localhost:48080/app-api/system/im/group/invite/join

8. 加入成功
   ↓
   跳转到聊天页面
```

## 优势

### 1. 配置集中管理
- ✅ 只需在前端配置 `BASE_URL`
- ✅ 后端不需要配置域名
- ✅ 避免配置冗余

### 2. 职责清晰
- ✅ 前端：管理应用地址配置
- ✅ 后端：接收参数，生成二维码
- ✅ 符合前后端分离原则

### 3. 灵活性
- ✅ 前端可以部署在任何域名
- ✅ 后端不需要知道前端地址
- ✅ 支持多环境部署

### 4. 无硬编码
- ✅ 后端不硬编码域名逻辑
- ✅ 所有配置来自前端
- ✅ 易于维护

### 5. 代码简洁
- ✅ 开发阶段无需考虑版本兼容
- ✅ 逻辑清晰，易于理解
- ✅ 减少维护成本

## 不同环境配置

### 开发环境
```typescript
// app.config.uts
export const BASE_URL = 'http://localhost:48080'  // 后端 API 地址
export const ADMIN_APP_DOMAIN = 'http://192.168.1.100:48080'  // 移动端应用域名（使用本机 IP）

// 二维码内容
http://192.168.1.100:48080/pages/message/join-group?code=xxx&groupId=xxx
```

**注意**：开发环境必须使用本机 IP 地址，不能使用 `localhost`，否则其他设备扫码后无法访问。

### 测试环境
```typescript
// app.config.uts
export const BASE_URL = 'https://api-test.shengyu.com'  // 后端 API 地址
export const ADMIN_APP_DOMAIN = 'https://app-test.shengyu.com'  // 移动端应用域名

// 二维码内容
https://app-test.shengyu.com/pages/message/join-group?code=xxx&groupId=xxx
```

### 生产环境
```typescript
// app.config.uts
export const BASE_URL = 'https://api.shengyu.com'  // 后端 API 地址
export const ADMIN_APP_DOMAIN = 'https://app.shengyu.com'  // 移动端应用域名

// 二维码内容
https://app.shengyu.com/pages/message/join-group?code=xxx&groupId=xxx
```

## 测试

### 1. 验证前端传递参数

打开浏览器控制台，查看请求：
```
GET /app-api/system/im/group/invite/qrcode-image?code=GRPxxx&groupId=123&baseUrl=http%3A%2F%2F192.168.1.100%3A48080
```

### 2. 验证二维码内容

扫描二维码，应该得到：
```
http://192.168.1.100:48080/pages/message/join-group?code=GRPxxx&groupId=123
```

**注意**：开发环境应该是本机 IP 地址，不是 `localhost`。

### 3. 验证页面跳转

扫码后应该跳转到前端的"加入群聊"页面，显示群信息。

### 4. 验证加入功能

点击"加入群聊"按钮，应该能成功加入并跳转到聊天页面。

## 常见问题

### Q1: 为什么要 URL 编码 baseUrl？

**A**: 
因为 `baseUrl` 包含特殊字符（如 `:` 和 `/`），需要编码后才能作为 URL 参数传递。

```typescript
encodeURIComponent('http://localhost:48080')
// 结果：http%3A%2F%2Flocalhost%3A48080
```

### Q2: 为什么需要两个域名配置（BASE_URL 和 ADMIN_APP_DOMAIN）？

**A**: 
因为它们的用途不同：

- **BASE_URL**：前端应用调用后端 API 的地址
  - 开发环境可以是 `localhost`（只在本机使用）
  - 用于前端内部调用后端接口

- **ADMIN_APP_DOMAIN**：其他用户扫码后访问的地址
  - 开发环境必须是本机 IP（其他设备需要访问）
  - 用于生成二维码、分享链接等场景
  - 生产环境是公网域名

例如开发环境：
```typescript
export const BASE_URL = 'http://localhost:48080'  // 本机调用 API
export const ADMIN_APP_DOMAIN = 'http://192.168.1.100:48080'  // 其他设备扫码访问
```

### Q3: 如果前端和后端域名不同怎么办？

**A**: 
完全没问题！这两个配置本来就可以不同。

例如生产环境：
- 前端应用：`https://app.shengyu.com`
- 后端 API：`https://api.shengyu.com`

配置：
```typescript
export const BASE_URL = 'https://api.shengyu.com'  // 后端 API 地址
export const ADMIN_APP_DOMAIN = 'https://app.shengyu.com'  // 前端应用地址
```

二维码中的 URL 是前端应用地址，用户扫码后跳转到前端页面。

### Q4: baseUrl 参数是必需的吗？

**A**: 
是的，`baseUrl` 参数是必需的。前端必须传递 `ADMIN_APP_DOMAIN` 参数，后端才能生成正确的二维码。

### Q5: 为什么二维码中的路径是 `/pages/message/join-group` 而不是 `/group/join`？

**A**: 
因为二维码中的 URL 是前端页面路径，不是后端 API 路径。

- `/pages/message/join-group` 是 uniapp 的页面路径
- 用户扫码后跳转到这个前端页面
- 前端页面再调用后端 API 完成加入群聊

这样的设计更灵活，前端可以在页面上展示群信息、处理各种状态（已在群中、需要审批等）。

## 总结

通过让前端传递 `BASE_URL` 参数，我们实现了：
- ✅ 配置集中管理（前端统一配置）
- ✅ 无硬编码（后端不硬编码域名逻辑）
- ✅ 职责清晰（前端管理配置，后端处理业务）
- ✅ 灵活部署（支持多环境、多域名）
- ✅ 代码简洁（开发阶段无需版本兼容）

这是一个更优雅、更符合前后端分离原则的设计！
