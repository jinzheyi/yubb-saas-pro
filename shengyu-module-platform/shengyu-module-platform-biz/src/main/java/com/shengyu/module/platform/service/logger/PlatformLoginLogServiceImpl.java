package com.shengyu.module.platform.service.logger;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.api.logger.dto.PlatformLoginLogCreateReqDTO;
import com.shengyu.module.platform.controller.platform.logger.vo.loginlog.LoginLogExportReqVO;
import com.shengyu.module.platform.controller.platform.logger.vo.loginlog.LoginLogPageReqVO;
import com.shengyu.module.platform.dal.dataobject.logger.PlatformLoginLogDO;
import com.shengyu.module.platform.dal.mysql.logger.PlatformLoginLogMapper;
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
