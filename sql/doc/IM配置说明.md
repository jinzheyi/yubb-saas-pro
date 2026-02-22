# IM 即时通讯配置说明

## 设计原则

### 单一配置源
前端应用地址统一在前端配置文件中管理，后端不重复配置，避免配置冗余和不一致。

## 配置位置

### 前端配置
**文件**：`shengyu-ui/shengyu-ui-admin-uniappx/config/app.config.uts`

```typescript
/**
 * API 基础地址
 * 同时也是前端应用的基础地址
 */
export const BASE_URL = 'http://localhost:48080'
```

### 不同环境配置

#### 开发环境
```typescript
export const BASE_URL = 'http://localhost:48080'
```

#### 测试环境
```typescript
export const BASE_URL = 'https://test.shengyu.com'
```

#### 生产环境
```typescript
export const BASE_URL = 'https://app.shengyu.com'
```

## 工作原理

### 1. 后端返回相对路径

**接口**：`/system/im/group/invite/get`

**返回数据**：
```json
{
  "code": 0,
  "data": {
    "inviteCode": "GRPTAUJBILXRJ0JMU94",
    "qrCodeUrl": "/group/join?code=GRPTAUJBILXRJ0JMU94&groupId=2025230965426188289",
    "expireTime": 1771826382000,
    ...
  }
}
```

注意：`qrCodeUrl` 是**相对路径**，不包含域名。

### 2. 前端拼接完整 URL

```typescript
// 前端代码
const result = await getGroupInviteCode(groupId)

// 拼接完整 URL
qrCodeUrl.value = `${BASE_URL}${result.qrCodeUrl}`
// 结果：http://localhost:48080/group/join?code=xxx&groupId=xxx
```

### 3. 生成二维码

```typescript
// 使用完整 URL 生成二维码图片
qrCodeImageUrl.value = `${BASE_URL}/app-api/system/im/group/invite/qrcode-image?code=${inviteCode}&groupId=${groupId}`
```

## 优势

### 1. 单一配置源
- ✅ 只需在前端配置一次 BASE_URL
- ✅ 后端不需要知道前端应用的地址
- ✅ 避免配置不一致

### 2. 灵活性
- ✅ 前端可以部署在任何域名
- ✅ 后端不需要修改代码
- ✅ 支持多环境部署

### 3. 前后端分离
- ✅ 后端只负责业务逻辑
- ✅ 前端负责 URL 拼接
- ✅ 职责清晰

## 相关代码

### 后端代码

**文件**：`ImGroupServiceImpl.java`

```java
private AppImGroupInviteRespVO buildInviteRespVO(ImGroupInviteDO invite, Long groupId) {
    AppImGroupInviteRespVO respVO = new AppImGroupInviteRespVO();
    respVO.setInviteCode(invite.getInviteCode());
    // 只返回相对路径
    respVO.setQrCodeUrl(String.format("/group/join?code=%s&groupId=%d",
            invite.getInviteCode(), groupId));
    // ...
    return respVO;
}
```

### 前端代码

**文件**：`group-qrcode.uvue`

```typescript
import { BASE_URL } from '../../config/app.config.uts'

async function loadInviteCode() {
    const result = await getGroupInviteCode(groupId.value)
    
    // 拼接完整 URL
    qrCodeUrl.value = result.qrCodeUrl ? `${BASE_URL}${result.qrCodeUrl}` : ''
    
    // 生成二维码
    await generateQRCode()
}
```

## 测试

### 1. 验证后端返回相对路径

```bash
curl "http://localhost:48080/app-api/system/im/group/invite/get?groupId=123456"

# 返回结果
{
  "code": 0,
  "data": {
    "inviteCode": "GRPxxx",
    "qrCodeUrl": "/group/join?code=GRPxxx&groupId=123456",  # 相对路径
    ...
  }
}
```

### 2. 验证前端拼接完整 URL

打开浏览器控制台，查看日志：
```
[GroupQRCode] 加载邀请码成功: {
  inviteCode: "GRPxxx",
  qrCodeUrl: "http://localhost:48080/group/join?code=GRPxxx&groupId=123456",  # 完整 URL
  ...
}
```

### 3. 验证二维码生成

扫描二维码，应该跳转到：
```
http://localhost:48080/group/join?code=GRPxxx&groupId=123456
```

## 常见问题

### Q1: 为什么不在后端配置前端地址？

**A**: 
1. 前端地址应该由前端管理，后端不应该关心
2. 避免配置冗余和不一致
3. 前端可能部署在多个域名（CDN、多地域等）

### Q2: 如果前后端域名不同怎么办？

**A**: 
这个设计仍然适用。例如：
- 前端：`https://app.shengyu.com`
- 后端：`https://api.shengyu.com`

前端配置：
```typescript
export const BASE_URL = 'https://app.shengyu.com'  // 前端应用地址
export const API_URL = 'https://api.shengyu.com'   // 后端 API 地址
```

然后在拼接时使用 `BASE_URL`（前端地址），调用 API 时使用 `API_URL`（后端地址）。

### Q3: 二维码中的 URL 是前端地址还是后端地址？

