package com.shengyu.module.system.dal.mysql.flow;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.controller.admin.flow.vo.FlwHisTaskVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwHisTaskDO;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

@Mapper
public interface FlwHisTaskMapper extends BaseMapperX<FlwHisTaskDO> {

    /**
     * 查询流程实例ID的审批历史
     */
    default List<FlwHisTaskVO> selectListHisTaskByInstanceId(Long instanceId) {
        return BeanUtils.toBean(selectList(new LambdaQueryWrapper<FlwHisTaskDO>()
                .eq(FlwHisTaskDO::getInstanceId, instanceId)
                .orderByAsc(FlwHisTaskDO::getCreateTime)), FlwHisTaskVO.class);
    }

}
