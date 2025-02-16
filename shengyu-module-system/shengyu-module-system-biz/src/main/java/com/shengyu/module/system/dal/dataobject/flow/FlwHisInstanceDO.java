/*
 * Copyright 2023-2025 Licensed under the Dual Licensing
 * website: https://aizuda.com
 */
package com.shengyu.module.system.dal.dataobject.flow;

import com.aizuda.bpm.engine.assist.Assert;
import com.aizuda.bpm.engine.assist.DateUtils;
import com.aizuda.bpm.engine.core.enums.InstanceState;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.Date;

/**
 * 历史流程实例实体类
 *
 * <p>
 * <a href="https://aizuda.com">官网</a>尊重知识产权，不允许非法使用，后果自负
 * </p>
 *
 * @author hubin
 * @since 1.0
 */
@Data
@TableName("flw_his_instance")
@EqualsAndHashCode(callSuper = true)
public class FlwHisInstanceDO extends FlwInstanceDO {
    /**
     * 状态 0，活动 1，结束 更多查看 {@link InstanceState}
     */
    protected Integer instanceState;
    /**
     * 结束时间
     */
    protected Date endTime;
    /**
     * 处理耗时
     */
    protected Long duration;

    public void setVariable(Integer instanceState) {
        this.instanceState = instanceState;
    }

    public void setInstanceState(InstanceState instanceState) {
        this.instanceState = instanceState.getValue();
    }

    public void setInstanceState(Integer instanceState) {
        Assert.isNull(InstanceState.get(instanceState), "插入的实例状态异常 [instanceState=" + instanceState + "]");
        this.instanceState = instanceState;
    }

    public static FlwHisInstanceDO of(FlwInstanceDO fi, InstanceState instanceState) {
        FlwHisInstanceDO his = new FlwHisInstanceDO();
        his.setId(fi.getId());
        his.setTenantId(fi.getTenantId());
        his.setCreator(fi.getCreator());
        his.createBy = fi.getCreateBy();
        his.setCreateTime(fi.getCreateTime());
        his.processId = fi.getProcessId();
        his.parentInstanceId = fi.getParentInstanceId();
        his.priority = fi.getPriority();
        his.instanceNo = fi.getInstanceNo();
        his.businessKey = fi.getBusinessKey();
        his.variable = fi.getVariable();
        his.currentNodeName = fi.getCurrentNodeName();
        his.currentNodeKey = fi.getCurrentNodeKey();
        his.expireTime = fi.getExpireTime();
        his.lastUpdateBy = fi.getLastUpdateBy();
        his.lastUpdateTime = fi.getLastUpdateTime();
        his.instanceState = instanceState.getValue();
        if (InstanceState.active != instanceState) {
            his.calculateDuration();
        }
        return his;
    }

    public FlwInstanceDO toFlwInstance() {
        FlwInstanceDO fi = new FlwInstanceDO();
        fi.setId(this.id);
        fi.setTenantId(this.getTenantId());
        fi.setCreator(this.getCreator());
        fi.setCreateBy(this.createBy);
        fi.setCreateTime(this.getCreateTime());
        fi.setProcessId(this.processId);
        fi.setParentInstanceId(this.parentInstanceId);
        fi.setPriority(this.priority);
        fi.setInstanceNo(this.instanceNo);
        fi.setBusinessKey(this.businessKey);
        fi.setVariable(this.variable);
        fi.setCurrentNodeName(this.currentNodeName);
        fi.setCurrentNodeKey(this.currentNodeKey);
        fi.setExpireTime(this.expireTime);
        fi.setLastUpdateBy(this.lastUpdateBy);
        fi.setLastUpdateTime(this.lastUpdateTime);
        return fi;
    }

    /**
     * 计算流程实例处理耗时
     */
    public void calculateDuration() {
        this.endTime = DateUtils.getCurrentDate();
        this.duration = DateUtils.calculateDateDifference(DateUtils.toDate(this.getCreateTime()), this.endTime);
    }
}
