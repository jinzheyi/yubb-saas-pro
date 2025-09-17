package com.shengyu.module.trade.service.order;

import com.shengyu.module.trade.convert.order.TradeOrderLogConvert;
import com.shengyu.module.trade.dal.dataobject.order.TradeOrderLogDO;
import com.shengyu.module.trade.dal.mysql.order.TradeOrderLogMapper;
import com.shengyu.module.trade.service.order.bo.TradeOrderLogCreateReqBO;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;
import java.util.List;

/**
 * 交易下单日志 Service 实现类
 *
 * @author 陈賝
 * @since 2023/7/6 15:44
 */
@Service
public class TradeOrderLogServiceImpl implements TradeOrderLogService {

    @Resource
    private TradeOrderLogMapper tradeOrderLogMapper;

    @Override
    public void createOrderLog(TradeOrderLogCreateReqBO createReqBO) {
        tradeOrderLogMapper.insert(TradeOrderLogConvert.INSTANCE.convert(createReqBO));
    }

    @Override
    public List<TradeOrderLogDO> getOrderLogListByOrderId(Long orderId) {
        return tradeOrderLogMapper.selectListByOrderId(orderId);
    }

}
