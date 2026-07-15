# IM 视频上传优化调研文档

> **文档状态**：✅ 所有推荐方案及视频压缩优化已实施完成（2026-07-14）
> 
> **已完成工作**：
> - ✅ 阶段一：修复 `fileId` 传递问题
> - ✅ 阶段二：扩展 `LocalFileClient` 支持分片上传
> - ✅ 阶段三：实现预签名 URL 直传（S3/MinIO）
> - ✅ 阶段四：实现视频压缩优化（对标微信/钉钉）
> - ✅ 三层上传策略已集成到 `ChatUploadCoordinator`

## 1. 问题描述

**现象**：视频拍摄大于 10 秒时发送失败

**初步分析**：
- 10 秒视频文件大小通常在 10-30MB 之间
- 当前代码中分片上传阈值为 10MB（`_multipartThreshold = 10 * 1024 * 1024`）
- 超过 10MB 的文件会触发分片上传逻辑
- 怀疑分片上传实现存在问题

## 2. 当前上传流程分析

### 2.1 Flutter 端上传流程

**文件路径**：`lib/features/im/chat/application/coordinators/chat_upload_coordinator.dart`

**关键代码**：
```dart
/// 分片上传阈值（10MB）
static const int _multipartThreshold = 10 * 1024 * 1024;

/// 执行实际上传（根据文件大小选择普通上传或分片上传）
Future<UploadResult> _doUpload({
  required UploadTask task,
  required ChatUploadInput input,
  required bool useMultipart,
  required void Function(int progress, String retryLabel) onProgress,
  required int lastRetryAttempt,
}) async {
  if (useMultipart) {
    return _doMultipartUpload(
      task: task,
      input: input,
      onProgress: (progress) =>
          onProgress((progress * 100).toInt(), retryLabel),
    );
  }

  return _uploadChatAssetUseCase.execute(
    taskId: task.taskId,
    input: input,
    onProgress: (sent, total) {
      final percent = total > 0 ? ((sent * 100) ~/ total) : 0;
      onProgress(percent, retryLabel);
    },
  );
}
```

**分片上传实现**：
```dart
Future<UploadResult> _doMultipartUpload({
  required UploadTask task,
  required ChatUploadInput input,
  required void Function(double progress) onProgress,
}) async {
  final directory = UploadDirectoryResolver.resolve(
    purpose: input.purpose,
    scope: input.scope,
  ).value;

  final file = File(input.localUri);
  final url = await _multipartUploadUseCase!.execute(
    file: file,
    directory: directory,
    onProgress: onProgress,
  );

  // 将分片上传结果包装为 UploadResult，以与普通上传保持一致
  return UploadResult(
    taskId: task.taskId,
    purpose: input.purpose,
    scope: input.scope,
    file: UploadedFile(
      fileId: '', // ⚠️ 问题：分片上传暂时无法获取 fileId
      url: url,
      name: input.displayName,
      size: input.fileSize,
      mimeType: input.mimeType,
    ),
  );
}
```

### 2.2 Web 端上传实现

**文件路径**：`shengyu-ui/shengyu-ui-admin-vue3/src/components/UploadFile/src/useUpload.ts`

**关键代码**：
```typescript
export const useUpload = (directory?: string) => {
  const uploadUrl = getUploadUrl()
  const isClientUpload = UPLOAD_TYPE.CLIENT === import.meta.env.VITE_UPLOAD_TYPE
  
  const httpRequest = async (options: UploadRequestOptions) => {
    const uploadProgressHandler = (evt: AxiosProgressEvent) => {
      const upEvt: UploadProgressEvent = Object.assign(evt.event)
      upEvt.percent = evt.progress ? evt.progress * 100 : 0
      options.onProgress(upEvt)
    }

    // 模式一：前端上传（客户端直连 S3）
    if (isClientUpload) {
      const fileName = options.file.name || options.filename
      const presignedInfo = await FileApi.getFilePresignedUrl(fileName, directory)
      return axios
        .put(presignedInfo.uploadUrl, options.file, {
          headers: {
            'Content-Type': options.file.type || 'application/octet-stream'
          },
          onUploadProgress: uploadProgressHandler
        })
        .then(() => {
          createFile(presignedInfo, options.file, fileName)
          return { data: presignedInfo.url }
        })
    } else {
      // 模式二：后端上传
      return new Promise((resolve, reject) => {
        FileApi.updateFile({ file: options.file, directory }, uploadProgressHandler)
          .then((res) => {
            if (res.code === 0) {
              resolve(res)
            } else {
              reject(res)
            }
          })
          .catch((res) => {
            reject(res)
          })
      })
    }
  }

  return {
    uploadUrl,
    httpRequest
  }
}
```

**结论**：Web 端使用的是**单文件上传**，没有实现分片上传。

## 3. 根因分析

### 3.1 发现的问题

1. **分片上传返回的 fileId 为空**
   - 代码注释明确说明：`fileId: '', // 分片上传暂时无法获取 fileId`
   - 这会导致后续发送消息时无法正确关联文件

2. **分片上传逻辑可能不完整**
   - 需要检查 `MultipartUploadUseCase` 的实现
   - 可能缺少分片合并、错误处理等关键逻辑

3. **后端接口支持情况未知**
   - AppConfig 中定义了分片上传相关接口路径：
     ```dart
     static const String fileMultipartUploadInitPath = '/infra/file/upload-init';
     static const String fileMultipartUploadChunkPath = '/infra/file/upload-chunk';
     static const String fileMultipartUploadMergePath = '/infra/file/upload-merge';
     static const String fileMultipartUploadAbortPath = '/infra/file/upload-abort';
     static const String fileMultipartUploadStatusPath = '/infra/file/upload-status';
     ```
   - 需要验证后端是否已实现这些接口

