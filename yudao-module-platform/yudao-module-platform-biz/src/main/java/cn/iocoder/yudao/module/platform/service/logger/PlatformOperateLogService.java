package cn.iocoder.yudao.module.platform.service.logger;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.platform.api.logger.dto.OperateLogCreateReqDTO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.operatelog.OperateLogExportReqVO;
import cn.iocoder.yudao.module.platform.controller.center.logger.vo.operatelog.OperateLogPageReqVO;
import cn.iocoder.yudao.module.platform.dal.dataobject.logger.PlatformOperateLogDO;

import java.util.List;

/**
 * 操作日志 Service 接口
 *
 * @author 芋道源码
 */
public interface PlatformOperateLogService {

    /**
     * 记录操作日志
     *
     * @param createReqDTO 操作日志请求
     */
    void createOperateLog(OperateLogCreateReqDTO createReqDTO);

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
    List<PlatformOperateLogDO> getOperateLogs(OperateLogExportReqVO reqVO);

}
