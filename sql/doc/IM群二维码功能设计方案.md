# IM 群二维码功能设计方案

## 功能概述

群二维码功能允许用户通过扫描二维码快速加入群聊，提升用户体验和群组推广效率。

## 业务流程

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  生成二维码  │ ───> │  扫码识别    │ ───> │  验证有效性  │
└─────────────┘      └─────────────┘      └─────────────┘
                                                  │
                                                  ▼
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  加入成功    │ <─── │  审批通过    │ <─── │  申请加入    │
└─────────────┘      └─────────────┘      └─────────────┘
                     (需要审批时)
```

## 数据库设计

### im_group_invite 表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| group_id | bigint | 群组ID |
| invite_code | varchar(64) | 邀请码（唯一） |
| creator_id | bigint | 创建者ID |
| expire_time | datetime | 过期时间 |
| max_use_count | int | 最大使用次数（0=不限制） |
| used_count | int | 已使用次数 |
| status | tinyint | 状态（1-有效 2-已过期 3-已禁用） |

### 索引设计

1. **唯一索引**：`idx_invite_code(invite_code)` - 确保邀请码唯一
2. **群组索引**：`idx_group(group_id)` - 快速查询群的邀请码
3. **过期索引**：`idx_expire(expire_time, status)` - 定时清理过期邀请码

## 二维码内容设计

### 最终方案：前端页面路径

二维码内容：`https://app.shengyu.com/pages/message/join-group?code=ABC123XYZ&groupId=123456`

**设计原则：**
- 二维码包含前端页面路径，用户扫码后跳转到前端页面
- 前端页面解析 URL 参数，调用后端 API 完成加入
- 前端可以展示群信息、处理各种状态（已在群中、需要审批等）

**交互流程：**
```
1. 用户扫描二维码
   ↓
2. 跳转到前端页面：/pages/message/join-group
   ↓
3. 前端页面解析参数（code, groupId）
   ↓
4. 前端调用 API 验证邀请码
   ↓
5. 显示群信息，用户点击"加入群聊"
   ↓
6. 前端调用 API 加入群聊
   ↓
7. 加入成功，跳转到聊天页面
```

### 域名配置说明

在 `app.config.uts` 中有两个重要的域名配置：

#### 1. BASE_URL（后端 API 地址）
- 用于前端调用后端接口
- 开发环境：`http://localhost:48080`
- 测试环境：`https://api-test.shengyu.com`
- 生产环境：`https://api.shengyu.com`

#### 2. ADMIN_APP_DOMAIN（移动端应用域名）
- 用于生成二维码、分享链接等场景
- 用户扫码后跳转到此域名
- 开发环境：`http://192.168.1.100:48080`（必须使用本机 IP，不能用 localhost）
- 测试环境：`https://app-test.shengyu.com`
- 生产环境：`https://app.shengyu.com`

#### 为什么需要两个域名？

**开发环境场景：**
- 前端调用后端 API 可以用 `localhost`（本机使用）
- 但手机扫码测试时无法访问 `localhost`
- 所以二维码中必须使用本机 IP 地址

**生产环境场景：**
- 前端和后端可能部署在不同的域名
- 前端：`https://app.shengyu.com`
- 后端：`https://api.shengyu.com`
- 二维码中应该使用前端域名

### 不同环境配置示例

**开发环境：**
```typescript
// app.config.uts
export const BASE_URL = 'http://localhost:48080'  // 后端 API 地址
export const ADMIN_APP_DOMAIN = 'http://192.168.1.100:48080'  // 移动端应用域名

// 二维码内容
http://192.168.1.100:48080/pages/message/join-group?code=xxx&groupId=xxx
```

**测试环境：**
```typescript
// app.config.uts
export const BASE_URL = 'https://api-test.shengyu.com'
export const ADMIN_APP_DOMAIN = 'https://app-test.shengyu.com'

// 二维码内容
https://app-test.shengyu.com/pages/message/join-group?code=xxx&groupId=xxx
```

**生产环境：**
```typescript
// app.config.uts
export const BASE_URL = 'https://api.shengyu.com'
export const ADMIN_APP_DOMAIN = 'https://app.shengyu.com'

// 二维码内容
https://app.shengyu.com/pages/message/join-group?code=xxx&groupId=xxx
```

### 二维码生成流程

