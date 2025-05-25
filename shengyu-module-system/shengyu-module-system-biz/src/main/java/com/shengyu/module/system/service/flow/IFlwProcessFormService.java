package com.shengyu.module.system.service.flow;

import com.shengyu.framework.mybatis.core.service.IBaseService;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessForm;

/**
 * 流程定义表单 服务类
 *
 * @author hubin
 * @since 2024-02-29
 */
public interface IFlwProcessFormService extends IBaseService<FlwProcessForm> {

    /**
     * 保存表单内容
     *
     * @param instanceId 流程实例ID
     * @param content    表单内容
     */
    boolean saveForm(Long instanceId, String content);

    /**
     * 根据 流程实例ID 获取流程定义表单
     *
     * @param instanceId 流程实例ID
     */
    FlwProcessForm getByInstanceId(Long instanceId);
}
