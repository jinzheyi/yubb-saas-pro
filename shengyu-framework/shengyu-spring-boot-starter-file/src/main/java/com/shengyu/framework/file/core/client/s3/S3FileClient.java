package com.shengyu.framework.file.core.client.s3;

import cn.hutool.core.io.IoUtil;
import cn.hutool.core.util.BooleanUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.http.HttpUtil;
import com.shengyu.framework.common.util.http.HttpUtils;
import com.shengyu.framework.file.core.client.AbstractFileClient;
import com.shengyu.framework.file.core.client.PartETag;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.net.URI;
import java.net.URL;
import java.time.Duration;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 基于 S3 协议的文件客户端，实现 MinIO、阿里云、腾讯云、七牛云、华为云等云服务
 *
 * @author 圣钰科技
 */
public class S3FileClient extends AbstractFileClient<S3FileClientConfig> {

    private static final Duration EXPIRATION_DEFAULT = Duration.ofHours(24);

    private S3Client client;
    private S3Presigner presigner;

    public S3FileClient(Long id, S3FileClientConfig config) {
        super(id, config);
    }

    @Override
    protected void doInit() {
        // 补全 domain
        if (StrUtil.isEmpty(config.getDomain())) {
            config.setDomain(buildDomain());
        }
        // 初始化 S3 客户端
        // 优先级：配置的 region > 从 endpoint 解析的 region > 默认值 us-east-1
        String regionStr = resolveRegion();
        Region region = Region.of(regionStr);
        AwsCredentialsProvider credentialsProvider = StaticCredentialsProvider.create(
                AwsBasicCredentials.create(config.getAccessKey(), config.getAccessSecret()));
        URI endpoint = URI.create(buildEndpoint());
        S3Configuration serviceConfiguration = S3Configuration.builder() // Path-style 访问
                .pathStyleAccessEnabled(Boolean.TRUE.equals(config.getEnablePathStyleAccess()))
                .chunkedEncodingEnabled(false) // 禁用分块编码，参见 https://t.zsxq.com/kBy57
                .build();
        client = S3Client.builder()
                .credentialsProvider(credentialsProvider)
                .region(region)
                .endpointOverride(endpoint)
                .serviceConfiguration(serviceConfiguration)
                .build();
        presigner = S3Presigner.builder()
                .credentialsProvider(credentialsProvider)
                .region(region)
                .endpointOverride(endpoint)
                .serviceConfiguration(serviceConfiguration)
                .build();
    }

    @Override
    public String upload(byte[] content, String path, String type) {
        // 构造 PutObjectRequest
        PutObjectRequest putRequest = PutObjectRequest.builder()
                .bucket(config.getBucket())
                .key(path)
                .contentType(type)
                .contentLength((long) content.length)
                .build();
        // 上传文件
        client.putObject(putRequest, RequestBody.fromBytes(content));
        // 拼接返回路径
        return presignGetUrl(path, null);
    }

    @Override
    public void delete(String path) {
        DeleteObjectRequest deleteRequest = DeleteObjectRequest.builder()
                .bucket(config.getBucket())
                .key(path)
                .build();
        client.deleteObject(deleteRequest);
    }

    @Override
    public byte[] getContent(String path) {
        GetObjectRequest getRequest = GetObjectRequest.builder()
                .bucket(config.getBucket())
                .key(path)
                .build();
        return IoUtil.readBytes(client.getObject(getRequest));
    }

    @Override
    public String presignPutUrl(String path) {
        return presigner.presignPutObject(PutObjectPresignRequest.builder()
                .signatureDuration(EXPIRATION_DEFAULT)
                .putObjectRequest(b -> b.bucket(config.getBucket()).key(path)).build())
                .url().toString();
    }