### 3.2 可能的失败原因

**场景 1：分片上传接口未实现**
- 后端可能只实现了普通上传接口
- 调用分片上传接口时返回 404 或 500 错误

**场景 2：分片上传逻辑错误**
- 分片大小计算错误
- 分片顺序错乱
- 分片合并失败

**场景 3：fileId 为空导致消息发送失败**
- 上传成功但返回的 fileId 为空
- 发送消息时后端校验失败

## 4. Web 端大文件上传方案调研

### 4.1 方案一：单文件上传（当前实现）

**优点**：
- 实现简单，维护成本低
- 适合小文件上传（< 10MB）

**缺点**：
- 大文件上传容易超时
- 无法断点续传
- 内存占用高（需要一次性加载整个文件）

**适用场景**：
- 文件大小 < 10MB
- 网络环境稳定

### 4.2 方案二：分片上传（推荐）

**实现原理**：
1. 客户端将大文件切分为多个固定大小的分片（如 5MB/片）
2. 逐个上传分片到服务器
3. 所有分片上传完成后，调用合并接口
4. 服务器合并分片，返回文件 URL

**优点**：
- 支持断点续传
- 降低单次请求的内存占用
- 可以并行上传多个分片，提升速度
- 失败重试成本低（只需重传失败的分片）

**缺点**：
- 实现复杂度高
- 需要后端支持分片合并
- 需要额外的状态管理

**适用场景**：
- 文件大小 > 10MB
- 网络环境不稳定
- 需要断点续传功能

**参考实现**：
```typescript
// 前端分片上传伪代码
async function uploadLargeFile(file: File, chunkSize = 5 * 1024 * 1024) {
  const totalChunks = Math.ceil(file.size / chunkSize);
  const fileId = await initUpload(file.name, file.size, totalChunks);
  
  const uploadPromises = [];
  for (let i = 0; i < totalChunks; i++) {
    const start = i * chunkSize;
    const end = Math.min(start + chunkSize, file.size);
    const chunk = file.slice(start, end);
    
    uploadPromises.push(
      uploadChunk(fileId, i, chunk)
    );
  }
  
  await Promise.all(uploadPromises);
  const result = await mergeChunks(fileId);
  return result.url;
}
```

### 4.3 方案三：预签名 URL 直传 S3（最优）

**实现原理**：
1. 客户端向后端请求预签名上传 URL
2. 客户端直接使用预签名 URL 上传文件到 S3/OSS
3. 上传完成后，将文件信息记录到后端

**优点**：
- 减轻服务器带宽压力
- 上传速度快（直连云存储）
- 实现相对简单
- 天然支持大文件

**缺点**：
- 依赖云存储服务（S3/OSS/Minio）
- 需要配置 CORS
- 预签名 URL 有过期时间

**适用场景**：
- 使用云存储服务
- 需要上传大文件
- 服务器带宽有限

**当前项目支持情况**：
- Web 端已实现（见 `useUpload.ts`）
- Flutter 端需要实现

## 5. 优化建议

### 5.1 短期方案（快速修复） ✅ 已完成

**方案**：修复 `fileId` 传递问题

**状态**：✅ 已完成（2026-07-14）

**实际修改**：
1. `MultipartUploadUseCase.execute()` 返回 `MergeResult`（包含 `fileId`）
2. `ChatUploadCoordinator._doMultipartUpload()` 使用 `mergeResult.fileId`

### 5.2 中期方案（推荐） ✅ 已完成

**方案**：实现完整的分片上传功能

**状态**：✅ 已完成（2026-07-14）

**实施步骤**：

1. ✅ **验证后端接口**
   - 后端分片上传接口已完整实现

2. ✅ **修复 Flutter 端分片上传逻辑**
   - `MultipartUploadUseCase` 已修复，返回 `MergeResult`
   - `fileId` 传递问题已解决

3. ✅ **添加上传进度条**
   - 已实现进度回调

4. ✅ **添加重试机制**
   - 已实现指数退避重试
   - 已支持断点续传

5. ✅ **扩展 LocalFileClient**
   - 已实现分片上传方法（2026-07-14）

### 5.3 长期方案（最优） ✅ 已完成

**方案**：实现预签名 URL 直传 S3

**状态**：✅ 已完成（2026-07-14）

**实施步骤**：

1. ✅ **后端实现预签名 URL 接口**
   - `GET /infra/file/presigned-url`：获取预签名上传 URL
   - `POST /infra/file/create`：创建文件记录

2. ✅ **Flutter 端实现直传逻辑**
   - 新增 `PresignedUrlUploadUseCase`
   - 新增 `FileHttpDataSource`
   - 新增 DTO：`PresignedUrlResponseDto`、`FileCreateRequestDto`
   - 集成到 `ChatUploadCoordinator`：三层上传策略（预签名 > 分片 > 普通）

3. ✅ **添加视频压缩**（已完成，2026-07-14）
   - 视频上传前进行压缩（降低分辨率/码率）
   - 压缩策略：720p 分辨率、2Mbps 比特率、30fps、medium 质量
   - 压缩阈值：20MB（超过此大小的视频才进行压缩）
   - 压缩失败时降级使用原始文件
   - 支持实时进度回调
   - 临时文件自动清理

## 6. 实施计划

### 阶段 1：问题排查（优先级：高） ✅ 已完成

**目标**：确认视频发送失败的根本原因

**状态**：✅ 已完成（2026-07-14）

**任务**：
1. ✅ 检查后端分片上传接口是否已实现
2. ✅ 查看 `MultipartUploadUseCase` 的完整实现
3. ✅ 在测试环境复现问题，查看错误日志
4. ✅ 验证是否是 fileId 为空导致的问题

**实际工作量**：已完成

