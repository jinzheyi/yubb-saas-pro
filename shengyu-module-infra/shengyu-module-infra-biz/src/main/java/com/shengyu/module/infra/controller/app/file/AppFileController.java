package com.shengyu.module.infra.controller.app.file;

import cn.hutool.core.util.StrUtil;
import cn.hutool.core.io.IoUtil;
import cn.hutool.crypto.digest.DigestUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.infra.controller.app.file.vo.AppFileUploadReqVO;
import com.shengyu.module.infra.controller.app.file.vo.AppFileUploadRespVO;
import com.shengyu.module.infra.controller.app.file.vo.AppFilePresignedGetUrlRespVO;
import com.shengyu.module.infra.controller.app.file.vo.AppFileOpenStrategyRespVO;
import com.shengyu.module.infra.controller.platform.file.vo.file.FileCreateReqVO;
import com.shengyu.module.infra.controller.platform.file.vo.file.FilePresignedUrlRespVO;
import com.shengyu.module.infra.dal.dataobject.file.FileDO;
import com.shengyu.module.infra.dal.mysql.file.FileMapper;
import com.shengyu.module.infra.enums.ErrorCodeConstants;
import com.shengyu.module.infra.framework.filepreview.config.ImFilePreviewProperties;
import com.shengyu.module.infra.service.file.FileService;
import com.shengyu.module.infra.service.file.VideoThumbnailService;
import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Parameters;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.validation.Valid;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants.BAD_REQUEST;
import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;

@Tag(name = "用户 App - 文件存储")
@RestController
@RequestMapping("/infra/file")
@Validated
@Slf4j
public class AppFileController {

    private static final int KK_PROBE_TIMEOUT_MS = 2500;

    private static final List<String> KK_ERROR_KEYWORDS = Arrays.asList(
            "预览失败",
            "文件预览失败",
            "不支持",
            "not supported",
            "Unsupported",
            "转换失败",
            "Conversion failed",
            "系统异常",
            "系统错误",
            "error",
            "Exception"
    );

    @Resource
    private FileService fileService;

    @Resource
    private FileMapper fileMapper;

    @Resource
    private VideoThumbnailService videoThumbnailService;

    @Resource
    private ImFilePreviewProperties filePreviewProperties;

    @PostMapping("/upload")
    @Operation(summary = "上传文件")
    @Parameter(name = "file", description = "文件附件", required = true,
            schema = @Schema(type = "string", format = "binary"))
    public CommonResult<String> uploadFile(AppFileUploadReqVO uploadReqVO) throws Exception {
        MultipartFile file = uploadReqVO.getFile();
        byte[] content = IoUtil.readBytes(file.getInputStream());
        return success(fileService.createFile(content, file.getOriginalFilename(),
                uploadReqVO.getDirectory(), file.getContentType()));
    }

    @PostMapping("/upload-and-return-id")
    @Operation(summary = "上传文件（返回 fileId）")
    @Parameter(name = "file", description = "文件附件", required = true,
            schema = @Schema(type = "string", format = "binary"))
    public CommonResult<AppFileUploadRespVO> uploadFileAndReturnId(@Valid AppFileUploadReqVO uploadReqVO) throws Exception {
        MultipartFile file = uploadReqVO.getFile();
        byte[] content = IoUtil.readBytes(file.getInputStream());

        String url = fileService.createFile(content, file.getOriginalFilename(),
                uploadReqVO.getDirectory(), file.getContentType());
        if (url == null) {
            throw exception(ErrorCodeConstants.FILE_UPLOAD_FAIL);
        }
        FileDO fileDO = fileMapper.selectOne(new LambdaQueryWrapper<FileDO>()
                .eq(FileDO::getUrl, url)
                .orderByDesc(FileDO::getCreateTime)
                .last("LIMIT 1"));
        if (fileDO == null || fileDO.getId() == null) {
            throw exception(ErrorCodeConstants.FILE_UPLOAD_RECORD_NOT_FOUND);
        }

        AppFileUploadRespVO respVO = new AppFileUploadRespVO();
        respVO.setFileId(fileDO.getId());
        respVO.setUrl(fileDO.getUrl());
        respVO.setName(fileDO.getName() != null ? fileDO.getName() : file.getOriginalFilename());
        respVO.setSize(fileDO.getSize() != null ? fileDO.getSize() : (int) file.getSize());
        respVO.setMimeType(fileDO.getType() != null ? fileDO.getType() : file.getContentType());
        respVO.setMd5(DigestUtil.md5Hex(content));
        enrichVideoThumbnail(uploadReqVO, file, content, respVO);
        return success(respVO);
    }

