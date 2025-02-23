package com.shengyu.module.system.service.flow;

import com.aizuda.boot.modules.flw.entity.FlwProcessActor;
import com.aizuda.service.service.IBaseService;

import java.util.List;

/**
 * 流程定义参与者 服务类
 *
 * @author 青苗
 * @since 2023-09-07
 */
public interface IFlwProcessActorService extends IBaseService<FlwProcessActor> {

    /**
     * 保存流程定义使用范围参与者
     *
     * @param processId        流程定义ID
     * @param flwProcessActors 使用范围参与者列表
     * @return true 成功 false 失败
     */
    boolean saveProcessActors(Long processId, List<FlwProcessActor> flwProcessActors);

    /**
     * 根据流程定义ID删除流程定义参与者
     *
     * @param processId 流程定义ID
     */
    void removeByProcessId(Long processId);

    /**
     * 根据流程定义ID查询程定义参与者列表
     *
     * @param processId 流程定义ID
     * @return true 成功 false 失败
     */
    List<FlwProcessActor> getByProcessId(Long processId);
}
