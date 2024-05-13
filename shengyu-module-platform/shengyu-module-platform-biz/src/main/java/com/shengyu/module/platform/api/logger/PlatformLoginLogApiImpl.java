package com.shengyu.module.platform.api.logger;

import com.shengyu.module.platform.api.logger.dto.PlatformLoginLogCreateReqDTO;
import com.shengyu.module.platform.service.logger.PlatformLoginLogService;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * 登录日志的 API 实现类
 *
 * @author 圣钰科技
 */
@Service
@Validated
public class PlatformLoginLogApiImpl implements PlatformLoginLogApi {

    @Resource
    private PlatformLoginLogService loginLogService;

    @Override
    public void createLoginLog(PlatformLoginLogCreateReqDTO reqDTO) {
        loginLogService.createLoginLog(reqDTO);
    }

}
