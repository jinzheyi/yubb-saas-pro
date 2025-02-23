package com.shengyu.module.system.framework.bpm.boot.handle;

import com.shengyu.module.system.framework.bpm.engine.FlowDataTransfer;
import com.shengyu.module.system.framework.bpm.engine.core.FlowCreator;
import com.shengyu.module.system.framework.bpm.engine.entity.FlwTaskActor;
import com.aizuda.service.web.UserSession;

/**
 * 工作流辅助类
 */
public class FlowHelper {

    public static FlowCreator getFlowCreator() {
        UserSession userSession = UserSession.getLoginInfo();
        return FlowCreator.of(userSession.getUserId(), userSession.getUsername());
    }

    public static FlwTaskActor getFlwTaskActor() {
        UserSession userSession = UserSession.getLoginInfo();
        return FlwTaskActor.ofUser(null, userSession.getUserId(), userSession.getUsername());
    }

    /**
     * 传递流程审批内容
     */
    public static void setProcessApprovalOpinion(String content) {
        FlowDataTransfer.put("processApprovalOpinion", content);
    }

    public static String getProcessApprovalOpinion() {
        return FlowDataTransfer.get("processApprovalOpinion");
    }

    public static void removeProcessApprovalOpinion() {
        FlowDataTransfer.removeByKey("processApprovalOpinion");
    }
}