### 阶段 2：快速修复（优先级：高） ✅ 已完成

**目标**：修复 `fileId` 传递问题

**状态**：✅ 已完成（2026-07-14）

**任务**：
1. ✅ 修复 `MultipartUploadUseCase` 返回值（返回 `MergeResult`）
2. ✅ 修复 `ChatUploadCoordinator._doMultipartUpload()` 使用 `mergeResult.fileId`

**实际工作量**：已完成

### 阶段 3：完整实现（优先级：中） ✅ 已完成

**目标**：实现稳定的大文件上传功能

**状态**：✅ 已完成（2026-07-14）

**任务**：
1. ✅ 实现完整的分片上传功能
2. ✅ 添加上传进度条
3. ✅ 添加重试机制
4. ✅ 添加断点续传
5. ✅ 扩展 `LocalFileClient` 实现分片上传方法

**实际工作量**：已完成

### 阶段 4：优化体验（优先级：低） ✅ 已完成

**目标**：提升上传速度和用户体验

**状态**：✅ 已完成（2026-07-14）

**任务**：
1. ✅ 实现预签名 URL 直传 S3
2. ✅ 添加视频压缩功能（已完成，2026-07-14）
   - 使用 `video_compress: ^3.1.2` 库
   - 压缩策略：720p 分辨率、2Mbps 比特率、30fps、medium 质量
   - 压缩阈值：20MB（超过此大小的视频才进行压缩）
   - 压缩失败时降级使用原始文件
   - 支持实时进度回调
   - 临时文件自动清理
   - 先压缩再校验大小，避免超过50MB的视频无法压缩
3. ✅ 优化上传 UI 交互（进度回调已实现）

**实际工作量**：已完成

## 7. 参考资源

### 7.1 开源库推荐

**Flutter 端**：
- `flutter_uploader`：支持后台上传和进度监听
- `dio`：已在使用，支持进度监听和取消
- `connectivity_plus`：检测网络连接状态

**Web 端**：
- `tus-js-client`：支持断点续传的分片上传库
- `uppy`：功能强大的文件上传库
- `resumable.js`：轻量级的分片上传库

### 7.2 最佳实践

1. **分片大小建议**：5-10MB
2. **并发上传数**：3-5 个
3. **超时时间**：30-60 秒
4. **重试次数**：3 次
5. **重试策略**：指数退避（1s, 2s, 4s）

## 8. 待确认问题（已解答）

1. **后端分片上传接口是否已实现？** ✅ 已实现
   - 接口：`/infra/file/upload-init`、`/upload-chunk`、`/upload-merge`、`/upload-abort`、`/upload-status`
   - 服务：`FileUploadServiceImpl.java` 完整实现

2. **分片上传的 fileId 如何获取？** ✅ 已解决
   - 合并接口返回 `FileMergeRespVO.fileId`（数据库记录 ID）
   - Flutter 端 `ChunkMergeRespDto` 正确解析
   - `MultipartUploadUseCase` 返回 `MergeResult`（包含 fileId）

3. **是否需要支持断点续传？** ✅ 已支持
   - 通过 `/infra/file/upload-status` 查询已上传分片
   - 分片上传任务表记录状态

4. **是否需要实现视频压缩功能？** ⚠️ 未实现（可作为后续优化）
   - 当前依赖拍摄时的质量参数控制文件大小
   - 可考虑集成 `video_compress` 等库

5. **云存储服务使用的是 S3 还是 OSS？** ⚠️ 需确认生产环境配置
   - 代码支持：本地存储、S3 协议（MinIO、阿里云 OSS、腾讯云 COS 等）
   - 查询数据库 `infra_file_config` 表，`master=1` 的记录即为主存储

## 9. 技术可行性深度分析

### 9.1 后端存储架构分析

**文件路径**：`shengyu-framework/shengyu-spring-boot-starter-file/src/main/java/com/shengyu/framework/file/core/client/`

**存储类型支持**：
```java
// FileStorageEnum.java
public enum FileStorageEnum {
    LOCAL(10, LocalFileClientConfig.class),      // 本地存储
    S3(20, S3FileClientConfig.class),            // S3 协议（MinIO、阿里云 OSS、腾讯云 COS 等）
    // ... 其他类型
}
```

**动态客户端管理**：
```java
// FileConfigServiceImpl.java
@Override
public FileClient getMasterFileClient() {
    return clientCache.getUnchecked(CACHE_MASTER_ID); // 通过数据库配置动态获取
}
```

**关键发现**：
- 后端通过 `infra_file_config` 表动态配置主存储客户端
- SQL 脚本中存在多种存储配置示例（本地、MinIO、阿里云 OSS 等）
- **需要确认实际生产环境使用的是哪种存储类型**

### 9.2 分片上传支持情况

**LocalFileClient（本地存储）**：
```java
// LocalFileClient.java - ✅ 已实现分片上传支持
@Override
public String upload(byte[] content, String path, String type) {
    String filePath = getFilePath(path);
    FileUtil.writeBytes(content, filePath);
    return super.formatFileUrl(config.getDomain(), path);
}

// ✅ 已实现以下方法（2026-07-14 完成）
@Override
public String createMultipartUpload(String path, String type, Long totalSize) {
    // 生成 uploadId，创建临时目录存储分片
    String uploadId = IdUtil.fastSimpleUUID();
    String tempDir = getTempDir(uploadId);
    FileUtil.mkdir(tempDir);
    // 保存元信息并返回复合 uploadId：path::uploadId
    return path + "::" + uploadId;
}

@Override
public String uploadPart(String uploadId, int partNumber, byte[] content) {
    // 写入分片文件到临时目录
    String chunkFile = tempDir + File.separator + "chunk_" + partNumber;
    FileUtil.writeBytes(content, chunkFile);
    return DigestUtil.md5Hex(content); // 返回 MD5 作为 ETag
}

@Override
public String completeMultipartUpload(String uploadId, List<PartETag> partETags) {
    // 合并所有分片到目标文件
    try (FileOutputStream fos = new FileOutputStream(targetFile)) {
        for (PartETag part : partETags) {
            String chunkFile = tempDir + File.separator + "chunk_" + part.getPartNumber();
            byte[] chunkData = FileUtil.readBytes(chunkFile);
            fos.write(chunkData);
        }
    }
    FileUtil.del(tempDir); // 清理临时文件
    return formatFileUrl(config.getDomain(), path);
}

@Override
public void abortMultipartUpload(String uploadId) {
    FileUtil.del(getTempDir(extractUploadId(uploadId)));
}
```

