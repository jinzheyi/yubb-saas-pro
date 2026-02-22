# IM 群二维码功能实施指南

## 实施概述

本指南提供群二维码功能的分步实施方案，确保功能稳定上线。

## 实施步骤

### Step 1: 数据库准备

#### 1.1 创建邀请码表

```bash
# 执行 DDL 脚本
mysql -u root -p shengyu < sql/mysql/1.0/im/ddl_im_tables.sql
```

#### 1.2 验证表创建

```sql
-- 验证表结构
DESC im_group_invite;

-- 验证索引
SHOW INDEX FROM im_group_invite;
```

### Step 2: 后端实现

#### 2.1 添加 Maven 依赖（pom.xml）

```xml
<!-- 二维码生成库 -->
<dependency>
    <groupId>com.google.zxing</groupId>
    <artifactId>core</artifactId>
    <version>3.5.1</version>
</dependency>
<dependency>
    <groupId>com.google.zxing</groupId>
    <artifactId>javase</artifactId>
    <version>3.5.1</version>
</dependency>
```

#### 2.2 创建实体类

**文件位置**：`shengyu-module-system-biz/src/main/java/com/shengyu/module/system/dal/dataobject/im/ImGroupInviteDO.java`

```java
@TableName("im_group_invite")
@Data
@EqualsAndHashCode(callSuper = true)
public class ImGroupInviteDO extends BaseDO {
    
    @TableId
    private Long id;
    
    private Long groupId;
    
    private String inviteCode;
    
    private Long creatorId;
    
    private LocalDateTime expireTime;
    
    private Integer maxUseCount;
    
    private Integer usedCount;
    
    private Integer status; // 1-有效 2-已过期 3-已禁用
}
```

#### 2.3 创建 Mapper

**文件位置**：`shengyu-module-system-biz/src/main/java/com/shengyu/module/system/dal/mysql/im/ImGroupInviteMapper.java`

```java
@Mapper
public interface ImGroupInviteMapper extends BaseMapperX<ImGroupInviteDO> {
    
    default ImGroupInviteDO selectByInviteCode(String inviteCode) {
        return selectOne(ImGroupInviteDO::getInviteCode, inviteCode);
    }
    
    default ImGroupInviteDO selectValidByGroupId(Long groupId) {
        return selectOne(new LambdaQueryWrapper<ImGroupInviteDO>()
            .eq(ImGroupInviteDO::getGroupId, groupId)
            .eq(ImGroupInviteDO::getStatus, 1)
            .gt(ImGroupInviteDO::getExpireTime, LocalDateTime.now())
            .orderByDesc(ImGroupInviteDO::getCreateTime)
            .last("LIMIT 1"));
    }
}
```

#### 2.4 创建 VO 类

**请求 VO**：
```java
// AppImGroupInviteGenerateReqVO.java
@Data
public class AppImGroupInviteGenerateReqVO {
    @NotNull(message = "群组ID不能为空")
    private Long groupId;
    
    private Integer expireHours = 24; // 默认24小时
    
    private Integer maxUseCount = 0; // 默认不限制
}

// AppImGroupInviteJoinReqVO.java
@Data
public class AppImGroupInviteJoinReqVO {
    @NotBlank(message = "邀请码不能为空")
    private String inviteCode;
}
```

**响应 VO**：
```java
// AppImGroupInviteRespVO.java
@Data
public class AppImGroupInviteRespVO {
    private String inviteCode;
    private String qrCodeUrl;
    private LocalDateTime expireTime;
    private Integer usedCount;
    private Integer maxUseCount;
}

// AppImGroupInviteVerifyRespVO.java
@Data
public class AppImGroupInviteVerifyRespVO {
    private Boolean valid;
    private Long groupId;
    private String groupName;
    private String groupAvatar;
    private Integer memberCount;
    private Boolean needApproval;
    private LocalDateTime expireTime;
}
```

#### 2.5 实现 Service

**核心方法**：

