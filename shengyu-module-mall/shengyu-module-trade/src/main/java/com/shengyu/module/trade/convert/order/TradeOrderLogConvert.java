package com.shengyu.module.trade.convert.order;

import com.shengyu.module.trade.dal.dataobject.order.TradeOrderLogDO;
import com.shengyu.module.trade.service.order.bo.TradeOrderLogCreateReqBO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

@Mapper
public interface TradeOrderLogConvert {

    TradeOrderLogConvert INSTANCE = Mappers.getMapper(TradeOrderLogConvert.class);

    TradeOrderLogDO convert(TradeOrderLogCreateReqBO bean);

}
