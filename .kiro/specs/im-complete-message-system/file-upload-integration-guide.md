# 文件上传服务集成指南

## 概述

本文档说明如何在 IM 消息系统中使用现有的文件上传服务。系统已经提供了完整的文件上传基础设施，包括后端 API、前端工具类和群文件管理功能。

## 现有基础设施

### 1. 后端文件上传 API

#### 1.1 通用文件上传接口

**接口地址**: `/app-api/infra/file/upload`

**Controller**: `AppFileController`

**位置**: `shengyu-module-infra/shengyu-module-infra-biz/src/main/java/com/shengyu/module/infra/controller/app/file/AppFileController.java`

**接口说明**:
```java
@PostMapping("/upload")
@Operation(summary = "上传文件")
public CommonResult<String> uploadFile(AppFileUploadReqVO uploadReqVO) throws Exception
```

**请求参数**:
- `file`: MultipartFile - 文件对象（必填）
- `directory`: String - 文件目录（可选，用于分类存储）

**返回结果**:
```json
{
  "code": 0,
  "msg": "success",
  "data": "https://example.com/path/to/file.jpg"  // 文件访问 URL
}
```

**特性**:
- ✅ 支持所有文件类型（图片、视频、音频、文档等）
- ✅ 自动生成唯一文件名（防止覆盖）
- ✅ 支持按日期分目录存储
- ✅ 自动识别文件 MIME 类型
- ✅ 支持 OSS/本地存储（通过配置切换）
- ✅ 自动记录文件元数据到数据库

#### 1.2 预签名 URL 上传（可选）

**接口地址**: `/app-api/infra/file/presigned-url`

**说明**: 用于前端直接上传到 OSS（七牛云、阿里云等），适用于大文件上传场景。

**使用场景**: 
- 大文件上传（>10MB）
- 需要显示上传进度
- 减轻服务器压力

#### 1.3 群文件专用接口

**Controller**: `AppImGroupFileController`

**位置**: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/AppImGroupFileController.java`

**接口列表**:

1. **上传群文件**
   ```
   POST /app-api/system/im/group/file/upload
   参数: groupId (Long), file (MultipartFile)
   返回: AppImGroupFileRespVO (包含文件信息和群组关联)
   ```

2. **获取群文件列表**
   ```
   GET /app-api/system/im/group/file/list
   参数: groupId (Long), pageNo, pageSize
   返回: PageResult<AppImGroupFileRespVO>
   ```

3. **删除群文件**
   ```
   DELETE /app-api/system/im/group/file/delete
   参数: id (Long)
   返回: Boolean
   ```

4. **记录文件下载**
   ```
   POST /app-api/system/im/group/file/download
   参数: id (Long)
   返回: Boolean
   ```

**特性**:
- ✅ 自动关联群组和文件
- ✅ 支持文件夹分类
- ✅ 记录上传者和上传时间
- ✅ 统计下载次数
- ✅ 支持权限控制（群成员可见）

### 2. 前端上传工具类

**文件位置**: `shengyu-ui/shengyu-ui-admin-uniappx/utils/upload.uts`

**核心方法**:

#### 2.1 通用文件上传

```typescript
/**
 * 上传文件（核心方法）
 * @param filePath 文件路径
 * @param config 上传配置
 * @returns Promise<UploadResult>
 */
export function uploadFile(
  filePath: string,
  config?: UploadConfig
): Promise<UploadResult>
```

**配置参数** (`UploadConfig`):
```typescript
{
  url?: string           // 上传地址（可选，默认使用 /infra/file/upload）
  directory?: string     // 文件目录（如 'im/images', 'im/videos'）
  formData?: UTSJSONObject  // 额外的表单数据
  maxSize?: number       // 最大文件大小（字节）
  showToast?: boolean    // 是否显示错误提示（默认 true）
  onProgress?: (progress: number) => void  // 进度回调
}
```

**返回结果** (`UploadResult`):
```typescript
{
  code: number
  msg: string
  data: {
    url: string        // 文件访问 URL
    path: string       // 文件存储路径
    name: string       // 文件名
    size: number       // 文件大小（字节）
    type: string       // MIME 类型
  }
  tempFilePath?: string  // 临时文件路径
}
```

#### 2.2 选择并上传图片

```typescript
/**
 * 选择并上传图片
 * @param count 最多可选择的图片数量（默认 1）
 * @param config 上传配置（可选）
 * @returns Promise<UploadResult[]>
 */
export function chooseAndUploadImage(
  count: number = 1,
  config?: UploadConfig
): Promise<UploadResult[]>
```

**特性**:
- ✅ 支持相册和相机选择
- ✅ 支持原图和压缩图
- ✅ 自动验证文件大小（默认 10MB）
- ✅ 支持批量上传
- ✅ 显示上传进度

#### 2.3 选择并上传视频

```typescript
/**
 * 选择并上传视频
 * @param config 上传配置（可选）
 * @returns Promise<UploadResult>
 */
