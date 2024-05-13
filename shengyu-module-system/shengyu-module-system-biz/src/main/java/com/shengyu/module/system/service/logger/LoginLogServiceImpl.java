package com.shengyu.module.system.service.logger;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.framework.tenant.core.context.TenantContextHolder;
import com.shengyu.module.system.api.logger.dto.LoginLogCreateReqDTO;
import com.shengyu.module.system.controller.admin.logger.vo.loginlog.LoginLogExportReqVO;
import com.shengyu.module.system.controller.admin.logger.vo.loginlog.LoginLogPageReqVO;
import com.shengyu.module.system.dal.dataobject.logger.LoginLogDO;
import com.shengyu.module.system.dal.mysql.logger.LoginLogMapper;
import java.util.List;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

/**
 * 登录日志 Service 实现
 */
@Service
@Validated
public class LoginLogServiceImpl implements LoginLogService {

    @Resource
    private LoginLogMapper loginLogMapper;

    @Override
    public PageResult<LoginLogDO> getLoginLogPage(LoginLogPageReqVO reqVO) {
        return loginLogMapper.selectPage(reqVO);
    }

    @Override
    public List<LoginLogDO> getLoginLogList(LoginLogExportReqVO reqVO) {
        return loginLogMapper.selectList(reqVO);
    }

    @Override
    public void createLoginLog(LoginLogCreateReqDTO reqDTO) {
        LoginLogDO loginLog = BeanUtils.toBean(reqDTO, LoginLogDO.class);
        loginLog.setTenantId(TenantContextHolder.getTenantId());
        loginLogMapper.insert(loginLog);
    }

}
