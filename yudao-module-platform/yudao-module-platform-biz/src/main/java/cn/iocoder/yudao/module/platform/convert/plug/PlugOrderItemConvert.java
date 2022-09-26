package cn.iocoder.yudao.module.platform.convert.plug;

import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

/**
 * 订单项 Convert
 *
 * @author 朱述勇
 */
@Mapper
public interface PlugOrderItemConvert {

    PlugOrderItemConvert INSTANCE = Mappers.getMapper(PlugOrderItemConvert.class);

}
