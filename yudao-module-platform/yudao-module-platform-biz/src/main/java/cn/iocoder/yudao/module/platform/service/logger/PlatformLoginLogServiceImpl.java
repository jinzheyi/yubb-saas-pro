package cn.iocoder.yudao.module.platform.service.logger;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.api.logger.dto.LoginLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog.LoginLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.loginlog.LoginLogPageReqVO;
import cn.iocoder.yudao.module.platform.convert.logger.LoginLogConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformLoginLogDO;
import cn.iocoder.yudao.module.platform.dal.mysql.logger.PlatformLoginLogMapper;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;
import java.util.List;

/**
 * 登录日志 Service 实现
 */
@Service
@Validated
public class PlatformLoginLogServiceImpl implements PlatformLoginLogService {

    @Resource
    private PlatformLoginLogMapper platformLoginLogMapper;

    @Override
    public PageResult<PlatformLoginLogDO> getLoginLogPage(LoginLogPageReqVO reqVO) {
        return platformLoginLogMapper.selectPage(reqVO);
    }

    @Override
    public List<PlatformLoginLogDO> getLoginLogList(LoginLogExportReqVO reqVO) {
        return platformLoginLogMapper.selectList(reqVO);
    }

    @Override
    public void createLoginLog(LoginLogCreateReqDTO reqDTO) {
        PlatformLoginLogDO loginLog = LoginLogConvert.INSTANCE.convert(reqDTO);
        platformLoginLogMapper.insert(loginLog);
    }

}
