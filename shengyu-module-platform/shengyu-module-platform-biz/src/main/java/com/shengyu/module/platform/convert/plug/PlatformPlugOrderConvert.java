package com.shengyu.module.platform.convert.plug;

import com.shengyu.module.platform.controller.platform.plug.vo.order.PlugOrderDetailRespVO;
import com.shengyu.module.system.api.plug.dto.order.PlugOrderDetailRespDTO;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

/**
 * 插件订单 Convert
 *
 * @author 圣钰SaaS
 */
@Mapper
public interface PlatformPlugOrderConvert {

    PlatformPlugOrderConvert INSTANCE = Mappers.getMapper(PlatformPlugOrderConvert.class);

    @Mapping(source = "itemRespDTOS", target = "itemRespVOS")
    PlugOrderDetailRespVO convert(PlugOrderDetailRespDTO respDTO);

}
