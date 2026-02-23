# IM 群文件和聊天记录功能设计

> **文档版本**: v1.0  
> **创建日期**: 2026-02-23  
> **项目**: 圣钰 SaaS Pro - IM 即时通讯系统  
> **设计原则**: 复用平台统一文件管理系统，避免重复造轮子

---

## 1. 群文件功能设计

### 1.1 设计原则

1. **复用平台文件系统**: 不重复实现文件存储逻辑，直接使用 `infra_file` 表
2. **关联表管理**: 创建 `im_group_file` 表存储群组与文件的关联关系
3. **目录规范**: 文件统一存储在 `im/group/{groupId}/` 目录下
4. **权限控制**: 只有群成员可以查看和下载群文件
5. **简化设计**: 初期不实现文件夹功能，所有文件平铺显示

### 1.2 数据库设计

#### 1.2.1 im_group_file 表（群文件关联表）

```sql
CREATE TABLE `im_group_file` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `group_id` bigint NOT NULL COMMENT '群组ID',
  `file_id` bigint NOT NULL COMMENT '文件ID(关联 infra_file.id)',
  `uploader_id` bigint NOT NULL COMMENT '上传者ID',
  `folder_id` bigint DEFAULT 0 COMMENT '文件夹ID(0表示根目录，预留字段)',
  `is_favorite` bit(1) DEFAULT b'0' COMMENT '是否收藏',
  `download_count` int DEFAULT 0 COMMENT '下载次数',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  `tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_file_deleted` (`group_id`, `file_id`, `tenant_id`, `deleted`),
  KEY `idx_group` (`group_id`, `tenant_id`),
  KEY `idx_uploader` (`uploader_id`),
  KEY `idx_tenant` (`tenant_id`)
) ENGINE=InnoDB COMMENT='IM群文件关联表';
```

**字段说明**:
- `group_id`: 群组ID
- `file_id`: 关联 `infra_file.id`，实际文件存储在平台文件表中
- `uploader_id`: 上传者用户ID
- `folder_id`: 预留字段，用于未来支持文件夹功能
- `is_favorite`: 是否收藏（用户级别的收藏功能可后续扩展）
- `download_count`: 下载统计


#### 1.2.2 复用 infra_file 表

平台已有的文件表结构：
```sql
CREATE TABLE `infra_file` (
  `id` bigint NOT NULL COMMENT '编号',
  `config_id` bigint NOT NULL COMMENT '配置编号',
  `name` varchar(256) NOT NULL COMMENT '原文件名',
  `path` varchar(512) NOT NULL COMMENT '路径',
  `url` varchar(1024) NOT NULL COMMENT '访问地址',
  `type` varchar(128) COMMENT '文件的 MIME 类型',
  `size` int NOT NULL COMMENT '文件大小(字节)',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB COMMENT='文件表';
```

**群文件存储规范**:
- 目录路径: `im/group/{groupId}/`
- 文件命名: 保持原文件名，由平台文件服务自动处理重名
- 示例: `im/group/123/会议纪要.docx`

### 1.3 后端 API 设计

#### 1.3.1 Controller 接口

文件路径: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/AppImGroupFileController.java`

```java
@RestController
@RequestMapping("/system/im/group/file")
@Tag(name = "移动端 - IM 群文件")
public class AppImGroupFileController {
    
    @Resource
    private ImGroupFileService groupFileService;
    
    @Resource
    private FileService fileService;
    
    /**
     * 上传群文件
     */
    @PostMapping("/upload")
    @Operation(summary = "上传群文件")
    public CommonResult<AppImGroupFileRespVO> uploadFile(
            @RequestParam("groupId") Long groupId,
            @RequestParam("file") MultipartFile file) throws Exception {
        return success(groupFileService.uploadFile(groupId, file));
    }
    