```java
// 生成邀请码
String generateInviteCode(Long userId, Long groupId, Integer expireHours, Integer maxUseCount);

// 验证邀请码
AppImGroupInviteVerifyRespVO verifyInviteCode(String inviteCode);

// 通过邀请码加入群
void joinGroupByInviteCode(Long userId, String inviteCode);

// 获取群的有效邀请码
AppImGroupInviteRespVO getGroupInviteCode(Long userId, Long groupId);
```

**邀请码生成算法**：

```java
private String generateInviteCode() {
    String prefix = "GRP";
    
    // 时间戳（Base36，6位）
    long timestamp = System.currentTimeMillis() / 1000;
    String timeStr = Long.toString(timestamp, 36).toUpperCase();
    timeStr = timeStr.substring(Math.max(0, timeStr.length() - 6));
    
    // 随机字符串（8位）
    String random = RandomStringUtils.randomAlphanumeric(8).toUpperCase();
    
    // 校验码（2位）
    String data = prefix + timeStr + random;
    int crc = data.hashCode() & 0xFF;
    String checksum = String.format("%02X", crc);
    
    return data + checksum;
}
```

#### 2.6 实现 Controller

**文件位置**：`AppImGroupController.java`

```java
@PostMapping("/invite/generate")
@Operation(summary = "生成群邀请码")
public CommonResult<AppImGroupInviteRespVO> generateInviteCode(
        @Valid @RequestBody AppImGroupInviteGenerateReqVO reqVO) {
    Long userId = SecurityFrameworkUtils.getLoginUserId();
    return success(groupService.generateInviteCode(userId, reqVO));
}

@GetMapping("/invite/verify")
@Operation(summary = "验证邀请码")
public CommonResult<AppImGroupInviteVerifyRespVO> verifyInviteCode(
        @RequestParam("code") String code) {
    return success(groupService.verifyInviteCode(code));
}

@PostMapping("/invite/join")
@Operation(summary = "通过邀请码加入群")
public CommonResult<Boolean> joinByInviteCode(
        @Valid @RequestBody AppImGroupInviteJoinReqVO reqVO) {
    Long userId = SecurityFrameworkUtils.getLoginUserId();
    groupService.joinGroupByInviteCode(userId, reqVO.getInviteCode());
    return success(true);
}

@GetMapping("/invite/get")
@Operation(summary = "获取群的有效邀请码")
public CommonResult<AppImGroupInviteRespVO> getGroupInviteCode(
        @RequestParam("groupId") Long groupId) {
    Long userId = SecurityFrameworkUtils.getLoginUserId();
    return success(groupService.getGroupInviteCode(userId, groupId));
}
```

### Step 3: 前端实现

#### 3.1 创建 API 文件

**文件位置**：`shengyu-ui/shengyu-ui-admin-uniappx/api/group.uts`

```typescript
/**
 * 生成群邀请码
 */
export function generateGroupInvite(data: any): Promise<any> {
  return request({
    url: '/system/im/group/invite/generate',
    method: 'POST',
    data: data
  })
}

/**
 * 验证邀请码
 */
export function verifyInviteCode(code: string): Promise<any> {
  return request({
    url: `/system/im/group/invite/verify?code=${code}`,
    method: 'GET'
  })
}

/**
 * 通过邀请码加入群
 */
export function joinGroupByInvite(code: string): Promise<any> {
  return request({
    url: '/system/im/group/invite/join',
    method: 'POST',
    data: { inviteCode: code }
  })
}

/**
 * 获取群的有效邀请码
 */
export function getGroupInviteCode(groupId: string): Promise<any> {
  return request({
    url: `/system/im/group/invite/get?groupId=${groupId}`,
    method: 'GET'
  })
}
```

#### 3.2 创建群二维码页面

**文件位置**：`shengyu-ui/shengyu-ui-admin-uniappx/pages/message/group-qrcode.uvue`

**核心功能**：
1. 加载群信息和邀请码
2. 生成二维码（使用 uQRCode 库）
3. 保存二维码到相册
4. 分享二维码

