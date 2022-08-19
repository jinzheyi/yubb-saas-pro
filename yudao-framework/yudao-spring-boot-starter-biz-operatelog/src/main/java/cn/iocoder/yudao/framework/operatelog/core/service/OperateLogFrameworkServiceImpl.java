package cn.iocoder.yudao.framework.operatelog.core.service;

import cn.hutool.core.bean.BeanUtil;
import cn.iocoder.yudao.framework.common.enums.UserTypeEnum;
import cn.iocoder.yudao.module.platform.api.logger.PlatformOperateLogApi;
import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformOperateLogCreateReqDTO;
import cn.iocoder.yudao.module.system.api.logger.OperateLogApi;
import cn.iocoder.yudao.module.system.api.logger.dto.OperateLogCreateReqDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Async;

import java.util.Objects;

/**
 * 操作日志 Framework Service 实现类
 *
 * 基于 {@link OperateLogApi} 实现，记录操作日志
 *
 * @author 芋道源码
 */
@RequiredArgsConstructor
public class OperateLogFrameworkServiceImpl implements OperateLogFrameworkService {

    private final OperateLogApi operateLogApi;

    private final PlatformOperateLogApi platformOperateLogApi;

    @Override
    @Async
    public void createOperateLog(OperateLog operateLog) {
        //TODO 这里我觉得没必要用策略模式去弄，也不多，创建过多的类不利于理解，当然而开想改也行
        if (Objects.equals(operateLog.getUserType(), UserTypeEnum.ADMIN.getValue())) {
            OperateLogCreateReqDTO reqDTO = BeanUtil.copyProperties(operateLog, OperateLogCreateReqDTO.class);
            operateLogApi.createOperateLog(reqDTO);
        }
        if (Objects.equals(operateLog.getUserType(), UserTypeEnum.CENTER.getValue())) {
            PlatformOperateLogCreateReqDTO reqDTO = BeanUtil.copyProperties(operateLog, PlatformOperateLogCreateReqDTO.class);
            platformOperateLogApi.createOperateLog(reqDTO);
        }
    }

}