    /**
     * 获取群文件列表
     */
    @GetMapping("/list")
    @Operation(summary = "获取群文件列表")
    public CommonResult<PageResult<AppImGroupFileRespVO>> getFileList(
            @Valid AppImGroupFilePageReqVO pageReqVO) {
        return success(groupFileService.getFileList(pageReqVO));
    }
    
    /**
     * 删除群文件
     */
    @DeleteMapping("/delete")
    @Operation(summary = "删除群文件")
    public CommonResult<Boolean> deleteFile(@RequestParam("id") Long id) {
        groupFileService.deleteFile(id);
        return success(true);
    }
    
    /**
     * 下载群文件（增加下载次数）
     */
    @PostMapping("/download")
    @Operation(summary = "记录文件下载")
    public CommonResult<Boolean> downloadFile(@RequestParam("id") Long id) {
        groupFileService.incrementDownloadCount(id);
        return success(true);
    }
}
```


#### 1.3.2 Service 接口

```java
public interface ImGroupFileService {
    
    /**
     * 上传群文件
     */
    AppImGroupFileRespVO uploadFile(Long groupId, MultipartFile file) throws Exception;
    
    /**
     * 获取群文件列表（分页）
     */
    PageResult<AppImGroupFileRespVO> getFileList(AppImGroupFilePageReqVO pageReqVO);
    
    /**
     * 删除群文件
     */
    void deleteFile(Long id);
    
    /**
     * 增加下载次数
     */
    void incrementDownloadCount(Long id);
}
```

#### 1.3.3 VO 对象

**请求 VO**:
```java
@Data
public class AppImGroupFilePageReqVO extends PageParam {
    @NotNull(message = "群组ID不能为空")
    private Long groupId;
    
    private String fileName;  // 文件名搜索（可选）
    private String fileType;  // 文件类型过滤（可选）
}
```

**响应 VO**:
```java
@Data
public class AppImGroupFileRespVO {
    private Long id;
    private Long groupId;
    private Long fileId;
    private Long uploaderId;
    private String uploaderName;
    
    // 文件信息（来自 infra_file）
    private String fileName;
    private String fileUrl;
    private String fileType;
    private Integer fileSize;
    
    private Integer downloadCount;
    private LocalDateTime createTime;
}
```

### 1.4 前端实现

#### 1.4.1 API 封装

文件路径: `shengyu-ui/shengyu-ui-admin-uniappx/api/file.uts`

```typescript
import { request } from '../utils/request.uts'

/**
 * 上传群文件
 */
export function uploadGroupFile(groupId: number, filePath: string) {
  return request({
    url: '/system/im/group/file/upload',
    method: 'POST',
    formData: {
      groupId: groupId,
      file: filePath
    }
  })
}

/**
 * 获取群文件列表
 */
export function getGroupFileList(params: any) {
  return request({
    url: '/system/im/group/file/list',
    method: 'GET',
    params: params
  })
}

/**
 * 删除群文件
 */
export function deleteGroupFile(id: number) {
  return request({
    url: '/system/im/group/file/delete',
    method: 'DELETE',
    params: { id }
  })
}

/**
 * 记录文件下载
 */
export function downloadGroupFile(id: number) {
  return request({
    url: '/system/im/group/file/download',
    method: 'POST',
    params: { id }
  })
}
```


#### 1.4.2 页面更新

文件路径: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat-files.uvue`

**需要修改的部分**:
1. 将模拟数据替换为真实 API 调用
2. 实现文件上传功能（调用平台文件上传接口）
3. 实现文件下载功能（调用平台文件下载接口）
4. 实现文件删除功能（只有上传者和群主可删除）

