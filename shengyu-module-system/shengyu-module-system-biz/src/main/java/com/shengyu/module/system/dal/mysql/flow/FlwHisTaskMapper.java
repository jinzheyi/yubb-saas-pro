package com.shengyu.module.system.dal.mysql.flow;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.controller.admin.flow.vo.FlwHisTaskVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwHisTask;
import com.shengyu.module.system.dal.dataobject.flow.FlwTask;
import com.shengyu.module.system.framework.engine.assist.Assert;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface FlwHisTaskMapper extends BaseMapperX<FlwHisTask> {

    /**
     * 查询流程实例ID的审批历史
     */
    default List<FlwHisTaskVO> selectListHisTaskByInstanceId(Long instanceId) {
        return BeanUtils.toBean(selectList(new LambdaQueryWrapper<FlwHisTask>()
                .eq(FlwHisTask::getInstanceId, instanceId)
                .orderByAsc(FlwHisTask::getCreateTime)), FlwHisTaskVO.class);
    }

    /**
     * 获取历史任务并检查ID的合法性
     *
     * @param id 任务ID
     * @return {@link FlwTask}
     */
    default FlwHisTask getCheckById(Long id) {
        FlwHisTask hisTask = selectById(id);
        Assert.isNull(hisTask, "指定的任务[id=" + id + "]不存在");
        return hisTask;
    }

}
