package com.shengyu.module.system.service.im;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.system.controller.app.im.vo.readreceipt.AppImReadReceiptDetailReqVO;
import com.shengyu.module.system.controller.app.im.vo.readreceipt.AppImReadReceiptDetailRespVO;
import com.shengyu.module.system.controller.app.im.vo.readreceipt.AppImReadReceiptSummaryRespVO;

public interface ImReadReceiptService {

    AppImReadReceiptSummaryRespVO getSummary(Long userId, Long messageId);

    PageResult<AppImReadReceiptDetailRespVO> getDetail(Long userId, AppImReadReceiptDetailReqVO reqVO);

}
