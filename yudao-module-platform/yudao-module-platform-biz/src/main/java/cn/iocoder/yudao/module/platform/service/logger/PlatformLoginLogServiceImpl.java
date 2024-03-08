package cn.iocoder.yudao.module.platform.service.logger;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.platform.api.logger.dto.PlatformLoginLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.loginlog.LoginLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.platform.logger.vo.loginlog.LoginLogPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformLoginLogDO;
import cn.iocoder.yudao.module.platform.dal.mysql.logger.PlatformLoginLogMapper;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

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
    public void createLoginLog(PlatformLoginLogCreateReqDTO reqDTO) {
        PlatformLoginLogDO loginLog = BeanUtils.toBean(reqDTO, PlatformLoginLogDO.class);
        platformLoginLogMapper.insert(loginLog);
    }

}
