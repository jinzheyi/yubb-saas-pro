package cn.iocoder.yudao.module.platform.api.logger;

import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformOperateLogCreateReqDTO;
import javax.validation.Valid;

/**
 * 操作日志 API 接口
 *
 * @author 圣钰科技
 */
public interface PlatformOperateLogApi {

    /**
     * 创建操作日志
     *
     * @param createReqDTO 请求
     */
    void createOperateLog(@Valid PlatformOperateLogCreateReqDTO createReqDTO);

}