**核心逻辑**:
```typescript
// 加载文件列表
async function loadFiles() {
  try {
    loading.value = true
    const result = await getGroupFileList({
      groupId: groupId.value,
      pageNo: 1,
      pageSize: 100
    })
    
    // 按日期分组
    const grouped = groupFilesByDate(result.list)
    fileGroups.value = grouped
  } catch (e) {
    console.error('[ChatFiles] 加载文件列表失败:', e)
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

// 上传文件
async function handleUploadFile() {
  uni.chooseFile({
    count: 1,
    success: async (res) => {
      const filePath = res.tempFilePaths[0]
      
      try {
        uni.showLoading({ title: '上传中...' })
        await uploadGroupFile(groupId.value, filePath)
        uni.showToast({ title: '上传成功', icon: 'success' })
        await loadFiles()  // 刷新列表
      } catch (e) {
        console.error('[ChatFiles] 上传失败:', e)
        uni.showToast({ title: '上传失败', icon: 'none' })
      } finally {
        uni.hideLoading()
      }
    }
  })
}

// 下载文件
async function handleFileClick(file: any) {
  try {
    // 记录下载次数
    await downloadGroupFile(file.id)
    
    // 下载文件
    uni.downloadFile({
      url: file.url,
      success: (res) => {
        if (res.statusCode === 200) {
          uni.showToast({ title: '下载成功', icon: 'success' })
          // 可以打开文件预览
          uni.openDocument({
            filePath: res.tempFilePath,
            showMenu: true
          })
        }
      }
    })
  } catch (e) {
    console.error('[ChatFiles] 下载失败:', e)
    uni.showToast({ title: '下载失败', icon: 'none' })
  }
}
```


---

## 2. 聊天记录功能设计

### 2.1 设计原则

1. **复用消息表**: 直接查询 `im_message` 表，无需额外存储
2. **按时间分页**: 支持向上加载更多历史消息
3. **搜索功能**: 支持按关键词搜索消息内容
4. **导出功能**: 支持导出聊天记录为文本文件（可选）

### 2.2 后端 API 设计

#### 2.2.1 Controller 接口

文件路径: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/AppImMessageController.java`

**新增接口**:
```java
/**
 * 搜索聊天记录
 */
@GetMapping("/search")
@Operation(summary = "搜索聊天记录")
public CommonResult<PageResult<AppImMessageRespVO>> searchMessages(
        @Valid AppImMessageSearchReqVO searchReqVO) {
    return success(messageService.searchMessages(searchReqVO));
}

/**
 * 导出聊天记录
 */
@GetMapping("/export")
@Operation(summary = "导出聊天记录")
public void exportMessages(
        @RequestParam("conversationId") Long conversationId,
        @RequestParam(value = "startTime", required = false) LocalDateTime startTime,
        @RequestParam(value = "endTime", required = false) LocalDateTime endTime,
        HttpServletResponse response) throws Exception {
    messageService.exportMessages(conversationId, startTime, endTime, response);
}
```

#### 2.2.2 请求 VO

```java
@Data
public class AppImMessageSearchReqVO extends PageParam {
    @NotNull(message = "会话ID不能为空")
    private Long conversationId;
    
    @NotBlank(message = "搜索关键词不能为空")
    private String keyword;
    