    @Override
    public String presignGetUrl(String url, Integer expirationSeconds) {
        // 1. 将 url 转换为 path
        String path = StrUtil.removePrefix(url, config.getDomain() + "/");
        path = HttpUtils.decodeUtf8(HttpUtils.removeUrlQuery(path));

        // 2.1 情况一：公开访问：无需签名
        // 考虑到老版本的兼容，所以必须是 config.getEnablePublicAccess() 为 false 时，才进行签名
        if (!BooleanUtil.isFalse(config.getEnablePublicAccess())) {
            return config.getDomain() + "/" + path;
        }

        // 2.2 情况二：私有访问：生成 GET 预签名 URL
        String finalPath = path;
        Duration expiration = expirationSeconds != null ? Duration.ofSeconds(expirationSeconds) : EXPIRATION_DEFAULT;
        URL signedUrl = presigner.presignGetObject(GetObjectPresignRequest.builder()
                .signatureDuration(expiration)
                .getObjectRequest(b -> b.bucket(config.getBucket()).key(finalPath)).build())
                .url();
        return signedUrl.toString();
    }

    @Override
    public String createMultipartUpload(String path, String type, Long totalSize) {
        // 构造 CreateMultipartUploadRequest
        CreateMultipartUploadRequest request = CreateMultipartUploadRequest.builder()
                .bucket(config.getBucket())
                .key(path)
                .contentType(type)
                .build();
        // 创建分片上传任务
        CreateMultipartUploadResponse response = client.createMultipartUpload(request);
        // 返回复合 token：path::uploadId，用于后续操作关联文件路径
        return path + "::" + response.uploadId();
    }

    @Override
    public String uploadPart(String uploadId, int partNumber, byte[] content) {
        // 构造 UploadPartRequest
        UploadPartRequest request = UploadPartRequest.builder()
                .bucket(config.getBucket())
                .key(pathFromUploadId(uploadId))
                .uploadId(s3UploadId(uploadId))
                .partNumber(partNumber)
                .contentLength((long) content.length)
                .build();
        // 上传分片
        UploadPartResponse response = client.uploadPart(request, RequestBody.fromBytes(content));
        return response.eTag();
    }

    @Override
    public String completeMultipartUpload(String uploadId, List<PartETag> partETags) {
        // 转换为 AWS SDK 的 CompletedPart 列表
        List<CompletedPart> completedParts = partETags.stream()
                .map(part -> CompletedPart.builder()
                        .partNumber(part.getPartNumber())
                        .eTag(part.getEtag())
                        .build())
                .collect(Collectors.toList());

        // 构造 CompleteMultipartUploadRequest
        CompleteMultipartUploadRequest request = CompleteMultipartUploadRequest.builder()
                .bucket(config.getBucket())
                .key(pathFromUploadId(uploadId))
                .uploadId(s3UploadId(uploadId))
                .multipartUpload(multipart -> multipart.parts(completedParts))
                .build();
        // 完成分片合并
        client.completeMultipartUpload(request);
        // 拼接返回路径
        return presignGetUrl(pathFromUploadId(uploadId), null);
    }

    @Override
    public void abortMultipartUpload(String uploadId) {
        // 构造 AbortMultipartUploadRequest
        AbortMultipartUploadRequest request = AbortMultipartUploadRequest.builder()
                .bucket(config.getBucket())
                .key(pathFromUploadId(uploadId))
                .uploadId(s3UploadId(uploadId))
                .build();
        // 取消分片上传
        client.abortMultipartUpload(request);
    }

    /**
     * 从复合 uploadId 中提取文件路径
     * <p>
     * 约定：uploadId 格式为 "{path}::{s3UploadId}"，用于在后续操作中关联文件路径
     *
     * @param compositeUploadId 分片上传任务 ID（格式：path::s3UploadId）
     * @return 文件路径
     */
    private String pathFromUploadId(String compositeUploadId) {
        int idx = compositeUploadId.indexOf("::");
        if (idx >= 0) {
            return compositeUploadId.substring(0, idx);
        }
        return compositeUploadId;
    }

    /**
     * 从复合 uploadId 中提取 S3 原生 uploadId
     *
     * @param compositeUploadId 分片上传任务 ID（格式：path::s3UploadId）
     * @return S3 原生 uploadId
     */
    private String s3UploadId(String compositeUploadId) {
        int idx = compositeUploadId.indexOf("::");
        if (idx >= 0) {
            return compositeUploadId.substring(idx + 2);
        }
        return compositeUploadId;
    }

