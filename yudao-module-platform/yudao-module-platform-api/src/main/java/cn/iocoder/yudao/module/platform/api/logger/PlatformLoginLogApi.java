package cn.iocoder.yudao.module.platform.api.logger;

import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformLoginLogCreateReqDTO;

import javax.validation.Valid;

/**
 * 平台登录日志的 API 接口
 *
 * @author 朱述勇
 * @since 2022/7/7 4:27 PM
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
public interface PlatformLoginLogApi {

    /**
     * 创建登录日志
     *
     * @param reqDTO 日志信息
     */
    void createLoginLog(@Valid PlatformLoginLogCreateReqDTO reqDTO);

}
