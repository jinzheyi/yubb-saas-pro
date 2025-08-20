package com.shengyu.module.system.dal.mysql.flow;

import com.github.yulichang.wrapper.MPJLambdaWrapper;
import com.shengyu.framework.mybatis.core.mapper.BaseMapperX;
import com.shengyu.module.system.controller.admin.flow.vo.TaskTransferVO;
import com.shengyu.module.system.dal.dataobject.flow.FlwTransferConfigure;
import com.shengyu.module.system.dal.dataobject.user.AdminUserDO;
import java.util.Date;

/**
 * <p>
 * 流程转办配置 Mapper 接口
 * </p>
 *
 * @author 青苗
 * @since 2025-08-17
 */
public interface FlwTransferConfigureMapper extends BaseMapperX<FlwTransferConfigure> {

    default TaskTransferVO selectByUserId(Long userId, Date nowTime) {
        return selectJoinOne(TaskTransferVO.class,
          new MPJLambdaWrapper<FlwTransferConfigure>()
            .select(AdminUserDO::getId, AdminUserDO::getNickname)
            .innerJoin(AdminUserDO.class, AdminUserDO::getId, FlwTransferConfigure::getTransferId)
            .eq(FlwTransferConfigure::getUserId, userId)
            .le(FlwTransferConfigure::getBeginTime, nowTime)
            .ge(FlwTransferConfigure::getEndTime, nowTime)
        );
    }


}
