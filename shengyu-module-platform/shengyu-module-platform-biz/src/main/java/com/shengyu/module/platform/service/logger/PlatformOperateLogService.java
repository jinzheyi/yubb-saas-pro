package com.shengyu.module.platform.service.logger;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.platform.api.logger.dto.PlatformOperateLogCreateReqDTO;
import com.shengyu.module.platform.controller.platform.logger.vo.operatelog.OperateLogExportReqVO;
import com.shengyu.module.platform.controller.platform.logger.vo.operatelog.OperateLogPageReqVO;
import com.shengyu.module.platform.dal.dataobject.logger.PlatformOperateLogDO;

import java.util.List;

/**
 * 操作日志 Service 接口
 *
 * @author 圣钰科技
 */
public interface PlatformOperateLogService {

    /**
     * 记录操作日志
     *
     * @param createReqDTO 操作日志请求
     */
    void createOperateLog(PlatformOperateLogCreateReqDTO createReqDTO);

    /**
     * 获得操作日志分页列表
     *
     * @param reqVO 分页条件
     * @return 操作日志分页列表
     */
    PageResult<PlatformOperateLogDO> getOperateLogPage(OperateLogPageReqVO reqVO);

    /**
     * 获得操作日志列表
     *
     * @param reqVO 列表条件
     * @return 日志列表
     */
    List<PlatformOperateLogDO> getOperateLogList(OperateLogExportReqVO reqVO);

}
