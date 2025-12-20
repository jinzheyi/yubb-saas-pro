package com.shengyu.module.system.service.im;

import com.shengyu.module.system.controller.admin.im.vo.report.ImReportSaveReqVO;
import com.shengyu.module.system.dal.dataobject.im.ImReportDO;

/**
 * 举报服务接口
 *
 * @author 朱述勇
 * @since 2025/12/20
 */
public interface ImReportService {

    /**
     * 保存举报
     *
     * @param reqVO 举报请求
     * @return 举报信息
     */
    ImReportDO saveReport(ImReportSaveReqVO reqVO);
}