```
1. 前端请求二维码
   ↓
   GET {BASE_URL}/app-api/system/im/group/invite/qrcode-image
   参数：code=xxx&groupId=xxx&baseUrl={ADMIN_APP_DOMAIN}

2. 后端生成二维码内容
   ↓
   pagePath = "/pages/message/join-group?code=xxx&groupId=xxx"
   qrContent = baseUrl + pagePath

3. 后端生成二维码图片
   ↓
   使用 ZXing 生成 PNG 图片

4. 返回图片
   ↓
   设置缓存头（12小时）
   输出 PNG 图片流
```

## 邀请码生成规则

### 格式设计

```
{prefix}{timestamp}{random}{checksum}
```

- **prefix**: 固定前缀（如 "GRP"）
- **timestamp**: 时间戳（6位，精确到秒）
- **random**: 随机字符串（8位）
- **checksum**: 校验码（2位）

示例：`GRP1A2B3C4D5E6F7G8H`

### 生成算法

```java
public String generateInviteCode() {
    // 1. 前缀
    String prefix = "GRP";
    
    // 2. 时间戳（Base36编码，6位）
    long timestamp = System.currentTimeMillis() / 1000;
    String timeStr = Long.toString(timestamp, 36).toUpperCase();
    timeStr = timeStr.substring(timeStr.length() - 6);
    
    // 3. 随机字符串（8位）
    String random = RandomStringUtils.randomAlphanumeric(8).toUpperCase();
    
    // 4. 校验码（前面字符的CRC校验）
    String data = prefix + timeStr + random;
    String checksum = calculateChecksum(data);
    
    return data + checksum;
}
```

## API 设计

### 1. 生成群二维码

**接口**：`POST /system/im/group/invite/generate`

**请求参数**：
```json
{
  "groupId": 123456,
  "expireHours": 24,      // 有效期（小时），默认24小时
  "maxUseCount": 0        // 最大使用次数，0表示不限制
}
```

**响应**：
```json
{
  "code": 0,
  "data": {
    "inviteCode": "GRP1A2B3C4D5E6F7G8H",
    "qrCodeUrl": "https://app.shengyu.com/group/join?code=GRP1A2B3C4D5E6F7G8H&groupId=123456",
    "expireTime": "2026-02-23 12:00:00"
  }
}
```

### 2. 验证邀请码

**接口**：`GET /system/im/group/invite/verify`

**请求参数**：
```
?code=GRP1A2B3C4D5E6F7G8H
```

**响应**：
```json
{
  "code": 0,
  "data": {
    "valid": true,
    "groupId": 123456,
    "groupName": "技术交流群",
    "groupAvatar": "https://...",
    "memberCount": 50,
    "needApproval": false,
    "expireTime": "2026-02-23 12:00:00"
  }
}
```

### 3. 通过邀请码加入群

**接口**：`POST /system/im/group/invite/join`

**请求参数**：
```json
{
  "inviteCode": "GRP1A2B3C4D5E6F7G8H"
}
```

**响应**：
```json
{
  "code": 0,
  "data": {
    "success": true,
    "groupId": 123456,
    "needApproval": false,  // 是否需要审批
    "message": "加入成功"
  }
}
```

### 4. 获取群的有效邀请码

**接口**：`GET /system/im/group/invite/get`

**请求参数**：
```
?groupId=123456
```

**响应**：
```json
{
  "code": 0,
  "data": {
    "inviteCode": "GRP1A2B3C4D5E6F7G8H",
    "qrCodeUrl": "/pages/message/join-group?code=GRP1A2B3C4D5E6F7G8H&groupId=123456",
    "expireTime": "2026-02-23 12:00:00",
    "usedCount": 10,
    "maxUseCount": 0
  }
}
```

**注意**：`qrCodeUrl` 返回的是相对路径，前端需要拼接 `ADMIN_APP_DOMAIN` 生成完整 URL。

### 5. 获取群邀请二维码图片

**接口**：`GET /system/im/group/invite/qrcode-image`

**请求参数**：
```
?code=GRP1A2B3C4D5E6F7G8H&groupId=123456&baseUrl=http://192.168.1.100:48080
```

**响应**：
- Content-Type: `image/png`
- Cache-Control: `public, max-age=43200`（12小时）
- 返回二维码图片的字节流

**说明**：
- `baseUrl` 参数是前端传递的 `ADMIN_APP_DOMAIN`
- 后端使用此参数拼接完整 URL 生成二维码
- 二维码内容：`{baseUrl}/pages/message/join-group?code=xxx&groupId=xxx`

## 前端实现

### 配置文件（app.config.uts）