    /**
     * 基于 bucket + endpoint 构建访问的 Domain 地址
     *
     * @return Domain 地址
     */
    private String buildDomain() {
        // 如果已经是 http 或者 https，则不进行拼接.主要适配 MinIO
        if (HttpUtil.isHttp(config.getEndpoint()) || HttpUtil.isHttps(config.getEndpoint())) {
            return StrUtil.format("{}/{}", config.getEndpoint(), config.getBucket());
        }
        // 阿里云、腾讯云、华为云都适合。七牛云比较特殊，必须有自定义域名
        return StrUtil.format("https://{}.{}", config.getBucket(), config.getEndpoint());
    }

    /**
     * 节点地址补全协议头
     *
     * @return 节点地址
     */
    private String buildEndpoint() {
        // 如果已经是 http 或者 https，则不进行拼接
        if (HttpUtil.isHttp(config.getEndpoint()) || HttpUtil.isHttps(config.getEndpoint())) {
            return config.getEndpoint();
        }
        return StrUtil.format("https://{}", config.getEndpoint());
    }

    /**
     * 解析 AWS 区域
     * 优先级：配置的 region > 从 endpoint 解析的 region > 默认值 us-east-1
     *
     * @return 区域字符串
     */
    private String resolveRegion() {
        // 1. 如果配置了 region，直接使用
        if (StrUtil.isNotEmpty(config.getRegion())) {
            return config.getRegion();
        }

        // 2.1 尝试从 endpoint 中解析 region
        String endpoint = config.getEndpoint();
        if (StrUtil.isEmpty(endpoint)) {
            return "us-east-1";
        }

        // 2.2 移除协议头（http:// 或 https://）
        String host = endpoint;
        if (HttpUtil.isHttp(endpoint) || HttpUtil.isHttps(endpoint)) {
            try {
                host = URI.create(endpoint).getHost();
            } catch (Exception e) {
                // 解析失败，使用默认值
                return "us-east-1";
            }
        }
        if (StrUtil.isEmpty(host)) {
            return "us-east-1";
        }

        // 3.1 AWS S3 格式：s3.us-west-2.amazonaws.com 或 s3.amazonaws.com
        if (host.contains("amazonaws.com")) {
            // 匹配 s3.{region}.amazonaws.com 格式
            if (host.startsWith("s3.") && host.contains(".amazonaws.com")) {
                String regionPart = host.substring(3, host.indexOf(".amazonaws.com"));
                if (StrUtil.isNotEmpty(regionPart) && !regionPart.equals("accelerate")) {
                    return regionPart;
                }
            }
            // s3.amazonaws.com 或 s3-accelerate.amazonaws.com 使用默认值
            return "us-east-1";
        }
        // 3.2 阿里云 OSS 格式：oss-cn-beijing.aliyuncs.com
        if (host.contains(S3FileClientConfig.ENDPOINT_ALIYUN)) {
            // 匹配 oss-{region}.aliyuncs.com 格式
            if (host.startsWith("oss-") && host.contains("." + S3FileClientConfig.ENDPOINT_ALIYUN)) {
                String regionPart = host.substring(4, host.indexOf("." + S3FileClientConfig.ENDPOINT_ALIYUN));
                if (StrUtil.isNotEmpty(regionPart)) {
                    return regionPart;
                }
            }
        }
        // 3.3 腾讯云 COS 格式：cos.ap-shanghai.myqcloud.com
        if (host.contains(S3FileClientConfig.ENDPOINT_TENCENT)) {
            // 匹配 cos.{region}.myqcloud.com 格式
            if (host.startsWith("cos.") && host.contains("." + S3FileClientConfig.ENDPOINT_TENCENT)) {
                String regionPart = host.substring(4, host.indexOf("." + S3FileClientConfig.ENDPOINT_TENCENT));
                if (StrUtil.isNotEmpty(regionPart)) {
                    return regionPart;
                }
            }
        }

        // 3.4 其他情况（MinIO、七牛云等）使用默认值
        return "us-east-1";
    }

}
