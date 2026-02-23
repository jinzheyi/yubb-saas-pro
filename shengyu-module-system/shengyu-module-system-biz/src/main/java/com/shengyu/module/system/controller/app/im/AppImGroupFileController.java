package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.app.im.vo.file.AppImGroupFilePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.file.AppImGroupFileRespVO;
import com.shengyu.module.system.service.im.ImGroupFileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.Resource;
import javax.validation.Valid;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 移动端 - IM 群文件 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - IM 群文件")
@RestController
@RequestMapping("/system/im/group/file")
@Validated
@Slf4j
public class AppImGroupFileController {

    @Resource
    private ImGroupFileService groupFileService;

    @PostMapping("/upload")
    @Operation(summary = "上传群文件")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    @Parameter(name = "file", description = "文件", required = true)
    public CommonResult<AppImGroupFileRespVO> uploadFile(
            @RequestParam("groupId") Long groupId,
            @RequestParam("file") MultipartFile file) throws Exception {
        return success(groupFileService.uploadFile(groupId, file));
    }

    @GetMapping("/list")
    @Operation(summary = "获取群文件列表")
    public CommonResult<PageResult<AppImGroupFileRespVO>> getFileList(
            @Valid AppImGroupFilePageReqVO pageReqVO) {
        return success(groupFileService.getFileList(pageReqVO));
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除群文件")
    @Parameter(name = "id", description = "文件ID", required = true)
    public CommonResult<Boolean> deleteFile(@RequestParam("id") Long id) {
        groupFileService.deleteFile(id);
        return success(true);
    }

    @PostMapping("/download")
    @Operation(summary = "记录文件下载")
    @Parameter(name = "id", description = "文件ID", required = true)
    public CommonResult<Boolean> downloadFile(@RequestParam("id") Long id) {
        groupFileService.incrementDownloadCount(id);
        return success(true);
    }

}
