package com.shengyu.module.system.controller.admin.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.system.controller.admin.im.vo.moment.*;
import com.shengyu.module.system.dal.dataobject.im.ImMomentCommentDO;
import com.shengyu.module.system.dal.dataobject.im.ImMomentDO;
import com.shengyu.module.system.service.im.ImMomentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import java.util.List;

/**
 * 朋友圈相关业务接口
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
@Tag(name = "朋友圈相关业务接口")
@RestController
@RequestMapping("/im/moment")
@Validated
public class ImMomentController {

    @Resource
    private ImMomentService imMomentService;

    /**
     * 发布朋友圈
     *
     * @param reqVO 发布朋友圈请求
     * @return 成功响应
     */
    @PostMapping("/create")
    @Operation(summary = "发布朋友圈")
    public CommonResult<ImMomentDO> createMoment(@RequestBody @Validated ImMomentCreateReqVO reqVO) {
        ImMomentDO moment = imMomentService.createMoment(reqVO);
        return CommonResult.success(moment);
    }

    /**
     * 朋友圈点赞
     *
     * @param reqVO 点赞请求
     * @return 成功响应
     */
    @PostMapping("/like")
    @Operation(summary = "朋友圈点赞")
    public CommonResult<Boolean> likeMoment(@RequestBody @Validated ImMomentLikeReqVO reqVO) {
        boolean result = imMomentService.likeMoment(reqVO);
        return CommonResult.success(result);
    }

    /**
     * 朋友圈评论
     *
     * @param reqVO 评论请求
     * @return 评论结果
     */
    @PostMapping("/comment")
    @Operation(summary = "朋友圈评论")
    public CommonResult<ImMomentCommentDO> commentMoment(@RequestBody @Validated ImMomentCommentReqVO reqVO) {
        ImMomentCommentDO comment = imMomentService.createComment(reqVO);
        return CommonResult.success(comment);
    }

    /**
     * 获取朋友圈时间线
     *
     * @param page 页码
     * @param limit 每页数量
     * @return 朋友圈列表
     */
    @GetMapping("/timeline")
    @Operation(summary = "获取朋友圈时间线")
    public CommonResult<List<ImMomentTimelineRespVO>> getTimeline(
            @Parameter(description = "页码，默认1") @RequestParam(defaultValue = "1") Integer page,
            @Parameter(description = "每页数量，默认10") @RequestParam(defaultValue = "10") Integer limit) {
        ImMomentTimelineReqVO reqVO = new ImMomentTimelineReqVO();
        reqVO.setPage(page);
        reqVO.setLimit(limit);
        List<ImMomentTimelineRespVO> timeline = imMomentService.getTimeline(reqVO);
        return CommonResult.success(timeline);
    }

    /**
     * 获取某个用户的朋友圈列表
     *
     * @param userId 用户ID
     * @param page 页码
     * @param limit 每页数量
     * @return 朋友圈列表
     */
    @GetMapping("/list")
    @Operation(summary = "获取某个用户的朋友圈列表")
    public CommonResult<List<ImMomentListRespVO>> getMomentList(
            @Parameter(description = "用户ID") @RequestParam(required = false) Long userId,
            @Parameter(description = "页码，默认1") @RequestParam(defaultValue = "1") Integer page,
            @Parameter(description = "每页数量，默认10") @RequestParam(defaultValue = "10") Integer limit) {
        ImMomentListReqVO reqVO = new ImMomentListReqVO();
        reqVO.setUserId(userId);
        reqVO.setPage(page);
        reqVO.setLimit(limit);
        List<ImMomentListRespVO> momentList = imMomentService.getMomentList(reqVO);
        return CommonResult.success(momentList);
    }
}