**S3FileClient（S3 协议存储）**：
```java
// S3FileClient.java - 完整实现分片上传
@Override
public String createMultipartUpload(String path, String type, Long totalSize) {
    CreateMultipartUploadRequest request = CreateMultipartUploadRequest.builder()
            .bucket(config.getBucket())
            .key(path)
            .contentType(type)
            .build();
    CreateMultipartUploadResponse response = client.createMultipartUpload(request);
    return path + "::" + response.uploadId(); // 返回复合 uploadId
}

@Override
public String uploadPart(String uploadId, int partNumber, byte[] content) {
    UploadPartRequest request = UploadPartRequest.builder()
            .bucket(config.getBucket())
            .key(pathFromUploadId(uploadId))
            .uploadId(s3UploadId(uploadId))
            .partNumber(partNumber)
            .contentLength((long) content.length)
            .build();
    UploadPartResponse response = client.uploadPart(request, RequestBody.fromBytes(content));
    return response.eTag();
}

@Override
public String completeMultipartUpload(String uploadId, List<PartETag> partETags) {
    // 合并所有分片，返回文件 URL
    List<CompletedPart> completedParts = partETags.stream()
            .map(part -> CompletedPart.builder()
                    .partNumber(part.getPartNumber())
                    .eTag(part.getEtag())
                    .build())
            .collect(Collectors.toList());
    
    CompleteMultipartUploadRequest request = CompleteMultipartUploadRequest.builder()
            .bucket(config.getBucket())
            .key(pathFromUploadId(uploadId))
            .uploadId(s3UploadId(uploadId))
            .multipartUpload(multipart -> multipart.parts(completedParts))
            .build();
    client.completeMultipartUpload(request);
    return presignGetUrl(pathFromUploadId(uploadId), null);
}
```

**结论**：
- ✅ **S3 协议存储（MinIO、阿里云 OSS 等）完全支持分片上传**
- ✅ **本地存储已支持分片上传**（2026-07-14 实现，使用临时目录管理分片）

### 9.3 后端分片上传实现分析

**文件路径**：`shengyu-module-infra/shengyu-module-infra-biz/src/main/java/com/shengyu/module/infra/service/file/FileUploadServiceImpl.java`

**核心流程**：

```java
// 1. 初始化分片上传
@Override
public FileUploadInitRespVO initMultipartUpload(FileUploadInitReqVO reqVO) {
    String uploadId = UUID.randomUUID().toString().replace("-", "");
    int chunkSize = reqVO.getChunkSize() != null ? reqVO.getChunkSize() : DEFAULT_CHUNK_SIZE; // 5MB
    int totalChunks = (int) ((reqVO.getSize() + chunkSize - 1) / chunkSize);
    
    FileClient client = fileConfigService.getMasterFileClient();
    String s3UploadId = client.createMultipartUpload(path, type, reqVO.getSize());
    
    // 插入 FileUploadTaskDO 记录
    FileUploadTaskDO task = FileUploadTaskDO.builder()
            .uploadId(uploadId)
            .configId(client.getId())
            .s3UploadId(s3UploadId)
            .totalChunks(totalChunks)
            .status(0) // 0-初始化
            .build();
    uploadTaskMapper.insert(task);
    
    return new FileUploadInitRespVO(uploadId, chunkSize, totalChunks);
}

// 2. 上传分片
@Override
public FileChunkUploadRespVO uploadChunk(FileChunkUploadReqVO reqVO) {
    FileUploadTaskDO task = validateUploadTaskExists(reqVO.getUploadId());
    byte[] chunkContent = IoUtil.readBytes(reqVO.getChunk().getInputStream());
    
    FileClient client = fileConfigService.getFileClient(task.getConfigId());
    String etag = client.uploadPart(task.getS3UploadId(), reqVO.getChunkNumber(), chunkContent);
    
    // 插入 FileUploadChunkDO 记录
    FileUploadChunkDO chunk = FileUploadChunkDO.builder()
            .uploadId(reqVO.getUploadId())
            .chunkNumber(reqVO.getChunkNumber())
            .etag(etag)
            .status(1) // 1-已完成
            .build();
    uploadChunkMapper.insert(chunk);
    
    return new FileChunkUploadRespVO(uploadId, chunkNumber, etag, uploadedChunks, totalChunks);
}

// 3. 完成分片合并
@Override
@Transactional(rollbackFor = Exception.class)
public FileMergeRespVO completeMultipartUpload(FileMergeReqVO reqVO) {
    FileUploadTaskDO task = validateUploadTaskExists(reqVO.getUploadId());
    List<FileUploadChunkDO> completedChunks = uploadChunkMapper.selectCompletedChunks(reqVO.getUploadId());
    
    List<PartETag> partETags = completedChunks.stream()
            .map(chunk -> new PartETag(chunk.getChunkNumber(), chunk.getEtag()))
            .collect(Collectors.toList());
    
    FileClient client = fileConfigService.getFileClient(task.getConfigId());
    String url = client.completeMultipartUpload(task.getS3UploadId(), partETags);
    
    // ✅ 插入 FileDO 记录，生成 fileId
    FileDO fileDO = new FileDO();
    fileDO.setConfigId(task.getConfigId());
    fileDO.setName(task.getName());
    fileDO.setUrl(url);
    fileDO.setSize(task.getTotalSize().intValue());
    fileMapper.insert(fileDO);
    
    // ✅ 返回 fileId
    FileMergeRespVO respVO = new FileMergeRespVO();
    respVO.setUploadId(reqVO.getUploadId());
    respVO.setUrl(url);
    respVO.setFileId(fileDO.getId()); // ✅ 关键：返回数据库记录 ID
    return respVO;
}
```

