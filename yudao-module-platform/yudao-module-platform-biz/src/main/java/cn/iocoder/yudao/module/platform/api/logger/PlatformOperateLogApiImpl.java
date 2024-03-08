package cn.iocoder.yudao.module.platform.api.logger;

import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformOperateLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.service.logger.PlatformOperateLogService;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * 操作日志 API 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
public class PlatformOperateLogApiImpl implements PlatformOperateLogApi {

    @Resource
    private PlatformOperateLogService platformOperateLogService;

    @Override
    public void createOperateLog(PlatformOperateLogCreateReqDTO createReqDTO) {
        platformOperateLogService.createOperateLog(createReqDTO);
    }

}
