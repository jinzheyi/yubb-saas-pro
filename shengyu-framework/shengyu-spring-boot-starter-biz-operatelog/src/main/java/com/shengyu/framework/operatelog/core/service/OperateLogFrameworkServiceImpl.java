package com.shengyu.framework.operatelog.core.service;

import cn.hutool.core.bean.BeanUtil;
import com.shengyu.framework.common.enums.UserTypeEnum;
import com.shengyu.module.platform.api.logger.PlatformOperateLogApi;
import com.shengyu.module.platform.api.logger.dto.PlatformOperateLogCreateReqDTO;
import com.shengyu.module.system.api.logger.OperateLogApi;
import com.shengyu.module.system.api.logger.dto.OperateLogCreateReqDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Async;
import java.util.Objects;

/**
 * 操作日志 Framework Service 实现类
 *
 * 基于 {@link OperateLogApi} 实现，记录操作日志
 *
 * @author 圣钰科技
 */
@RequiredArgsConstructor
public class OperateLogFrameworkServiceImpl implements OperateLogFrameworkService {

    private final OperateLogApi operateLogApi;

    private final PlatformOperateLogApi platformOperateLogApi;

    @Override
    @Async
    public void createOperateLog(OperateLog operateLog) {
        if (Objects.equals(operateLog.getTerrace(), UserTypeEnum.ADMIN.getValue())) {
            OperateLogCreateReqDTO reqDTO = BeanUtil.toBean(operateLog, OperateLogCreateReqDTO.class);
            operateLogApi.createOperateLog(reqDTO);
        }
        if (Objects.equals(operateLog.getTerrace(), UserTypeEnum.PLATFORM.getValue())) {
            PlatformOperateLogCreateReqDTO reqDTO = BeanUtil.toBean(operateLog, PlatformOperateLogCreateReqDTO.class);
            platformOperateLogApi.createOperateLog(reqDTO);
        }
    }

}