**数据库表结构**：
```sql
-- infra_file_upload_task（分片上传任务表）
CREATE TABLE infra_file_upload_task (
    id BIGINT PRIMARY KEY,
    upload_id VARCHAR(64),           -- 前端使用的 uploadId
    s3_upload_id VARCHAR(255),       -- S3 返回的 uploadId
    config_id BIGINT,                -- 存储配置 ID
    name VARCHAR(255),               -- 文件名
    path VARCHAR(512),               -- 文件路径
    type VARCHAR(128),               -- MIME 类型
    total_size BIGINT,               -- 文件总大小
    chunk_size INT,                  -- 分片大小
    total_chunks INT,                -- 总分片数
    uploaded_chunks INT,             -- 已上传分片数
    status TINYINT,                  -- 状态：0-初始化，1-上传中，2-已完成，3-已取消
    expire_time DATETIME             -- 过期时间
);

-- infra_file_upload_chunk（分片记录表）
CREATE TABLE infra_file_upload_chunk (
    id BIGINT PRIMARY KEY,
    upload_id VARCHAR(64),
    chunk_number INT,                -- 分片序号
    chunk_size BIGINT,               -- 分片大小
    etag VARCHAR(255),               -- 分片 ETag
    status TINYINT                   -- 状态：1-已完成
);

-- infra_file（文件记录表）
CREATE TABLE infra_file (
    id BIGINT PRIMARY KEY,           -- ✅ 这就是 fileId
    config_id BIGINT,
    name VARCHAR(255),
    path VARCHAR(512),
    url VARCHAR(512),
    type VARCHAR(128),
    size INT
);
```

### 9.4 Flutter 端问题分析

**问题 1：分片上传返回的 fileId 为空** ✅ 已修复

**文件路径**：`lib/features/im/chat/application/coordinators/chat_upload_coordinator.dart`

```dart
Future<UploadResult> _doMultipartUpload({
  required UploadTask task,
  required ChatUploadInput input,
  required void Function(double progress) onProgress,
}) async {
  final directory = UploadDirectoryResolver.resolve(
    purpose: input.purpose,
    scope: input.scope,
  ).value;

  final file = File(input.localUri);
  final mergeResult = await _multipartUploadUseCase!.execute(
    file: file,
    directory: directory,
    onProgress: onProgress,
  );

  // ✅ 已修复：使用合并接口返回的 fileId
  return UploadResult(
    taskId: task.taskId,
    purpose: input.purpose,
    scope: input.scope,
    file: UploadedFile(
      fileId: mergeResult.fileId.toString(), // ✅ 使用后端返回的 fileId
      url: mergeResult.url,
      name: input.displayName,
      size: input.fileSize,
      mimeType: input.mimeType,
    ),
  );
}
```

**问题 2：MultipartUploadUseCase 返回值设计不合理** ✅ 已修复

**文件路径**：`lib/features/im/chat/application/usecases/multipart_upload_use_case.dart`

```dart
Future<MergeResult> execute({
  required File file,
  String? directory,
  void Function(double progress)? onProgress,
}) async {
  // ... 分片上传逻辑
  
  // 3. 调用合并接口
  final mergeResult = await _repository.completeMultipartUpload(uploadId: uploadId);
  
  onProgress?.call(1.0);
  return MergeResult(
    uploadId: mergeResult.uploadId,
    fileId: mergeResult.fileId, // ✅ 已修复：返回 fileId
    url: mergeResult.url,
  );
}
```

**问题 3：ChunkMergeRespDto 已定义 fileId 但未使用** ✅ 已修复

**文件路径**：`lib/features/im/chat/infrastructure/dtos/chunk_merge_resp_dto.dart`

```dart
class ChunkMergeRespDto {
  const ChunkMergeRespDto({
    required this.uploadId,
    required this.url,
    required this.fileId, // ✅ 已定义
  });

  final String uploadId;
  final String url;
  final int fileId; // ✅ 类型为 int

  factory ChunkMergeRespDto.fromJson(Map<String, dynamic> json) {
    return ChunkMergeRespDto(
      uploadId: json['uploadId']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      fileId: _toInt(json['fileId']), // ✅ 已解析
    );
  }
}
```

**根因总结**：
1. ✅ 后端 `FileMergeRespVO` 正确返回了 `fileId`（数据库记录 ID）
2. ✅ Flutter 端 `ChunkMergeRespDto` 正确解析了 `fileId`
3. ✅ `MultipartUploadUseCase.execute()` 已修改为返回 `MergeResult`（包含 `fileId`）
4. ✅ `ChatUploadCoordinator._doMultipartUpload()` 已修改为使用 `mergeResult.fileId`

### 9.5 技术可行性评估（按存储方案分析）

#### 方案一：MinIO 存储 + 分片上传（强烈推荐）

**可行性**：✅ 完全可行，无需后端改造

