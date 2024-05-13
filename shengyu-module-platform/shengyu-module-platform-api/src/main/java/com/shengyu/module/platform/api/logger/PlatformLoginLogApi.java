package com.shengyu.module.platform.api.logger;

import com.shengyu.module.platform.api.logger.dto.PlatformLoginLogCreateReqDTO;
import javax.validation.Valid;

/**
 * 登录日志的 API 接口
 *
 * @author 圣钰科技
 */
public interface PlatformLoginLogApi {

    /**
     * 创建登录日志
     *
     * @param reqDTO 日志信息
     */
    void createLoginLog(@Valid PlatformLoginLogCreateReqDTO reqDTO);

}
