package com.shengyu.module.infra.controller.app.file;

import cn.hutool.core.io.IoUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.infra.controller.app.file.vo.AppFileUploadReqVO;
import com.shengyu.module.infra.controller.app.file.vo.AppFileUploadRespVO;
import com.shengyu.module.infra.controller.app.file.vo.AppFilePresignedGetUrlRespVO;
import com.shengyu.module.infra.controller.platform.file.vo.file.FileCreateReqVO;
import com.shengyu.module.infra.controller.platform.file.vo.file.FilePresignedUrlRespVO;
import com.shengyu.module.infra.dal.dataobject.file.FileDO;
import com.shengyu.module.infra.dal.mysql.file.FileMapper;
import com.shengyu.module.infra.enums.ErrorCodeConstants;
import com.shengyu.module.infra.service.file.FileService;
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

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants.BAD_REQUEST;
import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;

@Tag(name = "用户 App - 文件存储")
@RestController
@RequestMapping("/infra/file")
@Validated
@Slf4j
public class AppFileController {

    @Resource
    private FileService fileService;

    @Resource
    private FileMapper fileMapper;

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
                .orderByDesc(FileDO::getId)
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
        return success(respVO);
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