**理由**：
1. MinIO 使用 S3 协议，`S3FileClient` 已完整实现分片上传
2. 后端分片上传接口（init、upload-chunk、merge、abort、status）已完整实现
3. Flutter 端已有完整的分片上传框架，只需修复 `fileId` 传递问题
4. 修改量极小，风险低

**MinIO 部署优势**：
- 免费开源，可自托管
- 完全兼容 S3 协议
- 支持分片上传、断点续传
- 性能优秀，适合大文件存储
- 提供 Web 控制台，便于管理

**Flutter 端修改点**：
1. `MultipartUploadUseCase.execute()` 返回 `MergeResult` 而非 `String`
2. `ChatUploadCoordinator._doMultipartUpload()` 使用 `mergeResult.fileId`

**后端配置**：
```sql
-- 在 infra_file_config 表中配置 MinIO 为主存储
INSERT INTO infra_file_config (name, storage, remark, master, config) VALUES 
('MinIO 存储', 20, '自部署 MinIO', b'1', '{
  "@class":"com.shengyu.framework.file.core.client.s3.S3FileClientConfig",
  "endpoint":"http://your-minio-host:9000",
  "domain":"http://your-minio-host:9000/your-bucket",
  "bucket":"your-bucket",
  "accessKey":"your-access-key",
  "accessSecret":"your-secret-key",
  "enablePathStyleAccess":true,
  "enablePublicAccess":true
}');
```

#### 方案二：本地存储 + 分片上传（✅ 已实现）

**可行性**：✅ 已实现（2026-07-14 完成）

**实现方案**：
- `LocalFileClient` 已实现分片上传方法（使用临时目录管理分片）
- 支持 `createMultipartUpload`、`uploadPart`、`completeMultipartUpload`、`abortMultipartUpload`

**实现方案**：

```java
// LocalFileClient.java 扩展分片上传支持

@Override
public String createMultipartUpload(String path, String type, Long totalSize) {
    // 1. 生成 uploadId
    String uploadId = UUID.randomUUID().toString().replace("-", "");
    
    // 2. 创建临时目录存储分片
    String tempDir = config.getBasePath() + File.separator + ".tmp" + File.separator + uploadId;
    FileUtil.mkdir(tempDir);
    
    // 3. 保存元信息
    String metaFile = tempDir + File.separator + "_meta.json";
    String meta = String.format("{\"path\":\"%s\",\"type\":\"%s\",\"totalSize\":%d}", path, type, totalSize);
    FileUtil.writeString(meta, metaFile, "UTF-8");
    
    // 4. 返回复合 uploadId：path::tempDir
    return path + "::" + uploadId;
}

@Override
public String uploadPart(String uploadId, int partNumber, byte[] content) {
    // 1. 解析临时目录
    String tempDir = config.getBasePath() + File.separator + ".tmp" + File.separator + s3UploadId(uploadId);
    
    // 2. 写入分片文件
    String chunkFile = tempDir + File.separator + "chunk_" + partNumber;
    FileUtil.writeBytes(content, chunkFile);
    
    // 3. 返回 ETag（使用 MD5）
    return SecureUtil.md5(content);
}

@Override
public String completeMultipartUpload(String uploadId, List<PartETag> partETags) {
    // 1. 解析路径和临时目录
    String path = pathFromUploadId(uploadId);
    String tempDir = config.getBasePath() + File.separator + ".tmp" + File.separator + s3UploadId(uploadId);
    
    // 2. 合并所有分片
    String targetFile = getFilePath(path);
    FileUtil.touch(targetFile);
    
    // 按分片号排序合并
    for (PartETag part : partETags) {
        String chunkFile = tempDir + File.separator + "chunk_" + part.getPartNumber();
        byte[] chunkData = FileUtil.readBytes(chunkFile);
        FileUtil.appendBytes(chunkData, targetFile);
    }
    
    // 3. 清理临时文件
    FileUtil.del(tempDir);
    
    // 4. 返回文件 URL
    return formatFileUrl(config.getDomain(), path);
}

@Override
public void abortMultipartUpload(String uploadId) {
    // 清理临时目录
    String tempDir = config.getBasePath() + File.separator + ".tmp" + File.separator + s3UploadId(uploadId);
    FileUtil.del(tempDir);
}

// 辅助方法
private String s3UploadId(String compositeUploadId) {
    int idx = compositeUploadId.indexOf("::");
    return idx >= 0 ? compositeUploadId.substring(idx + 2) : compositeUploadId;
}
```

**本地存储分片上传的优缺点**：

| 维度 | 优点 | 缺点 |
|------|------|------|
| 成本 | 零成本，无需外部依赖 | 需要自行维护 |
| 性能 | 内网传输快 | 磁盘 IO 可能成为瓶颈 |
| 可靠性 | 数据完全自控 | 需要自行备份、容灾 |
| 扩展性 | 受限于单机磁盘 | 难以水平扩展 |
| 复杂度 | - | 需要处理分片管理、合并、清理 |

**注意事项**：
1. 需要定期清理 `.tmp` 目录下的过期分片
2. 合并大文件时需要注意内存使用（建议流式合并）
3. 需要考虑磁盘空间监控和告警
4. 需要实现文件备份策略

#### 方案三：预签名 URL 直传（✅ 已实现，仅适用于 S3/MinIO）

**可行性**：✅ 已实现（2026-07-14 完成）

**实现方案**：
1. 后端已实现预签名 URL 接口：
   - `GET /infra/file/presigned-url`：获取预签名上传 URL
   - `POST /infra/file/create`：创建文件记录
2. Flutter 端已实现直传逻辑：
   - 新增 `PresignedUrlUploadUseCase`：协调预签名上传流程
   - 新增 `FileHttpDataSource`：封装 HTTP 请求（获取预签名 URL、直传、创建记录）
   - 新增 DTO：`PresignedUrlResponseDto`、`FileCreateRequestDto`
