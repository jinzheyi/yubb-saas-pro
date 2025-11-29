package com.shengyu.module.im.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.module.im.constants.ImConstants;
import com.shengyu.module.im.dal.dataobject.ImMessageDO;
import com.shengyu.module.im.dal.mapper.ImMessageMapper;
import com.shengyu.module.im.dto.ImMessage;
import com.shengyu.module.im.enums.ErrorCodeConstants;
import com.shengyu.module.im.service.ImMessageService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import java.util.Date;
import java.util.List;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;

/**
 * IM消息服务实现类
 *
 * @author 圣钰科技
 */
@Slf4j
@Service
@Validated
public class ImMessageServiceImpl implements ImMessageService {

    @Autowired
    private ImMessageMapper imMessageMapper;

    @Override
    public Long saveMessage(ImMessage message) {
        ImMessageDO messageDO = new ImMessageDO();
        messageDO.setMessageId(message.getMessageId());
        messageDO.setType(message.getType());
        messageDO.setSenderId(message.getSenderId());
        messageDO.setReceiverId(message.getReceiverId());
        messageDO.setContent(message.getContent());
        messageDO.setStatus(message.getStatus());
        messageDO.setExt(message.getExt());
        imMessageMapper.insert(messageDO);
        return messageDO.getId();
    }

    @Override
    public List<ImMessageDO> getSingleChatHistory(Long senderId, Long receiverId, Integer limit, Integer offset) {
        return imMessageMapper.getSingleChatHistory(senderId, receiverId, limit, offset);
    }

    @Override
    public List<ImMessageDO> getGroupChatHistory(Long groupId, Integer limit, Integer offset) {
        return imMessageMapper.getGroupChatHistory(groupId, limit, offset);
    }

    @Override
    public List<ImMessageDO> getUnreadMessages(Long userId) {
        return imMessageMapper.getUnreadMessages(userId);
    }

    @Override
    public boolean updateMessageStatus(String messageId, Integer status) {
        ImMessageDO messageDO = new ImMessageDO();
        messageDO.setStatus(status);
        
        LambdaQueryWrapper<ImMessageDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImMessageDO::getMessageId, messageId);
        
        int result = imMessageMapper.update(messageDO, wrapper);
        return result > 0;
    }

    @Override
    public int batchUpdateMessageStatus(List<String> messageIds, Integer status) {
        return imMessageMapper.batchUpdateStatus(messageIds, status);
    }

    @Override
    public boolean deleteMessage(String messageId) {
        ImMessageDO messageDO = new ImMessageDO();
        messageDO.setStatus(ImConstants.MESSAGE_STATUS_DELETED); // 2表示已删除
        
        LambdaQueryWrapper<ImMessageDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImMessageDO::getMessageId, messageId);
        
        int result = imMessageMapper.update(messageDO, wrapper);
        return result > 0;
    }

    @Override
    public boolean recallMessage(String messageId, Long senderId) {
        // 检查消息是否存在且发送者是当前用户
        LambdaQueryWrapper<ImMessageDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ImMessageDO::getMessageId, messageId);
        wrapper.eq(ImMessageDO::getSenderId, senderId);
        
        ImMessageDO messageDO = imMessageMapper.selectOne(wrapper);
        if (messageDO == null) {
            throw exception(ErrorCodeConstants.IM_MESSAGE_NOT_EXISTS);
        }
        
        // 检查消息是否可以撤回（通常在发送后2分钟内）
        long now = System.currentTimeMillis();
        long sendTime = messageDO.getCreateTime().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();
        if (now - sendTime > ImConstants.MESSAGE_RECALL_TIMEOUT) { // 2分钟
            throw exception(ErrorCodeConstants.IM_MESSAGE_RECALL_TIMEOUT);
        }
        
        // 更新消息状态为撤回
        messageDO.setStatus(ImConstants.MESSAGE_STATUS_RECALLED); // 3表示已撤回
        
        int result = imMessageMapper.updateById(messageDO);
        return result > 0;
    }
}
