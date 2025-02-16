package com.shengyu.module.system.dal.mysql.flow;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.controller.admin.flow.dto.ProcessTaskDTO;
import com.shengyu.module.system.controller.admin.flow.vo.FlwProcessVO;
import com.shengyu.module.system.controller.admin.flow.vo.PendingApprovalTaskVO;
import com.shengyu.module.system.controller.admin.user.vo.user.UserRespVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessConfigureDO;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessDO;
import com.shengyu.module.system.dal.dataobject.flow.FlwTaskDO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Arrays;
import java.util.List;

@Mapper
public interface FlwProcessMapper extends BaseMapperX<FlwProcessDO> {

    default List<FlwProcessVO> selectFlwProcessList() {
        return selectJoinList(FlwProcessVO.class,
                new MPJLambdaWrapper<FlwProcessDO>()
                        .select(FlwProcessConfigureDO::getCategoryId, FlwProcessConfigureDO::getProcessId)
                        .select(FlwProcessDO::getProcessKey, FlwProcessDO::getProcessName, FlwProcessDO::getProcessIcon,
                                FlwProcessDO::getProcessType, FlwProcessDO::getProcessVersion, FlwProcessDO::getInstanceUrl,
                                FlwProcessDO::getRemark, FlwProcessDO::getUseScope, FlwProcessDO::getProcessState, FlwProcessDO::getCreateTime)
                        .selectAs(FlwProcessDO::getSort, FlwProcessVO::getProcessSort)
                        .innerJoin(FlwProcessConfigureDO.class, FlwProcessConfigureDO::getProcessId, FlwProcessDO::getId)
                        .in(FlwProcessDO::getProcessState, Arrays.asList(0, 1))
        );
    }

    default List<FlwProcessVO> selectLaunchProcessList() {
        return selectJoinList(FlwProcessVO.class,
                new MPJLambdaWrapper<FlwProcessDO>()
                        .select(FlwProcessConfigureDO::getCategoryId, FlwProcessConfigureDO::getProcessId)
                        .select(FlwProcessDO::getProcessKey, FlwProcessDO::getProcessName, FlwProcessDO::getProcessIcon,
                                FlwProcessDO::getProcessType, FlwProcessDO::getProcessVersion, FlwProcessDO::getInstanceUrl,
                                FlwProcessDO::getRemark, FlwProcessDO::getUseScope, FlwProcessDO::getProcessState, FlwProcessDO::getCreateTime)
                        .selectAs(FlwProcessDO::getSort, FlwProcessVO::getProcessSort)
                        .innerJoin(FlwProcessConfigureDO.class, FlwProcessConfigureDO::getProcessId, FlwProcessDO::getId)
                        .eq(FlwProcessDO::getProcessState, 1)
                        .eq(FlwProcessDO::getProcessType, "main")
        );
    }

}