    private void enrichVideoThumbnail(
            AppFileUploadReqVO uploadReqVO,
            MultipartFile file,
            byte[] content,
            AppFileUploadRespVO respVO
    ) {
        String mimeType = StrUtil.blankToDefault(respVO.getMimeType(), file.getContentType());
        if (!StrUtil.startWithIgnoreCase(mimeType, "video/")) {
            return;
        }
        VideoThumbnailService.GeneratedThumbnail thumbnail = videoThumbnailService.generate(
                content,
                file.getOriginalFilename()
        );
        if (thumbnail == null || thumbnail.getContent() == null || thumbnail.getContent().length == 0) {
            return;
        }
        String thumbDirectory = buildThumbnailDirectory(uploadReqVO.getDirectory());
        String thumbUrl = fileService.createFile(
                thumbnail.getContent(),
                thumbnail.getFileName(),
                thumbDirectory,
                thumbnail.getMimeType()
        );
        if (StrUtil.isBlank(thumbUrl)) {
            return;
        }
        FileDO thumbFileDO = findLatestFileByUrl(thumbUrl);
        if (thumbFileDO == null || thumbFileDO.getId() == null) {
            return;
        }
        respVO.setThumbFileId(thumbFileDO.getId());
        respVO.setThumbUrl(thumbFileDO.getUrl());
    }

    private String buildThumbnailDirectory(String directory) {
        String normalized = StrUtil.blankToDefault(directory, "").trim();
        if (normalized.isEmpty()) {
            return "thumb";
        }
        return normalized + "/thumb";
    }

    private FileDO findLatestFileByUrl(String url) {
        return fileMapper.selectOne(new LambdaQueryWrapper<FileDO>()
                .eq(FileDO::getUrl, url)
                .orderByDesc(FileDO::getCreateTime)
                .last("LIMIT 1"));
    }

    @GetMapping("/open-strategy")
    @Operation(summary = "获取文件打开策略（预览或下载）")
    @Parameters({
            @Parameter(name = "fileId", description = "文件ID", required = true),
            @Parameter(name = "expirationSeconds", description = "有效期（秒），建议 60~600")
    })
    public CommonResult<AppFileOpenStrategyRespVO> getFileOpenStrategy(
            @RequestParam("fileId") Long fileId,
            @RequestParam(value = "expirationSeconds", required = false) Integer expirationSeconds) {
        if (fileId == null) {
            throw exception(BAD_REQUEST);
        }
        int seconds = expirationSeconds == null ? 600 : expirationSeconds;
        if (expirationSeconds != null && (seconds < 60 || seconds > 600)) {
            throw exception(BAD_REQUEST);
        }

        FileDO fileDO = fileService.getFile(fileId);
        if (fileDO == null || fileDO.getUrl() == null) {
            throw exception(ErrorCodeConstants.FILE_NOT_EXISTS);
        }

        String downloadUrl = fileService.presignGetUrl(fileDO.getUrl(), seconds);
        long expiresAt = LocalDateTime.now().plusSeconds(seconds)
                .atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();

        String ext = "";
        String name = fileDO.getName();
        if (name != null) {
            int idx = name.lastIndexOf('.');
            if (idx >= 0 && idx < name.length() - 1) {
                ext = name.substring(idx + 1).toLowerCase();
            }
        }

        AppFileOpenStrategyRespVO respVO = new AppFileOpenStrategyRespVO();
        respVO.setDownloadUrl(downloadUrl);
        respVO.setExpiresAt(expiresAt);
        respVO.setContentType(fileDO.getType());

        populateOpenStrategy(respVO, fileDO, downloadUrl, ext);
        return success(respVO);
    }

