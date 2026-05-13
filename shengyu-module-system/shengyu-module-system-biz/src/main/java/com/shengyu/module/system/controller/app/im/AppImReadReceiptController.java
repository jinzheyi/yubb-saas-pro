package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.app.im.vo.readreceipt.AppImReadReceiptDetailReqVO;
import com.shengyu.module.system.controller.app.im.vo.readreceipt.AppImReadReceiptDetailRespVO;
import com.shengyu.module.system.controller.app.im.vo.readreceipt.AppImReadReceiptSummaryRespVO;
import com.shengyu.module.system.service.im.ImReadReceiptService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "移动端 - IM 已读回执")
@RestController
@RequestMapping("/system/im/read-receipt")
@Validated
@DataPermission(enable = false)
public class AppImReadReceiptController {

    @Resource
    private ImReadReceiptService readReceiptService;

    @GetMapping("/summary")
    @Operation(summary = "群聊已读聚合摘要")
    @Parameter(name = "messageId", description = "消息ID", required = true)
    public CommonResult<AppImReadReceiptSummaryRespVO> getSummary(@RequestParam("messageId") Long messageId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(readReceiptService.getSummary(userId, messageId));
    }

    @GetMapping("/summary/batch")
    @Operation(summary = "群聊已读聚合摘要批量查询")
    @Parameter(name = "messageIds", description = "消息ID列表", required = true)
    public CommonResult<List<AppImReadReceiptSummaryRespVO>> getSummaryBatch(@RequestParam("messageIds") List<Long> messageIds) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(readReceiptService.getSummaryBatch(userId, messageIds));
    }

    @GetMapping("/detail")
    @Operation(summary = "群聊已读/未读详情分页")
    public CommonResult<PageResult<AppImReadReceiptDetailRespVO>> getDetail(@Valid AppImReadReceiptDetailReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(readReceiptService.getDetail(userId, reqVO));
    }

}
