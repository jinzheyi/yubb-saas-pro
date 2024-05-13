package com.shengyu.module.platform.service.logger;

import com.shengyu.module.platform.controller.platform.logger.vo.loginlog.LoginLogExportReqVO;
import com.shengyu.module.platform.controller.platform.logger.vo.loginlog.LoginLogPageReqVO;
import com.shengyu.module.platform.dal.dataobject.logger.PlatformLoginLogDO;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.platform.api.logger.dto.PlatformLoginLogCreateReqDTO;

import javax.validation.Valid;
import java.util.List;

/**
 * 登录日志 Service 接口
 */
public interface PlatformLoginLogService {

    /**
     * 获得登录日志分页
     *
     * @param reqVO 分页条件
     * @return 登录日志分页
     */
    PageResult<PlatformLoginLogDO> getLoginLogPage(LoginLogPageReqVO reqVO);

    /**
     * 获得登录日志列表
     *
     * @param reqVO 列表条件
     * @return 登录日志列表
     */
    List<PlatformLoginLogDO> getLoginLogList(LoginLogExportReqVO reqVO);

    /**
     * 创建登录日志
     *
     * @param reqDTO 日志信息
     */
    void createLoginLog(@Valid PlatformLoginLogCreateReqDTO reqDTO);

}