**关键代码**：
```typescript
import uQRCode from '@/uni_modules/Sansnn-uQRCode/js_sdk/uqrcode/uqrcode.js'

// 生成二维码
function generateQRCode(url: string) {
  uQRCode.make({
    canvasId: 'qrcode',
    text: url,
    size: 200,
    margin: 10,
    success: (res) => {
      qrCodeImage.value = res
    }
  })
}
```

#### 3.3 创建扫码加入页面

**文件位置**：`shengyu-ui/shengyu-ui-admin-uniappx/pages/message/join-group.uvue`

**核心功能**：
1. 解析邀请码
2. 验证邀请码有效性
3. 显示群信息预览
4. 处理加入逻辑

### Step 4: 测试验证

#### 4.1 单元测试

```java
@Test
public void testGenerateInviteCode() {
    // 测试邀请码生成
    String code = generateInviteCode();
    assertNotNull(code);
    assertTrue(code.startsWith("GRP"));
    assertEquals(19, code.length());
}

@Test
public void testVerifyInviteCode() {
    // 测试邀请码验证
    String code = "GRP1A2B3C4D5E6F7G8H";
    AppImGroupInviteVerifyRespVO result = verifyInviteCode(code);
    assertTrue(result.getValid());
}
```

#### 4.2 集成测试

**测试场景**：
1. ✅ 生成邀请码 → 验证成功
2. ✅ 过期邀请码 → 验证失败
3. ✅ 使用次数达上限 → 验证失败
4. ✅ 已是群成员 → 提示已在群里
5. ✅ 群已满员 → 提示无法加入

#### 4.3 UI 测试

**测试流程**：
1. 打开群设置 → 点击群二维码
2. 查看二维码显示是否正常
3. 保存二维码到相册
4. 扫描二维码 → 验证加入流程

### Step 5: 上线部署

#### 5.1 数据库迁移

```bash
# 生产环境执行
mysql -u root -p shengyu_prod < sql/mysql/1.0/im/ddl_im_tables.sql
```

#### 5.2 配置检查

```yaml
# application.yml
shengyu:
  im:
    group:
      invite:
        default-expire-hours: 24
        max-use-count: 0
        qrcode-base-url: https://app.shengyu.com/group/join
```

#### 5.3 监控配置

```java
// 添加监控指标
@Scheduled(cron = "0 0 * * * ?") // 每小时执行
public void cleanExpiredInvites() {
    int count = groupInviteMapper.updateExpiredInvites();
    log.info("清理过期邀请码: {} 条", count);
}
```

## 注意事项

### 1. 安全性

- ✅ 邀请码必须包含校验码，防止伪造
- ✅ 限制单个用户生成邀请码的频率
- ✅ 监控异常使用行为

### 2. 性能

- ✅ 邀请码查询使用索引
- ✅ 二维码生成考虑缓存
- ✅ 定时清理过期数据

### 3. 用户体验

- ✅ 二维码加载要快
- ✅ 保存图片要流畅
- ✅ 错误提示要友好

## 常见问题

### Q1: 二维码生成失败

**原因**：ZXing 库未正确引入

**解决**：检查 Maven 依赖，确保版本正确

### Q2: 扫码后无法加入

**原因**：邀请码已过期或失效

**解决**：重新生成邀请码

### Q3: 保存图片失败

**原因**：缺少相册权限

**解决**：引导用户授权相册权限

## 后续优化

1. **个性化二维码**：支持自定义样式和颜色
2. **邀请统计**：记录每个邀请码的使用明细
3. **邀请奖励**：邀请达到一定人数给予奖励
4. **分享优化**：支持分享到微信、钉钉等平台

## 参考资料

- [ZXing GitHub](https://github.com/zxing/zxing)
- [uQRCode 文档](https://ext.dcloud.net.cn/plugin?id=1287)
- [微信群二维码](https://weixin.qq.com/)
