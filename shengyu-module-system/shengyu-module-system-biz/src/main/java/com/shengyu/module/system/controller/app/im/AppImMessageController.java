package com.shengyu.module.system.controller.app.im;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.datapermission.core.annotation.DataPermission;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageForwardReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageHistoryReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageHistoryRespVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessagePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessagePullReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageRecallConfigRespVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageRespVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSendReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageWindowReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageWindowRespVO;
import com.shengyu.module.system.dal.dataobject.im.ImChatUserDO;
import com.shengyu.module.system.dal.dataobject.im.ImChatMessageDO;
import com.shengyu.module.system.dal.mysql.im.ImChatMessageMapper;
import com.shengyu.module.system.dal.mysql.im.ImChatUserMapper;
import com.shengyu.module.system.enums.im.ImMessageStatusEnum;
import com.shengyu.module.system.service.im.ImConversationService;
import com.shengyu.module.system.service.im.ImMessageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

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
    private ImChatMessageMapper chatMessageMapper;

    @Resource
    private ImConversationService conversationService;

    @GetMapping("/page")
    @Operation(summary = "分页查询消息列表")
    public CommonResult<PageResult<AppImMessageRespVO>> getMessagePage(
            @Valid AppImMessagePageReqVO pageReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(messageService.getMessagePage(userId, pageReqVO));
    }

    @PostMapping("/send")
    @Operation(summary = "发送消息（REST兜底）")
    public CommonResult<String> sendMessage(@Valid @RequestBody AppImMessageSendReqVO sendReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        Long messageId = messageService.sendMessage(userId, sendReqVO);
        return success(messageId == null ? "0" : String.valueOf(messageId));
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

    @GetMapping("/window")
    @Operation(summary = "查询聊天页消息窗口（latest / anchor）")
    public CommonResult<AppImMessageWindowRespVO> getMessageWindow(@Valid AppImMessageWindowReqVO windowReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(messageService.getMessageWindow(userId, windowReqVO));
    }

    @GetMapping("/history")
    @Operation(summary = "查询更早历史消息")
    public CommonResult<AppImMessageHistoryRespVO> getMessageHistory(@Valid AppImMessageHistoryReqVO historyReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(messageService.getMessageHistory(userId, historyReqVO));
    }

    @PutMapping("/recall")
    @Operation(summary = "撤回消息")
    @Parameter(name = "id", description = "消息ID", required = true)
    public CommonResult<Boolean> recallMessage(@RequestParam("id") Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        messageService.recallMessage(userId, id);
        return success(true);
    }

    @GetMapping("/recall-config")
    @Operation(summary = "获取撤回窗口配置")
    public CommonResult<AppImMessageRecallConfigRespVO> getRecallConfig() {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(messageService.getRecallConfig(userId));
    }

    @DeleteMapping("/delete")
    @Operation(summary = "删除消息")
    @Parameter(name = "id", description = "消息ID", required = true)
    public CommonResult<Boolean> deleteMessage(@RequestParam("id") Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        messageService.deleteMessage(userId, id);
        return success(true);
    }

    @DeleteMapping("/clear")
    @Operation(summary = "清空聊天记录（对我清空，多端一致）")
    @Parameter(name = "chatId", description = "ChatID", required = true)
    public CommonResult<Boolean> clearConversationMessages(@RequestParam("chatId") Long chatId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        messageService.clearConversationMessages(userId, chatId);
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

    @GetMapping("/detail")
    @Operation(summary = "获取消息详情")
    @Parameter(name = "id", description = "消息ID", required = true)
    public CommonResult<AppImMessageRespVO> getMessageDetail(@RequestParam("id") Long id) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(messageService.getMessageDetail(userId, id));
    }

    @PutMapping("/mark-read")
    @Operation(summary = "标记消息已读（按 messageIds 批量）")
    @Parameter(name = "messageIds", description = "消息ID列表", required = true)
    public CommonResult<Boolean> markMessageRead(@RequestParam("messageIds") List<Long> messageIds) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        if (messageIds == null || messageIds.isEmpty()) {
            return success(true);
        }

        // 仅允许标记自己可见的会话消息，避免越权/误更新
        List<ImChatMessageDO> messages = chatMessageMapper.selectBatchIds(messageIds);
        if (messages == null || messages.isEmpty()) {
            return success(true);
        }
        List<Long> filteredIds = new ArrayList<>();
        for (ImChatMessageDO m : messages) {
            if (m == null || m.getId() == null || m.getChatId() == null) {
                continue;
            }
            ImChatUserDO chatUser = chatUserMapper.selectByUserIdAndChatId(userId, m.getChatId());
            if (chatUser == null) {
                continue;
            }
            // 自己发送的消息无需标记为已读也可更新（幂等），这里不做强限制
            filteredIds.add(m.getId());
        }
        if (filteredIds.isEmpty()) {
            return success(true);
        }
        messageService.batchUpdateMessageStatus(userId, filteredIds, ImMessageStatusEnum.READ.getStatus());
        return success(true);
    }

    @PutMapping("/mark-voice-played")
    @Operation(summary = "标记语音消息已播放（多端同步未听点）")
    @Parameter(name = "messageId", description = "语音消息ID", required = true)
    public CommonResult<Boolean> markVoicePlayed(@RequestParam("messageId") Long messageId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        messageService.markVoicePlayed(userId, messageId);
        return success(true);
    }

    @PutMapping("/mark-voice-played-batch")
    @Operation(summary = "鎵归噺鏍囪璇煶娑堟伅宸叉挱鏀撅紙绔晶鑱氬悎涓婃姤锛?")
    @Parameter(name = "messageIds", description = "璇煶娑堟伅ID鍒楄〃", required = true)
    public CommonResult<Boolean> markVoicePlayedBatch(@RequestParam("messageIds") List<Long> messageIds) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        messageService.batchMarkVoicePlayed(userId, messageIds);
        return success(true);
    }

    @GetMapping("/voice-played-status")
    @Operation(summary = "鏌ヨ璇煶宸叉挱鏀剧姸鎬侊紙鎺ㄩ€佷涪澶辫ˉ鍋匡級")
    @Parameter(name = "chatId", description = "浼氳瘽ID", required = true)
    @Parameter(name = "messageIds", description = "璇煶娑堟伅ID鍒楄〃", required = true)
    public CommonResult<List<String>> getVoicePlayedStatus(
            @RequestParam("chatId") Long chatId,
            @RequestParam("messageIds") List<Long> messageIds) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        List<Long> playedIds = messageService.getVoicePlayedMessageIds(userId, chatId, messageIds);
        List<String> result = new ArrayList<>();
        if (playedIds != null) {
            for (Long id : playedIds) {
                if (id != null) {
                    result.add(String.valueOf(id));
                }
            }
        }
        return success(result);
    }

    @PostMapping("/forward")
    @Operation(summary = "转发消息（支持逐条转发和合并转发）")
    public CommonResult<List<String>> forwardMessages(@Valid @RequestBody AppImMessageForwardReqVO forwardReqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        List<Long> newMessageIds = messageService.forwardMessages(userId, forwardReqVO);
        List<String> result = new ArrayList<>();
        for (Long id : newMessageIds) {
            if (id != null) {
                result.add(String.valueOf(id));
            }
        }
        return success(result);
    }

    @PostMapping("/forward-single")
    @Operation(summary = "单条转发消息（简化接口）")
    @Parameter(name = "messageId", description = "原消息ID", required = true)
    @Parameter(name = "targetChatId", description = "目标会话ID", required = true)
    public CommonResult<Long> forwardSingleMessage(
            @RequestParam("messageId") Long messageId,
            @RequestParam("targetChatId") Long targetChatId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        Long newMessageId = messageService.forwardMessage(userId, messageId, targetChatId);
        return success(newMessageId);
    }

}
