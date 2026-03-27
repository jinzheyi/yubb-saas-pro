package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerCollectReqVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerListRespVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerRespVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerSortReqVO;
import com.shengyu.module.system.controller.app.im.vo.sticker.AppImStickerUploadReqVO;
import com.shengyu.module.system.service.im.ImStickerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.validation.Valid;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "移动端 - IM 自定义表情")
@RestController
@RequestMapping("/system/im/sticker")
@Validated
public class AppImStickerController {

    @Resource
    private ImStickerService stickerService;

    @GetMapping("/list")
    @Operation(summary = "获取当前用户自定义表情列表")
    public CommonResult<AppImStickerListRespVO> getStickerList() {
        return success(stickerService.getStickerList(SecurityFrameworkUtils.getLoginUserId()));
    }

    @PostMapping("/upload")
    @Operation(summary = "上传文件后登记为自定义表情")
    public CommonResult<AppImStickerRespVO> uploadSticker(@Valid @RequestBody AppImStickerUploadReqVO reqVO) {
        return success(stickerService.uploadSticker(SecurityFrameworkUtils.getLoginUserId(), reqVO));
    }

    @PostMapping("/collect")
    @Operation(summary = "从聊天消息添加到自定义表情")
    public CommonResult<AppImStickerRespVO> collectSticker(@Valid @RequestBody AppImStickerCollectReqVO reqVO) {
        return success(stickerService.collectSticker(SecurityFrameworkUtils.getLoginUserId(), reqVO));
    }

    @PutMapping("/sort")
    @Operation(summary = "更新自定义表情排序")
    public CommonResult<Boolean> sortSticker(@Valid @RequestBody AppImStickerSortReqVO reqVO) {
        stickerService.sortStickers(SecurityFrameworkUtils.getLoginUserId(), reqVO);
        return success(true);
    }

    @DeleteMapping("/remove")
    @Operation(summary = "移除自定义表情")
    @Parameter(name = "id", description = "表情ID", required = true)
    public CommonResult<Boolean> removeSticker(@RequestParam("id") Long id) {
        stickerService.removeSticker(SecurityFrameworkUtils.getLoginUserId(), id);
        return success(true);
    }

    @PostMapping("/recent/use")
    @Operation(summary = "记录最近使用")
    @Parameter(name = "stickerId", description = "表情ID", required = true)
    public CommonResult<Boolean> recordRecentUse(@RequestParam("stickerId") Long stickerId) {
        stickerService.recordRecentUse(SecurityFrameworkUtils.getLoginUserId(), stickerId);
        return success(true);
    }
}