export function chooseAndUploadVideo(
  config?: UploadConfig
): Promise<UploadResult>
```

**特性**:
- ✅ 支持相册和相机选择
- ✅ 自动验证文件大小（默认 100MB）
- ✅ 显示上传进度

#### 2.4 选择并上传文件

```typescript
/**
 * 选择并上传文件（支持 H5、Android、iOS）
 * @param accept 接受的文件类型（如 'image/*', '.pdf'）
 * @param config 上传配置（可选）
 * @returns Promise<UploadResult>
 */
export function chooseAndUploadFile(
  accept: string = '*/*',
  config?: UploadConfig
): Promise<UploadResult>
```

**特性**:
- ✅ 跨平台支持（H5、App、小程序）
- ✅ 支持文件类型过滤
- ✅ 自动验证文件大小（默认 100MB）
- ✅ 显示上传进度

#### 2.5 辅助方法

```typescript
// 获取上传 URL
export function getUploadUrl(): string

// 获取上传请求头（包含 token 和 tenant-id）
export function getUploadHeader(): UTSJSONObject
```

### 3. 文件大小限制配置

**配置文件**: `shengyu-ui/shengyu-ui-admin-uniappx/config/app.config.uts`

```typescript
// 文件大小限制（字节）
export const MAX_FILE_SIZE = 100 * 1024 * 1024    // 100MB
export const MAX_IMAGE_SIZE = 10 * 1024 * 1024    // 10MB
export const MAX_VIDEO_SIZE = 100 * 1024 * 1024   // 100MB
```

## 在 IM 消息系统中的使用

### 1. 发送图片消息

```typescript
import { chooseAndUploadImage } from '@/utils/upload.uts'
import { messageService } from '@/services/message-service'

// 选择并上传图片
async function sendImageMessage(conversationId: number) {
  try {
    // 1. 选择并上传图片
    const results = await chooseAndUploadImage(1, {
      directory: 'im/images',  // 指定存储目录
      onProgress: (progress) => {
        console.log('上传进度:', progress + '%')
        // 可以在 UI 上显示进度条
      }
    })
    
    const result = results[0]
    
    // 2. 获取图片信息（需要从本地文件获取尺寸）
    uni.getImageInfo({
      src: result.tempFilePath!,
      success: (info) => {
        // 3. 发送图片消息
        messageService.sendImageMessage(
          null,              // receiverId (单聊)
          conversationId,    // groupId (群聊)
          result.data.url,   // 图片 URL
          info.width,        // 图片宽度
          info.height,       // 图片高度
          result.data.size   // 图片大小
        )
      }
    })
  } catch (e) {
    console.error('发送图片失败:', e)
  }
}
```

### 2. 发送视频消息

```typescript
import { chooseAndUploadVideo } from '@/utils/upload.uts'
import { messageService } from '@/services/message-service'

async function sendVideoMessage(conversationId: number) {
  try {
    // 1. 选择并上传视频
    const result = await chooseAndUploadVideo({
      directory: 'im/videos',
      onProgress: (progress) => {
        console.log('上传进度:', progress + '%')
      }
    })
    
    // 2. 获取视频信息
    uni.getVideoInfo({
      src: result.tempFilePath!,
      success: (info) => {
        // 3. 上传视频封面（可选）
        // TODO: 截取视频第一帧作为封面
        
        // 4. 发送视频消息
        messageService.sendVideoMessage(
          null,
          conversationId,
          result.data.url,   // 视频 URL
          '',                // 封面 URL
          info.duration,     // 视频时长
          info.width,        // 视频宽度
          info.height        // 视频高度
        )
      }
    })
  } catch (e) {
    console.error('发送视频失败:', e)
  }
}
```

### 3. 发送文件消息

```typescript
import { chooseAndUploadFile } from '@/utils/upload.uts'
import { messageService } from '@/services/message-service'

async function sendFileMessage(conversationId: number) {
  try {
    // 1. 选择并上传文件
    const result = await chooseAndUploadFile('*/*', {
      directory: 'im/files',
      onProgress: (progress) => {
        console.log('上传进度:', progress + '%')
      }
    })
    
    // 2. 发送文件消息
    messageService.sendFileMessage(
      null,
      conversationId,
      result.data.url,   // 文件 URL
      result.data.name,  // 文件名
      result.data.size,  // 文件大小
      result.data.type   // 文件类型
    )
  } catch (e) {
    console.error('发送文件失败:', e)
  }
}
```

### 4. 发送语音消息

```typescript
import { uploadFile } from '@/utils/upload.uts'
import { messageService } from '@/services/message-service'

