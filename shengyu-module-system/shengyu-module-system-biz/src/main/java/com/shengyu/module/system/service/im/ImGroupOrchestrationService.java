package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.app.im.vo.group.AppImGroupCreateReqVO;
import com.shengyu.module.system.controller.app.im.vo.group.AppImGroupCreateRespVO;

public interface ImGroupOrchestrationService {

    AppImGroupCreateRespVO createGroupWithConversation(Long userId, AppImGroupCreateReqVO createReqVO);
}
