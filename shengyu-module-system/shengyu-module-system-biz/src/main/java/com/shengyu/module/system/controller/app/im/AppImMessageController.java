package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessagePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageRespVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSearchReqVO;
import com.shengyu.module.system.service.im.ImMessageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

/**
 * 移动端 - IM 消息 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - IM 消息")
@RestController
@RequestMapping("/system/im/message")
@Validated
public class AppImMessageController {

    @Resource
    private ImMessageService messageService;

    @GetMapping("/page")
    @Operation(summary = "分页查询消息列表")
    public CommonResult<PageResult<AppImMessageRespVO>> getMessagePage(
            @Valid AppImMessagePageReqVO pageReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(messageService.getMessagePage(userId, pageReqVO));
    }

    @GetMapping("/list-by-conversation")
    @Operation(summary = "根据会话ID查询消息列表")
    @Parameter(name = "conversationId", description = "会话ID", required = true)
    @Parameter(name = "pageNo", description = "页码", required = false)
    @Parameter(name = "pageSize", description = "每页数量", required = false)
    public CommonResult<PageResult<AppImMessageRespVO>> getMessageListByConversation(
            @RequestParam("conversationId") Long conversationId,
            @RequestParam(value = "pageNo", required = false, defaultValue = "1") Integer pageNo,
            @RequestParam(value = "pageSize", required = false, defaultValue = "20") Integer pageSize) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        AppImMessagePageReqVO pageReqVO = new AppImMessagePageReqVO();
        pageReqVO.setConversationId(conversationId);
        pageReqVO.setPageNo(pageNo);
        pageReqVO.setPageSize(pageSize);
        return success(messageService.getMessagePage(userId, pageReqVO));
    }

    @GetMapping("/list-by-group")
    @Operation(summary = "根据群组ID查询消息列表")
    @Parameter(name = "groupId", description = "群组ID", required = true)
    @Parameter(name = "pageNo", description = "页码", required = false)
    @Parameter(name = "pageSize", description = "每页数量", required = false)
    public CommonResult<PageResult<AppImMessageRespVO>> getMessageListByGroup(
            @RequestParam("groupId") Long groupId,
            @RequestParam(value = "pageNo", required = false, defaultValue = "1") Integer pageNo,
            @RequestParam(value = "pageSize", required = false, defaultValue = "20") Integer pageSize) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        // 通过群组ID查询会话ID
        // TODO: 需要先查询会话ID
        AppImMessagePageReqVO pageReqVO = new AppImMessagePageReqVO();
        pageReqVO.setPageNo(pageNo);
        pageReqVO.setPageSize(pageSize);
        return success(messageService.getMessagePage(userId, pageReqVO));
    }

    @PutMapping("/recall")
    @Operation(summary = "撤回消息")
    @Parameter(name = "id", description = "消息ID", required = true)
    public CommonResult<Boolean> recallMessage(@RequestParam("id") Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        messageService.recallMessage(userId, id);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除消息")
    @Parameter(name = "id", description = "消息ID", required = true)
    public CommonResult<Boolean> deleteMessage(@RequestParam("id") Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        messageService.deleteMessage(userId, id);
        return success(true);
    }

    @PutMapping("/mark-read")
    @Operation(summary = "标记消息已读")
    @Parameter(name = "messageIds", description = "消息ID列表", required = true)
    public CommonResult<Boolean> markMessageRead(@RequestParam("messageIds") List<Long> messageIds) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        messageService.markMessagesRead(userId, messageIds);
        return success(true);
    }

    @GetMapping("/unread-count")
    @Operation(summary = "获取未读消息数")
    @Parameter(name = "conversationId", description = "会话ID", required = false)
    public CommonResult<Integer> getUnreadCount(
            @RequestParam(value = "conversationId", required = false) Long conversationId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        // TODO: 实现未读消息数统计
        return success(0);
    }

    @GetMapping("/search")
    @Operation(summary = "搜索聊天记录")
    public CommonResult<PageResult<AppImMessageRespVO>> searchMessages(
            @Valid AppImMessageSearchReqVO searchReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(messageService.searchMessages(userId, searchReqVO));
    }

}