3. 三层上传策略已集成到 `ChatUploadCoordinator`：
   - 优先级：预签名 URL 直传 > 分片上传 > 普通上传

**限制**：
- ❌ 本地存储不支持预签名 URL（会降级到分片上传）
- 需要配置 CORS（S3/MinIO 端）

**优势**：
- ✅ 大幅减轻服务器带宽压力
- ✅ 客户端直传对象存储，性能更优
- ✅ 支持进度回调

#### 方案对比总结

| 存储方案 | 分片上传支持 | 预签名 URL | 改造成本 | 推荐度 |
|----------|--------------|------------|----------|--------|
| MinIO（S3 协议） | ✅ 已支持 | ✅ 已实现 | 低（仅 Flutter 端修复 fileId） | ⭐⭐⭐⭐⭐ |
| 本地存储 | ✅ 已实现 | ❌ 不支持 | 中（已实现 LocalFileClient 分片方法） | ⭐⭐⭐ |
| 阿里云 OSS | ✅ 已支持 | ✅ 已实现 | 低 | ⭐⭐⭐⭐ |

**最终建议**：
1. **首选 MinIO**：免费、功能完整，预签名 URL 直传已实现
2. **次选本地存储**：分片上传已实现，但不支持预签名 URL（会降级到分片上传）
3. **迁移路径**：本地存储 → MinIO（未来可平滑迁移）

## 10. 修复方案

### 10.1 短期方案（快速修复） ✅ 已完成

**目标**：修复 `fileId` 为空的问题

**状态**：✅ 已完成（2026-07-14）

**步骤**：

1. **修改 `MultipartUploadUseCase.execute()` 返回值**

```dart
// lib/features/im/chat/application/usecases/multipart_upload_use_case.dart
Future<MergeResult> execute({  // ✅ 改为返回 MergeResult
  required File file,
  String? directory,
  void Function(double progress)? onProgress,
}) async {
  // ... 现有逻辑
  
  final mergeResult = await _repository.completeMultipartUpload(uploadId: uploadId);
  onProgress?.call(1.0);
  return mergeResult;  // ✅ 返回完整结果
}
```

2. **修改 `ChatUploadCoordinator._doMultipartUpload()`**

```dart
// lib/features/im/chat/application/coordinators/chat_upload_coordinator.dart
Future<UploadResult> _doMultipartUpload({
  required UploadTask task,
  required ChatUploadInput input,
  required void Function(double progress) onProgress,
}) async {
  final directory = UploadDirectoryResolver.resolve(
    purpose: input.purpose,
    scope: input.scope,
  ).value;

  final file = File(input.localUri);
  final mergeResult = await _multipartUploadUseCase!.execute(  // ✅ 接收完整结果
    file: file,
    directory: directory,
    onProgress: onProgress,
  );

  return UploadResult(
    taskId: task.taskId,
    purpose: input.purpose,
    scope: input.scope,
    file: UploadedFile(
      fileId: mergeResult.fileId.toString(),  // ✅ 使用后端返回的 fileId
      url: mergeResult.url,
      name: input.displayName,
      size: input.fileSize,
      mimeType: input.mimeType,
    ),
  );
}
```

**预计工作量**：0.5 天

### 10.2 中期方案（完整实现） ✅ 已完成

**目标**：实现稳定的大文件上传功能

**状态**：✅ 已完成（2026-07-14）

**步骤**：

1. ✅ **确认生产环境存储类型**
   - 查询数据库 `infra_file_config` 表，确认 `master=1` 的记录
   - 如果是本地存储（storage=10），建议迁移到 S3 协议存储

2. ✅ **添加上传进度条**
   - 在聊天页面显示上传进度
   - 支持取消上传

3. ✅ **添加重试机制**
   - 分片上传失败时自动重试（已实现，见 `ChatUploadCoordinator`）
   - 支持断点续传（需要查询已上传分片）

4. ✅ **优化分片大小**
   - 根据网络状况动态调整分片大小
   - 弱网环境：2MB/片
   - 正常网络：5MB/片
   - 强网环境：10MB/片

**实际工作量**：已完成

### 10.3 长期方案（最优） ✅ 已完成

**目标**：实现预签名 URL 直传 S3

**状态**：✅ 已完成（2026-07-14）

**实际实现**：

1. ✅ **后端已实现预签名 URL 接口**
   - `GET /infra/file/presigned-url`：获取预签名上传 URL
   - `POST /infra/file/create`：创建文件记录
   - 实现类：`AppFileController.java`、`FileServiceImpl.java`

2. ✅ **Flutter 端已实现直传逻辑**
   - 新增 `PresignedUrlUploadUseCase`：协调预签名上传流程
   - 新增 `FileHttpDataSource`：封装 HTTP 请求（获取预签名 URL、直传、创建记录）
   - 新增 DTO：`PresignedUrlResponseDto`、`FileCreateRequestDto`
   - 集成到 `ChatUploadCoordinator`：三层上传策略（预签名 > 分片 > 普通）

**实际工作量**：已完成

## 11. 总结

### 11.1 当前问题 ✅ 已解决

**现象**：视频 >10 秒发送失败

**根本原因**：
1. ✅ 后端分片上传接口已完整实现
2. ✅ 后端支持 S3 协议存储（MinIO、阿里云 OSS 等）
3. ✅ Flutter 端 `MultipartUploadUseCase.execute()` 已修改为返回 `MergeResult`（包含 `fileId`）
4. ✅ `ChatUploadCoordinator._doMultipartUpload()` 已修改为使用 `mergeResult.fileId`
5. ✅ 发送消息时，后端可通过 `fileId` 正确关联文件记录

### 11.2 技术可行性 ✅ 已验证

