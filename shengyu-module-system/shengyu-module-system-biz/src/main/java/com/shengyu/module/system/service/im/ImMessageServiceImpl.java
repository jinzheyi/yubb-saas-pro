package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessagePageReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageRespVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSearchReqVO;
import com.shengyu.module.system.controller.app.im.vo.message.AppImMessageSendReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImConversationDO;
import com.shengyu.module.system.dal.dataobject.im.ImMessageDO;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import com.shengyu.module.system.dal.mysql.im.ImMessageMapper;
import com.shengyu.module.system.dal.mysql.user.AdminUserMapper;
import com.shengyu.module.system.enums.im.ImMessageStatusEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.*;

/**
 * IM 消息 Service 实现类
 *
 * @author 圣钰科技
 */
@Service
@Slf4j
public class ImMessageServiceImpl implements ImMessageService {

    @Resource
    private ImMessageMapper messageMapper;

    @Resource
    private ImConversationService conversationService;

    @Resource
    private AdminUserMapper userMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long sendMessage(Long userId, AppImMessageSendReqVO sendReqVO) {
        // 验证会话是否存在
        ImConversationDO conversation = conversationService.getConversation(sendReqVO.getConversationId());
        if (conversation == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 创建消息
        ImMessageDO message = new ImMessageDO();
        message.setConversationId(sendReqVO.getConversationId());
        message.setSenderId(userId);
        message.setReceiverId(sendReqVO.getReceiverId());
        message.setGroupId(sendReqVO.getGroupId());
        message.setMessageType(sendReqVO.getMessageType());
        message.setContent(sendReqVO.getContent());
        message.setExtra(sendReqVO.getExtra());
        message.setSendTime(LocalDateTime.now());
        message.setStatus(ImMessageStatusEnum.SENT.getStatus());
        message.setQuoteMessageId(sendReqVO.getQuoteMessageId());
        messageMapper.insert(message);

        // 更新会话的最后消息
        conversationService.updateLastMessage(
                sendReqVO.getConversationId(),
                message.getId(),
                getMessagePreview(sendReqVO.getMessageType(), sendReqVO.getContent())
        );

        // 增加接收者的未读数
        conversationService.incrementUnreadCount(sendReqVO.getConversationId());

        return message.getId();
    }

    @Override
    public PageResult<AppImMessageRespVO> getMessagePage(Long userId, AppImMessagePageReqVO pageReqVO) {
        // 验证会话是否存在
        ImConversationDO conversation = conversationService.getConversation(pageReqVO.getConversationId());
        if (conversation == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 分页查询消息
        PageResult<ImMessageDO> pageResult = messageMapper.selectPageByConversationId(
                pageReqVO.getConversationId(),
                pageReqVO
        );

        // 转换为VO并填充发送者信息
        List<AppImMessageRespVO> respVOList = pageResult.getList().stream().map(message -> {
            AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
            fillSenderInfo(respVO, message);
            respVO.setIsSelf(message.getSenderId().equals(userId));
            return respVO;
        }).collect(Collectors.toList());

        return new PageResult<>(respVOList, pageResult.getTotal());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void recallMessage(Long userId, Long messageId) {
        // 查询消息
        ImMessageDO message = messageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        // 验证权限(只能撤回自己的消息)
        if (!message.getSenderId().equals(userId)) {
            throw exception(MESSAGE_RECALL_PERMISSION_DENIED);
        }

        // 验证时间(只能撤回2分钟内的消息)
        LocalDateTime twoMinutesAgo = LocalDateTime.now().minusMinutes(2);
        if (message.getSendTime().isBefore(twoMinutesAgo)) {
            throw exception(MESSAGE_RECALL_TIMEOUT);
        }

        // 更新消息状态为已撤回
        message.setStatus(ImMessageStatusEnum.RECALLED.getStatus());
        message.setRecallTime(LocalDateTime.now());
        message.setRecallBy(userId);
        messageMapper.updateById(message);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteMessage(Long userId, Long messageId) {
        // 查询消息
        ImMessageDO message = messageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        // 删除消息(物理删除)
        messageMapper.deleteById(messageId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markMessageRead(Long userId, Long messageId) {
        // 查询消息
        ImMessageDO message = messageMapper.selectById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_EXISTS);
        }

        // 只能标记发给自己的消息
        if (!message.getReceiverId().equals(userId)) {
            return;
        }

        // 更新消息状态为已读
        if (!ImMessageStatusEnum.isRead(message.getStatus())) {
            message.setStatus(ImMessageStatusEnum.READ.getStatus());
            messageMapper.updateById(message);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markMessagesRead(Long userId, List<Long> messageIds) {
        for (Long messageId : messageIds) {
            markMessageRead(userId, messageId);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void clearConversationMessages(Long userId, Long conversationId) {
        // 验证会话是否存在
        ImConversationDO conversation = conversationService.getConversation(conversationId);
        if (conversation == null || !conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 删除会话的所有消息(物理删除)
        // 注意: 这里简化处理,实际应该只删除用户自己的消息记录
        // TODO: 实现消息的用户级删除标记
        log.warn("清空会话消息功能待完善，conversationId: {}, userId: {}", conversationId, userId);
    }

    @Override
    public PageResult<AppImMessageRespVO> searchMessages(Long userId, AppImMessageSearchReqVO searchReqVO) {
        // 验证会话是否存在
        ImConversationDO conversation = conversationService.getConversation(searchReqVO.getConversationId());
        if (conversation == null) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 验证权限：用户必须是会话参与者
        if (!conversation.getUserId().equals(userId)) {
            throw exception(CONVERSATION_NOT_EXISTS);
        }

        // 搜索消息
        PageResult<ImMessageDO> pageResult = messageMapper.searchMessages(
                searchReqVO.getConversationId(),
                searchReqVO.getKeyword(),
                searchReqVO.getStartTime(),
                searchReqVO.getEndTime(),
                searchReqVO
        );

        // 转换为VO并填充发送者信息
        List<AppImMessageRespVO> respVOList = pageResult.getList().stream().map(message -> {
            AppImMessageRespVO respVO = BeanUtils.toBean(message, AppImMessageRespVO.class);
            fillSenderInfo(respVO, message);
            respVO.setIsSelf(message.getSenderId().equals(userId));
            return respVO;
        }).collect(Collectors.toList());

        return new PageResult<>(respVOList, pageResult.getTotal());
    }

    /**
     * 填充发送者信息
     */
    private void fillSenderInfo(AppImMessageRespVO respVO, ImMessageDO message) {
        AdminUserDO sender = userMapper.selectById(message.getSenderId());
        if (sender != null) {
            respVO.setSenderNickname(sender.getNickname());
            respVO.setSenderAvatar(sender.getAvatar());
        }
    }

    /**
     * 获取消息预览文本
     */
    private String getMessagePreview(Integer messageType, String content) {
        switch (messageType) {
            case 1: // 文本
                return content.length() > 50 ? content.substring(0, 50) + "..." : content;
            case 2: // 图片
                return "[图片]";
            case 3: // 语音
                return "[语音]";
            case 4: // 视频
                return "[视频]";
            case 5: // 文件
                return "[文件]";
            case 6: // 位置
                return "[位置]";
            case 7: // 表情包
                return "[表情]";
            case 8: // 自定义贴纸
                return "[贴纸]";
            case 10: // 系统消息
                return "[系统消息]";
            default:
                return "[未知消息]";
        }
    }

}