async function sendVoiceMessage(conversationId: number) {
  try {
    // 1. 录制语音（使用 uni.startRecord）
    uni.startRecord({
      success: async (res) => {
        const tempFilePath = res.tempFilePath
        
        // 2. 上传语音文件
        const result = await uploadFile(tempFilePath, {
          directory: 'im/voices'
        })
        
        // 3. 获取语音时长（从录音结果中获取）
        const duration = res.duration || 0
        
        // 4. 发送语音消息
        messageService.sendVoiceMessage(
          null,
          conversationId,
          result.data.url,
          duration
        )
      }
    })
  } catch (e) {
    console.error('发送语音失败:', e)
  }
}
```

### 5. 群文件上传

```typescript
import { uploadFile } from '@/utils/upload.uts'
import { request } from '@/utils/request.uts'

async function uploadGroupFile(groupId: number, filePath: string) {
  try {
    // 使用群文件专用接口
    const formData = {
      groupId: groupId
    }
    
    const result = await uploadFile(filePath, {
      url: '/app-api/system/im/group/file/upload',
      formData: formData
    })
    
    console.log('群文件上传成功:', result)
    return result
  } catch (e) {
    console.error('群文件上传失败:', e)
    throw e
  }
}
```

## 文件存储配置

### 存储类型

系统支持多种文件存储方式，通过后端配置切换：

1. **本地存储** (local)
   - 文件存储在服务器本地磁盘
   - 适用于开发环境和小规模部署
   - 配置简单，无需第三方服务

2. **阿里云 OSS** (aliyun-oss)
   - 文件存储在阿里云对象存储
   - 适用于生产环境
   - 支持 CDN 加速

3. **腾讯云 COS** (tencent-cos)
   - 文件存储在腾讯云对象存储
   - 适用于生产环境
   - 支持 CDN 加速

4. **七牛云** (qiniu)
   - 文件存储在七牛云存储
   - 适用于生产环境
   - 支持 CDN 加速

### 配置方式

文件存储配置由后端 `FileConfigService` 管理，通过数据库配置表动态切换。前端无需关心存储类型，统一调用 `/infra/file/upload` 接口即可。

### 文件目录规范

建议按照以下目录结构组织 IM 文件：

```
im/
├── images/          # 图片消息
├── videos/          # 视频消息
├── voices/          # 语音消息
├── files/           # 文件消息
├── avatars/         # 用户头像
└── group-files/     # 群文件
```

在上传时通过 `directory` 参数指定：

```typescript
const result = await chooseAndUploadImage(1, {
  directory: 'im/images'
})
```

## 最佳实践

### 1. 错误处理

```typescript
try {
  const result = await chooseAndUploadImage(1, {
    directory: 'im/images'
  })
  // 处理成功
} catch (e) {
  // 处理失败
  if (e.message.includes('文件大小')) {
    uni.showToast({
      title: '图片过大，请选择小于 10MB 的图片',
      icon: 'none'
    })
  } else {
    uni.showToast({
      title: '上传失败，请重试',
      icon: 'none'
    })
  }
}
```

### 2. 显示上传进度

```typescript
const uploadProgress = ref(0)

const result = await chooseAndUploadImage(1, {
  directory: 'im/images',
  onProgress: (progress) => {
    uploadProgress.value = progress
  }
})
```

在模板中显示进度条：

```vue
<progress :percent="uploadProgress" show-info />
```

### 3. 文件大小验证

```typescript
// 自定义文件大小限制
const result = await chooseAndUploadImage(1, {
  directory: 'im/images',
  maxSize: 5 * 1024 * 1024  // 限制为 5MB
})
```

### 4. 批量上传

```typescript
// 批量上传图片
const results = await chooseAndUploadImage(9, {
  directory: 'im/images'
})

// 依次发送图片消息
for (const result of results) {
  await messageService.sendImageMessage(
    null,
    conversationId,
    result.data.url,
    0, 0, result.data.size
  )
}
```

### 5. 取消上传（可选扩展）

```typescript
// 保存上传任务引用
let uploadTask: UploadTask | null = null

// 开始上传
uploadTask = uni.uploadFile({
  url: getUploadUrl(),
  filePath: filePath,
  name: 'file',
  // ...
})

// 取消上传
if (uploadTask) {
  uploadTask.abort()
}
```

## 性能优化建议

### 1. 图片压缩

在上传前对图片进行压缩，减少上传时间和存储空间：

```typescript
uni.compressImage({
  src: tempFilePath,
  quality: 80,  // 压缩质量 0-100
  success: async (res) => {
    const result = await uploadFile(res.tempFilePath, {
      directory: 'im/images'
    })
  }
})
```

### 2. 缩略图生成

对于图片消息，可以生成缩略图用于列表显示：

```typescript
// 1. 上传原图
const originalResult = await uploadFile(originalPath, {
  directory: 'im/images/original'
})

