package cn.iocoder.yudao.module.platform.service.logger;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformLoginLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog.LoginLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog.LoginLogPageReqVO;
import cn.iocoder.yudao.module.platform.convert.logger.LoginLogConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.LoginLogDO;
import cn.iocoder.yudao.module.platform.dal.mapper.logger.PlatformLoginLogMapper;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.List;

/**
 * 平台登录日志 Service 实现
 */
@Service
@Validated
public class PlatformLoginLogServiceImpl implements PlatformLoginLogService {

    @Resource
    private PlatformLoginLogMapper loginLogMapper;

    @Override
    public PageResult<LoginLogDO> getLoginLogPage(LoginLogPageReqVO reqVO) {
        return loginLogMapper.selectPage(reqVO);
    }

    @Override
    public List<LoginLogDO> getLoginLogList(LoginLogExportReqVO reqVO) {
        return loginLogMapper.selectList(reqVO);
    }

    @Override
    public void createLoginLog(PlatformLoginLogCreateReqDTO reqDTO) {
        LoginLogDO loginLog = LoginLogConvert.INSTANCE.convert(reqDTO);
        loginLogMapper.insert(loginLog);
    }

}
