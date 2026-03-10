package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessagePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessagePullReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageRespVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSearchReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.service.im.ImConversationService;
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
@DataPermission(enable = false)
public class AppImMessageController {

    @Resource
    private ImMessageService messageService;

    @Resource
    private ImChatUserMapper chatUserMapper;

    @Resource
    private ImConversationService conversationService;

    @GetMapping("/page")
    @Operation(summary = "分页查询消息列表")
    public CommonResult<PageResult<AppImMessageRespVO>> getMessagePage(
            @Valid AppImMessagePageReqVO pageReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(messageService.getMessagePage(userId, pageReqVO));
    }

    @GetMapping("/list-by-chat")
    @Operation(summary = "根据 ChatID 查询消息列表")
    @Parameter(name = "chatId", description = "ChatID", required = true)
    @Parameter(name = "pageNo", description = "页码", required = false)
    @Parameter(name = "pageSize", description = "每页数量", required = false)
    public CommonResult<PageResult<AppImMessageRespVO>> getMessageListByConversation(
            @RequestParam("chatId") Long chatId,
            @RequestParam(value = "pageNo", required = false, defaultValue = "1") Integer pageNo,
            @RequestParam(value = "pageSize", required = false, defaultValue = "20") Integer pageSize) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        AppImMessagePageReqVO pageReqVO = new AppImMessagePageReqVO();
        pageReqVO.setChatId(chatId);
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

    @GetMapping("/unread-count")
    @Operation(summary = "获取未读消息数")
    @Parameter(name = "chatId", description = "ChatID", required = false)
    public CommonResult<Integer> getUnreadCount(
            @RequestParam(value = "chatId", required = false) Long chatId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (chatId == null) {
            return success(conversationService.getUnreadCount(userId));
        }
        ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, chatId);
        if (chatUser == null || chatUser.getUnreadCount() == null) {
            return success(0);
        }
        return success(chatUser.getUnreadCount());
    }

    @GetMapping("/search")
    @Operation(summary = "搜索聊天记录")
    public CommonResult<PageResult<AppImMessageRespVO>> searchMessages(
            @Valid AppImMessageSearchReqVO searchReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(messageService.searchMessages(userId, searchReqVO));
    }

    @GetMapping("/pull")
    @Operation(summary = "增量拉取消息（断线补偿）")
    public CommonResult<List<AppImMessageRespVO>> pullMessages(@Valid AppImMessagePullReqVO pullReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(messageService.pullMessages(userId, pullReqVO));
    }

}
