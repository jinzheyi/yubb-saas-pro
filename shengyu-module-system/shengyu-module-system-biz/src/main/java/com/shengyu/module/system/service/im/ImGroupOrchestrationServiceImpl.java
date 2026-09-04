package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.app.im.vo.conversation.AppImConversationRespVO;
import com.shengyu.module.system.controller.app.im.vo.group.AppImGroupCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.group.AppImGroupCreateRespVO;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

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
        // 群组接口返回后用户就可以立刻发送首条消息。必须在同一事务内为
        // 每位初始成员初始化会话，不能依赖提交后的异步刷新，否则接收方的
        // Socket 会话快照可能在首条消息到来时尚不存在。
        List<Long> memberIds = new ArrayList<>();
        if (createReqVO.getMemberIds() != null) {
            for (Long memberId : createReqVO.getMemberIds()) {
                if (memberId != null && !memberIds.contains(memberId)) {
                    memberIds.add(memberId);
                }
            }
        }
        if (!memberIds.contains(userId)) {
            memberIds.add(userId);
        }

        AppImConversationRespVO conversation = null;
        for (Long memberId : memberIds) {
            AppImConversationRespVO memberConversation =
                    conversationService.getOrCreateGroupConversation(memberId, groupId);
            if (Objects.equals(memberId, userId)) {
                conversation = memberConversation;
            }
        }
        if (conversation == null || conversation.getChatId() == null) {
            throw exception(CONVERSATION_CREATE_FAILED);
        }
        AppImGroupCreateRespVO respVO = new AppImGroupCreateRespVO();
        respVO.setGroupId(groupId);
        respVO.setChatId(conversation.getChatId());
        return respVO;
    }
}
