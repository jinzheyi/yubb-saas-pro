package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationUpdateReqVO;
import com.shengyu.module.system.service.im.ImConversationService;
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
 * 移动端 - IM 会话 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - IM 会话")
@RestController
@RequestMapping("/system/im/conversation")
@Validated
public class AppImConversationController {

    @Resource
    private ImConversationService conversationService;

    @GetMapping("/list")
    @Operation(summary = "获取会话列表")
    public CommonResult<List<AppImConversationRespVO>> getConversationList() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(conversationService.getConversationList(userId));
    }

    @GetMapping("/list-by-type")
    @Operation(summary = "根据类型获取会话列表")
    @Parameter(name = "conversationType", description = "会话类型(1-单聊 2-群聊)", required = true)
    public CommonResult<List<AppImConversationRespVO>> getConversationListByType(
            @RequestParam("conversationType") Integer conversationType) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(conversationService.getConversationListByType(userId, conversationType));
    }

    @PostMapping("/create")
    @Operation(summary = "创建或获取会话")
    public CommonResult<AppImConversationRespVO> createOrGetConversation(
            @Valid @RequestBody AppImConversationCreateReqVO createReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(conversationService.createOrGetConversation(userId, createReqVO));
    }

    @PutMapping("/update")
    @Operation(summary = "更新会话设置")
    public CommonResult<Boolean> updateConversation(
            @Valid @RequestBody AppImConversationUpdateReqVO updateReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        conversationService.updateConversation(userId, updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除会话")
    @Parameter(name = "id", description = "会话ID", required = true)
    public CommonResult<Boolean> deleteConversation(@RequestParam("id") Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        conversationService.deleteConversation(userId, id);
        return success(true);
    }

    @PutMapping("/mark-read")
    @Operation(summary = "标记会话已读")
    @Parameter(name = "id", description = "会话ID", required = true)
    public CommonResult<Boolean> markConversationRead(@RequestParam("id") Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        conversationService.markConversationRead(userId, id);
        return success(true);
    }

    @GetMapping("/unread-count")
    @Operation(summary = "获取未读消息总数")
    public CommonResult<Integer> getUnreadCount() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(conversationService.getUnreadCount(userId));
    }

    @GetMapping("/get-by-target")
    @Operation(summary = "根据目标ID和类型获取会话")
    @Parameter(name = "targetId", description = "目标ID(单聊为对方用户ID,群聊为群ID)", required = true)
    @Parameter(name = "conversationType", description = "会话类型(1-单聊 2-群聊)", required = true)
    public CommonResult<AppImConversationRespVO> getConversationByTarget(
            @RequestParam("targetId") Long targetId,
            @RequestParam("conversationType") Integer conversationType) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        // 先尝试获取已存在的会话
        AppImConversationCreateReqVO createReqVO = new AppImConversationCreateReqVO();
        createReqVO.setTargetId(targetId);
        createReqVO.setConversationType(conversationType);
        return success(conversationService.createOrGetConversation(userId, createReqVO));
    }

}