// 2. 生成并上传缩略图
const thumbnailResult = await uploadFile(thumbnailPath, {
  directory: 'im/images/thumbnail'
})

// 3. 发送消息时同时包含原图和缩略图 URL
```

### 3. 断点续传（大文件）

对于大文件（>10MB），建议使用预签名 URL 方式直接上传到 OSS，并实现断点续传：

```typescript
// 1. 获取预签名 URL
const presignedUrl = await request({
  url: '/infra/file/presigned-url',
  method: 'GET',
  params: {
    name: fileName,
    directory: 'im/files'
  }
})

// 2. 直接上传到 OSS（支持断点续传）
// 3. 上传完成后调用 /infra/file/create 记录文件信息
```

## 安全注意事项

### 1. 文件类型验证

后端会自动验证文件类型，但前端也应该进行初步验证：

```typescript
const allowedTypes = ['image/jpeg', 'image/png', 'image/gif']
if (!allowedTypes.includes(file.type)) {
  uni.showToast({
    title: '不支持的文件类型',
    icon: 'none'
  })
  return
}
```

### 2. 文件大小限制

严格遵守文件大小限制，避免上传超大文件：

```typescript
const MAX_SIZE = 10 * 1024 * 1024  // 10MB
if (fileSize > MAX_SIZE) {
  uni.showToast({
    title: '文件过大',
    icon: 'none'
  })
  return
}
```

### 3. 敏感信息过滤

上传前检查文件名和内容，避免泄露敏感信息。

## 测试验证

### 1. 功能测试

- ✅ 测试图片上传（JPEG、PNG、GIF）
- ✅ 测试视频上传（MP4、MOV）
- ✅ 测试文件上传（PDF、DOC、XLS）
- ✅ 测试语音上传（AMR、MP3）
- ✅ 测试群文件上传
- ✅ 测试上传进度显示
- ✅ 测试文件大小限制
- ✅ 测试网络异常处理

### 2. 性能测试

- ✅ 测试单个文件上传时间
- ✅ 测试批量文件上传时间
- ✅ 测试大文件上传（>10MB）
- ✅ 测试并发上传

### 3. 兼容性测试

- ✅ 测试 Android 平台
- ✅ 测试 iOS 平台
- ✅ 测试 H5 平台
- ✅ 测试微信小程序

## 常见问题

### Q1: 上传失败，提示"客户端(master) 不能为空"

**原因**: 后端文件存储配置未初始化。

**解决**: 检查后端 `file_config` 表是否有配置记录，确保至少有一个 `master=true` 的配置。

### Q2: 上传成功但无法访问文件

**原因**: 
1. OSS 配置错误（Bucket 权限、域名配置）
2. 本地存储路径配置错误

**解决**: 
1. 检查 OSS 配置是否正确
2. 检查文件是否真实存储
3. 检查返回的 URL 是否可访问

### Q3: 上传进度不显示

**原因**: 未传入 `onProgress` 回调。

**解决**: 在上传配置中添加进度回调：

```typescript
const result = await uploadFile(filePath, {
  onProgress: (progress) => {
    console.log('进度:', progress)
  }
})
```

### Q4: 文件大小限制不生效

**原因**: 
1. 前端限制被绕过
2. 后端限制未配置

**解决**: 
1. 确保使用 `upload.uts` 提供的方法
2. 检查后端 Spring Boot 的 `spring.servlet.multipart.max-file-size` 配置

### Q5: 群文件上传后其他成员看不到

**原因**: 
1. 未调用群文件专用接口
2. 权限配置错误

**解决**: 
1. 使用 `/system/im/group/file/upload` 接口
2. 确保用户是群成员

## 总结

现有的文件上传服务已经提供了完整的功能，包括：

✅ **后端 API**: 通用文件上传、群文件管理
✅ **前端工具**: 图片、视频、文件上传封装
✅ **存储支持**: 本地存储、OSS、COS、七牛云
✅ **功能特性**: 进度显示、大小限制、类型验证
✅ **跨平台**: Android、iOS、H5、小程序

在 IM 消息系统中，只需要：

1. 导入 `upload.uts` 工具类
2. 调用对应的上传方法
3. 获取文件 URL 后发送消息

无需重新实现文件上传逻辑，直接使用现有基础设施即可。

## 相关文件

- 后端文件上传 API: `shengyu-module-infra/shengyu-module-infra-biz/src/main/java/com/shengyu/module/infra/controller/app/file/AppFileController.java`
- 后端群文件 API: `shengyu-module-system/shengyu-module-system-biz/src/main/java/com/shengyu/module/system/controller/app/im/AppImGroupFileController.java`
- 前端上传工具: `shengyu-ui/shengyu-ui-admin-uniappx/utils/upload.uts`
- 配置文件: `shengyu-ui/shengyu-ui-admin-uniappx/config/app.config.uts`
