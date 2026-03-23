package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.group.AppImGroupCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.group.AppImGroupCreateRespVO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;

import static com.shengyu.framework.common.exception.util.ServiceExceptionUtil.exception;
import static com.shengyu.module.system.enums.ErrorCodeConstants.CONVERSATION_CREATE_FAILED;

@Service
public class ImGroupOrchestrationServiceImpl implements ImGroupOrchestrationService {

    @Resource
    private ImGroupService groupService;

    @Resource
    private ImConversationService conversationService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AppImGroupCreateRespVO createGroupWithConversation(Long userId, AppImGroupCreateReqVO createReqVO) {
        Long groupId = groupService.createGroup(userId, createReqVO);
        AppImConversationRespVO conversation = conversationService.getOrCreateGroupConversation(userId, groupId);
        if (conversation == null || conversation.getChatId() == null) {
            throw exception(CONVERSATION_CREATE_FAILED);
        }
        AppImGroupCreateRespVO respVO = new AppImGroupCreateRespVO();
        respVO.setGroupId(groupId);
        respVO.setChatId(conversation.getChatId());
        return respVO;
    }
}
