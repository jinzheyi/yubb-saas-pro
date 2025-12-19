package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.admin.im.vo.message.ImChatMessageRespVO;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatRecallReqVO;
import com.shengyu.module.system.controller.admin.im.vo.message.ImChatSendReqVO;

/**
 * 用户聊天 Service 接口
 *
 * @author zhusy
 * @since 2022/11/23
 */
public interface ImChatService {

    /**
     * 发送消息
     *
     * @param reqVO 发送消息请求
     * @return 消息响应
     */
    ImChatMessageRespVO sendMessage(ImChatSendReqVO reqVO);

    /**
     * 获取离线消息
     */
    void getOfflineMessage();

    /**
     * 撤回消息
     *
     * @param reqVO 撤回消息请求
     * @return 消息响应
     */
    ImChatMessageRespVO recallMessage(ImChatRecallReqVO reqVO);
}
