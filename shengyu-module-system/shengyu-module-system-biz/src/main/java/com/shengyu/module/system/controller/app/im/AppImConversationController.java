package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationSyncRespVO;
import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationUpdateReqVO;
import com.shengyu.module.system.service.im.ImBadgeService;
import com.shengyu.module.system.service.im.ImConversationService;
import com.shengyu.module.system.service.im.ImConversationSyncRateLimitService;
import com.shengyu.module.system.service.im.ImSearchRateLimitService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;
import static com.shengyu.framework.common.exception.enums.GlobalErrorCodeConstants.TOO_MANY_REQUESTS;

/**
 * 移动端 - IM 会话 Controller
 *
 * @author 圣钰科技
 */
@Tag(name = "移动端 - IM 会话")
@RestController
@RequestMapping("/system/im/conversation")
@Validated
@DataPermission(enable = false)
public class AppImConversationController {

    @Resource
    private ImConversationService conversationService;

    @Resource
    private ImBadgeService imBadgeService;

    @Resource
    private ImConversationSyncRateLimitService conversationSyncRateLimitService;

    @Resource
    private ImSearchRateLimitService searchRateLimitService;

    @GetMapping("/list")
    @Operation(summary = "获取会话列表（支持分页，默认最多返回100条）")
    @Parameter(name = "pageNo", description = "页码（可选，默认1）", required = false)
    @Parameter(name = "pageSize", description = "每页数量（可选，默认100，最大200）", required = false)
    public CommonResult<List<AppImConversationRespVO>> getConversationList(
            @RequestParam(value = "pageNo", required = false, defaultValue = "1") Integer pageNo,
            @RequestParam(value = "pageSize", required = false, defaultValue = "100") Integer pageSize) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        // 限制最大 pageSize
        if (pageSize > 200) {
            pageSize = 200;
        }
        return success(conversationService.getConversationList(userId, pageNo, pageSize));
    }

    @GetMapping("/search")
    @Operation(summary = "搜索会话（群聊/单聊）")
    public ResponseEntity<CommonResult<PageResult<AppImConversationRespVO>>> searchConversations(
            @Valid AppImConversationSearchReqVO searchReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        Long tenantId = TenantContextHolder.getTenantId();
        ImSearchRateLimitService.CheckResult checkResult =
                searchRateLimitService.check(tenantId, userId, ImSearchRateLimitService.SCENE_CONVERSATION);
        if (!checkResult.isAllowed()) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .header("Retry-After", String.valueOf(checkResult.getRetryAfterSeconds()))
                    .body(CommonResult.error(TOO_MANY_REQUESTS));
        }
        return ResponseEntity.ok(success(conversationService.searchConversations(userId, searchReqVO)));
    }

    @GetMapping("/sync")
    @Operation(summary = "会话增量同步（cursorVersion 版）")
    @Parameter(name = "cursorVersion", description = "同步游标（用户维度版本号）", required = false)
    @Parameter(name = "limit", description = "拉取条数", required = false)
    public ResponseEntity<CommonResult<AppImConversationSyncRespVO>> syncConversations(
            @RequestParam(value = "cursorVersion", required = false) Long cursorVersion,
            @RequestParam(value = "limit", required = false) Integer limit) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        Long tenantId = TenantContextHolder.getTenantId();
        ImConversationSyncRateLimitService.CheckResult checkResult = conversationSyncRateLimitService.check(tenantId, userId);
        if (!checkResult.isAllowed()) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .header("Retry-After", String.valueOf(checkResult.getRetryAfterSeconds()))
                    .body(CommonResult.error(TOO_MANY_REQUESTS));
        }
        return ResponseEntity.ok(success(conversationService.syncConversations(userId, cursorVersion, limit)));
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
    @Parameter(name = "chatId", description = "ChatID", required = true)
    public CommonResult<Boolean> deleteConversation(@RequestParam("chatId") Long chatId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        conversationService.deleteConversation(userId, chatId);
        return success(true);
    }

    @PutMapping("/mark-read-seq")
    @Operation(summary = "标记会话已读（按 sequence 水位推进）")
    @Parameter(name = "chatId", description = "ChatID", required = true)
    @Parameter(name = "readSequence", description = "已读 sequence 水位", required = true)
    public CommonResult<Boolean> markConversationReadBySequence(@RequestParam("chatId") Long chatId,
                                                               @RequestParam("readSequence") Long readSequence) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        conversationService.markConversationReadBySequence(userId, chatId, readSequence);
        imBadgeService.pushBadgeUpdate(userId);
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
