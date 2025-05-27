package com.shengyu.module.system.framework.flow;

import com.shengyu.framework.flowlong.engine.FlowDataTransfer;
import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.entity.FlwTaskActor;
import com.shengyu.framework.security.core.LoginUser;
import com.shengyu.framework.security.core.util.SecurityFrameworkUtils;

/**
 * 工作流辅助类
 */
public class FlowHelper {

    public static FlowCreator getFlowCreator() {
        LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
        return FlowCreator.of(String.valueOf(userSession.getId()), userSession.getNickname());
    }

    public static FlwTaskActor getFlwTaskActor() {
        LoginUser userSession = SecurityFrameworkUtils.getLoginUser();
        return FlwTaskActor.ofUser(null, String.valueOf(userSession.getId()), userSession.getNickname());
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
