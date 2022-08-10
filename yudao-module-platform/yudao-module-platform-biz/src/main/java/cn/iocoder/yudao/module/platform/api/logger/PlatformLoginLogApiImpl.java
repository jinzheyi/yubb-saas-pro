package cn.iocoder.yudao.module.platform.api.logger;

import cn.iocoder.yudao.module.platform.api.logger.dto.LoginLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.service.logger.PlatformLoginLogService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

/**
 * 登录日志的 API 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
public class PlatformLoginLogApiImpl implements LoginLogApi {

    @Resource
    private PlatformLoginLogService platformLoginLogService;

    @Override
    public void createLoginLog(LoginLogCreateReqDTO reqDTO) {
        platformLoginLogService.createLoginLog(reqDTO);
    }

}