    private LocalDateTime startTime;  // 开始时间（可选）
    private LocalDateTime endTime;    // 结束时间（可选）
}
```

#### 2.2.3 Service 实现

```java
@Override
public PageResult<AppImMessageRespVO> searchMessages(AppImMessageSearchReqVO searchReqVO) {
    // 1. 验证权限：用户必须是会话参与者
    ImConversationDO conversation = conversationMapper.selectById(searchReqVO.getConversationId());
    if (conversation == null || !conversation.getUserId().equals(getLoginUserId())) {
        throw exception(CONVERSATION_NOT_EXISTS);
    }
    
    // 2. 构建查询条件
    LambdaQueryWrapper<ImMessageDO> wrapper = new LambdaQueryWrapper<>();
    wrapper.and(w -> {
        // 单聊：发送者或接收者是当前用户
        if (conversation.getConversationType() == 1) {
            w.eq(ImMessageDO::getSenderId, getLoginUserId())
             .or()
             .eq(ImMessageDO::getReceiverId, getLoginUserId());
        }
        // 群聊：群组ID匹配
        else {
            w.eq(ImMessageDO::getGroupId, conversation.getTargetId());
        }
    });
    
    // 3. 关键词搜索（模糊匹配）
    wrapper.like(ImMessageDO::getContent, searchReqVO.getKeyword());
    
    // 4. 时间范围
    if (searchReqVO.getStartTime() != null) {
        wrapper.ge(ImMessageDO::getCreateTime, searchReqVO.getStartTime());
    }
    if (searchReqVO.getEndTime() != null) {
        wrapper.le(ImMessageDO::getCreateTime, searchReqVO.getEndTime());
    }
    
    // 5. 排序：按时间倒序
    wrapper.orderByDesc(ImMessageDO::getCreateTime);
    
    // 6. 分页查询
    Page<ImMessageDO> page = messageMapper.selectPage(
        new Page<>(searchReqVO.getPageNo(), searchReqVO.getPageSize()), 
        wrapper
    );
    
    return new PageResult<>(
        BeanUtils.toBean(page.getRecords(), AppImMessageRespVO.class),
        page.getTotal()
    );
}
```


### 2.3 前端实现

#### 2.3.1 API 封装

文件路径: `shengyu-ui/shengyu-ui-admin-uniappx/api/message.uts`

```typescript
/**
 * 搜索聊天记录
 */
export function searchMessages(params: any) {
  return request({
    url: '/system/im/message/search',
    method: 'GET',
    params: params
  })
}

/**
 * 导出聊天记录
 */
export function exportMessages(conversationId: number, startTime?: string, endTime?: string) {
  return request({
    url: '/system/im/message/export',
    method: 'GET',
    params: {
      conversationId,
      startTime,
      endTime
    },
    responseType: 'blob'  // 文件下载
  })
}
```

#### 2.3.2 页面实现

文件路径: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat-history.uvue`

**页面功能**:
1. 显示聊天记录列表（按时间倒序）
2. 支持关键词搜索
3. 支持时间范围筛选
4. 点击消息跳转到聊天页面对应位置
5. 支持导出聊天记录

**核心代码**:
```typescript
<template>
  <view class="page">
    <!-- 搜索栏 -->
    <view class="search-bar">
      <input 
        class="search-input" 
        v-model="keyword" 
        placeholder="搜索聊天记录"
        @confirm="handleSearch"
      />
      <view class="filter-btn" @click="showFilterDialog = true">
        <text class="iconfont">&#xe60c;</text>
      </view>
    </view>
    
    <!-- 消息列表 -->
    <scroll-view class="message-list" scroll-y @scrolltolower="loadMore">
      <view class="message-item" 
        v-for="msg in messages" 
        :key="msg.id"
        @click="handleMessageClick(msg)">
        <view class="message-time">{{ formatTime(msg.createTime) }}</view>
        <view class="message-sender">{{ msg.senderName }}</view>
        <view class="message-content">{{ msg.content }}</view>
      </view>
    </scroll-view>
    
    <!-- 筛选弹窗 -->
    <view v-if="showFilterDialog" class="filter-dialog">
      <!-- 时间范围选择 -->
      <picker mode="date" @change="handleStartTimeChange">
        <view class="picker-item">开始时间: {{ startTime || '不限' }}</view>
      </picker>
      <picker mode="date" @change="handleEndTimeChange">
        <view class="picker-item">结束时间: {{ endTime || '不限' }}</view>
      </picker>
      
      <view class="dialog-actions">
        <button @click="handleResetFilter">重置</button>
        <button @click="handleApplyFilter">确定</button>
      </view>
    </view>
  </view>
</template>

<script setup lang="uts">
import { searchMessages } from '../../api/message.uts'

const conversationId = ref('')
const keyword = ref('')
const startTime = ref('')
const endTime = ref('')
const messages = ref<any[]>([])
const pageNo = ref(1)
const pageSize = ref(20)
const hasMore = ref(true)
const loading = ref(false)
const showFilterDialog = ref(false)

// 搜索消息
async function handleSearch() {
  pageNo.value = 1
  messages.value = []
  await loadMessages()
}

// 加载消息
async function loadMessages() {
  if (loading.value || !hasMore.value) return
  
  try {
    loading.value = true
    const result = await searchMessages({
      conversationId: conversationId.value,
      keyword: keyword.value,
      startTime: startTime.value,
      endTime: endTime.value,
      pageNo: pageNo.value,
      pageSize: pageSize.value
    })
    
    if (result.list && result.list.length > 0) {
      messages.value.push(...result.list)
      hasMore.value = result.list.length === pageSize.value
    } else {
      hasMore.value = false
    }
  } catch (e) {
    console.error('[ChatHistory] 加载失败:', e)
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

// 加载更多
function loadMore() {
  if (hasMore.value && !loading.value) {
    pageNo.value++
    loadMessages()
  }
}

// 点击消息，跳转到聊天页面
function handleMessageClick(msg: any) {
  uni.navigateTo({
    url: `/pages/message/chat?conversationId=${conversationId.value}&messageId=${msg.id}`
  })
}

onLoad((options: any) => {
  if (options['conversationId']) {
    conversationId.value = options['conversationId']
    loadMessages()
  }
})
</script>
```