```typescript
/**
 * API 基础地址（后端接口地址）
 */
export const BASE_URL = 'http://localhost:48080'

/**
 * 移动端应用域名（前端页面地址）
 * 用于生成二维码、分享链接等场景
 */
export const ADMIN_APP_DOMAIN = 'http://192.168.1.100:48080'
```

### 1. 群二维码页面（group-qrcode.uvue）

**功能：**
- 显示群信息（名称、头像、成员数）
- 显示二维码（后端生成的图片）
- 显示邀请码和有效期
- 支持保存二维码到相册
- 支持分享二维码
- 支持刷新二维码

**核心代码：**
```typescript
import { BASE_URL, ADMIN_APP_DOMAIN } from '../../config/app.config.uts'

async function generateQRCode() {
    // 请求后端生成的二维码图片
    // 传递 ADMIN_APP_DOMAIN 作为 baseUrl 参数
    qrCodeImageUrl.value = `${BASE_URL}/app-api/system/im/group/invite/qrcode-image?code=${inviteCode.value}&groupId=${groupId.value}&baseUrl=${encodeURIComponent(ADMIN_APP_DOMAIN)}`
}
```

**页面结构：**
```
┌─────────────────────────┐
│      群信息卡片          │
│  [头像] 技术交流群       │
│         50人            │
├─────────────────────────┤
│                         │
│   [二维码图片(后端生成)] │
│                         │
│   邀请码: GRP1A2B3C...  │
│   有效期: 24小时后过期   │
├─────────────────────────┤
│  [保存图片] [分享二维码] │
│  [刷新二维码]           │
└─────────────────────────┘
```

### 2. 扫码加入页面（join-group.uvue）

**功能：**
- 自动验证邀请码
- 显示群信息预览
- 显示加入按钮
- 处理加入逻辑
- 显示加入结果
- 处理已在群中的情况

**核心代码：**
```typescript
onLoad((options : any) => {
    // 获取 URL 参数
    if (options['code']) {
        inviteCode.value = options['code'] as string
    }
    if (options['groupId']) {
        groupId.value = options['groupId'] as string
    }
})

onMounted(async () => {
    // 自动验证邀请码
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

**页面结构：**
```
┌─────────────────────────┐
│      群信息预览          │
│  [头像] 技术交流群       │
│         50人            │
│                         │
│  邀请码: GRP1A2B3C...   │
│  有效期: 24小时后过期    │
│  加群方式: 直接加入      │
├─────────────────────────┤
│    [加入群聊按钮]        │
└─────────────────────────┘
```

## 安全设计

### 1. 邀请码安全

- ✅ 唯一性：每个邀请码全局唯一
- ✅ 时效性：支持设置过期时间
- ✅ 次数限制：支持限制使用次数
- ✅ 校验码：防止伪造和篡改

### 2. 权限控制

- ✅ 只有群成员可以生成邀请码
- ✅ 群主和管理员可以禁用邀请码
- ✅ 支持群设置"加群需要审批"

### 3. 防刷机制

- ✅ 同一用户短时间内多次加入同一群：限制
- ✅ 同一邀请码被大量使用：监控告警
- ✅ IP 限流：防止恶意扫码

## 业务规则

### 1. 邀请码生成规则

- 每个群同时只能有一个有效的邀请码
- 生成新邀请码时，旧邀请码自动失效
- 默认有效期：24小时
- 默认使用次数：不限制

### 2. 加入群规则

- 已经是群成员：提示"您已经在群里"
- 群已满员：提示"群人数已达上限"
- 需要审批：创建加群申请，等待审批
- 不需要审批：直接加入群聊

### 3. 邀请码失效规则

- 过期时间到达：自动失效
- 使用次数达到上限：自动失效
- 群主/管理员手动禁用：立即失效
- 群解散：所有邀请码失效

## 定时任务

### 清理过期邀请码

**执行频率**：每小时执行一次

**任务内容**：
```sql
UPDATE im_group_invite 
SET status = 2 
WHERE status = 1 
  AND expire_time < NOW()
  AND deleted = 0;
