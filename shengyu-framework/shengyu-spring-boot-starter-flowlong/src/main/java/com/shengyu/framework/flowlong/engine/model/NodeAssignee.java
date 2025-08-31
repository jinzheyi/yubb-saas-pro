/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.framework.flowlong.engine.model;

import cn.hutool.core.text.CharSequenceUtil;
import com.shengyu.framework.flowlong.engine.core.FlowCreator;
import com.shengyu.framework.flowlong.engine.core.FlowLongContext;
import com.shengyu.framework.flowlong.engine.entity.FlwTaskActor;
import lombok.Getter;
import lombok.Setter;

import java.io.Serializable;
import java.util.Map;

/**
 * JSON BPM 分配到任务的人或角色
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
@Getter
@Setter
public class NodeAssignee implements Serializable {
    /**
     * 租户ID
     */
    private Long tenantId;
    /**
     * 主键ID
     */
    private String id;
    /**
     * 名称
     */
    private String name;
    /**
     * 权重（ 用于票签，多个参与者合计权重 100% ）
     */
    private Integer weight;
    /**
     * 已阅 0，否 1，是
     */
    private Integer viewed;
    /**
     * 扩展配置，用于存储头像、等其它信息
     */
    private Map<String, Object> extendConfig;

    public static NodeAssignee of(FlwTaskActor flwTaskActor) {
        NodeAssignee nodeAssignee = new NodeAssignee();
        nodeAssignee.setTenantId(flwTaskActor.getTenantId());
        nodeAssignee.setId(flwTaskActor.getActorId());
        nodeAssignee.setName(flwTaskActor.getActorName());
        nodeAssignee.setWeight(flwTaskActor.getWeight());
        nodeAssignee.setViewed(flwTaskActor.getViewed());
        nodeAssignee.setExtendConfig(CharSequenceUtil.isNotBlank(flwTaskActor.getExtend())?
          FlowLongContext.str2map(flwTaskActor.getExtend()) : null);
        return nodeAssignee;
    }

    public static NodeAssignee ofFlowCreator(FlowCreator flowCreator) {
        NodeAssignee nodeAssignee = new NodeAssignee();
        nodeAssignee.setTenantId(flowCreator.getTenantId());
        nodeAssignee.setId(flowCreator.getCreateId());
        nodeAssignee.setName(flowCreator.getCreateBy());
        return nodeAssignee;
    }
}