---

## 3. 实施计划

### 3.1 群文件功能实施步骤

#### 阶段1: 数据库准备
- [x] 创建 `im_group_file` 表结构
- [ ] 执行 DDL 脚本创建表

#### 阶段2: 后端开发
- [ ] 创建 `ImGroupFileDO` 实体类
- [ ] 创建 `ImGroupFileMapper` 接口
- [ ] 创建 `ImGroupFileService` 接口和实现类
- [ ] 创建 `AppImGroupFileController` 控制器
- [ ] 创建 VO 对象（Request/Response）
- [ ] 实现文件上传逻辑（复用 FileService）
- [ ] 实现文件列表查询（分页）
- [ ] 实现文件删除逻辑
- [ ] 实现下载统计功能

#### 阶段3: 前端开发
- [ ] 创建 `api/file.uts` API 封装
- [ ] 更新 `chat-files.uvue` 页面
- [ ] 实现文件上传功能
- [ ] 实现文件列表加载
- [ ] 实现文件下载功能
- [ ] 实现文件删除功能
- [ ] 实现文件预览功能

#### 阶段4: 测试
- [ ] 单元测试
- [ ] 接口测试
- [ ] 前后端联调
- [ ] 权限测试（只有群成员可访问）
- [ ] 性能测试（大文件上传）

### 3.2 聊天记录功能实施步骤

#### 阶段1: 后端开发
- [ ] 在 `AppImMessageController` 添加搜索接口
- [ ] 在 `ImMessageService` 实现搜索逻辑
- [ ] 实现导出功能（可选）
- [ ] 创建搜索请求 VO

#### 阶段2: 前端开发
- [ ] 创建 `pages/message/chat-history.uvue` 页面
- [ ] 在 `api/message.uts` 添加搜索接口
- [ ] 实现搜索功能
- [ ] 实现时间筛选
- [ ] 实现消息跳转
- [ ] 在 `group-settings.uvue` 添加入口

#### 阶段3: 测试
- [ ] 搜索功能测试
- [ ] 分页加载测试
- [ ] 时间筛选测试
- [ ] 性能测试（大量消息）

---

## 4. 技术要点

### 4.1 文件上传流程

