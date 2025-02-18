package com.shengyu.module.system.dal.mysql.flow;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.controller.admin.flow.vo.FlwProcessVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcessConfigure;
import com.shengyu.module.system.dal.dataobject.flow.FlwProcess;
import org.apache.ibatis.annotations.Mapper;

import java.util.Arrays;
import java.util.List;

@Mapper
public interface FlwProcessMapper extends BaseMapperX<FlwProcess> {

    default List<FlwProcessVO> selectFlwProcessList() {
        return selectJoinList(FlwProcessVO.class,
                new MPJLambdaWrapper<FlwProcess>()
                        .select(FlwProcessConfigure::getCategoryId, FlwProcessConfigure::getProcessId)
                        .select(FlwProcess::getProcessKey, FlwProcess::getProcessName, FlwProcess::getProcessIcon,
                                FlwProcess::getProcessType, FlwProcess::getProcessVersion, FlwProcess::getInstanceUrl,
                                FlwProcess::getRemark, FlwProcess::getUseScope, FlwProcess::getProcessState, FlwProcess::getCreateTime)
                        .selectAs(FlwProcess::getSort, FlwProcessVO::getProcessSort)
                        .innerJoin(FlwProcessConfigure.class, FlwProcessConfigure::getProcessId, FlwProcess::getId)
                        .in(FlwProcess::getProcessState, Arrays.asList(0, 1))
        );
    }

    default List<FlwProcessVO> selectLaunchProcessList() {
        return selectJoinList(FlwProcessVO.class,
                new MPJLambdaWrapper<FlwProcess>()
                        .select(FlwProcessConfigure::getCategoryId, FlwProcessConfigure::getProcessId)
                        .select(FlwProcess::getProcessKey, FlwProcess::getProcessName, FlwProcess::getProcessIcon,
                                FlwProcess::getProcessType, FlwProcess::getProcessVersion, FlwProcess::getInstanceUrl,
                                FlwProcess::getRemark, FlwProcess::getUseScope, FlwProcess::getProcessState, FlwProcess::getCreateTime)
                        .selectAs(FlwProcess::getSort, FlwProcessVO::getProcessSort)
                        .innerJoin(FlwProcessConfigure.class, FlwProcessConfigure::getProcessId, FlwProcess::getId)
                        .eq(FlwProcess::getProcessState, 1)
                        .eq(FlwProcess::getProcessType, "main")
        );
    }

    default List<FlwProcess> selectListByProcessKey(String tenantId, String processKey) {
        return this.selectList(Wrappers.<FlwProcess>lambdaQuery()
                .eq(FlwProcess::getProcessKey, processKey)
                .eq(StrUtil.isNotBlank(tenantId), FlwProcess::getTenantId, tenantId)
                .orderByDesc(FlwProcess::getProcessVersion));
    }

}
