package cn.iocoder.yudao.module.platform.api.logger;

import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformOperateLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.service.logger.PlatformOperateLogService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

/**
 * 操作日志 API 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
public class PlatformPlatformOperateLogApiImpl implements PlatformOperateLogApi {

    @Resource
    private PlatformOperateLogService platformOperateLogService;

    @Override
    public void createOperateLog(PlatformOperateLogCreateReqDTO createReqDTO) {
        platformOperateLogService.createOperateLog(createReqDTO);
    }

}