```
移动端                    System Module              Infra Module
  │                            │                          │
  │ 1. 选择文件                │                          │
  │                            │                          │
  │ 2. 调用上传接口            │                          │
  │──────────────────────────>│                          │
  │                            │ 3. 调用 FileService      │
  │                            │    上传文件              │
  │                            │────────────────────────>│
  │                            │                          │
  │                            │                          │ 4. 保存到 infra_file
  │                            │                          │    返回 fileId
  │                            │                          │
  │                            │ 5. 创建群文件关联        │
  │                            │    保存到 im_group_file  │
  │                            │                          │
  │ 6. 返回文件信息            │                          │
  │<──────────────────────────│                          │
```

### 4.2 权限控制

**群文件权限**:
- 查看: 只有群成员可以查看群文件列表
- 上传: 所有群成员都可以上传文件
- 删除: 只有文件上传者和群主可以删除文件
- 下载: 所有群成员都可以下载文件

**实现方式**:
```java
// 在 Service 层验证权限
private void validateGroupMember(Long groupId, Long userId) {
    ImGroupUserDO groupUser = groupUserMapper.selectOne(
        new LambdaQueryWrapper<ImGroupUserDO>()
            .eq(ImGroupUserDO::getGroupId, groupId)
            .eq(ImGroupUserDO::getUserId, userId)
            .eq(ImGroupUserDO::getDeleted, false)
    );
    
    if (groupUser == null) {
        throw exception(NOT_GROUP_MEMBER);
    }
}

// 删除权限验证
private void validateDeletePermission(ImGroupFileDO groupFile, Long userId) {
    // 文件上传者可以删除
    if (groupFile.getUploaderId().equals(userId)) {
        return;
    }
    
    // 群主可以删除
    ImGroupUserDO groupUser = groupUserMapper.selectOne(
        new LambdaQueryWrapper<ImGroupUserDO>()
            .eq(ImGroupUserDO::getGroupId, groupFile.getGroupId())
            .eq(ImGroupUserDO::getUserId, userId)
            .eq(ImGroupUserDO::getRole, 2)  // 2-群主
            .eq(ImGroupUserDO::getDeleted, false)
    );
    
    if (groupUser == null) {
        throw exception(NO_PERMISSION_TO_DELETE);
    }
}
```

### 4.3 文件类型识别

```typescript
// 根据文件扩展名识别文件类型
function getFileType(fileName: string): string {
  const ext = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
  
  const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
  const videoExts = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv']
  const audioExts = ['mp3', 'wav', 'wma', 'ogg', 'aac']
  const docExts = ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'pdf', 'txt']
  const zipExts = ['zip', 'rar', '7z', 'tar', 'gz']
  
  if (imageExts.includes(ext)) return 'image'
  if (videoExts.includes(ext)) return 'video'
  if (audioExts.includes(ext)) return 'audio'
  if (docExts.includes(ext)) return 'document'
  if (zipExts.includes(ext)) return 'archive'
  
  return 'other'
}
```

---

## 5. 注意事项

1. **文件大小限制**: 建议限制单个文件大小不超过 100MB
2. **存储空间管理**: 定期清理已删除的文件，释放存储空间
3. **文件安全**: 上传文件需要进行病毒扫描（可选）
4. **并发控制**: 文件上传时需要考虑并发问题
5. **性能优化**: 大文件上传建议使用分片上传
6. **搜索性能**: 聊天记录搜索建议添加全文索引（MySQL 5.7+）

---

## 6. 后续优化方向

1. **文件夹功能**: 支持创建文件夹，分类管理文件
2. **文件预览**: 支持在线预览图片、PDF、Office 文档
3. **文件分享**: 支持将群文件分享到其他群或联系人
4. **文件收藏**: 支持用户收藏常用文件
5. **文件版本**: 支持文件版本管理（同名文件覆盖时保留历史版本）
6. **全文搜索**: 使用 Elasticsearch 实现更强大的搜索功能
7. **聊天记录导出**: 支持导出为 PDF、Word 等格式
8. **消息统计**: 统计聊天记录的消息数量、活跃时间等

