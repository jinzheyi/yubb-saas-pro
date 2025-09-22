package com.shengyu.module.pay.api.refund;

import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.pay.api.refund.dto.PayRefundCreateReqDTO;
import com.shengyu.module.pay.api.refund.dto.PayRefundRespDTO;
import com.shengyu.module.pay.dal.dataobject.refund.PayRefundDO;
import com.shengyu.module.pay.service.refund.PayRefundService;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;

import javax.annotation.Resource;

/**
 * 退款单 API 实现类
 *
 * @author 芋道源码
 */
@Service
@Validated
public class PayRefundApiImpl implements PayRefundApi {

    @Resource
    private PayRefundService payRefundService;

    @Override
    public Long createRefund(PayRefundCreateReqDTO reqDTO) {
        return payRefundService.createRefund(reqDTO);
    }

    @Override
    public PayRefundRespDTO getRefund(Long id) {
        PayRefundDO refund = payRefundService.getRefund(id);
        return BeanUtils.toBean(refund, PayRefundRespDTO.class);
    }

}
