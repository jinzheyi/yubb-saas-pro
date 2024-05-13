package com.shengyu.module.system.convert.plug;

import com.shengyu.module.system.api.plug.dto.order.PlugOrderDetailRespDTO;
import com.shengyu.module.system.controller.admin.plug.vo.order.PlugOrderDetailRespVO;
import com.shengyu.module.system.dal.dataobject.plug.PlugOrderDO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

/**
 * 插件订单 Convert
 *
 * @author zhusy
 */
@Mapper
public interface PlugOrderConvert {

    PlugOrderConvert INSTANCE = Mappers.getMapper(PlugOrderConvert.class);

    PlugOrderDetailRespVO convert1(PlugOrderDO bean);

    @Mapping(source = "itemRespVOS", target = "itemRespDTOS")
    PlugOrderDetailRespDTO convertDTO(PlugOrderDetailRespVO respVO);

}