    private void populateOpenStrategy(
            AppFileOpenStrategyRespVO respVO,
            FileDO fileDO,
            String downloadUrl,
            String ext
    ) {
        String mimeType = StrUtil.blankToDefault(fileDO.getType(), "").trim().toLowerCase(Locale.ROOT);
        String normalizedExt = StrUtil.blankToDefault(ext, "").trim().toLowerCase(Locale.ROOT);

        if (isImageFile(normalizedExt, mimeType)) {
            respVO.setAction("PREVIEW");
            respVO.setRenderStrategy("native_image");
            respVO.setPreviewUrl(downloadUrl);
            return;
        }
        if (isVideoFile(normalizedExt, mimeType)) {
            respVO.setAction("PREVIEW");
            respVO.setRenderStrategy("native_video");
            respVO.setPreviewUrl(downloadUrl);
            return;
        }
        if (isAudioFile(normalizedExt, mimeType)) {
            respVO.setAction("PREVIEW");
            respVO.setRenderStrategy("native_audio");
            respVO.setPreviewUrl(downloadUrl);
            return;
        }
        if (isMarkdownFile(normalizedExt, mimeType)) {
            respVO.setAction("PREVIEW");
            respVO.setRenderStrategy("native_markdown");
            respVO.setPreviewUrl(downloadUrl);
            return;
        }
        if (isTextFile(normalizedExt, mimeType)) {
            respVO.setAction("PREVIEW");
            respVO.setRenderStrategy("native_text");
            respVO.setPreviewUrl(downloadUrl);
            return;
        }
        if (isPdfFile(normalizedExt, mimeType)) {
            respVO.setAction("PREVIEW");
            respVO.setRenderStrategy("native_pdf");
            respVO.setPreviewUrl(downloadUrl);
            respVO.setConvertedPdfUrl(downloadUrl);
            return;
        }
        if (isOfficeFile(normalizedExt)) {
            ImFilePreviewProperties.Kkfileview kkfileview = filePreviewProperties.getKkfileview();
            if (!kkfileview.isEnabled()) {
                respVO.setAction("DOWNLOAD");
                respVO.setRenderStrategy("download_only");
                respVO.setMessage("当前环境未启用在线预览服务，将为你下载打开");
                return;
            }
            String previewUrl = buildKkPreviewUrl(downloadUrl);
            if (StrUtil.isBlank(previewUrl)) {
                respVO.setAction("DOWNLOAD");
                respVO.setRenderStrategy("download_only");
                respVO.setMessage("预览链接生成失败，将为你下载打开");
                return;
            }
            boolean unstable = isUnstableKkPreviewExt(normalizedExt);
            boolean probeSuccess = probeKkPreviewable(previewUrl);
            respVO.setAction("PREVIEW");
            respVO.setRenderStrategy("embedded_office_viewer");
            respVO.setPreviewUrl(previewUrl);
            respVO.setViewerUrl(previewUrl);
            respVO.setUnstable(unstable || !probeSuccess);
            if (!probeSuccess) {
                respVO.setMessage("在线预览服务响应不稳定，若预览失败请改用下载或外部打开");
            } else if (unstable) {
                respVO.setMessage("该文件在线预览可能存在兼容性波动");
            }
            return;
        }

        respVO.setAction("DOWNLOAD");
        respVO.setRenderStrategy("download_only");
        respVO.setMessage("该文件暂不支持在线预览，将为你下载打开");
    }

    private String buildKkPreviewUrl(String sourceUrl) {
        try {
            String raw = rewriteKkSourceUrl(sourceUrl);
            String b64 = Base64.getEncoder().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
            String encoded = URLEncoder.encode(b64, StandardCharsets.UTF_8.name());
            String base = StrUtil.blankToDefault(filePreviewProperties.getKkfileview().getBaseUrl(), "");
            if (base.endsWith("/")) {
                base = base.substring(0, base.length() - 1);
            }
            return base + "/onlinePreview?url=" + encoded;
        } catch (Exception e) {
            return "";
        }
    }

    private String rewriteKkSourceUrl(String sourceUrl) {
        String raw = sourceUrl == null ? "" : sourceUrl;
        String overrideBase = StrUtil.blankToDefault(
                filePreviewProperties.getKkfileview().getSourceBaseUrl(), "").trim();
        if (raw.isEmpty() || overrideBase.isEmpty()) {
            return raw;
        }
        try {
            URI sourceUri = URI.create(raw);
            URI overrideUri = URI.create(overrideBase);
            return new URI(
                    overrideUri.getScheme(),
                    overrideUri.getUserInfo(),
                    overrideUri.getHost(),
                    overrideUri.getPort(),
                    sourceUri.getPath(),
                    sourceUri.getQuery(),
                    sourceUri.getFragment()
            ).toString();
        } catch (Exception e) {
            log.warn("[rewriteKkSourceUrl][sourceUrl({}) overrideBase({}) error({})]",
                    sourceUrl, overrideBase, e.getMessage());
            return raw;
        }
    }

    private static boolean isOfficeFile(String ext) {
        if (ext == null || ext.isEmpty()) {
            return false;
        }
        return "doc".equals(ext) || "docx".equals(ext)
                || "xls".equals(ext) || "xlsx".equals(ext)
                || "ppt".equals(ext) || "pptx".equals(ext)
                || "odt".equals(ext) || "ods".equals(ext) || "odp".equals(ext);
    }

    private static boolean isPdfFile(String ext, String mimeType) {
        return "pdf".equals(ext) || mimeType.contains("pdf");
    }

    private static boolean isImageFile(String ext, String mimeType) {
        return mimeType.startsWith("image/")
                || "jpg".equals(ext) || "jpeg".equals(ext) || "png".equals(ext)
                || "gif".equals(ext) || "webp".equals(ext) || "bmp".equals(ext)
                || "svg".equals(ext);
    }

    private static boolean isVideoFile(String ext, String mimeType) {
        return mimeType.startsWith("video/")
                || "mp4".equals(ext) || "mov".equals(ext) || "m4v".equals(ext)
                || "webm".equals(ext) || "avi".equals(ext) || "mkv".equals(ext);
    }

