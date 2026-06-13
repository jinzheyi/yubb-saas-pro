package com.shengyu.module.infra.controller.platform.file;

import cn.hutool.core.io.IoUtil;
import cn.hutool.core.util.StrUtil;
import cn.hutool.core.util.URLUtil;
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.tenant.core.aop.TenantIgnore;
import com.shengyu.module.infra.controller.platform.file.vo.file.*;
import com.shengyu.module.infra.dal.dataobject.file.FileDO;
import com.shengyu.module.infra.service.file.FileService;
import com.shengyu.module.infra.service.file.FileUploadService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Parameters;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.annotation.security.PermitAll;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;

import java.nio.charset.StandardCharsets;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.file.core.utils.FileTypeUtils.writeAttachment;

@Tag(name = "管理后台 - 文件存储")
@RestController
@RequestMapping("/infra/file")
@Validated
@Slf4j
public class FileController {

    @Resource
    private FileService fileService;

    @Resource
    private FileUploadService fileUploadService;

    @PostMapping("/upload")
    @Operation(summary = "上传文件", description = "模式一：后端上传文件")
    @Parameter(name = "file", description = "文件附件", required = true,
            schema = @Schema(type = "string", format = "binary"))
    public CommonResult<String> uploadFile(@Valid FileUploadReqVO uploadReqVO) throws Exception {
        MultipartFile file = uploadReqVO.getFile();
        byte[] content = IoUtil.readBytes(file.getInputStream());
        return success(fileService.createFile(content, file.getOriginalFilename(),
                uploadReqVO.getDirectory(), file.getContentType()));
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

    @PostMapping("/create")
    @Operation(summary = "创建文件", description = "模式二：前端上传文件：配合 presigned-url 接口，记录上传了上传的文件")
    public CommonResult<Long> createFile(@Valid @RequestBody FileCreateReqVO createReqVO) {
        return success(fileService.createFile(createReqVO));
    }

    @GetMapping("/get")
    @Operation(summary = "获得文件")
    @Parameter(name = "id", description = "编号", required = true)
    @PreAuthorize("@ps.hasPermission('infra:file:query')")
    public CommonResult<FileRespVO> getFile(@RequestParam("id") Long id) {
        return success(BeanUtils.toBean(fileService.getFile(id), FileRespVO.class));
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除文件")
    @Parameter(name = "id", description = "编号", required = true)
    @PreAuthorize("@ps.hasPermission('infra:file:delete')")
    public CommonResult<Boolean> deleteFile(@RequestParam("id") Long id) throws Exception {
        fileService.deleteFile(id);
        return success(true);
    }

    @DeleteMapping("/delete-list")
    @Operation(summary = "批量删除文件")
    @Parameter(name = "ids", description = "编号列表", required = true)
    @PreAuthorize("@ps.hasPermission('infra:file:delete')")
    public CommonResult<Boolean> deleteFileList(@RequestParam("ids") List<Long> ids) throws Exception {
        fileService.deleteFileList(ids);
        return success(true);
    }

    @GetMapping("/{configId}/get/**")
    @PermitAll
    @TenantIgnore
    @Operation(summary = "下载文件")
    @Parameter(name = "configId", description = "配置编号", required = true)
    public void getFileContent(HttpServletRequest request,
                               HttpServletResponse response,
                               @PathVariable("configId") Long configId) throws Exception {
        // 获取请求的路径
        String path = StrUtil.subAfter(request.getRequestURI(), "/get/", false);
        if (StrUtil.isEmpty(path)) {
            throw new IllegalArgumentException("结尾的 path 路径必须传递");
        }
        // 解码，解决中文路径的问题
        // https://gitee.com/zhijiantianya/ruoyi-vue-pro/pulls/807/
        // https://gitee.com/zhijiantianya/ruoyi-vue-pro/pulls/1432/
        path = URLUtil.decode(path, StandardCharsets.UTF_8, false);

        // 读取内容
        byte[] content = fileService.getFileContent(configId, path);
        if (content == null) {
            log.warn("[getFileContent][configId({}) path({}) 文件不存在]", configId, path);
            response.setStatus(HttpStatus.NOT_FOUND.value());
            return;
        }
        writeAttachment(response, path, content);
    }

    @GetMapping("/page")
    @Operation(summary = "获得文件分页")
    @PreAuthorize("@ps.hasPermission('infra:file:query')")
    public CommonResult<PageResult<FileRespVO>> getFilePage(@Valid FilePageReqVO pageVO) {
        PageResult<FileDO> pageResult = fileService.getFilePage(pageVO);
        return success(BeanUtils.toBean(pageResult, FileRespVO.class));
    }

    // ==================== 分片上传相关接口 ====================

    @PostMapping("/upload-init")
    @Operation(summary = "初始化分片上传")
    public CommonResult<FileUploadInitRespVO> initMultipartUpload(@Valid @RequestBody FileUploadInitReqVO reqVO) {
        return success(fileUploadService.initMultipartUpload(reqVO));
    }

    @PostMapping("/upload-chunk")
    @Operation(summary = "上传分片", description = "用于前端上传文件分片")
    @Parameter(name = "chunk", description = "分片文件", required = true,
            schema = @Schema(type = "string", format = "binary"))
    public CommonResult<FileChunkUploadRespVO> uploadChunk(@Valid FileChunkUploadReqVO reqVO) throws Exception {
        return success(fileUploadService.uploadChunk(reqVO));
    }

    @PostMapping("/upload-merge")
    @Operation(summary = "完成分片合并", description = "所有分片上传完成后，调用此接口合并文件")
    public CommonResult<FileMergeRespVO> completeMultipartUpload(@Valid @RequestBody FileMergeReqVO reqVO) throws Exception {
        return success(fileUploadService.completeMultipartUpload(reqVO));
    }

    @PostMapping("/upload-abort")
    @Operation(summary = "取消分片上传", description = "取消正在进行中的分片上传任务")
    @Parameter(name = "uploadId", description = "分片上传唯一标识", required = true)
    public CommonResult<Boolean> abortMultipartUpload(@RequestParam("uploadId") String uploadId) {
        fileUploadService.abortMultipartUpload(uploadId);
        return success(true);
    }

    @GetMapping("/upload-status")
    @Operation(summary = "查询上传进度", description = "查询指定分片上传任务的进度信息")
    @Parameter(name = "uploadId", description = "分片上传唯一标识", required = true)
    public CommonResult<FileUploadStatusRespVO> getUploadStatus(@RequestParam("uploadId") String uploadId) {
        return success(fileUploadService.getUploadStatus(uploadId));
    }

}
