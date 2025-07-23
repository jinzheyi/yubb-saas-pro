package com.shengyu.module.system.dal.mysql.flow;

import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.flowlong.engine.core.enums.FlowState;
import com.shengyu.framework.flowlong.engine.core.enums.ProcessType;
import com.shengyu.framework.flowlong.engine.entity.FlwProcess;
import com.shengyu.framework.flowlong.engine.mapper.FlwProcessMapper;
import com.shengyu.module.system.controller.admin.flow.vo.FlwProcessVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessConfigure;
import java.util.Arrays;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.context.annotation.Primary;

@Primary
@Mapper
public interface SyFlwProcessMapper extends FlwProcessMapper {

    default List<FlwProcessVO> selectFlwProcessList() {
        return selectJoinList(FlwProcessVO.class,
                new MPJLambdaWrapper<FlwProcess>()
                        .select(
                          FlwProcessConfigure::getCategoryId,
                          FlwProcessConfigure::getProcessId)
                        .select(
                          FlwProcess::getProcessKey,
                          FlwProcess::getProcessName,
                          FlwProcess::getProcessIcon,
                          FlwProcess::getProcessType,
                          FlwProcess::getProcessVersion,
                          FlwProcess::getInstanceUrl,
                          FlwProcess::getRemark,
                          FlwProcess::getUseScope,
                          FlwProcess::getProcessState,
                          FlwProcess::getCreateTime)
                        .selectAs(FlwProcess::getSort, FlwProcessVO::getProcessSort)
                        .innerJoin(FlwProcessConfigure.class, FlwProcessConfigure::getProcessId, FlwProcess::getId)
                        .in(FlwProcess::getProcessState, Arrays.asList(FlowState.inactive.getValue(), FlowState.active.getValue()))
        );
    }

    /**
     * 查询已启用的主流程列表
     * @return List<FlwProcessVO>
     */
    default List<FlwProcessVO> selectLaunchProcessList() {
        return selectJoinList(FlwProcessVO.class,
                new MPJLambdaWrapper<FlwProcess>()
                        .select(FlwProcessConfigure::getCategoryId, FlwProcessConfigure::getProcessId)
                        .select(
                          FlwProcess::getProcessKey,
                          FlwProcess::getProcessName,
                          FlwProcess::getProcessIcon,
                          FlwProcess::getProcessType,
                          FlwProcess::getProcessVersion,
                          FlwProcess::getInstanceUrl,
                          FlwProcess::getRemark,
                          FlwProcess::getUseScope,
                          FlwProcess::getProcessState,
                          FlwProcess::getCreateTime)
                        .selectAs(FlwProcess::getSort, FlwProcessVO::getProcessSort)
                        .innerJoin(FlwProcessConfigure.class, FlwProcessConfigure::getProcessId, FlwProcess::getId)
                        .eq(FlwProcess::getProcessState, FlowState.active.getValue())
                        .eq(FlwProcess::getProcessType, ProcessType.main.name())
        );
    }

}