**A**: 
二维码中的 URL 是**前端应用地址**，因为用户扫码后要跳转到前端页面，而不是后端 API。

例如：
```
https://app.shengyu.com/group/join?code=xxx&groupId=xxx
```

用户扫码后，浏览器打开这个前端页面，页面再调用后端 API 验证邀请码并加入群聊。

## 总结

通过这种设计，我们实现了：
- ✅ 配置集中管理（前端统一配置）
- ✅ 避免配置冗余
- ✅ 前后端职责清晰
- ✅ 灵活支持多环境部署

这是一个更优雅、更符合前后端分离原则的设计。

### 1. 群二维码生成

当用户查看群二维码时，系统会：
1. 生成或获取群邀请码（如 `GRPTAUJBILXRJ0JMU94`）
2. 使用配置的 URL 构建完整链接：
   ```
   https://app.shengyu.com/group/join?code=GRPTAUJBILXRJ0JMU94&groupId=2025230965426188289
   ```
3. 将链接编码成二维码图片
4. 用户扫描二维码后，跳转到该链接

### 2. 不同环境配置

#### 开发环境
```yaml
shengyu:
  im:
    group-invite-url: http://localhost:8080/group/join
```

#### 测试环境
```yaml
shengyu:
  im:
    group-invite-url: https://test.shengyu.com/group/join
```

#### 生产环境
```yaml
shengyu:
  im:
    group-invite-url: https://app.shengyu.com/group/join
```

## 相关代码

### 配置类

**文件**：`ImProperties.java`

```java
@Component
@ConfigurationProperties(prefix = "shengyu.im")
@Data
public class ImProperties {
    /**
     * 群邀请页面 URL
     */
    private String groupInviteUrl = "https://app.shengyu.com/group/join";
}
```

### 使用示例

**文件**：`ImGroupServiceImpl.java`

```java
@Resource
private ImProperties imProperties;

private AppImGroupInviteRespVO buildInviteRespVO(ImGroupInviteDO invite, Long groupId) {
    AppImGroupInviteRespVO respVO = new AppImGroupInviteRespVO();
    respVO.setQrCodeUrl(String.format("%s?code=%s&groupId=%d",
            imProperties.getGroupInviteUrl(), invite.getInviteCode(), groupId));
    // ...
    return respVO;
}
```

## 注意事项

### 1. URL 格式

- 必须是完整的 URL（包含协议）
- 不要在末尾添加 `/`
- 系统会自动添加查询参数 `?code=xxx&groupId=xxx`

### 2. HTTPS 要求

生产环境建议使用 HTTPS：
- ✅ 安全性更高
- ✅ 微信等平台要求 HTTPS
- ✅ 避免中间人攻击

### 3. 域名配置

确保域名已正确配置：
- DNS 解析正确
- SSL 证书有效
- 服务器正常运行

### 4. 前端路由

前端需要实现对应的路由：
- 路径：`/group/join`
- 参数：`code`（邀请码）、`groupId`（群组ID）
- 功能：验证邀请码并加入群聊

## 测试

### 1. 验证配置是否生效

```bash
# 调用获取邀请码接口
curl "http://localhost:48080/app-api/system/im/group/invite/get?groupId=123456"

# 返回结果中的 qrCodeUrl 应该使用配置的 URL
{
  "code": 0,
  "data": {
    "inviteCode": "GRPxxx",
    "qrCodeUrl": "https://app.shengyu.com/group/join?code=GRPxxx&groupId=123456",
    ...
  }
}
```

### 2. 验证二维码生成

```bash
# 访问二维码图片接口
curl "http://localhost:48080/app-api/system/im/group/invite/qrcode-image?code=GRPxxx&groupId=123456" --output qrcode.png

# 扫描生成的二维码，应该跳转到配置的 URL
```

## 常见问题

### Q1: 修改配置后不生效？

**A**: 需要重启应用服务器，配置才会生效。

### Q2: 可以使用 IP 地址吗？

**A**: 可以，但不推荐。建议使用域名，便于后期迁移和维护。

### Q3: 开发环境如何测试？

**A**: 可以配置为 `http://localhost:8080/group/join`，但需要注意：
- 二维码只能在本机扫描测试
- 其他设备无法访问 localhost

建议使用本机 IP 地址：
```yaml
shengyu:
  im:
    group-invite-url: http://192.168.1.100:8080/group/join
```

### Q4: 支持多个域名吗？

**A**: 当前只支持单个 URL。如果需要支持多个域名（如国内外不同域名），需要扩展配置：

```yaml
shengyu:
  im:
    group-invite-url: https://app.shengyu.com/group/join
    group-invite-url-cn: https://app.shengyu.cn/group/join  # 国内域名
    group-invite-url-global: https://app.shengyu.com/group/join  # 国际域名
```

然后在代码中根据用户地区选择对应的 URL。

## 总结

通过配置化管理群邀请 URL，我们实现了：
- ✅ 消除硬编码
- ✅ 支持多环境部署
- ✅ 便于维护和修改
- ✅ 提高代码质量

这是一个良好的实践，符合 12-Factor App 的配置管理原则。
