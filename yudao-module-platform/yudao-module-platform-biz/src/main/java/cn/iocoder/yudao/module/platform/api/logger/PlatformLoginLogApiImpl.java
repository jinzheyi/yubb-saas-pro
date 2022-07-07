package cn.iocoder.yudao.module.platform.api.logger;

import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformLoginLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.service.logger.PlatformLoginLogService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

/**
 * 平台登录日志的 API 实现类
 *
 * @author 朱述勇
 * @since 2022/7/7 4:32 PM
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 */
@Service
@Validated
public class PlatformLoginLogApiImpl implements PlatformLoginLogApi {

    @Resource
    private PlatformLoginLogService platformLoginLogService;

    @Override
    public void createLoginLog(PlatformLoginLogCreateReqDTO reqDTO) {
        platformLoginLogService.createLoginLog(reqDTO);
    }

}