    private static boolean isAudioFile(String ext, String mimeType) {
        return mimeType.startsWith("audio/")
                || "mp3".equals(ext) || "wav".equals(ext) || "aac".equals(ext)
                || "m4a".equals(ext) || "ogg".equals(ext) || "flac".equals(ext);
    }

    private static boolean isMarkdownFile(String ext, String mimeType) {
        return "md".equals(ext) || "markdown".equals(ext)
                || "text/markdown".equals(mimeType);
    }

    private static boolean isTextFile(String ext, String mimeType) {
        return mimeType.startsWith("text/")
                || "txt".equals(ext) || "log".equals(ext) || "json".equals(ext)
                || "xml".equals(ext) || "yaml".equals(ext) || "yml".equals(ext)
                || "csv".equals(ext) || "java".equals(ext) || "kt".equals(ext)
                || "js".equals(ext) || "ts".equals(ext) || "dart".equals(ext)
                || "py".equals(ext) || "go".equals(ext) || "sql".equals(ext);
    }

    private static boolean isUnstableKkPreviewExt(String ext) {
        if (ext == null || ext.isEmpty()) {
            return false;
        }
        return "ppt".equals(ext) || "pptx".equals(ext);
    }

    private boolean probeKkPreviewable(String previewUrl) {
        if (previewUrl == null || previewUrl.isEmpty()) {
            return false;
        }
        try (HttpResponse resp = HttpRequest.get(previewUrl)
                .timeout(KK_PROBE_TIMEOUT_MS)
                .setFollowRedirects(true)
                .execute()) {
            int status = resp.getStatus();
            if (status >= 400) {
                log.warn("[probeKkPreviewable][previewUrl({}) status({})]", previewUrl, status);
                return false;
            }
            String body = resp.body();
            if (body == null || body.isEmpty()) {
                return false;
            }
            String lower = body.toLowerCase();
            for (String kw : KK_ERROR_KEYWORDS) {
                if (kw == null || kw.isEmpty()) {
                    continue;
                }
                if (lower.contains(kw.toLowerCase())) {
                    log.warn("[probeKkPreviewable][previewUrl({}) hitKeyword({})]", previewUrl, kw);
                    return false;
                }
            }
            return true;
        } catch (Exception e) {
            log.warn("[probeKkPreviewable][previewUrl({}) probeError] {}", previewUrl, e.getMessage());
            return false;
        }
    }

    @GetMapping("/presigned-url")
    @Operation(summary = "获取文件预签名地址（上传）", description = "模式二：前端上传文件：用于前端直接上传七牛、阿里云 OSS 等文件存储器")
    @Parameters({
            @Parameter(name = "name", description = "文件名称", required = true),
            @Parameter(name = "directory", description = "文件目录")
    })
    public CommonResult<FilePresignedUrlRespVO> getFilePresignedUrl(
            @RequestParam("name") String name,
            @RequestParam(value = "directory", required = false) String directory) {
        return success(fileService.presignPutUrl(name, directory));
    }

    @GetMapping("/presigned-get-url")
    @Operation(summary = "获取文件预签名地址（读取）")
    @Parameters({
            @Parameter(name = "fileId", description = "文件ID", required = true),
            @Parameter(name = "expirationSeconds", description = "有效期（秒），建议 60~600")
    })
    public CommonResult<AppFilePresignedGetUrlRespVO> getFilePresignedGetUrl(
            @RequestParam("fileId") Long fileId,
            @RequestParam(value = "expirationSeconds", required = false) Integer expirationSeconds) {
        if (fileId == null) {
            throw exception(BAD_REQUEST);
        }
        int seconds = expirationSeconds == null ? 600 : expirationSeconds;
        if (expirationSeconds != null && (seconds < 60 || seconds > 600)) {
            throw exception(BAD_REQUEST);
        }

        FileDO fileDO = fileService.getFile(fileId);
        if (fileDO == null || fileDO.getUrl() == null) {
            throw exception(ErrorCodeConstants.FILE_NOT_EXISTS);
        }

        String signedUrl = fileService.presignGetUrl(fileDO.getUrl(), seconds);

        AppFilePresignedGetUrlRespVO respVO = new AppFilePresignedGetUrlRespVO();
        respVO.setUrl(signedUrl);
        long expiresAt = LocalDateTime.now().plusSeconds(seconds)
                .atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
        respVO.setExpiresAt(expiresAt);
        return success(respVO);
    }

    @PostMapping("/create")
    @Operation(summary = "创建文件", description = "模式二：前端上传文件：配合 presigned-url 接口，记录上传了上传的文件")
    public CommonResult<Long> createFile(@Valid @RequestBody FileCreateReqVO createReqVO) {
        return success(fileService.createFile(createReqVO));
    }

}