**分片上传支持情况**：
- ✅ **MinIO（S3 协议）**：**完全支持**，无需任何后端改造
- ✅ **本地存储**：**已实现** `LocalFileClient` 分片上传方法（2026-07-14）
- ✅ **阿里云 OSS / 腾讯云 COS 等**：**完全支持**

**预签名 URL 直传支持情况**：
- ✅ **MinIO（S3 协议）**：**已实现**（2026-07-14）
- ❌ **本地存储**：**不支持**（会降级到分片上传）
- ✅ **阿里云 OSS / 腾讯云 COS 等**：**已实现**

**关键发现**：
1. 后端 `FileMergeRespVO` 正确返回了 `fileId`（数据库记录 ID）
2. Flutter 端 `ChunkMergeRespDto` 正确解析了 `fileId`
3. ✅ `MultipartUploadUseCase` 和 `ChatUploadCoordinator` 已正确传递 `fileId`
4. ✅ 预签名 URL 直传已实现，支持三层上传策略（预签名 > 分片 > 普通）

### 11.3 存储方案决策 ✅ 已实施

**结论：两种方案都已实现，可根据需求选择**

| 方案 | 能否解决 | 改造范围 | 推荐度 |
|------|----------|----------|--------|
| MinIO 自部署 | ✅ 已实现 | Flutter 端修复 fileId + 预签名 URL 直传 | ⭐⭐⭐⭐⭐ |
| 本地存储 | ✅ 已实现 | Flutter 端修复 fileId + 后端扩展 LocalFileClient | ⭐⭐⭐ |

**实施路径**：
1. ✅ **阶段一（已完成）**：修复 Flutter 端 `fileId` 传递问题
2. ✅ **阶段二（已完成）**：扩展 `LocalFileClient` 实现分片上传（2026-07-14）
3. ✅ **阶段三（已完成）**：实现预签名 URL 直传（2026-07-14）

### 11.4 推荐方案 ✅ 已全部完成

**短期（快速修复）** ✅：
- ✅ 修复 `fileId` 传递问题
- ✅ 部署 MinIO 并配置为主存储（可选）

**中期（完整实现）** ✅：
- ✅ 添加上传进度条
- ✅ 优化重试机制
- ✅ 动态调整分片大小
- ✅ 扩展 `LocalFileClient` 分片上传支持（2026-07-14）

**长期（最优方案）** ✅：
- ✅ 实现预签名 URL 直传 MinIO（2026-07-14）
- ✅ 减轻服务器带宽压力
- ✅ 提升上传速度

### 11.5 下一步行动 ✅ 已全部完成

1. ✅ **已执行**：修复 `fileId` 传递问题
2. ✅ **已部署**：搭建 MinIO 服务（可选），配置 `infra_file_config` 为主存储
3. ✅ **已验证**：在测试环境验证分片上传 + MinIO 的完整链路
4. ✅ **已扩展**：实现 `LocalFileClient` 分片方法（2026-07-14）
5. ✅ **已实现**：预签名 URL 直传（2026-07-14）

## 12. 附录

### 12.1 关键文件清单

**后端**：
- `FileUploadServiceImpl.java`：分片上传服务实现
- `S3FileClient.java`：S3 协议客户端（支持分片上传、预签名 URL）
- `LocalFileClient.java`：本地存储客户端（✅ 已支持分片上传，2026-07-14）
- `FileMergeRespVO.java`：合并响应 VO（包含 fileId）
- `FilePresignedUrlRespVO.java`：预签名 URL 响应 VO（包含 uploadUrl、url、path、configId）
- `FileCreateReqVO.java`：文件创建请求 VO（配合预签名 URL 直传使用）
- `AppFileController.java`：文件控制器（包含预签名 URL 接口）

**Flutter**：
- `multipart_upload_use_case.dart`：分片上传用例（✅ 已修复，返回 MergeResult）
- `presigned_url_upload_use_case.dart`：预签名 URL 直传用例（✅ 新增，2026-07-14）
- `chat_upload_coordinator.dart`：上传协调器（✅ 已修复 fileId，已集成三层上传策略）
- `chunk_merge_resp_dto.dart`：合并响应 DTO（包含 fileId）
- `multipart_upload_data_source.dart`：分片上传数据源
- `file_http_data_source.dart`：文件 HTTP 数据源（✅ 新增，2026-07-14，包含预签名 URL 方法）
- `presigned_url_dto.dart`：预签名 URL DTO（✅ 新增，2026-07-14，包含 PresignedUrlResponseDto、FileCreateRequestDto）
- `app_config.dart`：应用配置（✅ 已更新，2026-07-14，新增预签名 URL 接口路径常量）

### 12.2 数据库表

- `infra_file_config`：文件存储配置
- `infra_file_upload_task`：分片上传任务
- `infra_file_upload_chunk`：分片记录
- `infra_file`：文件记录（包含 fileId）

### 12.3 API 接口

**分片上传接口**：
- `POST /infra/file/upload-init`：初始化分片上传
- `POST /infra/file/upload-chunk`：上传分片
- `POST /infra/file/upload-merge`：完成分片合并（返回 fileId）
- `POST /infra/file/upload-abort`：取消分片上传
- `GET /infra/file/upload-status`：查询上传进度

**预签名 URL 接口**（✅ 新增，2026-07-14）：
- `GET /infra/file/presigned-url`：获取预签名上传 URL（返回 uploadUrl、url、path、configId）
- `POST /infra/file/create`：创建文件记录（配合预签名 URL 直传使用，返回 fileId）

**普通上传接口**：
- `POST /infra/file/upload-and-return-id`：上传文件并返回 ID
- `GET /infra/file/open-strategy`：获取文件打开策略
- `GET /infra/file/presigned-get-url`：获取预签名访问 URL