```

## 监控指标

1. **邀请码生成量**：每日生成的邀请码数量
2. **扫码加入量**：通过二维码加入的用户数
3. **转化率**：扫码/加入的比例
4. **平均有效期**：邀请码的平均使用时长
5. **异常告警**：单个邀请码短时间内大量使用

## 扩展功能

### 1. 邀请统计

- 记录每个邀请码的使用明细
- 统计每个用户邀请的人数
- 邀请排行榜

### 2. 个性化二维码

- 支持自定义二维码样式
- 支持添加群头像到二维码中心
- 支持品牌化定制

### 3. 邀请奖励

- 邀请达到一定人数给予奖励
- 积分系统集成
- 邀请活动

## 技术选型

### 二维码生成库

**Java 后端**：
- **ZXing**（已采用）：功能强大，社区活跃
  - 依赖管理：在 `shengyu-dependencies/pom.xml` 中统一管理版本
  - 工具类：`QRCodeUtil.java` 封装在 `shengyu-common` 模块
  - 生成尺寸：300x300 像素
  - 输出格式：PNG

**前端**：
- **后端生成方案**（已采用）：
  - 后端使用 ZXing 生成二维码图片
  - 前端通过 `<image>` 标签显示
  - 优点：跨平台兼容性好（Android、iOS、H5）
  - 缺点：需要网络请求

### 缓存策略

**浏览器缓存**：
- Cache-Control: `public, max-age=43200`（12小时）
- 小于服务器有效期（24小时），避免使用过期数据

**服务器缓存**：
- 邀请码有效期：24小时（默认）
- 定时任务每小时清理过期邀请码

### 租户隔离

**租户白名单**：
- 二维码图片接口需要匿名访问
- 配置路径：`application.yaml` 的 `shengyu.tenant.ignore-urls`
- 白名单路径：`/app-api/system/im/group/invite/qrcode-image`

## 实施计划

### Phase 1：基础功能（已完成 ✅）
- ✅ 数据库表设计（`im_group_invite` 表）
- ✅ 后端 API 实现（生成、验证、加入、获取）
- ✅ 后端二维码图片生成（ZXing）
- ✅ 前端二维码页面（`group-qrcode.uvue`）
- ✅ 前端加入页面（`join-group.uvue`）
- ✅ 扫码加入流程
- ✅ 域名配置（`BASE_URL` 和 `ADMIN_APP_DOMAIN`）
- ✅ 租户白名单配置
- ✅ 缓存策略（12小时浏览器缓存）

### Phase 2：增强功能
- ⏳ 邀请统计
- ⏳ 个性化二维码
- ⏳ 分享功能优化

### Phase 3：运营功能
- ⏳ 邀请奖励
- ⏳ 邀请活动
- ⏳ 数据分析

## 测试验证

### 1. 功能测试

**生成二维码：**
- ✅ 群成员可以生成邀请码
- ✅ 每个群同时只有一个有效邀请码
- ✅ 二维码图片正常显示

**扫码加入：**
- ✅ 扫码后跳转到加入页面
- ✅ 显示正确的群信息
- ✅ 点击加入后成功加入群聊
- ✅ 已在群中时显示提示

**邀请码验证：**
- ✅ 有效邀请码验证通过
- ✅ 过期邀请码验证失败
- ✅ 不存在的邀请码验证失败

### 2. 环境测试

**开发环境：**
- ✅ 使用本机 IP 地址
- ✅ 其他设备可以扫码访问

**测试环境：**
- ⏳ 使用测试域名
- ⏳ HTTPS 协议

**生产环境：**
- ⏳ 使用生产域名
- ⏳ HTTPS 协议
- ⏳ CDN 加速

### 3. 性能测试

- ⏳ 二维码生成性能
- ⏳ 并发扫码测试
- ⏳ 缓存命中率

## 常见问题

### Q1: 为什么需要两个域名配置？

**A**: 因为它们的用途不同：
- `BASE_URL`：前端调用后端 API 的地址（可以是 localhost）
- `ADMIN_APP_DOMAIN`：用户扫码后访问的地址（必须是可访问的 IP 或域名）

### Q2: 开发环境为什么不能用 localhost？

**A**: 因为其他设备（如手机）无法访问你电脑上的 localhost，必须使用本机 IP 地址。

### Q3: 二维码中的路径为什么是 `/pages/message/join-group`？

**A**: 这是 uniapp 的页面路径，用户扫码后跳转到前端页面，前端页面再调用后端 API 完成加入。

### Q4: 如何获取本机 IP 地址？

**A**: 
- macOS/Linux: `ifconfig | grep "inet " | grep -v 127.0.0.1`
- Windows: `ipconfig | findstr IPv4`

### Q5: 二维码缓存时间为什么是 12 小时？

**A**: 小于服务器有效期（24小时），避免用户使用过期的二维码。

## 参考资料

- [微信群二维码功能](https://weixin.qq.com/)
- [钉钉群二维码功能](https://www.dingtalk.com/)
- [ZXing 文档](https://github.com/zxing/zxing)
